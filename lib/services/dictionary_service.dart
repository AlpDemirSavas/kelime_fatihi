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

class DictionaryService {
  static const int maxLevel = 10000;

  final Set<String> _words = <String>{};
  final List<String> _dailyWords = <String>[];
  final Set<String> _levelWords = <String>{};
  final List<String> _seedWords = <String>[];
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
    ]);
    final parsed = await compute(_parseDictionaryPayload, rawAssets);

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
        'tool/build_quality_dictionary.py yeniden çalıştırılmalı.',
      );
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
    // V6 has one prevalidated UNIQUE wheel signature per level for 1..10,000.
    // Wheel size grows from 5 letters early in the campaign to 9 letters late.
    final seed = _seedWords[safeNumber - 1];
    final seeded = Random(safeNumber * 7919 + 104729);
    final words = _subWordsFor(seed).toList();

    // Builder guarantees at least eight candidates. Later, larger wheels
    // can expose more targets, but never more than are actually available.
    final targetCount = safeNumber < 100
        ? 5
        : safeNumber < 1000
        ? 6
        : safeNumber < 3000
        ? 7
        : safeNumber < 5500
        ? 8
        : safeNumber < 8000
        ? 9
        : 10;

    final sameSignature = words
        .where((word) => _signature(word) == _signature(seed))
        .toList();
    // A wheel seed is an internal letter source, not necessarily a mandatory
    // answer. Rare/archaic words may stay in level_seeds.txt to preserve the
    // existing 10,000-level mapping while being excluded from _levelWords.
    // If the seed itself is not an allowed target, prefer a safe anagram; if
    // there is none, use the strongest available safe subword instead.
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

    final letters = seed.split('')..shuffle(seeded);
    return ConquestLevel(number: safeNumber, letters: letters, words: selected);
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
