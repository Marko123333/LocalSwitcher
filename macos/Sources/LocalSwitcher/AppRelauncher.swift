import AppKit
import Foundation

/// Единая точка перезапуска приложения.
/// Раньше эта последовательность была скопирована в AppDelegate и UpdateChecker.
@MainActor
enum AppRelauncher {
    /// Перезапускает приложение: открывает бандл заново и завершает текущий процесс.
    static func relaunch(bundlePath: String = Bundle.main.bundlePath) {
        // Путь передаём ПОЗИЦИОННЫМ аргументом ($1), а НЕ интерполяцией в команду — иначе
        // путь с кавычкой/;/`$()` привёл бы к shell-инъекции. sh не пере-парсит $1.
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1; open \"$1\"", "localswitcher-relaunch", bundlePath]
        try? task.run()
        NSApplication.shared.terminate(nil)
    }
}
