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

  test('kampanya ilerledikçe harf çemberi büyür', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    expect(dictionary.buildLevel(1).letters.length, 5);
    expect(dictionary.buildLevel(1001).letters.length, 6);
    expect(dictionary.buildLevel(3001).letters.length, 7);
    expect(dictionary.buildLevel(5501).letters.length, 8);
    expect(dictionary.buildLevel(8201).letters.length, 9);
  });

  test('örnek uzak seviyelerde harf çemberleri tekrar etmez', () async {
    final dictionary = DictionaryService();
    await dictionary.load();

    final seen = <String>{};
    for (var levelNo = 1; levelNo <= 500; levelNo++) {
      final level = dictionary.buildLevel(levelNo);
      expect(seen.add(signature(level.letters.join())), isTrue, reason: 'Tekrar eden seviye: $levelNo');
    }
  });
}
