#!/usr/bin/env python3
"""Build deterministic runtime dictionaries from pinned upstream data."""

from __future__ import annotations

import argparse
from array import array
import gzip
from pathlib import Path
import re
import shutil
import struct
from typing import Iterable, TextIO


ROOT = Path(__file__).resolve().parents[1]
RESOURCE_DIR = ROOT / "macos/Sources/SwitcherCore/Resources"
SAFE_OUTPUT = RESOURCE_DIR / "yo_safe_forms.txt"
UNSAFE_OUTPUT = RESOURCE_DIR / "yo_unsafe_forms.txt"
OLD_OUTPUT = RESOURCE_DIR / "yo_forms.txt"
LICENSE_OUTPUT = ROOT / "third_party/eyo-kernel/LICENSE"
RU_HASH_OUTPUT = RESOURCE_DIR / "ru_words.fnv64"
EN_HASH_OUTPUT = RESOURCE_DIR / "en_words.fnv64"
RU_LICENSE_OUTPUT = ROOT / "third_party/russian-spelling-dictionary/LICENSE"
SCOWL_LICENSE_OUTPUT = ROOT / "third_party/esdb-scowl/Copyright"

LEXICON_MAGIC = b"LSLEX1\0\0"
FNV_OFFSET_BASIS = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3


def expand_pattern(pattern: str) -> list[str]:
    match = re.search(r"\(([^()]*)\)", pattern)
    if not match:
        return [pattern]
    expanded: list[str] = []
    for option in match.group(1).split("|"):
        expanded.extend(
            expand_pattern(pattern[: match.start()] + option + pattern[match.end() :])
        )
    return expanded


def expand_dictionary(path: Path) -> list[str]:
    forms: set[str] = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        pattern = raw.split("#", 1)[0].strip().removeprefix("_")
        if not pattern:
            continue
        forms.update(
            word.lower()
            for word in expand_pattern(pattern)
            if word.isalpha() and "ё" in word.lower()
        )
    return sorted(forms)


def write_resource(path: Path, forms: list[str], source_commit: str, safety: str) -> None:
    header = (
        "# Generated from e2yo/eyo-kernel v4.1.1\n"
        f"# source commit: {source_commit}\n"
        f"# source class: {safety}\n"
        "# SPDX-License-Identifier: MIT\n"
    )
    path.write_text(header + "\n".join(forms) + "\n", encoding="utf-8")


def open_text(path: Path) -> TextIO:
    if path.suffix == ".gz":
        return gzip.open(path, "rt", encoding="utf-8")
    return path.open("r", encoding="utf-8")


def fnv1a64(value: str) -> int:
    result = FNV_OFFSET_BASIS
    for byte in value.encode("utf-8"):
        result ^= byte
        result = (result * FNV_PRIME) & 0xFFFFFFFFFFFFFFFF
    return result


def valid_words(lines: Iterable[str], language: str) -> Iterable[str]:
    pattern = re.compile(r"^[a-z]+$") if language == "en" else re.compile(r"^[а-яё]+$")
    for raw in lines:
        word = raw.strip().lstrip("\ufeff").lower()
        if pattern.fullmatch(word):
            yield word


def write_hash_lexicon(source: Path, output: Path, language: str) -> int:
    """Write sorted 64-bit hashes for exact, memory-mapped membership checks.

    The chance of an FNV-1a collision affecting one lookup is negligible. The
    app uses this broad corpus only as its weakest language signal; AppleSpell
    and the curated technical lexicon have higher priority.
    """
    with open_text(source) as handle:
        hashes = array("Q", (fnv1a64(word) for word in valid_words(handle, language)))
    hashes = array("Q", sorted(set(hashes)))

    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as handle:
        handle.write(LEXICON_MAGIC)
        handle.write(struct.pack("<Q", len(hashes)))
        for value in hashes:
            handle.write(struct.pack("<Q", value))
    return len(hashes)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--eyo-safe", required=True, type=Path)
    parser.add_argument("--eyo-unsafe", required=True, type=Path)
    parser.add_argument("--eyo-license", required=True, type=Path)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--ru-words", required=True, type=Path)
    parser.add_argument("--ru-license", required=True, type=Path)
    parser.add_argument("--scowl-words", required=True, type=Path)
    parser.add_argument("--scowl-copyright", required=True, type=Path)
    args = parser.parse_args()

    safe = expand_dictionary(args.eyo_safe)
    unsafe = expand_dictionary(args.eyo_unsafe)
    RESOURCE_DIR.mkdir(parents=True, exist_ok=True)
    write_resource(SAFE_OUTPUT, safe, args.source_commit, "safe")
    write_resource(UNSAFE_OUTPUT, unsafe, args.source_commit, "unsafe")
    OLD_OUTPUT.unlink(missing_ok=True)

    LICENSE_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(args.eyo_license, LICENSE_OUTPUT)
    RU_LICENSE_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    SCOWL_LICENSE_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(args.ru_license, RU_LICENSE_OUTPUT)
    shutil.copyfile(args.scowl_copyright, SCOWL_LICENSE_OUTPUT)

    ru_count = write_hash_lexicon(args.ru_words, RU_HASH_OUTPUT, "ru")
    en_count = write_hash_lexicon(args.scowl_words, EN_HASH_OUTPUT, "en")
    print(f"wrote {len(safe)} safe and {len(unsafe)} unsafe Russian ё forms")
    print(f"wrote {ru_count} Russian and {en_count} English hashed forms")


if __name__ == "__main__":
    main()
