#!/usr/bin/env python3
"""Generate Kelime Fatihi's optimized 8,000-level campaign.

The campaign stays fully offline. A Turkish frequency list is used only at
build time to rank mandatory answers. The 8,000-level layout intentionally
uses fewer mandatory answers per board so more valid words remain rewarding bonus
discoveries, while globally enforcing a hard 20-use cap and short-word limits.

Frequency source expected by this script:
  hermitdave/FrequencyWords, content/2016/tr/tr_50k.txt
  Content license: CC BY-SA 4.0 (see THIRD_PARTY_NOTICES.md).
"""
from collections import Counter, defaultdict
from pathlib import Path
from itertools import combinations
import argparse
import hashlib
import json
import re
import statistics
import math
from collections import deque
import random

parser = argparse.ArgumentParser(
    description="Build the globally optimized 8,000-level Kelime Fatihi campaign."
)
parser.add_argument(
    "frequency_list",
    type=Path,
    help="HermitDave FrequencyWords Turkish tr_50k.txt (word + count format).",
)
parser.add_argument(
    "--project",
    type=Path,
    default=Path(__file__).resolve().parents[1],
)
args = parser.parse_args()
P = args.project.resolve()
D = P / "assets" / "dictionary"
F = args.frequency_list.resolve()
if not F.exists():
    raise SystemExit(f"Frequency list not found: {F}")

TR = str.maketrans(
    {'I': 'ı', 'İ': 'i', 'Â': 'a', 'Î': 'i', 'Û': 'u', 'â': 'a', 'î': 'i', 'û': 'u'}
)
ALLOWED = set('abcçdefgğhıijklmnoöprsştuüvyz')
MAX_LEVEL = 8000

# Keep 8,000 levels but reduce mandatory density enough for a true global
# 20-use ceiling. Extra valid words remain discoverable as bonus answers.
WHEEL_QUOTA = {5: 500, 6: 1100, 7: 2200, 8: 2500, 9: 1700}
MAX_TARGET_BY_WHEEL = {5: 5, 6: 6, 7: 6, 8: 7, 9: 6}
# User feedback specifically called out boards containing 4-5 three-letter
# answers. New campaign never permits more than three, and later boards are
# stricter because larger wheels have enough longer alternatives.
MAX_THREE_BY_WHEEL = {5: 3, 6: 3, 7: 3, 8: 3, 9: 3}
SAFE_BUFFER_BY_WHEEL = {5: 1, 6: 1, 7: 1, 8: 1, 9: 1}

# Metrics measured from the App Store campaign supplied before this V8 rebuild.
# They are kept here so the generated report remains a stable before/after
# comparison even when this deterministic optimizer is run more than once.
APP_STORE_BASELINE = {
    'level_count': 10000,
    'mandatory_total': 82405,
    'mandatory_unique': 6146,
    'mandatory_max_repeat': 97,
    'three_letter_total': 12935,
    'levels_with_4plus_three_letter': 883,
    'adjacent_wheel_similarity_mean': 0.15196233909105195,
    'adjacent_wheel_similarity_ge075': 31,
}

# The QUALITY version committed before this CAP20 pass is the migration/diff
# baseline for this update.
CAP20_BASELINE = {
    'level_count': 8000,
    'mandatory_total': 53400,
    'mandatory_unique': 5967,
    'mandatory_max_repeat': 20,
    'three_letter_total': 6696,
    'levels_with_4plus_three_letter': 0,
    'adjacent_wheel_similarity_mean': 0.12031156672361823,
    'adjacent_wheel_similarity_ge075': 0,
    'adjacent_target_overlap_max': 1,
}


def norm(w):
    return w.translate(TR).lower().replace('\u0307', '').strip()


def read(name):
    return [
        norm(line.split('#', 1)[0])
        for line in (D / name).read_text(encoding='utf8').splitlines()
        if norm(line.split('#', 1)[0])
    ]


def sig(w):
    return ''.join(sorted(w))


def subsets(s):
    chars = list(s)
    out = set()
    for n in range(3, len(chars) + 1):
        for inds in combinations(range(len(chars)), n):
            out.add(''.join(chars[i] for i in inds))
    return out


def target_count_for_seed(seed):
    return MAX_TARGET_BY_WHEEL[len(seed)]


def overlap(a, b):
    ca = Counter(a)
    cb = Counter(b)
    return sum((ca & cb).values()) / max(len(a), len(b))


def write_crlf(path, text):
    # Keep generated campaign/report files in the project's existing CRLF
    # convention so regeneration does not create noisy whole-file diffs.
    path.write_bytes(text.replace('\r\n', '\n').replace('\n', '\r\n').encode('utf8'))


freq = {}
for rank, line in enumerate(F.read_text(encoding='utf8').splitlines(), 1):
    parts = line.rsplit(' ', 1)
    if len(parts) != 2:
        continue
    word = norm(parts[0])
    if word and all(c in ALLOWED for c in word):
        freq.setdefault(word, rank)

blocked = set(read('blocked_words.txt'))
blocked_level = set(read('blocked_level_words.txt'))
play = set(read('play_words.txt'))
review = set(read('reviewed_expansion_words.txt'))
daily = set(read('daily_words.txt'))
curated = play | review | daily

# Name-only entries remain bonus answers; they are never mandatory targets.
# If a spelling is also explicitly curated as an everyday noun (ada, deniz,
# etc.), curated status wins and the common-noun use can still be a target.
proper_names_source = (P / 'lib' / 'data' / 'proper_names.dart').read_text(encoding='utf8')
proper_names = set(re.findall(r"'([^']+)'", proper_names_source))
proper_only = proper_names - curated

level_words = set(read('level_words.txt')) | {
    w for w in curated if 3 <= len(w) <= 9
}
level_words -= blocked | blocked_level | proper_only

by_signature = defaultdict(list)
for word in level_words:
    by_signature[sig(word)].append(word)
for signature in by_signature:
    by_signature[signature].sort()

FREQ_LIMIT = 35000
THREE_LIMIT = 15000


def mandatory_ok(word):
    if word in curated:
        return True
    rank = freq.get(word, 10**9)
    return rank <= FREQ_LIMIT and (len(word) >= 4 or rank <= THREE_LIMIT)


sub_cache = {}


def all_sub(signature):
    if signature not in sub_cache:
        result = set()
        for subset in subsets(signature):
            result.update(by_signature.get(subset, ()))
        sub_cache[signature] = sorted(result, key=lambda w: (-len(w), w))
    return sub_cache[signature]


def safe_sub(signature):
    return [w for w in all_sub(signature) if mandatory_ok(w)]


def freq_score(word):
    rank = freq.get(word)
    if rank is None:
        return 0.0
    return 150 * max(0.0, 1 - (rank - 1) / FREQ_LIMIT) ** 0.68


def best_full(signature):
    same = [w for w in by_signature[signature] if mandatory_ok(w)]
    if not same:
        return None
    return max(
        same,
        key=lambda w: (
            1 if w in play or w in daily else 0,
            1 if w in review else 0,
            freq_score(w),
            -len(w),
            w,
        ),
    )


def representative(signature):
    full = best_full(signature)
    if full:
        return full
    return min(
        by_signature[signature],
        key=lambda w: (
            0 if w in curated else 1 if w in freq else 2,
            freq.get(w, 999999),
            w,
        ),
    )


# Select only wheels that can satisfy both target count and three-letter caps.
# Candidate collection is separated from final selection so the optimizer can
# see which answer words are scarce across the whole 8,000-level campaign.
candidates_by_len = {}
quality_by_sig = {}
for wheel_len in range(5, 10):
    candidates = []
    required_targets = MAX_TARGET_BY_WHEEL[wheel_len]
    max_three = MAX_THREE_BY_WHEEL[wheel_len]
    safe_buffer = SAFE_BUFFER_BY_WHEEL[wheel_len]
    required_non_three = required_targets - max_three

    for signature in by_signature:
        if len(signature) != wheel_len:
            continue
        safe = safe_sub(signature)
        non_three = sum(len(w) >= 4 for w in safe)
        if len(safe) < required_targets + safe_buffer or non_three < required_non_three:
            continue

        curated_count = sum(w in curated for w in safe)
        three_count = sum(len(w) == 3 for w in safe)
        full = best_full(signature)
        full_bonus = 0
        if full:
            full_bonus = 850 + (400 if full in curated else 0) + freq_score(full) * 2

        top = sorted(
            safe,
            key=lambda w: (1 if w in curated else 0, freq_score(w), len(w)),
            reverse=True,
        )[: required_targets + 8]
        avg = sum(
            (120 if w in curated else 0) + freq_score(w) + len(w) * 8
            for w in top
        ) / len(top)

        distinct = len(set(signature))
        duplicate_penalty = (wheel_len - distinct) * 22
        short_pressure = max(0, three_count - max_three) * 18
        q = (
            full_bonus
            + min(len(safe), 60) * 22
            + min(curated_count, 15) * 65
            + avg * 4
            - duplicate_penalty
            - short_pressure
        )
        rep = representative(signature)
        candidates.append((q, signature, rep, len(safe), curated_count, full))
        quality_by_sig[signature] = q

    quota = WHEEL_QUOTA[wheel_len]
    if len(candidates) < quota:
        raise RuntimeError(
            f"{wheel_len}-letter eligible wheels: {len(candidates)}, quota: {quota}"
        )
    candidates_by_len[wheel_len] = candidates

# A word that is available on thousands of candidate wheels is not useful for
# reducing repetition. Candidate-wheel scarcity still contributes to wheel
# quality, but V11 additionally schedules both wheels and mandatory answers
# with a hard temporal cooldown.
eligible_word_degree = Counter()
for candidates in candidates_by_len.values():
    for _q, signature, *_rest in candidates:
        eligible_word_degree.update(safe_sub(signature))

SCARCITY_WEIGHT = 8000
BALANCE_MAX_REPEAT = 20
MIN_REPEAT_DISTANCE = 20
MIN_THREE_LETTER_REPEAT_DISTANCE = 30


def scarcity_bonus(signature):
    return sum(
        1.0 / math.sqrt(eligible_word_degree[word])
        for word in safe_sub(signature)
    )


def repeat_distance(word):
    return MIN_THREE_LETTER_REPEAT_DISTANCE if len(word) == 3 else MIN_REPEAT_DISTANCE


def tie(level, word):
    digest = hashlib.blake2b(
        f'{level}:{word}:campaign-8000-v11-spacing20'.encode(), digest_size=8
    ).digest()
    return int.from_bytes(digest, 'big') / 2**64


def answer_quality(word):
    score = freq_score(word)
    if word in play or word in daily:
        score += 205
    elif word in review:
        score += 155
    score += {3: -35, 4: 42, 5: 64, 6: 68, 7: 64, 8: 56, 9: 50}[len(word)]
    return score


# Sort every eligible wheel deterministically. Including the signature in the
# final key prevents Python hash/set iteration order from changing the campaign.
for wheel_len in range(5, 10):
    candidates_by_len[wheel_len].sort(
        key=lambda item: (
            -(item[0] + SCARCITY_WEIGHT * scarcity_bonus(item[1])),
            item[2],
            item[1],
        )
    )

word_degree_by_len = {
    wheel_len: Counter(
        word
        for _q, signature, *_rest in candidates_by_len[wheel_len]
        for word in set(safe_sub(signature))
    )
    for wheel_len in range(5, 10)
}


def _build_spaced_campaign():
    """Select/order wheels and targets while enforcing V11 cooldowns.

    The hard rules are campaign-wide:
      * every mandatory word is used at most 20 times;
      * 4+ letter words wait at least 20 levels before reuse;
      * 3-letter words wait at least 30 levels before reuse;
      * adjacent wheels stay below 75% multiset similarity;
      * no level contains more than three 3-letter mandatory answers.

    Within each wheel-size band we choose from the full eligible wheel pool,
    rather than fixing the 8,000 wheels first and repairing afterward. This is
    what makes the spacing rule feasible without admitting lower-quality words.
    """
    rng = random.Random(50021)
    usage = Counter()
    last_used = {}
    seeds = []
    targets = []
    previous_seed = None
    global_level = 0

    for wheel_len in range(5, 10):
        pool = candidates_by_len[wheel_len]
        remaining = list(range(len(pool)))
        quota = WHEEL_QUOTA[wheel_len]
        required = MAX_TARGET_BY_WHEEL[wheel_len]

        for _ in range(quota):
            global_level += 1
            search_positions = list(range(min(80, len(remaining))))
            valid = []

            def evaluate(position):
                pool_index = remaining[position]
                quality, signature, seed, *_rest = pool[pool_index]
                if previous_seed is not None and overlap(previous_seed, seed) >= 0.75:
                    return

                available = []
                long_count = 0
                for word in safe_sub(signature):
                    if usage[word] >= BALANCE_MAX_REPEAT:
                        continue
                    if global_level - last_used.get(word, -10**9) < repeat_distance(word):
                        continue
                    available.append(word)
                    if len(word) >= 4:
                        long_count += 1

                if len(available) < required or long_count < required - MAX_THREE_BY_WHEEL[wheel_len]:
                    return

                # Preserve capacity for later/larger wheels: among equally used
                # words, prefer spellings with less future-band demand. Quality
                # remains the final semantic tie-breaker.
                available.sort(
                    key=lambda word: (
                        usage[word],
                        sum(
                            word_degree_by_len[next_len][word]
                            for next_len in range(wheel_len + 1, 10)
                        ),
                        1 if len(word) == 3 else 0,
                        word_degree_by_len[wheel_len][word],
                        -answer_quality(word),
                        tie(global_level, word),
                        word,
                    )
                )

                chosen_words = []
                short_count = 0
                for word in available:
                    if len(word) == 3 and short_count >= MAX_THREE_BY_WHEEL[wheel_len]:
                        continue
                    chosen_words.append(word)
                    short_count += int(len(word) == 3)
                    if len(chosen_words) == required:
                        break
                if len(chosen_words) != required:
                    return

                slack = len(available) - required
                similarity = overlap(previous_seed, seed) if previous_seed else 0.0
                valid.append((position, pool_index, chosen_words, slack, similarity))

            for position in search_positions:
                evaluate(position)

            if not valid:
                # Deterministic broadened search. Randomization uses a fixed seed
                # and is only a search-order tool; final output is reproducible.
                extra = list(range(len(remaining)))
                rng.shuffle(extra)
                already_seen = set(search_positions)
                for position in extra[: min(320, len(extra))]:
                    if position not in already_seen:
                        evaluate(position)

            if not valid and len(remaining) <= 450:
                already_seen = set(search_positions)
                for position in range(len(remaining)):
                    if position not in already_seen:
                        evaluate(position)

            if not valid:
                raise RuntimeError(
                    f'Cannot satisfy repeat-distance rules at level {global_level} '
                    f'({wheel_len}-letter band, {len(remaining)} wheels remain).'
                )

            # The pool itself is sorted by wheel quality. Keep selection inside
            # the earliest valid candidates, then prefer the more constrained
            # wheel so fragile boards are not stranded at the end of a band.
            valid.sort(key=lambda item: item[0])
            shortlist = valid[: min(24, len(valid))]
            shortlist.sort(key=lambda item: (item[3], item[4], item[0]))
            top = shortlist[: min(6, len(shortlist))]
            position, pool_index, chosen_words, _slack, _similarity = top[
                rng.randrange(len(top))
            ]

            _quality, _signature, seed, *_rest = pool[pool_index]
            remaining.pop(position)
            seeds.append(seed)
            targets.append(chosen_words)
            previous_seed = seed

            for word in chosen_words:
                usage[word] += 1
                last_used[word] = global_level

    return seeds, targets, usage


seeds, targets, usage = _build_spaced_campaign()

assert len(seeds) == MAX_LEVEL
assert len({sig(seed) for seed in seeds}) == MAX_LEVEL
assert Counter(map(len, seeds)) == Counter(WHEEL_QUOTA)

for level_number, (seed, row) in enumerate(zip(seeds, targets), 1):
    expected = target_count_for_seed(seed)
    if len(row) != expected:
        raise RuntimeError(
            f'Level {level_number} target count mismatch: {len(row)}/{expected}'
        )
    if len(set(row)) != len(row):
        raise RuntimeError(f'Duplicate mandatory answer at level {level_number}.')
    if sum(len(word) == 3 for word in row) > MAX_THREE_BY_WHEEL[len(seed)]:
        raise RuntimeError(f'Three-letter cap violated at level {level_number}.')

# Sort only for stable display/storage. The selection itself is already fixed.
for row in targets:
    row.sort(key=lambda word: (-len(word), word))

balance_replacements = 0
adjacency_replacements = 0

# Before/after metrics use the campaign that existed when the optimizer began.
old_seed_rows = read('level_seeds.txt')
old_target_rows = []
for line in (D / 'level_targets.txt').read_text(encoding='utf8').splitlines():
    cleaned = line.split('#', 1)[0].strip()
    if not cleaned or '|' not in cleaned:
        continue
    old_target_rows.append([norm(x) for x in cleaned.split('|', 1)[1].split(',') if norm(x)])
old_usage = Counter(w for row in old_target_rows for w in row)
old_three = sum(len(w) == 3 for row in old_target_rows for w in row)
old_four_plus_three_levels = sum(sum(len(w) == 3 for w in row) >= 4 for row in old_target_rows)

old_sigs = {sig(s) for s in old_seed_rows}
new_sigs = {sig(s) for s in seeds}
letter_sim = [overlap(a, b) for a, b in zip(seeds, seeds[1:])]
target_jaccard = [
    len(set(a) & set(b)) / len(set(a) | set(b))
    for a, b in zip(targets, targets[1:])
]
length_counts = Counter(length for arr in targets for length in map(len, arr))
ranks = [freq[w] for arr in targets for w in arr if w in freq]
full_levels = sum(any(sig(w) == sig(seed) for w in arr) for seed, arr in zip(seeds, targets))
curated_levels = sum(any(w in curated for w in arr) for arr in targets)
three_per_level = [sum(len(w) == 3 for w in arr) for arr in targets]
feedback_forbidden = {'açım', 'dini', 'iple', 'stop'}
feedback_leaks = {
    w: [i for i, arr in enumerate(targets, 1) if w in arr]
    for w in sorted(feedback_forbidden)
}


positions_by_word = defaultdict(list)
for level_number, row in enumerate(targets, 1):
    for word in row:
        positions_by_word[word].append(level_number)

repeat_distance_violations = []
minimum_repeat_distance_4plus = MAX_LEVEL
minimum_repeat_distance_3 = MAX_LEVEL
for word, positions in positions_by_word.items():
    for left, right in zip(positions, positions[1:]):
        distance = right - left
        if len(word) == 3:
            minimum_repeat_distance_3 = min(minimum_repeat_distance_3, distance)
        else:
            minimum_repeat_distance_4plus = min(minimum_repeat_distance_4plus, distance)
        if distance < repeat_distance(word):
            repeat_distance_violations.append((word, left, right, distance))

report = {
    'app_store_baseline': APP_STORE_BASELINE,
    'cap20_baseline': CAP20_BASELINE,
    'previous_level_count': len(old_target_rows),
    'level_count': MAX_LEVEL,
    'seed_signature_overlap_with_previous': len(old_sigs & new_sigs),
    'removed_previous_wheel_signatures': len(old_sigs - new_sigs),
    'unique_wheels': len(new_sigs),
    'wheel_length_counts': dict(sorted(Counter(map(len, seeds)).items())),
    'all_exact_target_count': all(
        len(arr) == target_count_for_seed(seeds[i - 1]) for i, arr in enumerate(targets, 1)
    ),
    'levels_with_full_wheel_answer': full_levels,
    'levels_with_curated_answer': curated_levels,
    'mandatory_total': sum(map(len, targets)),
    'mandatory_unique': len(usage),
    'mandatory_max_repeat': max(usage.values()),
    'mandatory_at_repeat_cap': sum(v == BALANCE_MAX_REPEAT for v in usage.values()),
    'minimum_repeat_distance_4plus': minimum_repeat_distance_4plus,
    'minimum_repeat_distance_3': minimum_repeat_distance_3,
    'repeat_distance_violations': repeat_distance_violations,
    'balance_replacements': balance_replacements,
    'mandatory_length_counts': dict(sorted(length_counts.items())),
    'three_letter_total': sum(three_per_level),
    'three_letter_max_per_level': max(three_per_level),
    'levels_with_4plus_three_letter': sum(v >= 4 for v in three_per_level),
    'previous_mandatory_total': sum(len(row) for row in old_target_rows),
    'previous_mandatory_unique': len(old_usage),
    'previous_mandatory_max_repeat': max(old_usage.values()) if old_usage else 0,
    'previous_three_letter_total': old_three,
    'previous_levels_with_4plus_three_letter': old_four_plus_three_levels,
    'median_frequency_rank': statistics.median(ranks),
    'adjacent_wheel_similarity_mean': statistics.mean(letter_sim),
    'adjacent_wheel_similarity_p90': statistics.quantiles(letter_sim, n=10)[8],
    'adjacent_wheel_similarity_max': max(letter_sim),
    'adjacent_wheel_similarity_ge075': sum(v >= .75 for v in letter_sim),
    'adjacent_target_jaccard_mean': statistics.mean(target_jaccard),
    'adjacent_target_jaccard_max': max(target_jaccard),
    'adjacent_target_overlap_max': max(
        len(set(a) & set(b)) for a, b in zip(targets, targets[1:])
    ),
    'feedback_forbidden_target_levels': feedback_leaks,
    'most_repeated': usage.most_common(25),
    'examples': {
        str(i): {'seed': seeds[i - 1], 'targets': targets[i - 1]}
        for i in [1, 10, 50, 99, 100, 500, 800, 801, 1500, 2200, 2201, 3000, 4100, 4101, 5000, 6500, 6501, 7000, 7999, 8000]
    },
}

if any(feedback_leaks.values()):
    raise RuntimeError(f"Feedback-blocked target leaked into campaign: {feedback_leaks}")
if report['levels_with_4plus_three_letter'] != 0:
    raise RuntimeError('A level contains four or more three-letter mandatory answers.')
if report['mandatory_max_repeat'] > BALANCE_MAX_REPEAT:
    raise RuntimeError(
        f"Mandatory repetition remains above {BALANCE_MAX_REPEAT}: "
        f"{report['mandatory_max_repeat']}"
    )
if report['adjacent_target_overlap_max'] != 0:
    raise RuntimeError(
        f"Adjacent levels share mandatory targets: {report['adjacent_target_overlap_max']}"
    )
if repeat_distance_violations:
    raise RuntimeError(
        f"Repeat-distance rule violated: {repeat_distance_violations[:10]}"
    )
if minimum_repeat_distance_4plus < MIN_REPEAT_DISTANCE:
    raise RuntimeError('A 4+ letter target repeats before 20 levels.')
if minimum_repeat_distance_3 < MIN_THREE_LETTER_REPEAT_DISTANCE:
    raise RuntimeError('A three-letter target repeats before 30 levels.')

(D / 'level_seeds.txt').write_text('\n'.join(seeds) + '\n', encoding='utf8')
(D / 'level_targets.txt').write_text(
    '\n'.join(
        f"{sig(seed)}|{','.join(arr)}" for seed, arr in zip(seeds, targets)
    ) + '\n',
    encoding='utf8',
)
(P / 'CAMPAIGN_QUALITY_REPORT.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n',
    encoding='utf8',
)
summary = (
    "Kelime Fatihi 8,000-level campaign quality\n"
    "==========================================\n\n"
    f"Unique wheel signatures:                   {report['unique_wheels']:,}\n"
    f"Wheel sizes 5/6/7/8/9:                    "
    f"{WHEEL_QUOTA[5]:,}/{WHEEL_QUOTA[6]:,}/{WHEEL_QUOTA[7]:,}/{WHEEL_QUOTA[8]:,}/{WHEEL_QUOTA[9]:,}\n"
    f"Mandatory answer slots:                    {report['mandatory_total']:,}\n"
    f"Average mandatory answers per level:       {report['mandatory_total'] / MAX_LEVEL:.2f}\n"
    f"Unique mandatory answers:                  {report['mandatory_unique']:,}\n"
    f"Maximum mandatory answer repetition:       {report['mandatory_max_repeat']}\n"
    f"Minimum reuse distance (4+ letters):         {report['minimum_repeat_distance_4plus']} levels\n"
    f"Minimum reuse distance (3 letters):          {report['minimum_repeat_distance_3']} levels\n"
    f"Reuse-balance replacements:                {report['balance_replacements']:,}\n"
    f"Three-letter mandatory answers:            {report['three_letter_total']:,}\n"
    f"Max three-letter answers on one level:      {report['three_letter_max_per_level']}\n"
    f"Levels with 4+ three-letter answers:        {report['levels_with_4plus_three_letter']}\n"
    f"CAP20 baseline max repetition:              {CAP20_BASELINE['mandatory_max_repeat']}\n"
    f"App Store baseline max repetition:          {APP_STORE_BASELINE['mandatory_max_repeat']}\n"
    f"App Store baseline levels with 4+ 3-letter: {APP_STORE_BASELINE['levels_with_4plus_three_letter']}\n"
    f"Mean adjacent wheel similarity:             {report['adjacent_wheel_similarity_mean']:.4f}\n"
    f"Adjacent wheel pairs >= 75% similar:        {report['adjacent_wheel_similarity_ge075']}\n"
    f"Maximum adjacent target overlap:            {report['adjacent_target_overlap_max']}\n"
    "Feedback-blocked target leaks:             0\n"
)
write_crlf(P / 'CAMPAIGN_QUALITY_REPORT.txt', summary)
print(summary)
print('Most repeated:', usage.most_common(10))
