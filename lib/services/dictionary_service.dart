import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/turkish_text.dart';
import '../models/conquest_level.dart';

List<List<String>> _parseDictionaryPayload(List<String> texts) {
  return texts
      .map((text) {
        final words = <String>[];
        for (final raw in const LineSplitter().convert(text)) {
          final cleaned = raw.split('#').first.trim();
          if (cleaned.isEmpty) continue;
          final word = TurkishText.normalizeWord(cleaned);
          if (word.length >= 2) words.add(word);
        }
        return words;
      })
      .toList(growable: false);
}

List<List<String>> _parseLevelTargetPayload(String text) {
  final rows = <List<String>>[];
  for (final raw in const LineSplitter().convert(text)) {
    final cleaned = raw.split('#').first.trim();
    if (cleaned.isEmpty) continue;
    final separator = cleaned.indexOf('|');
    if (separator <= 0 || separator >= cleaned.length - 1) continue;

    final signature = TurkishText.normalizeWord(
      cleaned.substring(0, separator).trim(),
    );
    final words = cleaned
        .substring(separator + 1)
        .split(',')
        .map((word) => TurkishText.normalizeWord(word.trim()))
        .where((word) => word.length >= 3)
        .toList(growable: false);
    rows.add(<String>[signature, ...words]);
  }
  return rows;
}

class DictionaryService {
  static const int maxLevel = 10000;

  final Set<String> _words = <String>{};
  final List<String> _dailyWords = <String>[];
  final Set<String> _levelWords = <String>{};
  final List<String> _seedWords = <String>[];
  final List<List<String>> _levelTargets = <List<String>>[];
  final Map<String, List<String>> _levelWordsBySignature =
      <String, List<String>>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get wordCount => _words.length;
  int get levelWordCount => _levelWords.length;
  int get seedCount => _seedWords.length;

  Future<void> load() async {
    if (_loaded) return;

    // All vocabulary is bundled in the app and therefore fully offline.
    // Text parsing happens on a worker isolate to keep the first frame responsive.
    final rawAssets = await Future.wait([
      rootBundle.loadString('assets/dictionary/core_words.txt'),
      rootBundle.loadString('assets/dictionary/daily_words.txt'),
      rootBundle.loadString('assets/dictionary/play_words.txt'),
      rootBundle.loadString('assets/dictionary/level_words.txt'),
      rootBundle.loadString('assets/dictionary/level_seeds.txt'),
      rootBundle.loadString('assets/dictionary/manual_surface_words.txt'),
      rootBundle.loadString('assets/dictionary/reviewed_expansion_words.txt'),
      rootBundle.loadString('assets/dictionary/blocked_words.txt'),
      rootBundle.loadString('assets/dictionary/blocked_level_words.txt'),
      rootBundle.loadString('assets/dictionary/level_targets.txt'),
    ]);
    final parsed = await compute(
      _parseDictionaryPayload,
      rawAssets.take(9).toList(growable: false),
    );
    final parsedTargets = await compute(_parseLevelTargetPayload, rawAssets[9]);

    final blockedWords = parsed[7].toSet();
    final blockedLevelWords = parsed[8].toSet();

    _dailyWords
      ..clear()
      ..addAll(
        parsed[1].where(
          (word) => word.length == 5 && !blockedWords.contains(word),
        ),
      );

    _levelWords
      ..clear()
      ..addAll(parsed[3])
      ..addAll(parsed[2].where((word) => word.length >= 3 && word.length <= 9))
      ..addAll(parsed[6].where((word) => word.length >= 3 && word.length <= 9))
      ..addAll(_dailyWords.where((word) => word.length >= 3 && word.length <= 9))
      ..removeAll(blockedWords)
      ..removeAll(blockedLevelWords);

    _words
      ..clear()
      ..addAll(parsed[0])
      ..addAll(parsed[5])
      ..addAll(parsed[6])
      ..addAll(_dailyWords)
      ..addAll(_levelWords)
      ..removeAll(blockedWords);

    _seedWords
      ..clear()
      ..addAll(
        parsed[4].where(
          (word) => word.length >= 5 && word.length <= 9,
        ),
      );

    _levelWordsBySignature.clear();
    for (final word in _levelWords) {
      final key = _signature(word);
      (_levelWordsBySignature[key] ??= <String>[]).add(word);
    }

    if (_seedWords.length < maxLevel) {
      throw StateError(
        'Seviye tohumu eksik: ${_seedWords.length}/$maxLevel. '
        'tool/optimize_campaign.py yeniden çalıştırılmalı.',
      );
    }

    if (parsedTargets.length < maxLevel) {
      throw StateError(
        'Optimize hedef planı eksik: ${parsedTargets.length}/$maxLevel. '
        'tool/optimize_campaign.py yeniden çalıştırılmalı.',
      );
    }

    _levelTargets.clear();
    for (var index = 0; index < maxLevel; index++) {
      final row = parsedTargets[index];
      final seed = _seedWords[index];
      final expectedSignature = _signature(seed);
      if (row.isEmpty || row.first != expectedSignature) {
        throw StateError(
          'Seviye ${index + 1} hedef imzası seed ile uyuşmuyor.',
        );
      }

      final expectedCount = _targetCount(index + 1);
      final targets = row.skip(1).toList(growable: false);
      if (targets.length != expectedCount ||
          targets.toSet().length != targets.length ||
          targets.any(
            (word) =>
                !_levelWords.contains(word) || !_canBuildFrom(seed, word),
          )) {
        throw StateError(
          'Seviye ${index + 1} optimize hedef planı geçersiz.',
        );
      }
      _levelTargets.add(targets);
    }

    _loaded = true;
  }

  bool contains(String value) =>
      _words.contains(TurkishText.normalizeWord(value));

  String dailyWord(DateTime now) {
    if (_dailyWords.isEmpty) return 'kalem';
    final localDate = DateTime(now.year, now.month, now.day);
    final epoch = DateTime(2026, 1, 1);
    final index = localDate.difference(epoch).inDays.abs() % _dailyWords.length;
    return _dailyWords[index];
  }

  ConquestLevel buildLevel(int number) {
    if (_seedWords.isEmpty) {
      return const ConquestLevel(
        number: 1,
        letters: ['k', 'a', 'l', 'e', 'm'],
        words: ['kalem', 'alem', 'elma', 'kel', 'mal'],
      );
    }

    final safeNumber = number.clamp(1, maxLevel).toInt();
    // V7 has one prevalidated UNIQUE wheel signature per level for 1..10,000.
    // Wheel size grows at the same boundaries as the mandatory target count.
    final seed = _seedWords[safeNumber - 1];
    final seeded = Random(safeNumber * 7919 + 104729);

    // V7 mandatory answers are precomputed globally. The optimizer sees the
    // whole 10,000-level campaign at once, so it can reduce repeated answers,
    // favor curated/frequent vocabulary and keep adjacent boards dissimilar.
    // This is deliberately not re-randomized at runtime.
    final selected = _levelTargets.isNotEmpty
        ? List<String>.from(_levelTargets[safeNumber - 1])
        : _fallbackTargets(seed, safeNumber, seeded);

    final letters = seed.split('')..shuffle(seeded);
    return ConquestLevel(number: safeNumber, letters: letters, words: selected);
  }

  int _targetCount(int levelNumber) {
    if (levelNumber < 100) return 5;
    if (levelNumber < 1000) return 6;
    if (levelNumber < 3000) return 7;
    if (levelNumber < 5500) return 8;
    if (levelNumber < 8000) return 9;
    return 10;
  }

  List<String> _fallbackTargets(String seed, int levelNumber, Random seeded) {
    final words = _subWordsFor(seed).toList();
    final targetCount = _targetCount(levelNumber);
    final sameSignature = words
        .where((word) => _signature(word) == _signature(seed))
        .toList();
    final mainWord = sameSignature.contains(seed)
        ? seed
        : (sameSignature.isNotEmpty
              ? sameSignature.first
              : (words.isNotEmpty ? words.first : seed));
    final others = words.where((word) => word != mainWord).toList()
      ..shuffle(seeded);
    final selected = <String>[
      mainWord,
      ...others.take(targetCount - 1),
    ].toSet().toList();
    selected.sort((a, b) {
      final length = b.length.compareTo(a.length);
      return length != 0 ? length : a.compareTo(b);
    });
    return selected;
  }

  bool _canBuildFrom(String seed, String word) {
    final available = <String, int>{};
    for (final char in seed.split('')) {
      available[char] = (available[char] ?? 0) + 1;
    }
    for (final char in word.split('')) {
      final count = available[char] ?? 0;
      if (count <= 0) return false;
      available[char] = count - 1;
    }
    return true;
  }

  Iterable<String> _subWordsFor(String seed) sync* {
    final subsetKeys = _subsetSignatures(seed);
    final result = <String>{};
    for (final key in subsetKeys) {
      result.addAll(_levelWordsBySignature[key] ?? const <String>[]);
    }
    final sorted = result.toList()
      ..sort((a, b) {
        final length = b.length.compareTo(a.length);
        return length != 0 ? length : a.compareTo(b);
      });
    yield* sorted;
  }

  Set<String> _subsetSignatures(String word) {
    final chars = word.split('')..sort();
    final result = <String>{};
    final combinations = 1 << chars.length;
    for (var mask = 1; mask < combinations; mask++) {
      var count = 0;
      final buffer = StringBuffer();
      for (var i = 0; i < chars.length; i++) {
        if ((mask & (1 << i)) != 0) {
          count++;
          buffer.write(chars[i]);
        }
      }
      if (count >= 3) result.add(buffer.toString());
    }
    return result;
  }

  String _signature(String word) {
    final chars = word.split('')..sort();
    return chars.join();
  }
}
