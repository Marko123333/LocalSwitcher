import Testing
@testable import SwitcherCore

@Suite("Yo restorer")
struct YoRestorerTests {
    private let restorer = YoRestorer(
        words: ["ёлка", "берёза", "все", "всё", "осел", "осёл", "ещё"],
        contextRules: [
            "это|все|*": "всё",
            "*|все|люди": "все",
        ]
    )

    @Test func restoresUniqueWordAndPreservesCase() {
        #expect(restorer.restore("елка") == .restored("ёлка"))
        #expect(restorer.restore("Елка") == .restored("Ёлка"))
        #expect(restorer.restore("ЕЛКА") == .restored("ЁЛКА"))
        #expect(restorer.restore("береза") == .restored("берёза"))
    }

    @Test func doesNotGuessAmbiguousWord() {
        #expect(restorer.restore("все") == .ambiguous(["все", "всё"]))
        #expect(restorer.restore("осел") == .ambiguous(["осел", "осёл"]))
    }

    @Test func usesExplicitContextRule() {
        #expect(restorer.restore("все", previous: "это") == .restored("всё"))
        #expect(restorer.restore("все", next: "люди") == .unchanged)
    }

    @Test func alreadyCorrectAndUnknownWordsStayUnchanged() {
        #expect(restorer.restore("ещё") == .unchanged)
        #expect(restorer.restore("марсианин") == .unchanged)
        #expect(restorer.restore("елка!") == .unchanged)
    }
}
