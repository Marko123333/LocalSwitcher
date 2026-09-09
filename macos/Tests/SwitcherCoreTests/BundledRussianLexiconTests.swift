import Testing
@testable import SwitcherCore

@Suite("Bundled Russian lexicon")
struct BundledRussianLexiconTests {
    @Test func loadsLargeFallbackDictionaries() {
        #expect(BundledLexicon.count(language: "ru") == 2_323_330)
        #expect(BundledLexicon.count(language: "en") == 148_957)
        #expect(BundledLexicon.contains("гиперспектральный", language: "ru"))
        #expect(BundledLexicon.contains("colourisation", language: "en"))
        #expect(!BundledLexicon.contains("ыыррррр", language: "ru"))
        #expect(!BundledLexicon.contains("qqqqqqq", language: "en"))
    }

    @Test func loadsPinnedYoDictionary() {
        let restorer = BundledRussianLexicon.makeYoRestorer()
        #expect(restorer.restore("елка") == .restored("ёлка"))
        #expect(restorer.restore("авиаперелетов") == .restored("авиаперелётов"))
    }

    @Test func protectsKnownSemanticAmbiguities() {
        let restorer = BundledRussianLexicon.makeYoRestorer()
        #expect(restorer.restore("все") == .ambiguous(["все", "всё"]))
        #expect(restorer.restore("небо") == .ambiguous(["небо", "нёбо"]))
        #expect(restorer.restore("осел") == .ambiguous(["осел", "осёл"]))
    }
}
