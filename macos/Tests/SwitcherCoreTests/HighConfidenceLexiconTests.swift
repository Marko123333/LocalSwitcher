import Testing
@testable import SwitcherCore

@Suite("High confidence lexicon")
struct HighConfidenceLexiconTests {
    @Test func recognizesTechnicalTermsCaseInsensitively() {
        #expect(HighConfidenceLexicon.contains("ssh", language: "en"))
        #expect(HighConfidenceLexicon.contains("mcp", language: "en"))
        #expect(HighConfidenceLexicon.contains("MCP", language: "en"))
        #expect(HighConfidenceLexicon.contains("GitHub", language: "en-US"))
        #expect(HighConfidenceLexicon.contains("NGINX", language: "EN"))
        #expect(HighConfidenceLexicon.contains("ISP", language: "en"))
        #expect(HighConfidenceLexicon.contains("ispmanager", language: "en"))
        #expect(HighConfidenceLexicon.contains("inst", language: "en"))
        #expect(HighConfidenceLexicon.contains("aaPanel", language: "en"))
    }

    @Test func recognizesRussianAbbreviationsAndInformalVocabulary() {
        for word in ["руб", "рус", "тд", "хуй", "блядь", "пиздец", "заебись"] {
            #expect(HighConfidenceLexicon.contains(word, language: "ru"))
        }
        #expect(!HighConfidenceLexicon.contains("питух", language: "ru"))
    }

    @Test func recognizesDedicatedRussianAbbreviationsCaseInsensitively() {
        #expect(RussianAbbreviations.corpusCount == 1_604)
        #expect(RussianAbbreviations.all.count > 1_700)
        for word in [
            "фсб", "фбр", "пдн", "жкх", "мвд", "мчс", "гибдд", "тсж",
            "ооо", "инн", "снилс", "днк", "мрт", "егэ", "оон", "сша",
            "вднх", "гоэлро", "пэвм", "цска",
        ] {
            #expect(RussianAbbreviations.contains(word), "Missing abbreviation: \(word)")
            #expect(RussianAbbreviations.contains(word.uppercased()))
            #expect(HighConfidenceLexicon.contains(word, language: "ru"))
            #expect(HighConfidenceLexicon.contains(word.uppercased(), language: "ru-RU"))
        }

        #expect(!RussianAbbreviations.contains("ssh"))
        #expect(!HighConfidenceLexicon.contains("фсб", language: "en"))
    }

    @Test func recognizesRussianParticlesCaseInsensitively() {
        for word in [
            "уж", "же", "бы", "ли", "ль", "ведь", "разве", "неужели",
            "вот", "вон", "именно", "только", "лишь", "пусть", "пускай",
            "дескать", "якобы", "мол", "вряд", "едва", "всё-таки",
            "опять-таки", "как-никак", "всего-навсего",
        ] {
            #expect(RussianParticles.contains(word), "Missing particle: \(word)")
            #expect(RussianParticles.contains(word.uppercased()), "Missing uppercase particle: \(word)")
            #expect(HighConfidenceLexicon.contains(word, language: "ru"))
            #expect(HighConfidenceLexicon.contains(word.uppercased(), language: "ru-RU"))
        }
    }

    @Test func doesNotLeakTermsAcrossLanguages() {
        #expect(!HighConfidenceLexicon.contains("ssh", language: "ru"))
        #expect(HighConfidenceLexicon.contains("еще", language: "ru"))
        #expect(HighConfidenceLexicon.contains("ещё", language: "ru"))
        #expect(!HighConfidenceLexicon.contains("definitely-not-a-term", language: "en"))
    }

    @Test func recognizesDottedTechnicalTokensWithoutTreatingDomainsAsProducts() {
        for token in ["node.js", "Node.js", "node.js,", "node.js.", "socket.io", "ASP.NET"] {
            #expect(HighConfidenceLexicon.containsTechnicalToken(token, language: "en"))
        }
        #expect(!HighConfidenceLexicon.containsTechnicalToken("example.com", language: "en"))
        #expect(!HighConfidenceLexicon.containsTechnicalToken("node.js", language: "ru"))
    }

    @Test func recognizesModernRussianAndAITermsCaseInsensitively() {
        #expect(ModernRussianLexicon.allWords.count > 6_000)
        for word in [
            "ресерч", "поресерч", "поресерчи", "поресерчить", "заресерчил",
            "проресерчите", "ИИ", "АИ", "ЛЛМ", "РАГ", "нейронка", "промпты",
            "датасетом", "эмбеддинги", "файн-тюнинг", "вайб-кодинг",
        ] {
            #expect(ModernRussianLexicon.contains(word), "Missing modern term: \(word)")
            #expect(HighConfidenceLexicon.contains(word, language: "ru"))
        }

        for word in ["AI", "LLM", "RAG", "GPT", "ChatGPT", "OpenAI", "Qwen", "DeepSeek"] {
            #expect(HighConfidenceLexicon.contains(word, language: "en"), "Missing AI term: \(word)")
        }
    }
}
