import Foundation

/// Filters operating-system spellchecker suggestions before they may rewrite
/// live input. The OS ranks the candidates; this type enforces local safety.
public enum SpellingCandidateSelector {
    private static let shortTypos: [String: String] = [
        "adn": "and",
        "питух": "петух",
        "teh": "the",
    ]

    public static func best(original: String, guesses: [String]) -> String? {
        let source = original.lowercased()
        guard original.allSatisfy(\.isLetter),
              !isMixedScript(original),
              original != original.uppercased() else { return nil }

        if let short = shortTypos[source] {
            return copyCase(from: original, to: short)
        }
        guard original.count >= 4 else { return nil }

        for guess in guesses.prefix(5) {
            let candidate = guess.lowercased()
            guard candidate != source,
                  candidate.allSatisfy(\.isLetter),
                  !isMixedScript(candidate),
                  script(of: candidate) == script(of: source),
                  abs(candidate.count - source.count) <= 1,
                  editDistance(source, candidate) == 1 else { continue }
            return copyCase(from: original, to: candidate)
        }
        return nil
    }

    /// Optimal-string-alignment distance. Adjacent transposition counts as one
    /// typo, which covers a large share of real fast-typing mistakes.
    public static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }

        var matrix = Array(
            repeating: Array(repeating: 0, count: b.count + 1),
            count: a.count + 1
        )
        for i in 0...a.count { matrix[i][0] = i }
        for j in 0...b.count { matrix[0][j] = j }

        for i in 1...a.count {
            for j in 1...b.count {
                let substitution = matrix[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    substitution
                )
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    matrix[i][j] = min(matrix[i][j], matrix[i - 2][j - 2] + 1)
                }
            }
        }
        return matrix[a.count][b.count]
    }

    private enum Script {
        case latin
        case cyrillic
        case other
    }

    private static func script(of word: String) -> Script {
        var latin = false
        var cyrillic = false
        for scalar in word.unicodeScalars {
            switch scalar.value {
            case 0x41...0x5A, 0x61...0x7A:
                latin = true
            case 0x0400...0x04FF:
                cyrillic = true
            default:
                break
            }
        }
        if latin && !cyrillic { return .latin }
        if cyrillic && !latin { return .cyrillic }
        return .other
    }

    private static func isMixedScript(_ word: String) -> Bool {
        var latin = false
        var cyrillic = false
        for scalar in word.unicodeScalars {
            if (0x41...0x5A).contains(scalar.value) || (0x61...0x7A).contains(scalar.value) {
                latin = true
            } else if (0x0400...0x04FF).contains(scalar.value) {
                cyrillic = true
            }
        }
        return latin && cyrillic
    }

    private static func copyCase(from source: String, to replacement: String) -> String {
        if source.first?.isUppercase == true {
            return replacement.prefix(1).uppercased() + replacement.dropFirst()
        }
        return replacement
    }
}
