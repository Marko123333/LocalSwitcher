#!/usr/bin/env python3
"""Build the bundled Russian abbreviation corpus from a Wiktionary title snapshot."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re


UPPERCASE_CYRILLIC_INITIALISM = re.compile(r"^[А-ЯЁ]{3,}$")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--wiktionary-titles", required=True, type=Path)
    parser.add_argument("--snapshot-date", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    source_bytes = args.wiktionary_titles.read_bytes()
    source_sha256 = hashlib.sha256(source_bytes).hexdigest()
    titles = source_bytes.decode("utf-8").splitlines()
    abbreviations = sorted({
        title.lower()
        for title in (raw.strip() for raw in titles)
        if UPPERCASE_CYRILLIC_INITIALISM.fullmatch(title)
    })

    header = (
        "# Generated from Russian Wiktionary category: Аббревиатуры/ru\n"
        "# https://ru.wiktionary.org/wiki/Категория:Аббревиатуры/ru\n"
        f"# source snapshot date: {args.snapshot_date}\n"
        f"# source title-list sha256: {source_sha256}\n"
        "# filter: uppercase Cyrillic letter-only titles, minimum length 3\n"
        "# SPDX-License-Identifier: CC-BY-SA-4.0\n"
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(header + "\n".join(abbreviations) + "\n", encoding="utf-8")
    print(f"wrote {len(abbreviations)} Russian abbreviations")


if __name__ == "__main__":
    main()
