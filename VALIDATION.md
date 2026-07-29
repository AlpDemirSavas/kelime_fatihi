# Sözlük kalite yaması doğrulaması — 2026-07-29

Statik/asset kontrolleri:

- Runtime validation lexicon: 27.854 kelime
- Mandatory level target vocabulary: 23.538 kelime
- Reviewed expansion: 1.095 kelime
- Global gameplay denylist: 212 kelime
- Mandatory-target denylist: 400 kelime
- Unique level wheels: 10.000
- `level_seeds.txt` sırası korunmuştur.
- Yeni 853 onaylı kelime doğrulama katmanına eklenmiştir.
- Bunların 679 adet 5–9 harfli kısmı zorunlu hedef havuzuna uygundur.
- Global denylist ile `core_words.txt` / `level_words.txt` arasında kesişim yoktur.
- Mandatory-target denylist ile `level_words.txt` arasında kesişim yoktur.
- Runtime katmanı reviewed/manual listeleri doğrudan birleştirir ve denylist'leri son kez uygular.
- Çekimli zaman/kip, otomatik iyelik/hal ve fiilimsi üretimi kapalı kalmıştır.
- `content_version = 6`; yalnızca güncelleme sırasında açık olan bölümün geçici hedef/bonus/ipucu durumu sıfırlanır.

Gerçek Flutter SDK doğrulaması kullanıcı makinesinde yapılmalıdır:

```text
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```
