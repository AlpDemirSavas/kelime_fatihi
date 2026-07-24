# Kelime Fatihi V7 - Statik Doğrulama

Tarih: 2026-07-23

Bu çalışma ortamında Flutter/Dart SDK bulunmadığı için `flutter analyze`, `flutter test`, Android AAB veya iOS IPA derlemesi burada çalıştırılamadı.

Yapılan statik kontroller:

- `pubspec.yaml` YAML olarak parse edildi.
- 32 Dart dosyası için parantez/süslü parantez/köşeli parantez dengesi tarandı.
- Google + Apple hesap ekranı ve Firebase fallback akışı mevcut.
- Firestore kullanıcı bazlı güvenlik kuralı mevcut.
- `kf_reklamsiz` non-consumable ürün akışı ve restore butonu mevcut.
- Bölüm sonu interstitial çağrısı her bölüm tamamlama akışına bağlı.
- Reklam hazır değilse/offline ise oyun bloklanmadan devam ediyor.
- Mevcut bölümde daha önce bulunan bonus kelimeler `+1` listesinde gösteriliyor.
- Oyun çekirdeği sözlük/seviye/can/altın/görev/kayıt açısından yerel varlıklara dayanıyor; Firebase/AdMob/IAP açılışı bloke etmiyor.
- Sözlük varlıkları: 26.453 doğrulama kelimesi, 23.376 bölüm kelimesi, 10.000 seviye tohumu.

Kullanıcının bilgisayarında yayın öncesi zorunlu gerçek kontroller:

```text
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

Daha sonra gerçek Android/iPhone cihaz, TestFlight ve mağaza sandbox/test purchase kontrolleri yapılmalıdır.
