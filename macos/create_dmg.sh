#!/bin/bash
set -e

APP_NAME="LocalSwitcher"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"   # все относительные пути — от macos/ (аудит: раньше зависели от CWD)
# --beta: собрать ПРЕД-РЕЛИЗ из version-beta.json, НЕ трогая стабильный фид (version.json)
# и cask. Иначе — обычный стабильный релиз из version.json (живой фид обновлений).
BETA=0
VERSION_FILE="../version.json"
if [ "${1:-}" = "--beta" ]; then
    BETA=1
    VERSION_FILE="../version-beta.json"
    echo "=== BETA build (source: $VERSION_FILE — stable version.json/cask untouched) ==="
fi
# build_app.sh читает тот же источник версии через RS_VERSION_JSON.
export RS_VERSION_JSON="$SCRIPT_DIR/$VERSION_FILE"
VERSION=$(/usr/bin/python3 -c "import json;print(json.load(open('$VERSION_FILE'))['version'])")
BUILD=$(/usr/bin/python3 -c "import json;print(json.load(open('$VERSION_FILE')).get('build','1'))")
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
# Нотаризация: предпочитаем API-ключ App Store Connect — файл на диске, НЕ зависит
# от Keychain (keychain-профиль уже дважды пропадал: 2026-07-01 и 2026-07-10).
# Конфиг ключа: ~/.config/localswitcher/notary.conf (задаёт NOTARY_KEY_FILE,
# NOTARY_KEY_ID, NOTARY_ISSUER_ID; chmod 600). Фолбэк — keychain-профиль.
# Переопределение: NOTARIZE_PROFILE=<name>, NOTARY_CONF=<path>. Пропуск: SKIP_NOTARIZE=1.
NOTARIZE_PROFILE="${NOTARIZE_PROFILE:-localswitcher-notary}"
NOTARY_CONF="${NOTARY_CONF:-$HOME/.config/localswitcher/notary.conf}"
if [ -f "$NOTARY_CONF" ]; then
    # shellcheck source=/dev/null
    . "$NOTARY_CONF"
fi
if [ -n "${NOTARY_KEY_FILE:-}" ] && [ -f "$NOTARY_KEY_FILE" ] \
   && [ -n "${NOTARY_KEY_ID:-}" ] && [ -n "${NOTARY_ISSUER_ID:-}" ]; then
    NOTARY_ARGS=(--key "$NOTARY_KEY_FILE" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID")
    NOTARY_VIA="ASC API key $NOTARY_KEY_ID"
else
    NOTARY_ARGS=(--keychain-profile "$NOTARIZE_PROFILE")
    NOTARY_VIA="keychain profile $NOTARIZE_PROFILE"
fi
DMG_TEMP="${APP_NAME}-temp.dmg"
VOL_NAME="${APP_NAME}"
BACKGROUND="dmg_background.png"
APP_PATH="${APP_NAME}.app"
DMG_SIZE="24m"

echo "=== Creating styled DMG ==="

# 00. Fail fast: нотаризационный профиль проверяем ДО многоминутной сборки.
#     Профиль уже ДВАЖДЫ пропадал из Keychain (2026-07: удалён на живой системе
#     между релизами, без ребута/обновлений — подозрение на чистильщики/VPN-софт),
#     и падение в середине пайплайна путает. Ловим сразу, с рецептом починки.
if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
    if ! xcrun notarytool history "${NOTARY_ARGS[@]}" >/dev/null 2>&1; then
        echo "ОШИБКА: нотаризационные креды недоступны (пробовали: $NOTARY_VIA)."
        echo "Вариант 1 (надёжный): API-ключ App Store Connect в $NOTARY_CONF"
        echo "  (NOTARY_KEY_FILE=…AuthKey_XXX.p8, NOTARY_KEY_ID=…, NOTARY_ISSUER_ID=…)."
        echo "Вариант 2: keychain-профиль (пароль — app-specific password, интерактивно):"
        echo "  xcrun notarytool store-credentials $NOTARIZE_PROFILE \\"
        echo "      --apple-id you@example.com --team-id YOUR_TEAM_ID"
        exit 69
    fi
    echo "→ Notary credentials OK ($NOTARY_VIA)"
fi

# 0. ВСЕГДА пересобираем приложение из исходников. Без этого шага DMG берёт имя
#    из version.json, а payload — из случайно лежащего рядом LocalSwitcher.app.
#    Именно так в релиз 2.1.0 попал бандл 2.0.3: имя было 2.1.0, а внутри 2.0.3.
echo "→ Rebuilding app from source (build_app.sh)..."
"$SCRIPT_DIR/build_app.sh"

# 0a. Жёсткая проверка: версия в собранном бандле обязана совпадать с version.json,
#     иначе отказываемся паковать DMG.
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")
BUNDLE_BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist")
if [ "$BUNDLE_VERSION" != "$VERSION" ] || [ "$BUNDLE_BUILD" != "$BUILD" ]; then
    echo "ERROR: bundle is $BUNDLE_VERSION (build $BUNDLE_BUILD) but version.json is $VERSION (build $BUILD)."
    echo "       Refusing to ship a version-mismatched DMG."
    exit 1
fi
echo "→ Verified bundle $BUNDLE_VERSION (build $BUNDLE_BUILD) matches version.json"

# 0b. Нотаризуем и стейплим САМО приложение ДО упаковки — чтобы тикет был внутри .app.
#     Без этого вытащенный из DMG бандл не имеет своего тикета и при первом запуске
#     зависит от ОНЛАЙН-проверки Gatekeeper (после переноса/в офлайне → «не могу запустить»).
#     Со стейплом на бандле приложение запускается чисто офлайн, без xattr.
if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
    echo "→ Notarizing the app bundle..."
    ditto -c -k --keepParent "$APP_PATH" "${APP_NAME}-app.zip"
    xcrun notarytool submit "${APP_NAME}-app.zip" "${NOTARY_ARGS[@]}" --wait
    rm -f "${APP_NAME}-app.zip"
    echo "→ Stapling the app bundle..."
    xcrun stapler staple "$APP_PATH"
    xcrun stapler validate "$APP_PATH"
fi

# Clean up
rm -f "$DMG_NAME" "$DMG_TEMP"

# 0c. Снимаем «застрявшие» тома с тем же именем. Если /Volumes/LocalSwitcher уже занят,
#     наш temp-образ примонтируется как «LocalSwitcher 1», а AppleScript-оформление
#     (`tell disk "LocalSwitcher"`) уйдёт на чужой/несуществующий диск → .DS_Store с фоном
#     и позициями НЕ запишется в наш образ, и DMG откроется голым. Чистим заранее.
for v in "/Volumes/${VOL_NAME}"*; do
    if [ -d "$v" ]; then
        echo "→ Detaching stale volume: $v"
        hdiutil detach "$v" -force 2>/dev/null || true
    fi
done

# 1. Create temporary writable DMG
echo "→ Creating temp DMG..."
hdiutil create -volname "$VOL_NAME" -fs HFS+ \
    -size "$DMG_SIZE" -layout NONE "$DMG_TEMP"

# 2. Mount it
echo "→ Mounting..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_TEMP" | grep "/Volumes/" | sed 's/.*\(\/Volumes\/.*\)/\1/')
echo "   Mounted at: $MOUNT_DIR"
# Защита: если имя всё же разъехалось (том «LocalSwitcher 1») — оформление уйдёт мимо. Прерываемся.
if [ "$MOUNT_DIR" != "/Volumes/${VOL_NAME}" ]; then
    echo "ERROR: temp DMG mounted at '$MOUNT_DIR', expected '/Volumes/${VOL_NAME}'."
    echo "       Stale volume collision — refusing to build an unstyled DMG."
    hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
    exit 1
fi

# 3. Copy app and create Applications symlink
echo "→ Copying app..."
cp -R "$APP_PATH" "$MOUNT_DIR/"
ln -sf /Applications "$MOUNT_DIR/Applications"

# 4. Create .background directory and copy background image
mkdir -p "$MOUNT_DIR/.background"
cp "$BACKGROUND" "$MOUNT_DIR/.background/background.png"

# 5. Apply Finder settings via AppleScript
echo "→ Configuring Finder view..."
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 760, 500}

        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 96
        set text size of theViewOptions to 13
        set background picture of theViewOptions to file ".background:background.png"

        -- Position: app icon on left, Applications on right
        set position of item "$APP_NAME.app" of container window to {170, 210}
        set position of item "Applications" of container window to {490, 210}

        close
        open

        update without registering applications
        delay 2
    end tell
end tell
APPLESCRIPT

# 6. Set volume icon
if [ -f "${APP_NAME}.icns" ]; then
    cp "${APP_NAME}.icns" "$MOUNT_DIR/.VolumeIcon.icns"
    SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$MOUNT_DIR" 2>/dev/null || true
fi

# 7. Finalize permissions
chmod -Rf go-w "$MOUNT_DIR" 2>/dev/null || true
sync

# 7a. Проверяем, что Finder реально записал оформление. .DS_Store хранит фон и позиции
#     иконок; если его нет — DMG откроется голым. Лучше упасть, чем отдать кривой образ.
if [ ! -f "$MOUNT_DIR/.DS_Store" ]; then
    echo "ERROR: .DS_Store not written to $MOUNT_DIR — DMG styling did NOT apply."
    echo "       Refusing to ship an unstyled DMG."
    hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
    exit 1
fi
echo "→ Styling OK (.DS_Store present)"

# 8. Unmount
echo "→ Unmounting..."
hdiutil detach "$MOUNT_DIR" -quiet

# 9. Convert to compressed read-only DMG
echo "→ Compressing..."
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"
rm -f "$DMG_TEMP"

# 9a. Подписываем САМ .dmg Developer ID. Без этого образ нотаризуется и стейплится, но
#     `spctl -t install` даёт "no usable signature" — у скачанного образа нет подписи
#     контейнера, и на части Mac это приводит к недоверию к вынутому из него .app.
SIGN_ID="${RS_SIGN_ID:--}"
if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
    echo "→ Code signing the DMG (Developer ID + secure timestamp)..."
    codesign --force --timestamp --sign "$SIGN_ID" "$DMG_NAME"
    codesign --verify --verbose=2 "$DMG_NAME"
fi

# 10. Notarize with Apple (required for Gatekeeper to accept the DMG on end-user Macs).
# Signed-but-unnotarized DMGs trigger "Apple could not verify [app] is free of malware".
if [ "${SKIP_NOTARIZE:-0}" = "1" ]; then
    echo "→ SKIP_NOTARIZE=1 — skipping notarization (DMG will NOT pass Gatekeeper on other Macs)"
else
    echo "→ Submitting to Apple notary service ($NOTARY_VIA)..."
    xcrun notarytool submit "$DMG_NAME" \
        "${NOTARY_ARGS[@]}" \
        --wait

    echo "→ Stapling notarization ticket..."
    xcrun stapler staple "$DMG_NAME"
    xcrun stapler validate "$DMG_NAME"
    # Контрольная проверка: образ должен приниматься как установочный носитель.
    echo "→ Verifying DMG passes Gatekeeper (install assessment)..."
    spctl -a -vvv -t install "$DMG_NAME" 2>&1 || echo "WARNING: spctl install assessment did not pass"
fi

# 11. Записываем sha256 обратно в version.json и cask — хэш механически привязан
#     к реально собранному DMG, а не копируется руками (раньше это расходилось).
DMG_SHA=$(shasum -a 256 "$DMG_NAME" | awk '{print $1}')
if [ "$BETA" = "1" ]; then
    # Бета: пишем sha ТОЛЬКО в version-beta.json. Стабильный version.json и cask не трогаем
    # (Homebrew отслеживает стабильные релизы; беты идут только через встроенный апдейтер).
    echo "→ Writing sha256 into $VERSION_FILE (beta feed only; stable version.json/cask untouched)..."
    /usr/bin/python3 - "$DMG_SHA" "$VERSION_FILE" <<'PY'
import json, sys
sha, path = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
data["sha256"] = sha
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
else
    echo "→ Writing sha256 into version.json and localswitcher.rb..."
    /usr/bin/python3 - "$DMG_SHA" <<'PY'
import json, sys
sha = sys.argv[1]
with open("../version.json") as f:
    data = json.load(f)
data["sha256"] = sha
with open("../version.json", "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
    /usr/bin/sed -i '' -E "s/^([[:space:]]*sha256 \").*(\")/\1${DMG_SHA}\2/" "$SCRIPT_DIR/localswitcher.rb"
    /usr/bin/sed -i '' -E "s/^([[:space:]]*version \").*(\")/\1${VERSION}\2/" "$SCRIPT_DIR/localswitcher.rb"

    # Проверяем, что подстановка реально произошла: sed при отсутствии совпадения выходит
    # с кодом 0 (set -e не ловит), поэтому дрейф формата каска прошёл бы молча со старой версией.
    if ! grep -q "sha256 \"${DMG_SHA}\"" "$SCRIPT_DIR/localswitcher.rb" || ! grep -q "version \"${VERSION}\"" "$SCRIPT_DIR/localswitcher.rb"; then
        echo "ERROR: cask update via sed did not take (format drift in localswitcher.rb?). Aborting." >&2
        exit 1
    fi
fi

echo ""
echo "=== Done! ==="
echo "DMG: $(pwd)/$DMG_NAME ($(du -h "$DMG_NAME" | cut -f1))"
echo "SHA256: $DMG_SHA"
echo "→ version.json and localswitcher.rb updated with this hash."
