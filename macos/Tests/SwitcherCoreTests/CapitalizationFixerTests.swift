import Testing
@testable import SwitcherCore

@Suite("Capitalization fixer")
struct CapitalizationFixerTests {
    @Test func fixesAccidentalSecondCapital() {
        #expect(CapitalizationFixer.accidentalSecondCapital(in: "ПРивет") == "Привет")
        #expect(CapitalizationFixer.accidentalSecondCapital(in: "WOrld") == "World")
    }

    @Test func leavesAcronymsAndMixedCaseAlone() {
        #expect(CapitalizationFixer.accidentalSecondCapital(in: "SSH") == nil)
        #expect(CapitalizationFixer.accidentalSecondCapital(in: "iPhone") == nil)
        #expect(CapitalizationFixer.accidentalSecondCapital(in: "GitHub") == nil)
        #expect(CapitalizationFixer.accidentalSecondCapital(in: "USAid", protectedWords: ["usaid"]) == nil)
    }
}
