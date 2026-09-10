import Foundation
import Testing
@testable import LocalSwitcher

@Suite("Reported layout regressions")
struct LayoutRegressionTests {
    @Test func projectMenuDestinationsAreConcreteHTTPSLinks() {
        for link in [SettingsManager.starURL, SettingsManager.supportURL, SettingsManager.contactURL] {
            let url = URL(string: link)
            #expect(url?.scheme == "https")
            #expect(url?.host == "github.com")
            #expect(link.contains("Marko123333/LocalSwitcher"))
        }
    }

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

    @Test @MainActor func keepsEnglishInstInsteadOfTrustingNoisyFallback() {
        let target = KeyMapping.convert("inst")
        #expect(LayoutDetector.decide(
            typed: "inst",
            converted: target,
            currentLang: "en",
            otherLang: "ru",
            capsLock: false
        ) == .keep)
    }

    @Test @MainActor func convertsISPAndISPManagerFromRussianLayout() {
        #expect(KeyMapping.convert("isp") == "шыз")
        #expect(KeyMapping.convert("ispmanager") == "шызьфтфпук")
        for target in ["isp", "ispmanager", "api", "cdn", "db", "dev", "inst", "sftp", "ui", "ux"] {
            let typed = KeyMapping.convert(target)
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: target,
                currentLang: "ru",
                otherLang: "en",
                capsLock: false
            ) == .switchToConverted)
        }
    }

    @Test @MainActor func convertsRussianConjunctionFromEnglishLayout() {
        for (typed, converted) in [("b", "и"), ("d", "в"), ("c", "с"), ("r", "к"),
                                   ("j", "о"), ("e", "у"), ("f", "а"), ("z", "я")] {
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: converted,
                currentLang: "en",
                otherLang: "ru",
                capsLock: false
            ) == .switchToConverted)
        }
        #expect(LayoutDetector.decide(
            typed: "i",
            converted: "ш",
            currentLang: "en",
            otherLang: "ru",
            capsLock: false
        ) == .keep)
        #expect(LayoutDetector.decide(
            typed: "B",
            converted: "И",
            currentLang: "en",
            otherLang: "ru",
            capsLock: false
        ) == .undecided)
    }

    @Test @MainActor func convertsDottedTechnicalNameFromRussianLayout() {
        for target in ["node.js", "Node.js", "node.js,", "socket.io"] {
            let typed = KeyMapping.convert(target)
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: target,
                currentLang: "ru",
                otherLang: "en",
                capsLock: false
            ) == .switchToConverted)
        }

        let domain = "example.com"
        #expect(LayoutDetector.decide(
            typed: KeyMapping.convert(domain),
            converted: domain,
            currentLang: "ru",
            otherLang: "en",
            capsLock: false
        ) == .keep)
    }

    @Test @MainActor func convertsEnglishArticlesFromRussianLayout() {
        for (typed, converted) in [("ф", "a"), ("ш", "i")] {
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: converted,
                currentLang: "ru",
                otherLang: "en",
                capsLock: false
            ) == .switchToConverted)
        }
    }
}
