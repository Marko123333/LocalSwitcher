import Foundation

/// Small, high-precision additions for terms that general spellcheckers often
/// miss. Large dictionaries remain a fallback; this set is a positive signal.
public enum HighConfidenceLexicon {
    private static let english: Set<String> = [
        "admin", "ai", "api", "app", "apps", "asp", "auth", "backend", "bash",
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
        "vpn", "vps", "vue", "wifi", "yaml", "zsh", "deno", "express",
        "io", "js", "nest", "net", "next", "nuxt", "socket", "three", "ts",
    ]

    /// Dotted product/runtime names are not normal dictionary words, but they are
    /// common layout-switching targets. Keep this deliberately narrow: treating
    /// any `word.tld` as a positive signal would rewrite URLs and email domains.
    private static let englishDottedTokens: Set<String> = [
        "asp.net", "deno.land", "express.js", "nest.js", "next.js", "node.js",
        "nuxt.js", "react.js", "socket.io", "three.js", "vue.js",
    ]

    public static func contains(_ word: String, language: String) -> Bool {
        switch language.lowercased().prefix(2) {
        case "en": english.contains(word.lowercased())
        default: false
        }
    }

    /// Recognises a curated technical token, optionally followed by ordinary
    /// sentence punctuation (`node.js,`). The punctuation is not part of the
    /// positive signal; callers still convert the original key sequence so it is
    /// preserved in the destination layout.
    public static func containsTechnicalToken(_ token: String, language: String) -> Bool {
        guard language.lowercased().hasPrefix("en") else { return false }
        let trimmed = token.lowercased().trimmingCharacters(
            in: CharacterSet(charactersIn: ".,!?;:)]}")
        )
        return englishDottedTokens.contains(trimmed)
    }
}
