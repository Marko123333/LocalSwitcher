import Foundation

/// Small, high-precision additions for terms that general spellcheckers often
/// miss. Large dictionaries remain a fallback; this set is a positive signal.
public enum HighConfidenceLexicon {
    private static let english: Set<String> = [
        "aapanel", "admin", "ai", "api", "app", "apps", "asp", "auth", "backend", "bash",
        "cdn", "ci", "cli", "cms", "config", "crm", "css", "db", "dev",
        "dns", "docker", "docs", "erp", "frontend", "ftp", "git", "github",
        "gitlab", "html", "http", "https", "iaas", "ide", "info", "inst",
        "install", "instance", "instagram", "ios", "ipad", "iphone", "ip",
        "isp", "ispmanager", "javascript", "json", "jwt", "kubernetes",
        "linux", "llm", "macos", "mcp", "ml", "mongodb", "mysql", "nginx", "node",
        "nodejs", "npm", "npx", "oauth", "paas", "postgres", "postgresql",
        "prod", "python", "qa", "react", "redis", "repo", "saas", "sdk",
        "sftp", "sql", "ssh", "ssl", "swift", "tcp", "tls", "toml",
        "typescript", "udp", "ui", "uri", "url", "uuid", "ux", "vds",
        "vpn", "vps", "vue", "wifi", "yaml", "zsh", "deno", "express",
        "io", "js", "nest", "net", "next", "nuxt", "socket", "three", "ts",
        "cloudpanel", "coolify", "cpanel", "cyberpanel", "directadmin",
        "dokploy", "hestiacp", "openlitespeed", "plesk", "runcloud",
        "virtualmin", "webmin",
    ]

    /// Frequent Russian abbreviations and informal words that are commonly
    /// absent from general-purpose spelling dictionaries. They are an exact
    /// positive signal, not a replacement for the bundled Russian corpus.
    private static let russian: Set<String> = [
        "руб", "рус", "рос", "коп", "стр", "шт", "тыс", "млн", "млрд",
        "мин", "сек", "мес", "тел", "имхо", "пж", "пжл", "спс", "прив", "ещё",
        "норм", "бля", "блядь", "блять", "сука", "суки", "сучка", "мудак",
        "мудака", "мудаки", "хуй", "хуя", "хуе", "хуё", "хуи", "хуем",
        "хуём", "хуев", "хуёв", "хуйню", "хуйня", "нахуй", "похуй",
        "ебать", "ёбать", "ебаный", "ёбаный", "ебаная", "ёбаная", "ебаное",
        "ёбаное", "заебал", "заебала", "заебали", "заебись", "охуел",
        "охуела", "охуели", "охуеть", "пизда", "пиздец", "пизду", "пизды",
        "пиздой", "пиздеть", "пиздит",
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
        case "ru": russian.contains(word.lowercased())
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
