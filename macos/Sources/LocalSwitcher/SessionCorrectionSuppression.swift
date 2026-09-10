import Foundation

/// Remembers auto-corrections the user immediately rejected with Backspace or
/// Undo. The override is intentionally session-only: it prevents an argument
/// with the user while avoiding a permanent dictionary mutation from one key.
struct SessionCorrectionSuppression {
    private(set) var words: Set<String> = []

    mutating func remember(original: String, alternatives: some Sequence<String>) {
        insert(original)
        for alternative in alternatives { insert(alternative) }
    }

    func contains(_ word: String) -> Bool {
        words.contains(normalize(word))
    }

    private mutating func insert(_ word: String) {
        let normalized = normalize(word)
        if !normalized.isEmpty { words.insert(normalized) }
    }

    private func normalize(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
