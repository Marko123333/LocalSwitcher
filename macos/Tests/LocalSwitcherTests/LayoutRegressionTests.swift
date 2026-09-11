import Foundation
import Testing
import SwitcherCore
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

    @Test @MainActor func convertsMCPInLowercaseAndUppercaseFromRussianLayout() {
        for target in ["mcp", "MCP"] {
            let typed = KeyMapping.convert(target)
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: target,
                currentLang: "ru",
                otherLang: "en",
                capsLock: target == "MCP"
            ) == .switchToConverted)
        }
        #expect(KeyMapping.convert("mcp") == "ьсз")
        #expect(KeyMapping.convert("MCP") == "ЬСЗ")
    }

    @Test @MainActor func convertsReportedRussianPhraseFromEnglishLayout() {
        for target in ["не", "работает", "ещё"] {
            let typed = KeyMapping.convert(target)
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: target,
                currentLang: "en",
                otherLang: "ru",
                capsLock: false
            ) == .switchToConverted)
        }

        #expect(KeyMapping.convert("не") == "yt")
        #expect(KeyMapping.convert("работает") == "hf,jnftn")
        #expect(KeyMapping.convert("ещё") == "to`")
        #expect(LayoutDetector.prefersWholeToken(
            typed: "to`",
            converted: "ещё",
            currentLang: "en",
            otherLang: "ru",
            convertedHasSafeCorrection: false
        ))
    }

    @Test @MainActor func convertsPlainEImageOfYoWordFromEnglishLayout() {
        #expect(KeyMapping.convert("еще") == "tot")
        #expect(LayoutDetector.decide(
            typed: "tot",
            converted: "еще",
            currentLang: "en",
            otherLang: "ru",
            capsLock: false
        ) == .switchToConverted)
        #expect(BundledRussianLexicon.makeYoRestorer().restore("еще") == .restored("ещё"))
    }

    @Test @MainActor func convertsRussianHyphenatedWordsFromEnglishLayout() {
        for target in [
            "что-то", "Что-то", "ЧТО-ТО", "где-то", "из-за", "кто-нибудь",
            "когда-нибудь", "какой-либо", "по-моему", "во-первых",
            "онлайн-магазин", "давным-давно",
        ] {
            let typed = KeyMapping.convert(target)
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: target,
                currentLang: "en",
                otherLang: "ru",
                capsLock: false
            ) == .switchToConverted, "Failed hyphenated target: \(target)")
        }

        #expect(KeyMapping.convert("что-то") == "xnj-nj")
        #expect(KeyMapping.convert("где-то") == "ult-nj")
        #expect(LayoutDetector.decide(
            typed: "что-то",
            converted: "xnj-nj",
            currentLang: "ru",
            otherLang: "en",
            capsLock: false
        ) == .keep)
        let punctuated = LayoutDetector.splitTrailingPunctuation("xnj-nj,")
        #expect(punctuated.coreLength == 6)
        #expect(punctuated.suffix == ",")

        let endingOnPunctuationKey = KeyMapping.convert("во-первых")
        #expect(endingOnPunctuationKey == "dj-gthds[")
        #expect(LayoutDetector.prefersWholeToken(
            typed: endingOnPunctuationKey,
            converted: "во-первых",
            currentLang: "en",
            otherLang: "ru",
            convertedHasSafeCorrection: false
        ))

        #expect(!LayoutDetector.prefersWholeToken(
            typed: "xnj-nj,",
            converted: KeyMapping.convert("xnj-nj,"),
            currentLang: "en",
            otherLang: "ru",
            convertedHasSafeCorrection: false
        ))
    }

    @Test @MainActor func keepsRealEnglishHyphenatedWords() {
        for word in ["well-known", "state-of-the-art"] {
            #expect(LayoutDetector.decide(
                typed: word,
                converted: KeyMapping.convert(word),
                currentLang: "en",
                otherLang: "ru",
                capsLock: false
            ) == .keep)

            let typedInRussianLayout = KeyMapping.convert(word)
            #expect(LayoutDetector.decide(
                typed: typedInRussianLayout,
                converted: word,
                currentLang: "ru",
                otherLang: "en",
                capsLock: false
            ) == .switchToConverted)
        }
    }

    @Test @MainActor func convertsRussianEtCeteraAbbreviationFromEnglishLayout() {
        #expect(KeyMapping.convert("тд") == "nl")
        #expect(LayoutDetector.decide(
            typed: "nl",
            converted: "тд",
            currentLang: "en",
            otherLang: "ru",
            capsLock: false
        ) == .switchToConverted)
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
        for target in ["А", "В", "И", "К", "О", "С", "У", "Я"] {
            #expect(LayoutDetector.decide(
                typed: KeyMapping.convert(target),
                converted: target,
                currentLang: "en",
                otherLang: "ru",
                capsLock: false
            ) == .switchToConverted, "Failed uppercase one-letter word: \(target)")
        }
        #expect(KeyMapping.convert("И") == "B")
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

    @Test @MainActor func convertsPreferredRussianShortRepliesFromEnglishLayout() {
        for (typed, target) in [
            ("ye", "ну"), ("jr", "ок"), ("uj", "го"),
            ("lf", "да"), ("yt", "не"),
        ] {
            #expect(KeyMapping.convert(typed) == target)
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: target,
                currentLang: "en",
                otherLang: "ru",
                capsLock: false
            ) == .switchToConverted)
        }
    }

    @Test @MainActor func convertsRussianAbbreviationsAndProfanityFromEnglishLayout() {
        for target in ["руб", "рус", "хуй", "блядь", "пиздец"] {
            let typed = KeyMapping.convert(target)
            #expect(LayoutDetector.decide(
                typed: typed,
                converted: target,
                currentLang: "en",
                otherLang: "ru",
                capsLock: false
            ) == .switchToConverted)
        }
        #expect(KeyMapping.convert("руб") == "he,")
        #expect(KeyMapping.convert("хуй") == "[eq")
    }

    @Test @MainActor func convertsAaPanelFromRussianLayout() {
        let typed = KeyMapping.convert("aapanel")
        #expect(typed == "ффзфтуд")
        #expect(LayoutDetector.decide(
            typed: typed,
            converted: "aapanel",
            currentLang: "ru",
            otherLang: "en",
            capsLock: false
        ) == .switchToConverted)
    }

    @Test @MainActor func treatsPunctuationKeyAsTargetLetterOnlyWithStrongEvidence() {
        #expect(LayoutDetector.prefersWholeToken(
            typed: "he,",
            converted: "руб",
            currentLang: "en",
            otherLang: "ru",
            convertedHasSafeCorrection: false
        ))
        #expect(LayoutDetector.prefersWholeToken(
            typed: "gbne[",
            converted: "питух",
            currentLang: "en",
            otherLang: "ru",
            convertedHasSafeCorrection: true
        ))
        #expect(!LayoutDetector.prefersWholeToken(
            typed: "levf.",
            converted: "думаю",
            currentLang: "en",
            otherLang: "ru",
            convertedHasSafeCorrection: false
        ))
        #expect(Dict.bestCorrection("питух", lang: "ru") == "петух")
    }

    @Test @MainActor func doesNotRewriteKnownRussianWordAsAnotherWord() {
        #expect(BundledLexicon.contains("скачивание", language: "ru"))
        #expect(Dict.bestCorrection("скачивание", lang: "ru") == nil)
    }

    @Test func rejectedCorrectionIsSuppressedOnlyOncePerSpelling() {
        var suppression = SessionCorrectionSuppression()
        suppression.remember(original: "gbne[", alternatives: ["питух"])
        let consumesOriginalOnce = suppression.consume("GBNE[")
        let consumesOriginalTwice = suppression.consume("gbne[")
        let consumesAlternativeOnce = suppression.consume("ПИТУХ")
        let consumesAlternativeTwice = suppression.consume("питух")
        let consumesUnrelated = suppression.consume("петух")
        #expect(consumesOriginalOnce)
        #expect(!consumesOriginalTwice)
        #expect(consumesAlternativeOnce)
        #expect(!consumesAlternativeTwice)
        #expect(!consumesUnrelated)
    }

    @Test @MainActor func deletingIntoCorrectionRejectsOnlyTheLastConversion() async {
        let monitor = KeyboardMonitor()
        var rejectionCount = 0
        monitor.onRejectLastConversion = { rejectionCount += 1 }
        monitor.markConverted()

        monitor.handleKeyDown(keyCode: KC.backspace, flags: [])
        await Task.yield()
        #expect(rejectionCount == 0) // first Backspace removes the triggering space

        monitor.handleKeyDown(keyCode: KC.backspace, flags: [])
        await Task.yield()
        #expect(rejectionCount == 1)

        monitor.handleKeyDown(keyCode: KC.backspace, flags: [])
        await Task.yield()
        #expect(rejectionCount == 1)
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
