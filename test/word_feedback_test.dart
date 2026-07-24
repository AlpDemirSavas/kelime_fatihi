import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_fatihi/core/turkish_text.dart';

void main() {
  test('Türkçe büyük/küçük I dönüşümü doğrudur', () {
    expect(TurkishText.lower('IİĞÜŞÖÇ'), 'ıiğüşöç');
    expect(TurkishText.upper('ıiğüşöç'), 'IİĞÜŞÖÇ');
  });

  test('Kelime normalize edilir', () {
    expect(TurkishText.normalizeWord('  ARMUT! '), 'armut');
    expect(TurkishText.normalizeWord('DESTE'), 'deste');
    expect(TurkishText.normalizeWord('KÂĞIT'), 'kağıt');
    expect(TurkishText.normalizeWord('SÛRET'), 'suret');
  });
}
