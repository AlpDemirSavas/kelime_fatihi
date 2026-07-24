#!/usr/bin/env python3
"""Extract REVIEW CANDIDATES from a Kaikki/Wiktionary Turkish JSONL dump.

This script intentionally does NOT modify the game's bundled dictionary. It
writes a candidate file for human/build-pipeline review because Kaikki data is
CC-BY-SA/GFDL and contains proper names, inflected/form-of entries and rare
material that should not be blindly promoted into a commercial word game.

Source: https://kaikki.org/dictionary/Turkish/
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

WORD_RE = re.compile(r"^[abcçdefgğhıijklmnoöprsştuüvyz]+$")
ALLOWED_POS = {"noun", "adj", "adv", "interj", "num", "pron", "verb"}


def normalize(value: str) -> str:
    return value.translate(str.maketrans({"I": "ı", "İ": "i", "â": "a", "î": "i", "û": "u"})).lower().strip()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("jsonl", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    accepted: set[str] = set()
    with args.jsonl.open("r", encoding="utf-8") as handle:
        for raw in handle:
            try:
                item = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if item.get("lang_code") not in {None, "tr"} and item.get("lang") != "Turkish":
                continue
            pos = str(item.get("pos", "")).lower()
            if pos not in ALLOWED_POS:
                continue
            word_raw = str(item.get("word", ""))
            if not word_raw or word_raw != word_raw.lower():
                continue
            word = normalize(word_raw)
            if " " in word or not WORD_RE.fullmatch(word) or not 3 <= len(word) <= 12:
                continue
            # Top-level form-of entries are not independent headwords for game purposes.
            senses = [sense for sense in (item.get("senses") or []) if isinstance(sense, dict)]
            if senses and all((sense.get("form_of") or sense.get("alt_of")) for sense in senses):
                continue
            if pos == "verb" and word.endswith(("mak", "mek")):
                word = word[:-3]
                if len(word) < 3:
                    continue
            accepted.add(word)

    args.output.write_text("\n".join(sorted(accepted)) + "\n", encoding="utf-8")
    print(f"Review candidates: {len(accepted):,}")
    print("IMPORTANT: preserve Wiktionary/Kaikki CC-BY-SA + GFDL attribution if distributed.")


if __name__ == "__main__":
    main()
