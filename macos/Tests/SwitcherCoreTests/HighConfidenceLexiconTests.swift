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

    @Test func recognizesDottedTechnicalTokensWithoutTreatingDomainsAsProducts() {
        for token in ["node.js", "Node.js", "node.js,", "node.js.", "socket.io", "ASP.NET"] {
            #expect(HighConfidenceLexicon.containsTechnicalToken(token, language: "en"))
        }
        #expect(!HighConfidenceLexicon.containsTechnicalToken("example.com", language: "en"))
        #expect(!HighConfidenceLexicon.containsTechnicalToken("node.js", language: "ru"))
    }
}
