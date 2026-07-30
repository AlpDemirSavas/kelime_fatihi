KELIME FATIHI - GAMEPLAY UX + BANNER PATCH
==========================================

Degisiklikler
-------------
1) Harf tekerinde geri surukleme:
   - Secim yolunda bir onceki harfe geri gelince son harf geri alinir.
   - Parmak kaldirilana kadar hatali secim duzeltilebilir.

2) Gunun Kelimesi klavyesi:
   - Standart Turkce Q dizilimi:
     Q W E R T Y U I O P G(UZATMA) U(UMLAUT)
     A S D F G H J K L S(CEDILLA) I(DOTTED)
     Z X C V B N M O(UMLAUT) C(CEDILLA)
   - Uygulamadaki gercek karakterler Turkce: Ğ Ü Ş İ Ö Ç ve dotless ı.
   - Dogru harf yesil, kelimede olan harf sari, olmayan harf koyu renktir.
   - Kelimede olmadigi kesinlesen tus tekrar basilamaz.

3) Kapatilabilir banner reklam:
   - Sonsuz Fetih ve Gunun Kelimesi ekranlarinin altinda gosterilir.
   - X ile kapatilinca o uygulama oturumu boyunca tekrar cikmaz.
   - Reklamsiz satin alim aktifse hic gosterilmez.
   - Internet/consent/ad-unit yoksa oyun bloke olmaz, banner gorunmez.
   - Mevcut interstitial ve rewarded video akislari aynen korunur.

4) 0 can bug fix:
   - 0 can ile dogru/bonus kelime artik kabul edilmez.
   - Son can yanlis kelimede bittigi anda can kazanma ekrani acilir.

AdMob banner ayari
------------------
Debug build Google test banner ID'lerini otomatik kullanir.
Release build icin AdMob'da BANNER ad unit olustur ve Codemagic build'e ekle:

  --dart-define=ADMOB_IOS_BANNER=ca-app-pub-.../...
  --dart-define=ADMOB_ANDROID_BANNER=ca-app-pub-.../...

Sadece iOS yayinliyorsan ADMOB_IOS_BANNER yeterlidir.
Bu deger AdMob App ID veya Publisher ID DEGIL, Banner Ad Unit ID olmalidir.
Deger verilmezse release build bozulmaz; sadece banner gosterilmez.

Uygulama
--------
Proje kokunde:
  git apply --check kelime_fatihi_gameplay_improvements.patch
  git apply kelime_fatihi_gameplay_improvements.patch
  flutter analyze
  flutter test
  flutter run

Not: Projedeki bazi mevcut Dart dosyalari CRLF satir sonu kullandigi icin
`git apply --check` sadece whitespace uyarisi yazabilir. Patch temiz kopyada
uygulanarak kontrol edilmelidir.

CANLI IOS BANNER AYARI
----------------------
AdMob iOS App ID: ca-app-pub-7947363274814419~9478418238
Banner Ad Unit ID: ca-app-pub-7947363274814419/3373485363
Banner unit ID, ad_service.dart içinde release defaultValue olarak eklenmiştir.
