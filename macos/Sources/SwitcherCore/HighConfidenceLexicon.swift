import Foundation

/// Small, high-precision additions for terms that general spellcheckers often
/// miss. Large dictionaries remain a fallback; this set is a positive signal.
public enum HighConfidenceLexicon {
    private static let english: Set<String> = [
        "admin", "ai", "api", "app", "apps", "auth", "backend", "bash",
        "cdn", "ci", "cli", "cms", "config", "crm", "css", "db", "dev",
        "dns", "docker", "docs", "erp", "frontend", "ftp", "git", "github",
        "gitlab", "html", "http", "https", "iaas", "ide", "info", "inst",
        "install", "instance", "instagram", "ios", "ipad", "iphone", "ip",
        "isp", "ispmanager", "javascript", "json", "jwt", "kubernetes",
        "linux", "llm", "macos", "ml", "mongodb", "mysql", "nginx", "node",
        "nodejs", "npm", "npx", "oauth", "paas", "postgres", "postgresql",
        "prod", "python", "qa", "react", "redis", "repo", "saas", "sdk",
        "sftp", "sql", "ssh", "ssl", "swift", "tcp", "tls", "toml",
        "typescript", "udp", "ui", "uri", "url", "uuid", "ux", "vds",
        "vpn", "vps", "vue", "wifi", "yaml", "zsh",
    ]

    public static func contains(_ word: String, language: String) -> Bool {
        switch language.lowercased().prefix(2) {
        case "en": english.contains(word.lowercased())
        default: false
        }
    }
}
