import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_fatihi/services/dictionary_service.dart';

String signature(String word) {
  final chars = word.split('')..sort();
  return chars.join();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('oyun sözlüğü gerçek başlıkları ve yalın fiil biçimlerini kabul eder', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'ana',
      'armut',
      'deste',
      'karınca',
      'tara',
      'boşal',
      'oyuncu',
      'sanatçı',
      'yayıncı',
      'kitapçı',
      'şarkıcı',
    ]) {
      expect(dictionary.contains(word), isTrue, reason: '$word sözlükte olmalı');
    }
  });

  test('zaman kip çekimleri iyelik fiilimsi ve yapay biçimler kabul edilmez', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'atar',
      'tarar',
      'boşuyor',
      'tarıyor',
      'atıyor',
      'atacak',
      'taradı',
      'geliyor',
      'geldi',
      'gelmiş',
      'gidiyor',
      'gitti',
      'gidecek',
      'yapıyor',
      'yaptı',
      'yapacak',
      'koşuyor',
      'koştu',
      'koşacak',
      'bakıyor',
      'baktı',
      'bakacak',
      'anam',
      'annem',
      'evim',
      'kitabı',
      'atarak',
      'atınca',
      'atmış',
      'gelmek',
      'yapmak',
      'temizlemek',
      'abrakadabralamak',
    ]) {
      expect(dictionary.contains(word), isFalse, reason: '$word oyun sözlüğünde olmamalı');
    }
  });


  test('yeni kürasyonlu kelimeler runtime sözlüğüne doğrudan dahil edilir', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'internet',
      'siber',
      'vizyoner',
      'yazılımcı',
      'girişimci',
      'tasarımcı',
      'üretici',
      'kullanıcı',
      'etkinlik',
      'liderlik',
      'dürüstlük',
      'toplumsal',
      'fiziksel',
      'bilinçli',
      'mantıklı',
      'sağlıklı',
      'gerçekçi',
      'riskli',
      'sürdürülebilirlik',
    ]) {
      expect(dictionary.contains(word), isTrue, reason: '$word sözlükte olmalı');
    }
  });

  test('global denylist runtime katmanında da kesin uygulanır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'ram',
      'ruam',
      'astik',
      'arkıt',
      'hilat',
      'rasıt',
      'abdiaciz',
      'adacyo',
      'accelerando',
      'aktinyum',
      'blastula',
      'single',
    ]) {
      expect(dictionary.contains(word), isFalse, reason: '$word kesin reddedilmeli');
    }
  });

  test('nadir kelimeler 10.000 bölümün hiçbirinde zorunlu hedef olmaz', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    final raw = await rootBundle.loadString(
      'assets/dictionary/blocked_level_words.txt',
    );
    final blockedTargets = raw
        .split(RegExp(r'\r?\n'))
        .map((line) => line.split('#').first.trim())
        .where((line) => line.isNotEmpty)
        .toSet();

    for (var levelNo = 1; levelNo <= DictionaryService.maxLevel; levelNo++) {
      final level = dictionary.buildLevel(levelNo);
      final leaked = level.words.where(blockedTargets.contains).toList();
      expect(leaked, isEmpty, reason: 'Bölüm $levelNo nadir hedef içeriyor: $leaked');
    }
  });

  test('10.000 seviyelik geniş havuz hazırdır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    expect(dictionary.wordCount, greaterThan(26000));
    expect(dictionary.levelWordCount, greaterThan(23000));
    expect(dictionary.seedCount, DictionaryService.maxLevel);

    final checkpoints = <int>[1, 99, 100, 999, 1000, 2999, 3000, 5499, 5500, 7999, 8000, 9999, 10000];
    for (final levelNo in checkpoints) {
      final level = dictionary.buildLevel(levelNo);
      expect(level.number, levelNo);
      expect(level.words.length, inInclusiveRange(5, 10));
      expect(level.letters.length, inInclusiveRange(5, 9));
    }
  });

  test('kampanya hedef sayısı ile birlikte harf çemberini büyütür', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    expect(dictionary.buildLevel(1).letters.length, 5);
    expect(dictionary.buildLevel(999).letters.length, 5);
    expect(dictionary.buildLevel(1000).letters.length, 6);
    expect(dictionary.buildLevel(2999).letters.length, 6);
    expect(dictionary.buildLevel(3000).letters.length, 7);
    expect(dictionary.buildLevel(5499).letters.length, 7);
    expect(dictionary.buildLevel(5500).letters.length, 8);
    expect(dictionary.buildLevel(7999).letters.length, 8);
    expect(dictionary.buildLevel(8000).letters.length, 9);
    expect(dictionary.buildLevel(10000).letters.length, 9);
  });

  test('10.000 optimize bölüm benzersiz ve tekrar dengeli kalır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    final seenWheels = <String>{};
    final targetFrequency = <String, int>{};
    var threeLetterTargets = 0;
    Set<String>? previousTargets;

    for (var levelNo = 1; levelNo <= DictionaryService.maxLevel; levelNo++) {
      final level = dictionary.buildLevel(levelNo);
      final wheelSignature = signature(level.letters.join());
      expect(
        seenWheels.add(wheelSignature),
        isTrue,
        reason: 'Tekrar eden harf çemberi: $levelNo',
      );

      final expectedTargetCount = levelNo < 100
          ? 5
          : levelNo < 1000
          ? 6
          : levelNo < 3000
          ? 7
          : levelNo < 5500
          ? 8
          : levelNo < 8000
          ? 9
          : 10;
      expect(
        level.words.length,
        expectedTargetCount,
        reason: 'Bölüm $levelNo hedef sayısı dengesiz',
      );

      for (final word in level.words) {
        targetFrequency[word] = (targetFrequency[word] ?? 0) + 1;
        if (word.length == 3) threeLetterTargets++;
      }

      if (previousTargets != null) {
        final overlap = previousTargets.intersection(level.words.toSet()).length;
        expect(
          overlap,
          lessThanOrEqualTo(2),
          reason: 'Ardışık bölümler fazla benzer: ${levelNo - 1}/$levelNo',
        );
      }
      previousTargets = level.words.toSet();
    }

    final maxTargetRepeat = targetFrequency.values.fold<int>(
      0,
      (current, value) => value > current ? value : current,
    );
    expect(seenWheels.length, DictionaryService.maxLevel);
    expect(maxTargetRepeat, lessThanOrEqualTo(120));
    expect(threeLetterTargets, lessThan(15000));
  });
}
