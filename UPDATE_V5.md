# Kelime Fatihi V5 — 10K Campaign & Lexicon Quality

## Sözlük
- `boşuyor`, `tarıyor`, `atıyor` gibi şimdiki zaman çekimleri kaldırıldı.
- Geçmiş/gelecek/fiilimsi/iyelik biçimlerinin otomatik üretimi kaldırıldı.
- Zemberek'ten gerçek lexical headword'ler ve fiillerin yalın emir/kök biçimleri kullanılıyor.
- `atar`, `tara` elle onaylı istisna listesinde.
- 26.212 doğrulama kelimesi.
- 17.611 adet 3–7 harfli bölüm kelimesi.
- 10.000 benzersiz harf multiset'li seviye tohumu.

## Seviye sistemi
- Kampanya üst sınırı: 10.000.
- 100 bölüm = 1 bölge.
- 100 toplam bölge.
- Her seed en az 8 hedef üretilebilir şekilde build-time doğrulanıyor.
- Bölüm hedef sayısı ilerledikçe 5 → 6 → 7 → 8 olarak artıyor.

## Günlük giriş serisi
- Oyuncu her takvim günü uygulamayı açtığında seri +1.
- Aynı gün tekrar açmak seri artırmaz.
- Bir gün atlanırsa seri yeniden 1 olur.
- Her 7 gün: +5 altın.
- Her 30 gün: +20 altın.
- Günün Kelimesi kazanma/kaybetme giriş serisini bozmaz.

## Offline
Sözlük, 10.000 bölüm, günlük giriş serisi, görevler, sandıklar, ekonomi, sesler ve kayıtlar tamamen cihazda çalışır. Reklam/IAP internet gerektirir.
