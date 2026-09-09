import Testing
@testable import SwitcherCore

@Suite("High confidence lexicon")
struct HighConfidenceLexiconTests {
    @Test func recognizesTechnicalTermsCaseInsensitively() {
        #expect(HighConfidenceLexicon.contains("ssh", language: "en"))
        #expect(HighConfidenceLexicon.contains("GitHub", language: "en-US"))
        #expect(HighConfidenceLexicon.contains("NGINX", language: "EN"))
        #expect(HighConfidenceLexicon.contains("ISP", language: "en"))
        #expect(HighConfidenceLexicon.contains("ispmanager", language: "en"))
        #expect(HighConfidenceLexicon.contains("inst", language: "en"))
    }

    @Test func doesNotLeakTermsAcrossLanguages() {
        #expect(!HighConfidenceLexicon.contains("ssh", language: "ru"))
        #expect(!HighConfidenceLexicon.contains("definitely-not-a-term", language: "en"))
    }
}
