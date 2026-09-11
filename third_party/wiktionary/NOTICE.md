# Russian Wiktionary abbreviation data

`macos/Sources/SwitcherCore/Resources/ru_abbreviations.txt` is derived from
the page titles in the Russian Wiktionary category
[`Аббревиатуры/ru`](https://ru.wiktionary.org/wiki/Категория:Аббревиатуры/ru),
snapshot retrieved on 2026-09-11.

The generated resource keeps only titles made of three or more uppercase
Cyrillic letters, converts them to lowercase and removes duplicates. The
source snapshot contained 3,170 category members; 1,604 passed this filter.
The source title-list checksum and transformation are recorded in the resource
header and `scripts/build_abbreviation_corpus.py`.

Russian Wiktionary text is available under the
[Creative Commons Attribution-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-sa/4.0/).
The generated abbreviation resource is distributed under the same license.
