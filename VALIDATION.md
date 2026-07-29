# V7 Validation

## Sözlük

- `core_words.txt`: 27.854 doğrulama/bonus kelimesi.
- `level_words.txt`: 23.538 adet 3–9 harfli seviye kelimesi.
- `reviewed_expansion_words.txt`: 1.095 insan-kürasyonlu genişletme.
- `blocked_words.txt`: 212 kesin reddedilen kelime.
- `blocked_level_words.txt`: 400 zorunlu hedefe çıkamayan nadir/eski kelime.

## 10.000 bölüm

- `level_seeds.txt`: tam 10.000 satır ve 10.000 benzersiz harf imzası.
- `level_targets.txt`: tam 10.000 satır.
- Bütün target satırları seed harflerinden kurulabilir.
- Bütün target kelimeleri runtime `level_words` havuzunda bulunur.
- Bölüm hedef sayıları 5/6/7/8/9/10 eğrisine eksiksiz uyar.
- Wheel uzunlukları 5/6/7/8/9 olarak aynı difficulty sınırlarında artar.
- Nadir target denylist'i 10.000 bölümün hiçbirinde sızmaz.

## Kalite guard'ları

- Aynı wheel signature iki farklı bölümde kullanılmaz.
- En çok tekrar eden zorunlu kelime: 97 (test limiti <=120).
- 3 harfli zorunlu hedef: 12.935 (test limiti <15.000).
- Ardışık iki bölüm en fazla 2 ortak zorunlu hedef taşır.
- Curated hedef içeren bölüm: 9.446 / 10.000.
- Build-time frekans/kürasyon filtresi dışındaki kelime zorunlu hedefe alınmaz.

## Migration

`content_version = 7`. Kampanya sırası bilinçli yeniden optimize edildiği için yalnızca açık board'un `found_words`, `bonus_words` ve hint state'i temizlenir. Ulaşılan level ve ekonomi korunur.

## Çalıştırılacak kontroller

```text
flutter clean
flutter pub get
flutter analyze
flutter test
```
