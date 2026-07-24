# Kelime Fatihi — V6

Türkçe, iki modlu Flutter mobil kelime oyunu. V6; Günün Kelimesi, **10.000 bölümlük Sonsuz Fetih**, 100 bölümlük fetih bölgeleri, combo, sandıklar, günlük görevler, günlük giriş serisi, çevrimdışı ses/müzik, reklam/IAP altyapısı ve morfoloji açısından sıkılaştırılmış Türkçe sözlük içerir.

## Günün Kelimesi
- Her gün deterministik 5 harfli kelime
- 6 deneme
- Wordle benzeri renkli geri bildirim
- Günlük galibiyet: +30 altın
- Uygulamaya ardışık günlerde girme serisi
- Her 7 günlük kesintisiz giriş serisi: +5 altın
- Her 30 günlük kesintisiz giriş serisi: +20 altın
- Bir gün uygulamaya girilmezse seri bir sonraki girişte 1'e döner
- Paylaşılabilir emoji sonucu

## Sonsuz Fetih
- 1–10.000 arasında ön-doğrulanmış bölüm
- İlk 10.000 bölümde birbirinden farklı harf çemberi imzası
- 23.376 temiz 3–7 harfli hedef kelime havuzu
- Her çemberde en az 8 üretilebilir hedef adayı
- Bölüm zorluğu: ilk 99 bölüm 5 hedef; 100–999 6; 1.000–4.999 7; 5.000–10.000 8 hedef
- 100 bölümlük 100 tematik fetih bölgesi
- Combo, haptic, ses ve konfeti
- İlk bonus kelime +1 altın; aynı bonus tekrar ödül vermez ve can götürmez
- Bölüm tamamlama +5 altın
- Her 5 bölümde Fetih Sandığı
- Her gün 3 görev

## Sözlük
- 26.453 çevrimdışı doğrulama kelimesi
- 23.309 Zemberek lexical headword tabanı
- 3.168 fiilin yalın emir/kök biçimi
- `atar` ve `tara` kullanıcı tarafından özellikle onaylanmış yüzey biçimleri olarak korunur
- `boşuyor`, `tarıyor`, `atıyor`, `atacak`, `taradı`, `anam`, `evim`, `kitabı`, `atarak`, `abrakadabralamak` kabul edilmez
- Otomatik şimdiki zaman/geçmiş/gelecek/iyelik/fiilimsi üretimi kapalıdır

Ayrıntı: `docs/DICTIONARY.md` ve `docs/LEXICON_RESEARCH.md`.

## Ekonomi ve monetizasyon
- 50 altın → +1 can
- Ödüllü reklam → +1 can
- Hedef kelimeler ekstra altın üretmez
- Yeni bonus kelime → +1 altın
- Bölüm bitişi → +5 altın
- Interstitial reklamlar doğal bölüm geçişlerinde; sandık anı reklamla bölünmez
- Google Play / App Store tüketilebilir can paketleri
- IAP yayınında sunucu tarafı receipt/token doğrulaması eklenmelidir

## Tam çevrimdışı çekirdek

İnternet olmadan çalışanlar:
- Günün Kelimesi
- 10.000 Sonsuz Fetih bölümü
- tüm sözlük doğrulamaları
- harita/bölgeler
- günlük giriş serisi
- günlük görevler
- sandıklar
- can/altın/ipuçları/taçlar
- ses efektleri ve bölge atmosfer müziği
- yerel kayıtlar

Yalnızca reklam ve gerçek para satın alma ağ ister.

## Kurulum

Mevcut çalışan Android projesine V6 patch ZIP içindeki `kelime_fatihi` klasörünün içeriğini proje kökünün üzerine kopyala:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

Sıfırdan kurulum:

```powershell
./bootstrap.ps1
flutter run
```

macOS/Linux:

```bash
./bootstrap.sh
flutter run
```

## Yayın öncesi

Bu üretim ortamında Flutter/Dart SDK bulunmadığı için APK/AAB/IPA gerçek derlemesi yapılamadı. Kendi makinen üzerinde `flutter analyze`, `flutter test`, gerçek cihazda `flutter run --profile` ve uçak modu testlerini çalıştır.

## V7 yayın adımları

Google/Apple giriş, Firebase bulut yedeği, reklamsız IAP ve gerçek AdMob kurulumunun sıfırdan anlatımı için:

`docs/YAYIN_REHBERI_TR.md`

V7 yeni özellik özeti: `UPDATE_V7.md`.
