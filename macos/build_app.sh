#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="LocalSwitcher"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
# version.json живёт в КОРНЕ репозитория (живой фид обновлений) — не переносить!
# RS_VERSION_JSON переопределяет источник версии (для бета-сборок → version-beta.json).
VERSION_JSON="${RS_VERSION_JSON:-$PROJECT_DIR/../version.json}"

# version.json — единый источник правды. Значения в Info.plist в репо
# игнорируются: скрипт штампует CFBundleShortVersionString и CFBundleVersion
# в копию Info.plist внутри собранного бандла.
SHORT_VERSION=$(/usr/bin/python3 -c "import json,sys;print(json.load(open('$VERSION_JSON'))['version'])")
BUILD_VERSION=$(/usr/bin/python3 -c "import json,sys;print(json.load(open('$VERSION_JSON')).get('build','1'))")
DEV_TAG=$(/usr/bin/python3 -c "import json,sys;print(json.load(open('$VERSION_JSON')).get('dev',''))")

if [ -z "$SHORT_VERSION" ]; then
    echo "ERROR: could not read version from $VERSION_JSON"
    exit 1
fi

echo "=== Building $APP_NAME v$SHORT_VERSION (build $BUILD_VERSION) ==="

# 1. На локальной M1-машине по умолчанию собираем arm64. Universal SwiftPM
# требует полный Xcode; включается явно через RS_UNIVERSAL=1.
cd "$PROJECT_DIR"
if [ "${RS_UNIVERSAL:-0}" = "1" ]; then
    echo "→ swift build -c release --arch arm64 --arch x86_64 (universal)..."
    swift build -c release --arch arm64 --arch x86_64
    BUILD_DIR="$PROJECT_DIR/.build/apple/Products/Release"
    EXPECTED_ARCHS=("arm64" "x86_64")
else
    BUILD_ARCH="${RS_ARCH:-$(uname -m)}"
    echo "→ swift build -c release --arch $BUILD_ARCH..."
    swift build -c release --arch "$BUILD_ARCH"
    BUILD_DIR="$PROJECT_DIR/.build/$BUILD_ARCH-apple-macosx/release"
    EXPECTED_ARCHS=("$BUILD_ARCH")
fi

# 2. Создаём .app bundle
echo "→ Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Копируем бинарник
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 3a. SwiftPM кладёт ресурсы SwitcherCore в отдельный bundle. Без него
# словари е/ё будут недоступны в упакованном приложении.
RESOURCE_BUNDLE="$BUILD_DIR/${APP_NAME}_SwitcherCore.bundle"
if [ ! -d "$RESOURCE_BUNDLE" ]; then
    echo "ERROR: resource bundle not found: $RESOURCE_BUNDLE"
    exit 1
fi
cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"

# 3b. Самопроверка архитектуры.
ARCHS=$(lipo -archs "$APP_BUNDLE/Contents/MacOS/$APP_NAME")
for expected in "${EXPECTED_ARCHS[@]}"; do
    if [[ "$ARCHS" != *"$expected"* ]]; then
        echo "ERROR: expected architecture $expected, got: $ARCHS"
        exit 1
    fi
done
echo "→ Architecture OK: $ARCHS"

# 4. Копируем Info.plist и штампуем версию из version.json
cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $SHORT_VERSION" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_VERSION" "$APP_BUNDLE/Contents/Info.plist"
# Dev-метка (буква) для непубликуемых сборок — пусто для релиза. Показывается в About/меню.
/usr/libexec/PlistBuddy -c "Set :RSDevTag $DEV_TAG" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :RSDevTag string $DEV_TAG" "$APP_BUNDLE/Contents/Info.plist"
echo "→ Stamped Info.plist: CFBundleShortVersionString=$SHORT_VERSION$DEV_TAG CFBundleVersion=$BUILD_VERSION"

# 5. Копируем иконку
cp "$PROJECT_DIR/LocalSwitcher.icns" "$APP_BUNDLE/Contents/Resources/LocalSwitcher.icns"

# 6. Создаём PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# 7. Finder/File Provider добавляет xattrs даже свежему bundle в Documents.
# Они запрещены codesign, поэтому очищаем только что созданный .app.
xattr -cr "$APP_BUNDLE"

# 8. Локально подписываем ad-hoc. Для релиза RS_SIGN_ID должен содержать
#    собственный Developer ID автора сборки.
SIGN_ID="${RS_SIGN_ID:--}"
echo "→ Code signing..."
codesign --force --deep --sign "$SIGN_ID" \
    --options runtime \
    --entitlements "$PROJECT_DIR/LocalSwitcher.entitlements" \
    "$APP_BUNDLE"
# Documents может повторно добавить FinderInfo сразу после подписи. Удаление
# xattrs не меняет seal, но делает bundle приемлемым для strict-проверки.
xattr -cr "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo ""
echo "=== Done! ==="
echo "App bundle: $APP_BUNDLE"
echo "Signed with: $SIGN_ID"
echo ""
echo "To install:"
echo "  cp -R $APP_BUNDLE /Applications/"
