#!/usr/bin/env python3
"""Build Kelime Fatihi V6's offline Turkish gameplay dictionaries.

V6 policy
---------
1. Finite tense/mood conjugations are NOT generated as gameplay words.
2. Zemberek lexical headwords are the primary source. Proper names,
   abbreviations, punctuation and bare infinitives are excluded.
3. Dictionary verbs contribute only the bare imperative/root surface
   (taramak -> tara). This is not a tense form.
4. A small manually-reviewed expansion list comes from the MIT-licensed
   Turkish Hunspell spelling dictionary. It contains human-readable lexical
   items only; no bulk Hunspell inflection expansion is imported.
5. Level vocabulary accepts 3..9 letter lexical words. This grows the target
   vocabulary without inventing suffix combinations.
6. 10,000 level wheels use unique letter multisets. Wheel size increases
   through the campaign: 5 letters early, up to 9 letters late.

Primary source: Zemberek-NLP master dictionary (Apache-2.0).
Secondary reviewed source: Turkish Hunspell / dictionary-tr (MIT).
"""
from __future__ import annotations

import argparse
import random
import re
from collections import defaultdict
from itertools import combinations
from pathlib import Path

TR_TRANSLATION = str.maketrans({
    "I": "ı", "İ": "i", "Â": "a", "Î": "i", "Û": "u",
    "â": "a", "î": "i", "û": "u",
})
WORD_RE = re.compile(r"^[abcçdefgğhıijklmnoöprsştuüvyz]+$")


def normalize(word: str) -> str:
    return word.translate(TR_TRANSLATION).lower().replace("\u0307", "").strip()


def valid_plain(word: str, min_len: int = 2, max_len: int = 24) -> bool:
    return bool(WORD_RE.fullmatch(word)) and min_len <= len(word) <= max_len


def read_plain_words(path: Path) -> set[str]:
    result: set[str] = set()
    if not path.exists():
        return result
    for raw in path.read_text(encoding="utf-8").splitlines():
        word = normalize(raw.split("#", 1)[0])
        if valid_plain(word):
            result.add(word)
    return result


def parse_zemberek(path: Path, blocked: set[str]) -> tuple[set[str], set[str]]:
    """Return (safe lexical headwords, verb infinitives)."""
    lexical: set[str] = set()
    verbs: set[str] = set()

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("##"):
            continue

        lemma_raw = line.split(" [", 1)[0].strip()
        metadata = line[len(lemma_raw):]
        lemma = normalize(lemma_raw)
        if not valid_plain(lemma) or lemma in blocked:
            continue

        excluded = (
            "P:Noun,Prop" in metadata
            or "P:Abbrv" in metadata
            or "P:Punc" in metadata
        )
        if excluded:
            continue

        # Some surface forms are lexical homographs of verb forms, e.g.
        # "gelir" (income), "yazar" (author), "dolar" (dollar). If Zemberek
        # stores them as independent non-verb entries they remain valid words.
        nonverb_homograph = any(
            marker in metadata
            for marker in ("P:Noun", "P:Adj", "P:Adv", "P:Pron", "P:Num", "P:Interj")
        )
        is_verb_infinitive = lemma.endswith(("mak", "mek")) and not nonverb_homograph
        if is_verb_infinitive:
            verbs.add(lemma)
        else:
            lexical.add(lemma)

    return lexical, verbs


def imperative_roots(verbs: set[str], blocked: set[str]) -> set[str]:
    """Convert infinitives to bare command/root form only (not tense)."""
    result: set[str] = set()
    for infinitive in verbs:
        root = infinitive[:-3]
        if valid_plain(root, 3, 12) and root not in blocked:
            result.add(root)
    return result


def signature(word: str) -> str:
    return "".join(sorted(word))


def subword_signatures(sig: str) -> set[str]:
    chars = list(sig)
    found: set[str] = set()
    for size in range(3, len(chars) + 1):
        for indexes in combinations(range(len(chars)), size):
            found.add("".join(chars[i] for i in indexes))
    return found


def build_level_seeds(
    level_words: set[str],
    curated: set[str],
    daily: set[str],
) -> tuple[list[str], dict[str, int]]:
    """Choose 10k unique wheel signatures with progressively larger wheels."""
    by_sig: dict[str, list[str]] = defaultdict(list)
    for word in level_words:
        by_sig[signature(word)].append(word)

    candidates_by_len: dict[int, list[tuple[str, int, str, int]]] = defaultdict(list)
    for sig, same_sig_words in by_sig.items():
        if not 5 <= len(sig) <= 9:
            continue
        count = sum(len(by_sig.get(sub_sig, ())) for sub_sig in subword_signatures(sig))
        if count < 8:
            continue

        preferred = sorted(
            same_sig_words,
            key=lambda w: (
                0 if w in curated else 1 if w in daily else 2,
                len(w),
                w,
            ),
        )[0]
        tier = 0 if preferred in curated else 1 if preferred in daily else 2
        candidates_by_len[len(sig)].append((preferred, count, sig, tier))

    # 10,000-stage difficulty curve. Exact quotas total 10,000.
    quotas = {5: 1000, 6: 2000, 7: 2500, 8: 2700, 9: 1800}
    for length, required in quotas.items():
        if len(candidates_by_len[length]) < required:
            raise SystemExit(
                f"Only {len(candidates_by_len[length]):,} viable {length}-letter wheels; "
                f"need {required:,}."
            )

    rng = random.Random(20260722)
    chosen: list[tuple[str, int, str, int]] = []
    for length in range(5, 10):
        candidates = candidates_by_len[length]
        candidates.sort(key=lambda item: (item[3], -item[1], item[0]))
        ordered: list[tuple[str, int, str, int]] = []
        for start in range(0, len(candidates), 250):
            block = candidates[start:start + 250]
            rng.shuffle(block)
            ordered.extend(block)
        chosen.extend(ordered[:quotas[length]])

    richness = {word: count for word, count, _, _ in chosen}
    return [word for word, _, _, _ in chosen], richness


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("zemberek", type=Path)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    project = args.project.resolve()
    dictionary_dir = project / "assets" / "dictionary"
    daily = read_plain_words(dictionary_dir / "daily_words.txt")
    curated = read_plain_words(dictionary_dir / "play_words.txt")
    blocked = read_plain_words(dictionary_dir / "blocked_words.txt")
    manual_surface = read_plain_words(dictionary_dir / "manual_surface_words.txt")
    reviewed_expansion = read_plain_words(dictionary_dir / "reviewed_expansion_words.txt")

    lexical, verbs = parse_zemberek(args.zemberek, blocked)
    imperative = imperative_roots(verbs, blocked)

    # No productive tense/possessive expansion. Every addition must come from
    # a lexical source or the explicit reviewed file.
    validation = (
        lexical | imperative | manual_surface | reviewed_expansion | daily | curated
    ) - blocked

    # 3..9 letters makes substantially more real lexical entries playable,
    # instead of padding the lexicon with conjugated forms.
    level_words = {
        w for w in (lexical | imperative | reviewed_expansion | curated | daily)
        if 3 <= len(w) <= 9 and w not in blocked
    }

    seeds, richness = build_level_seeds(level_words, curated, daily)

    (dictionary_dir / "core_words.txt").write_text(
        "\n".join(sorted(validation)) + "\n", encoding="utf-8"
    )
    (dictionary_dir / "level_words.txt").write_text(
        "\n".join(sorted(level_words)) + "\n", encoding="utf-8"
    )
    (dictionary_dir / "level_seeds.txt").write_text(
        "\n".join(seeds) + "\n", encoding="utf-8"
    )

    should_accept = {
        "ana", "tara", "armut", "deste", "karınca", "boşal",
        "oyuncu", "sanatçı", "yayıncı", "kitapçı", "şarkıcı",
    }
    should_reject = {
        "atar", "tarar", "boşuyor", "tarıyor", "atıyor", "atacak", "taradı",
        "atarak", "atınca", "atmış", "anam", "annem", "evim", "kitabı",
        "geliyor", "geldi", "gelmiş", "gidiyor", "gitti", "gidecek",
        "yapıyor", "yaptı", "yapacak", "koşuyor", "koştu", "koşacak",
        "bakıyor", "baktı", "bakacak", "abrakadabralamak", "temizlemek",
    }
    failed = []
    for word in sorted(should_accept):
        if word not in validation:
            failed.append((word, True, False))
    for word in sorted(should_reject):
        if word in validation:
            failed.append((word, False, True))
    if failed:
        raise SystemExit(f"Dictionary regression failed: {failed}")

    signatures = [signature(word) for word in seeds]
    if len(seeds) != 10_000 or len(set(signatures)) != 10_000:
        raise SystemExit("10,000 level seeds are not unique by wheel signature")
    if min(richness.values()) < 8:
        raise SystemExit("A level seed has fewer than eight buildable target words")

    seed_lengths = {n: sum(1 for word in seeds if len(word) == n) for n in range(5, 10)}
    report = (
        f"Zemberek lexical headwords:              {len(lexical):,}\n"
        f"Verb imperative/root forms:              {len(imperative):,}\n"
        f"Reviewed Hunspell additions:             {len(reviewed_expansion):,}\n"
        f"Manual exceptional surface forms:        {len(manual_surface):,}\n"
        f"Validation lexicon:                       {len(validation):,}\n"
        f"Level target vocabulary (3-9 letters):   {len(level_words):,}\n"
        f"Unique prevalidated level wheels:         {len(seeds):,}\n"
        f"Wheel sizes 5/6/7/8/9:                   "
        f"{seed_lengths[5]:,}/{seed_lengths[6]:,}/{seed_lengths[7]:,}/"
        f"{seed_lengths[8]:,}/{seed_lengths[9]:,}\n"
        f"Minimum buildable targets per wheel:      {min(richness.values())}\n"
        "Finite tense/mood generation:             OFF\n"
        "Possessive/case inflection generation:    OFF\n"
        "Gerund/participle generation:             OFF\n"
        "Quality regression checks:                OK\n"
    )
    (project / "DICTIONARY_BUILD_REPORT.txt").write_text(report, encoding="utf-8")
    print(report)


if __name__ == "__main__":
    main()
