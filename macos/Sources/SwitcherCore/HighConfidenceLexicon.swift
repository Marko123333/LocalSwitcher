import Foundation

/// Small, high-precision additions for terms that general spellcheckers often
/// miss. Large dictionaries remain a fallback; this set is a positive signal.
public enum HighConfidenceLexicon {
    private static let english: Set<String> = [
        "api", "bash", "cli", "css", "dns", "docker", "git", "github",
        "gitlab", "html", "http", "https", "ide", "ios", "ipad", "iphone",
        "javascript", "json", "jwt", "kubernetes", "linux", "macos", "mongodb",
        "mysql", "nginx", "node", "nodejs", "npm", "npx", "oauth", "postgres",
        "postgresql", "python", "react", "redis", "sdk", "sql", "ssh", "ssl",
        "swift", "tcp", "tls", "toml", "typescript", "udp", "uri", "url",
        "uuid", "vds", "vpn", "vps", "vue", "wifi", "yaml", "zsh",
    ]

    public static func contains(_ word: String, language: String) -> Bool {
        switch language.lowercased().prefix(2) {
        case "en": english.contains(word.lowercased())
        default: false
        }
    }
}
