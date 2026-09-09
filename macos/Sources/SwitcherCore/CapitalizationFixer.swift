import Foundation

/// Conservative fixes that are safe to apply before language scoring.
public enum CapitalizationFixer {
    /// Fixes a common accidental second capital: "ПРивет" -> "Привет" and
    /// "WOrld" -> "World". Acronyms and mixed-case identifiers are left alone.
    public static func accidentalSecondCapital(
        in word: String,
        protectedWords: Set<String> = []
    ) -> String? {
        let characters = Array(word)
        guard characters.count >= 3,
              !protectedWords.contains(word.lowercased()),
              characters[0].isUppercase,
              characters[1].isUppercase,
              characters.dropFirst(2).allSatisfy({ $0.isLetter && $0.isLowercase }) else {
            return nil
        }

        let corrected = String(characters[0]) + String(characters.dropFirst()).lowercased()
        return corrected == word ? nil : corrected
    }
}
