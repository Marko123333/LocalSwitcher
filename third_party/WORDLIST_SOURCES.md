# Word-list sources

Runtime word lists are generated with `scripts/build_dictionaries.py` from
these pinned sources:

- Russian: `Goudron/ru-spelling-dictionary`, release 1.0.8, commit
  `69a18ae079084f11569f5190ac2080289055ef5e`, file
  `cspell/dictionaries/ru_RU.txt.gz`. License: MPL-2.0.
- Russian abbreviations: Russian Wiktionary category `Аббревиатуры/ru`,
  snapshot retrieved 2026-09-11. From 3,170 category members,
  `scripts/build_abbreviation_corpus.py` retains 1,604 uppercase Cyrillic
  initialisms of at least three letters. License: CC BY-SA 4.0.
- English: English Speller Database (formerly SCOWL), commit
  `1e5b7d3a72f47a71da5d28686c1dd4b397178485`. The source command is
  `./scowl --db scowl.db word-list 70 A,B,Z 5 --deaccent`. License: the
  MIT-like notice in `third_party/esdb-scowl/Copyright`.
- Russian е/ё: `e2yo/eyo-kernel` v4.1.1, commit
  `5df5a4905d927cc8644ad464582dc889d14ac6cc`. License: MIT.

The binary `.fnv64` resources contain sorted 64-bit hashes, not executable
code. They allow exact local membership checks through memory mapping without
loading millions of Swift strings into RAM. Regeneration is deterministic for
the same inputs.
