import Foundation

public enum YoRestoration: Equatable, Sendable {
    case unchanged
    case restored(String)
    case ambiguous([String])
}

/// Restores Russian "ё" only when a dictionary or an explicit context rule
/// makes the replacement unambiguous. It never blindly rewrites pairs such as
/// "все/всё" or "осел/осёл".
public struct YoRestorer: Sendable {
    private let variantsByNormalizedWord: [String: [String]]
    private let contextRules: [String: String]

    /// - Parameters:
    ///   - words: Russian dictionary forms. Include both е and ё spellings when
    ///     both are valid words so the restorer can detect ambiguity.
    ///   - contextRules: Optional disambiguation rules. Supported keys are
    ///     previous|word|next, previous|word|*, and *|word|next. All parts
    ///     are lowercase and use е in the key. The value is the desired form.
    public init(words: [String], contextRules: [String: String] = [:]) {
        var collected: [String: Set<String>] = [:]
        for raw in words {
            let word = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !word.isEmpty, word.allSatisfy(\.isLetter) else { continue }
            collected[Self.withoutYo(word), default: []].insert(word)
        }

        var variants: [String: [String]] = [:]
        variants.reserveCapacity(collected.count)
        for (key, values) in collected {
            variants[key] = values.sorted()
        }
        self.variantsByNormalizedWord = variants

        var normalizedRules: [String: String] = [:]
        for (key, value) in contextRules {
            normalizedRules[key.lowercased()] = value.lowercased()
        }
        self.contextRules = normalizedRules
    }

    public func restore(
        _ word: String,
        previous: String? = nil,
        next: String? = nil
    ) -> YoRestoration {
        guard !word.isEmpty, word.allSatisfy(\.isLetter) else { return .unchanged }
        let lowercase = word.lowercased()
        let normalized = Self.withoutYo(lowercase)
        guard let candidates = variantsByNormalizedWord[normalized] else { return .unchanged }

        let selected: String
        if candidates.count == 1, let only = candidates.first {
            selected = only
        } else if let contextual = contextualCandidate(
            word: normalized,
            previous: previous,
            next: next
        ), candidates.contains(contextual) {
            selected = contextual
        } else {
            return .ambiguous(candidates)
        }

        let cased = Self.copyCase(from: word, to: selected)
        return cased == word ? .unchanged : .restored(cased)
    }

    public static func withoutYo(_ word: String) -> String {
        word.replacingOccurrences(of: "ё", with: "е")
            .replacingOccurrences(of: "Ё", with: "Е")
    }

    private func contextualCandidate(word: String, previous: String?, next: String?) -> String? {
        let prev = previous.map { Self.withoutYo($0.lowercased()) } ?? "*"
        let following = next.map { Self.withoutYo($0.lowercased()) } ?? "*"
        let keys = [
            "\(prev)|\(word)|\(following)",
            "\(prev)|\(word)|*",
            "*|\(word)|\(following)",
        ]
        return keys.compactMap { contextRules[$0] }.first
    }

    private static func copyCase(from source: String, to replacement: String) -> String {
        let sourceCharacters = Array(source)
        let replacementCharacters = Array(replacement)
        guard sourceCharacters.count == replacementCharacters.count else { return replacement }

        return String(zip(sourceCharacters, replacementCharacters).flatMap { sourceChar, replacementChar in
            Array(sourceChar.isUppercase
                ? String(replacementChar).uppercased()
                : String(replacementChar).lowercased())
        })
    }
}
