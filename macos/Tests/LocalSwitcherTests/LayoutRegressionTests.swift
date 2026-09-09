import Testing
@testable import LocalSwitcher

@Suite("Reported layout regressions")
struct LayoutRegressionTests {
    @Test func mapsCyrillicImageOfSSHBackToEnglish() {
        #expect(KeyMapping.convert("ыыр") == "ssh")
    }

    @Test func mapsShiftedPunctuationKeyAsRussianCapital() {
        #expect(KeyMapping.convert("<kby") == "Блин")
    }

    @Test @MainActor func detectorAcceptsSSHAsTargetWord() {
        let decision = LayoutDetector.decide(
            typed: "ыыр",
            converted: "ssh",
            currentLang: "ru",
            otherLang: "en",
            capsLock: false
        )
        #expect(decision == .switchToConverted)
    }

    @Test @MainActor func detectorUsesBroadCorpusOnlyAsFallback() {
        let target = "colourisation"
        let typed = KeyMapping.convert(target)
        let decision = LayoutDetector.decide(
            typed: typed,
            converted: target,
            currentLang: "ru",
            otherLang: "en",
            capsLock: false
        )
        #expect(decision == .switchToConverted)
    }

    @Test @MainActor func detectorConvertsWholeCapitalizedRussianWord() {
        let decision = LayoutDetector.decide(
            typed: "<kby",
            converted: "Блин",
            currentLang: "en",
            otherLang: "ru",
            capsLock: false
        )
        #expect(decision == .switchToConverted)
    }
}
