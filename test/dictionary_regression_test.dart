import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_fatihi/models/conquest_region.dart';
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
      'atel',
      'atıl',
      'iban',
      'kobi',
      'pati',
      'pile',
      'admin',
      'mesir',
      'sana',
      'piksel',
      'rakun',
      'ünlü',
      'kalıcı',
      'kanlı',
      'etli',
      'atlı',
      'katlı',
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
      'aştı',
      'iple',
      'stop',
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


  test('App Store sürümündeki güvenli bonus kelimeler korunur', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'alman',
      'anka',
      'ataç',
      'çinli',
      'koreli',
      'laz',
      'rus',
      'sota',
      'türk',
      'yunan',
    ]) {
      expect(
        dictionary.contains(word),
        isTrue,
        reason: '$word App Store davranışıyla bonus kabul edilmeli',
      );
    }
  });

  test('App Store reviewed kelimeleri yeni sözlükte kaybolmaz', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'akan',
      'alma',
      'alman',
      'anaç',
      'anka',
      'anlaş',
      'arşın',
      'bana',
      'baya',
      'besi',
      'beyit',
      'emel',
      'fevri',
      'jel',
      'kalan',
      'karaca',
      'meze',
      'nötr',
      'obur',
      'oje',
      'pazı',
      'peşrev',
      'promosyon',
      'rakun',
      'reel',
      'reji',
      'safha',
      'ısın',
      'şıra',
    ]) {
      expect(
        dictionary.contains(word),
        isTrue,
        reason: '$word App Store reviewed sözlüğünden kaybolmamalı',
      );
    }
  });

  test('App Store global uygunsuzluk denylisti geri dönmez', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'abazan',
      'boktan',
      'fahişe',
      'gerdek',
      'götün',
      'kahpe',
      'kaltak',
      'orgazm',
      'penis',
      'porno',
      'sakso',
      'seks',
      'seksi',
      'seksüel',
      'sürtük',
      'taşak',
      'testis',
      'vajina',
      'yarak',
      'yavşak',
      'çük',
      'şıllık',
    ]) {
      expect(
        dictionary.contains(word),
        isFalse,
        reason: '$word App Store global denylistinde kalmalı',
      );
    }
  });

  test('App Store Günün Kelimesi sırası korunur', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    expect(dictionary.dailyWord(DateTime(2026, 1, 1)), 'kalem');
    expect(dictionary.dailyWord(DateTime(2026, 8, 6)), 'yazar');
  });

  test('şehirler ve fetih haritası adları özel ad olarak can götürmez', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    for (final word in <String>[
      'van',
      'ankara',
      'izmir',
      'mila',
      'almila',
      'nare',
      'akan',
      'erdi',
      'roma',
      'söğüt',
      'semerkant',
    ]) {
      expect(
        dictionary.isProperName(word),
        isTrue,
        reason: '$word özel ad olarak can götürmemeli',
      );
    }

    for (var index = 0; index < ConquestRegion.regionCount; index++) {
      final region = ConquestRegion.forLevel(
        index * ConquestRegion.regionSize + 1,
      );
      expect(
        dictionary.isProperName(region.name),
        isTrue,
        reason: '${region.name} harita adı bonus/özel ad olarak tanınmalı',
      );
    }
  });

  test('Günün Kelimesi hassas hedef filtresini de uygular', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    final blockedLevelRaw = await rootBundle.loadString(
      'assets/dictionary/blocked_level_words.txt',
    );
    final blockedDaily = blockedLevelRaw
        .split(RegExp(r'\r?\n'))
        .map((line) => line.split('#').first.trim())
        .where((line) => line.isNotEmpty)
        .toSet();

    final start = DateTime(2026, 1, 1);
    for (var day = 0; day < 400; day++) {
      final word = dictionary.dailyWord(start.add(Duration(days: day)));
      expect(
        blockedDaily.contains(word),
        isFalse,
        reason: 'Günün Kelimesi hassas hedef içeriyor: $word',
      );
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
      'anal',
      'bira',
      'rakı',
      'kanla',
      'der',
    ]) {
      expect(dictionary.contains(word), isFalse, reason: '$word kesin reddedilmeli');
    }
  });

  test('nadir kelimeler 8.000 bölümün hiçbirinde zorunlu hedef olmaz', () async {
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


  test('8.000 bölüm 80 benzersiz harita durağına yayılır', () {
    expect(ConquestRegion.regionCount, 80);
    final names = <String>{};
    for (var index = 0; index < ConquestRegion.regionCount; index++) {
      names.add(ConquestRegion.forLevel(index * ConquestRegion.regionSize + 1).name);
    }
    expect(names.length, ConquestRegion.regionCount);
    expect(ConquestRegion.forLevel(8000).endLevel, 8000);
  });

  test('8.000 seviyelik yoğunlaştırılmış havuz hazırdır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    expect(dictionary.wordCount, greaterThan(26000));
    expect(dictionary.levelWordCount, greaterThan(22500));
    expect(dictionary.seedCount, DictionaryService.maxLevel);

    final checkpoints = <int>[
      1,
      99,
      100,
      500,
      501,
      1600,
      1601,
      3800,
      3801,
      6300,
      6301,
      7999,
      8000,
    ];
    for (final levelNo in checkpoints) {
      final level = dictionary.buildLevel(levelNo);
      expect(level.number, levelNo);
      expect(level.words.length, inInclusiveRange(5, 8));
      expect(level.letters.length, inInclusiveRange(5, 9));
    }
  });

  test('kampanya hedef sayısı ile birlikte harf çemberini büyütür', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    expect(dictionary.buildLevel(1).letters.length, 5);
    expect(dictionary.buildLevel(500).letters.length, 5);
    expect(dictionary.buildLevel(501).letters.length, 6);
    expect(dictionary.buildLevel(1600).letters.length, 6);
    expect(dictionary.buildLevel(1601).letters.length, 7);
    expect(dictionary.buildLevel(3800).letters.length, 7);
    expect(dictionary.buildLevel(3801).letters.length, 8);
    expect(dictionary.buildLevel(6300).letters.length, 8);
    expect(dictionary.buildLevel(6301).letters.length, 9);
    expect(dictionary.buildLevel(8000).letters.length, 9);
  });

  test('8.000 optimize bölüm benzersiz ve tekrar dengeli kalır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    final seenWheels = <String>{};
    final targetFrequency = <String, int>{};
    var threeLetterTargets = 0;
    Set<String>? previousTargets;
    final lastTargetLevel = <String, int>{};

    for (var levelNo = 1; levelNo <= DictionaryService.maxLevel; levelNo++) {
      final level = dictionary.buildLevel(levelNo);
      final wheelSignature = signature(level.letters.join());
      expect(
        seenWheels.add(wheelSignature),
        isTrue,
        reason: 'Tekrar eden harf çemberi: $levelNo',
      );

      final expectedTargetCount = switch (level.letters.length) {
        5 => 5,
        6 => 6,
        7 => 6,
        8 => 7,
        9 => 6,
        _ => 0,
      };
      expect(
        level.words.length,
        expectedTargetCount,
        reason: 'Bölüm $levelNo hedef sayısı dengesiz',
      );

      final shortTargetCount = level.words.where((word) => word.length == 3).length;
      expect(
        shortTargetCount,
        lessThanOrEqualTo(3),
        reason: 'Bölüm $levelNo üç harfli hedefleri fazla yoğun',
      );
      for (final forbidden in <String>[
        'açım',
        'dini',
        'iple',
        'stop',
        'anal',
        'bira',
        'rakı',
        'kanla',
        'der',
        'birarada',
        'mantarlar',
        'sensen',
        'verdi',
        'kelepçele',
        'restore',
        'pagan',
        'misal',
        'ikaz',
        'alındı',
        'bastı',
        'bindi',
        'indi',
        'kondu',
        'bilinen',
        'çıkacak',
        'tutacak',
        'taklidi',
        'yurdu',
        'daim',
        'idam',
        'afedersin',
        'bendeniz',
        'görünürde',
        'görünüşte',
        'götün',
        'hafızasız',
        'hödük',
        // Final release: geçerli olsa bile bonus-only/kalite nedeniyle
        // zorunlu hedefe dönmemesi gereken kelimeler.
        'bilme',
        'sever',
        'uyur',
        'pezo',
        'jigolo',
        'sut',
        'mimle',
        'tulu',
        'roda',
        'deh',
        'edi',
        'cezire',
        'zecir',
        'zecri',
        'merci',
        'bala',
        'illi',
        'kumla',
        'neşide',
        'kula',
        'kıs',
        'şeni',
        'cemil',
        'deni',
        'ede',
        'kubaş',
        'met',
        'ulam',
        'deş',
        'ehli',
        'memeliler',
        'ene',
      ]) {
        expect(
          level.words,
          isNot(contains(forbidden)),
          reason: 'Bölüm $levelNo feedback ile kaldırılan hedef içeriyor: $forbidden',
        );
      }

      for (final word in level.words) {
        targetFrequency[word] = (targetFrequency[word] ?? 0) + 1;
        if (word.length == 3) threeLetterTargets++;

        final previousLevel = lastTargetLevel[word];
        if (previousLevel != null) {
          final minimumDistance = word.length == 3 ? 30 : 20;
          expect(
            levelNo - previousLevel,
            greaterThanOrEqualTo(minimumDistance),
            reason:
                'Hedef kelime çok erken tekrar ediyor: $word ($previousLevel/$levelNo)',
          );
        }
        lastTargetLevel[word] = levelNo;
      }

      if (previousTargets != null) {
        final overlap = previousTargets.intersection(level.words.toSet()).length;
        expect(
          overlap,
          0,
          reason: 'Ardışık bölümlerde aynı zorunlu kelime var: ${levelNo - 1}/$levelNo',
        );
      }
      previousTargets = level.words.toSet();
    }

    final maxTargetRepeat = targetFrequency.values.fold<int>(
      0,
      (current, value) => value > current ? value : current,
    );
    expect(seenWheels.length, DictionaryService.maxLevel);
    expect(maxTargetRepeat, lessThanOrEqualTo(20));
    expect(threeLetterTargets, lessThan(7000));
    expect(targetFrequency.length, greaterThanOrEqualTo(5900));
  });
}
