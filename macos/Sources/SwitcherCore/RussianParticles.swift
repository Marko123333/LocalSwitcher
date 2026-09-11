import Foundation

/// Russian particles are too short and too semantically flexible for a broad
/// spelling dictionary to be a reliable layout signal. Keep a reviewed exact
/// lexicon instead. The main groups follow Gramota's grammatical overview;
/// common independent modal and emphatic forms are included as well.
///
/// Multiword constructions are represented by their independently typed
/// components. Hyphenated particles are kept whole because the keyboard monitor
/// treats them as one token.
public enum RussianParticles {
    private static let words: Set<String> = [
        // Negation and question.
        "не", "ни", "неужели", "разве", "ли", "ль",

        // Demonstrative and specifying.
        "вот", "вон", "это", "именно", "прямо", "точно", "ровно",
        "буквально", "точь-в-точь",

        // Limiting and emphatic.
        "только", "лишь", "исключительно", "почти", "единственно",
        "то", "даже", "же", "ведь", "уж", "ну", "хоть", "просто",
        "решительно", "положительно",

        // Form-building and imperative.
        "бы", "пусть", "пускай", "да", "давай", "давайте",

        // Reported speech, comparison, doubt and colloquial modality.
        "дескать", "якобы", "мол", "будто", "словно", "авось", "небось",
        "поди", "едва", "вряд",

        // Components of common multiword particles and frequent particle uses.
        "как", "что", "вовсе", "далеко", "отнюдь", "так", "уже", "еще", "ещё",

        // Frequent hyphenated particles and particle-like repetitions.
        "всё-таки", "все-таки", "опять-таки", "прямо-таки", "так-таки",
        "то-то", "ну-ну", "как-никак", "всего-навсего",
    ]

    public static func contains(_ word: String) -> Bool {
        words.contains(word.lowercased())
    }
}
