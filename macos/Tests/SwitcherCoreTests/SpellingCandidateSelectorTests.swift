import Testing
@testable import SwitcherCore

@Suite("Spelling candidate selector")
struct SpellingCandidateSelectorTests {
    @Test func acceptsOneEditAndTransposition() {
        #expect(SpellingCandidateSelector.best(original: "превет", guesses: ["привет"]) == "привет")
        #expect(SpellingCandidateSelector.best(original: "wrold", guesses: ["world"]) == "world")
        #expect(SpellingCandidateSelector.best(original: "Wrold", guesses: ["world"]) == "World")
    }

    @Test func supportsCuratedShortTypos() {
        #expect(SpellingCandidateSelector.best(original: "teh", guesses: []) == "the")
        #expect(SpellingCandidateSelector.best(original: "adn", guesses: []) == "and")
        #expect(SpellingCandidateSelector.best(original: "питух", guesses: ["питых"]) == "петух")
    }

    @Test func rejectsRiskySuggestions() {
        #expect(SpellingCandidateSelector.best(original: "SSH", guesses: ["ash"]) == nil)
        #expect(SpellingCandidateSelector.best(original: "iРhone", guesses: ["iphone"]) == nil)
        #expect(SpellingCandidateSelector.best(original: "слон", guesses: ["сложный"]) == nil)
        #expect(SpellingCandidateSelector.best(original: "кот", guesses: ["кит"]) == nil)
    }
}
