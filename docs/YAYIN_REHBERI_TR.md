# Kelime Fatihi V7 — Sıfırdan Yayına Alma Rehberi

Bu rehber **23 Temmuz 2026** itibarıyla Kelime Fatihi'nin Android ve iOS mağaza yayını için hazırlanmıştır.

> Bu proje kod tarafında bir **release candidate**'dır. Firebase, Apple Developer, App Store Connect, Google Play Console, AdMob, banka/vergi hesapları ve gerçek mağaza ürünleri sizin hesaplarınıza bağlı olduğundan bunlar otomatik olarak proje içine konamaz. Aşağıdaki adımlar tamamlanmadan canlı mağazaya göndermeyin.

---

## 0. Önce neyin hazır olduğunu bil

V7 kodunda hazır olanlar:

- Google hesabıyla opsiyonel giriş.
- iOS'ta Apple hesabıyla opsiyonel giriş.
- Firebase/Firestore ile seviye ve ilerleme yedeği.
- Misafir/offline oyun; giriş zorunlu değil.
- Hesap ekranından çıkış, manuel bulut senkronu ve hesap silme.
- Bölüm içinde daha önce bulunan bonus kelimelerin `KELİME +1` listesi.
- Her bölüm sonundaki doğal geçişte, reklam önceden yüklüyse interstitial reklam.
- İnternet/reklam hazır değilse hiçbir bekleme olmadan sonraki bölüme geçiş.
- `kf_reklamsiz` adlı tek seferlik reklamsız ürün.
- Satın almaları geri yükleme.
- 50 altın -> +1 can.
- Ödüllü reklam -> +1 can.
- 10.000 bölüm ve sözlük tamamen cihazda; metroda internet olmadan oynanabilir.

Bulut yedeğine **can ve altın gönderilmez**. Bunun nedeni iki cihaz arasında ekonomi çoğaltma açığını önlemektir. Buluta seviye/istatistik/taç ilerlemesi gider. Reklamsız hak mağaza satın almasını geri yükleyerek geri gelir.

---

# BÖLÜM A — ÜRETİM KİMLİĞİNİ BELİRLE

## 1. Kalıcı paket/bundle ID seç

Şu an geliştirme projenizde `com.example.kelime_fatihi` bulunabilir. Bunu mağazaya çıkmadan önce değiştirin.

Örnek format:

```text
com.sirketiniz.kelimefatihi
```

veya bireysel geliştiriciyseniz size ait bir ters-domain yapısı:

```text
com.markaniz.kelimefatihi
```

**Bir kere mağaza/Firebase/AdMob kayıtlarını bu ID ile oluşturduktan sonra değiştirmemek en doğrusudur.**

### Android
Modern Flutter projesinde genellikle:

```text
android/app/build.gradle.kts
```

İçindeki:

```kotlin
namespace = "com.example.kelime_fatihi"
applicationId = "com.example.kelime_fatihi"
```

satırlarını seçtiğiniz ID ile değiştirin.

`MainActivity.kt` içindeki `package ...` satırını da aynı pakete taşıyın/güncelleyin.

### iOS
Mac'te Xcode ile:

```text
ios/Runner.xcworkspace
```

açın.

Runner > TARGETS > Runner > Signing & Capabilities > **Bundle Identifier** alanını aynı kalıcı kimliğe ayarlayın.

---

# BÖLÜM B — FIREBASE: GOOGLE/APPLE GİRİŞİ + BULUT YEDEĞİ

## 2. Firebase projesi oluştur

1. https://console.firebase.google.com adresine girin.
2. **Create a project / Proje oluştur**.
3. Proje adı olarak örneğin `Kelime Fatihi` yazın.
4. Google Analytics zorunlu değil; isterseniz açabilirsiniz.
5. Projeyi oluşturun.

## 3. Firebase CLI ve FlutterFire CLI kur

Bilgisayarınızda Firebase CLI yoksa resmi Firebase CLI kurulumunu yapın. Node.js kullanıyorsanız tipik komut:

```powershell
npm install -g firebase-tools
```

Sonra:

```powershell
firebase login
```

FlutterFire CLI:

```powershell
dart pub global activate flutterfire_cli
```

Kontrol:

```powershell
firebase --version
flutterfire --version
```

## 4. Flutter projesini Firebase'e bağla

Proje köküne gelin:

```powershell
cd C:\Users\Monster\Downloads\Kelime_Fatihi_Flutter_Game\kelime_fatihi
flutter pub get
flutterfire configure
```

Sorulduğunda oluşturduğunuz Firebase projesini seçin.

**Şu an Windows'taki mevcut projenizde yalnızca `android/` klasörü varsa önce Android'i seçin.** iOS klasörünü Mac'te oluşturduktan ve gerçek Bundle ID'yi ayarladıktan sonra `flutterfire configure` komutunu yeniden çalıştırıp iOS'u da ekleyin.

Android + iOS klasörlerinin ikisi de mevcutsa platformları şöyle seçebilirsiniz:

```text
Android  [x]
iOS      [x]
```

`flutterfire configure` gerçek:

```text
lib/firebase_options.dart
```

dosyasını oluşturacaktır. Paketteki placeholder dosyanın yerine geçmesi beklenir.

## 5. Firebase Authentication aç

Firebase Console:

```text
Build / Security > Authentication > Sign-in method
```

### Google

1. Google provider'ı açın.
2. Support email seçin.
3. Save.

### Apple
Apple provider'ı da açacağız; önce Apple Developer tarafında Sign in with Apple kimliklerini hazırlamak gerekir. Bu adımlar aşağıdaki Apple bölümünde ayrıntılı.

## 6. Android Google girişinde SHA-1/SHA-256 ekle

Proje kökünden:

```powershell
cd android
.\gradlew signingReport
```

Çıktıda debug ve release için SHA-1/SHA-256 değerleri göreceksiniz.

Firebase Console:

```text
Project settings > Your apps > Android app > SHA certificate fingerprints
```

özellikle kullandığınız imzanın SHA-1 ve SHA-256 değerlerini ekleyin.

Ardından proje kökünde tekrar:

```powershell
flutterfire configure
```

çalıştırın.

## 7. Firestore veritabanını oluştur

Firebase Console:

```text
Build > Firestore Database > Create database
```

Üretim modunu seçebilirsiniz.

Projede `firestore.rules` hazırdır:

```text
firestore.rules
```

Mantık şudur: bir oyuncu yalnızca kendi `players/{uid}` belgesini okuyup yazabilir.

Firebase projesini CLI ile bağladıktan sonra rules deploy edebilirsiniz:

```powershell
firebase init firestore
```

Sorulduğunda mevcut `firestore.rules` dosyanızı kullanın.

Sonra:

```powershell
firebase deploy --only firestore:rules
```

## 8. Bulut yedeğini test et

1. Uygulamayı çalıştırın.
2. Ana ekrandan **Hesap**.
3. **Google ile giriş yap**.
4. Birkaç bölüm ilerleyin.
5. Hesap > **Şimdi Yedekle**.
6. Firebase Console > Firestore > `players` koleksiyonuna bakın.
7. Kullanıcının UID'si altında `levelNumber`, `levelsCompleted` vb. alanlar görünmelidir.

Test senaryosu:

- Cihaz A'da örneğin seviye 20'ye çıkın.
- Cihaz B'de aynı Google hesabıyla giriş yapın.
- Bulut senkronu tamamlandığında yüksek olan seviye korunmalıdır.

---

# BÖLÜM C — APPLE İLE GİRİŞ

## 9. Apple Developer hesabı aç

App Store'a uygulama yüklemek için Apple Developer Program gerekir. **23 Temmuz 2026 itibarıyla yıllık üyelik ücreti 99 USD'dir** (yerel para biriminde gösterilebilir).

https://developer.apple.com/programs/enroll/

Bireysel hesap açarsanız App Store'da seller/developer adı olarak kişisel yasal adınız görünebilir. Şirket/organizasyon hesabı için tüzel kişilik ve D-U-N-S doğrulaması gerekir.

## 10. Kalıcı Bundle ID oluştur

Apple Developer:

```text
Certificates, Identifiers & Profiles > Identifiers > + > App IDs > App
```

Bundle ID olarak 1. adımda seçtiğiniz değeri girin.

Örnek:

```text
com.markaniz.kelimefatihi
```

Capabilities altında **Sign in with Apple** özelliğini açın.

## 11. Xcode'da Sign in with Apple capability ekle

Mac'te:

```text
Runner > Signing & Capabilities > + Capability > Sign in with Apple
```

## 12. Apple Sign-In key oluştur

Apple Developer:

```text
Certificates, Identifiers & Profiles > Keys > +
```

- Bir key adı verin.
- **Sign in with Apple** seçin.
- App ID'nizi ilişkilendirin.
- Key'i oluşturun.
- `.p8` private key dosyasını güvenli yerde tutun; Apple bunu tekrar indirtmeyebilir.
- **Key ID**'yi kaydedin.
- Apple Developer üyelik ekranından **Team ID**'yi kaydedin.

Firebase Authentication > Apple provider ekranında Apple'ın istediği alanlara göre:

- Team ID
- Key ID
- Private key
- Service ID / OAuth code flow bilgileri

girin.

Token iptali/hesap silme için OAuth code flow yapılandırmasının eksiksiz olması önemlidir.

## 13. iOS'ta Google Sign-In URL Scheme ekle

Google ile giriş iPhone'da da kullanılacağı için Xcode'da Google URL scheme gerekir.

Firebase'den iOS uygulamanızın `GoogleService-Info.plist` bilgilerini alın. İçindeki:

```text
REVERSED_CLIENT_ID
```

değerini bulun.

Xcode:

```text
Runner > Info > URL Types > +
```

URL Schemes alanına bu `REVERSED_CLIENT_ID` değerini ekleyin.

Bu adım yapılmazsa iOS Google giriş callback'i uygulamaya dönemeyebilir.

## 14. Apple hesabıyla giriş ve hesap silmeyi gerçek iPhone'da test et

1. Fiziksel iPhone'da Apple hesabıyla giriş yapın.
2. Firebase Authentication > Users altında kullanıcı oluştuğunu doğrulayın.
3. Oyunda ilerleyin ve Firestore yedeğini doğrulayın.
4. Hesap ekranında **Hesabı ve bulut yedeğini sil** seçeneğini test edin.
5. Apple yeniden kimlik doğrulaması isterse tamamlayın.
6. Firebase Auth kullanıcı kaydı ve Firestore `players/{uid}` belgesi silinmelidir.

---

# BÖLÜM D — ADMOB VE REKLAM GELİRİ

## 15. AdMob hesabı oluştur

https://admob.google.com

Google hesabınızla kayıt olun. Ödeme profilini gerçek kişi/şirket bilgilerinize göre tamamlayın.

## 16. AdMob'da iki uygulama kaydı oluştur

Bir Android, bir iOS:

```text
Kelime Fatihi Android
Kelime Fatihi iOS
```

Henüz mağazada yayınlı değilse AdMob'da buna uygun seçeneği kullanabilirsiniz.

Her platform size ayrı bir **AdMob App ID** verecek.

Format:

```text
ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
```

## 17. Reklam birimleri oluştur

Her platform için en az:

1. **Interstitial** — bölüm sonu zorunlu reklam.
2. **Rewarded** — +1 can reklamı.

oluşturun.

Bunların ID formatı App ID'den farklıdır:

```text
ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
```

## 18. Android AdMob App ID

`android/app/src/main/AndroidManifest.xml` içinde `<application>` içine:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="SENIN_ANDROID_ADMOB_APP_ID" />
```

ekleyin.

Debug/test döneminde Google'ın test App ID'si kullanılabilir; canlı yayında kendi App ID'niz olmalıdır.

## 19. iOS AdMob App ID

`ios/Runner/Info.plist` içine Google Mobile Ads kılavuzundaki `GADApplicationIdentifier` alanını kendi iOS AdMob App ID'nizle ekleyin.

Aynı zamanda Google'ın yayın günündeki iOS kılavuzunda istediği güncel SKAdNetwork girdilerini kontrol edin.

## 20. UMP gizlilik mesajlarını ayarla

AdMob:

```text
Privacy & messaging
```

bölümünden uygulamalarınız için gerekli GDPR/EEA ve desteklenen diğer bölgesel mesajları yapılandırın.

Kod `canRequestAds()` izin vermeden reklam istemez ve gerekiyorsa gizlilik seçenekleri girişini gösterir.

## 21. Canlı reklam ID'leriyle release build al

Kod debug modunda otomatik olarak Google'ın test reklam unit ID'lerini kullanır.

**Release build** gerçek unit ID'leri `--dart-define` ile bekler.

Android örneği:

```powershell
flutter build appbundle --release `
  --dart-define=ADMOB_ANDROID_INTERSTITIAL=ca-app-pub-XXX/INTERSTITIAL `
  --dart-define=ADMOB_ANDROID_REWARDED=ca-app-pub-XXX/REWARDED `
  --dart-define=SUPPORT_EMAIL=destek@alanadiniz.com
```

Mac/iOS:

```bash
flutter build ipa --release \
  --dart-define=ADMOB_IOS_INTERSTITIAL=ca-app-pub-XXX/INTERSTITIAL \
  --dart-define=ADMOB_IOS_REWARDED=ca-app-pub-XXX/REWARDED \
  --dart-define=SUPPORT_EMAIL=destek@alanadiniz.com
```

**Canlı reklam ID'leriyle kendi reklamlarınıza tıklamayın.** Geliştirmede test reklamlarını kullanın.

## 22. Bölüm sonu reklam davranışı

V7 davranışı:

```text
Bölüm biter
  ↓
Reklamsız satın alma var mı?
  ├─ Evet -> reklam yok
  └─ Hayır
       ↓
Interstitial önceden yüklü mü?
       ├─ Evet -> reklam -> bölüm sonuç ekranı
       └─ Hayır/offline -> beklemeden bölüm sonuç ekranı
```

Bu tasarım metroda bağlantı olmadığı için oyuncuyu kilitlemez.

AdMob interstitial'ları seviyeler arasındaki doğal geçişlerde önerir; ancak reklamı aşırı sık göstermemek de önemlidir. Kelime Fatihi her tamamlanan seviyeyi doğal geçiş olarak kullanır. Gerçek kullanıcı verisinde bölümler çok kısa sürüyorsa daha seyrek frekans A/B testi düşünün.

---

# BÖLÜM E — UYGULAMA İÇİ SATIN ALMA

Kodda ürün kimlikleri:

```text
kf_can_5
kf_can_20
kf_can_50
kf_reklamsiz
```

Ürün ID'lerini mağazada **harf harfine aynı** oluşturun.

## 23. Apple App Store Connect ürünleri

App Store Connect:

```text
Apps > Kelime Fatihi > Monetization > In-App Purchases > +
```

### Can paketleri

```text
kf_can_5   -> Consumable
kf_can_20  -> Consumable
kf_can_50  -> Consumable
```

### Reklamsız

```text
kf_reklamsiz -> Non-Consumable
```

Non-consumable, bir kere satın alınıp süresiz kalan ürün tipidir. Bu yüzden reklamsız sürüm için doğru tür budur.

## 24. Reklamsız ürün fiyatı

Türkiye storefront için hedef fiyatı yaklaşık:

```text
149,99 TL / 150 TL
```

olarak seçin. App Store Connect size mevcut price point seçeneklerini gösterecektir. Oyunda gerçek cihazda mağazanın döndürdüğü lokal fiyat gösterilir; kod içindeki `₺149,99` yalnızca ürün metadata'sı henüz yüklenmediyse fallback'tir.

## 25. Apple IAP metadata

Her ürün için:

- Reference Name
- Product ID
- Display Name / Localization
- Description
- Price
- Availability
- Review screenshot (istenen alanda, mağaza ekranını gösteren bir görüntü)

girin.

İlk **consumable** ve ilk **non-consumable** ürün tipleri uygulama sürümüyle birlikte App Review'a gönderilmelidir.

## 26. Satın alma geri yükleme

Mağaza ekranında **SATIN ALMALARI GERİ YÜKLE** butonu hazırdır.

- `kf_reklamsiz` gibi non-consumable hak geri yüklenebilir.
- Consumable can paketleri normalde restore edilmez; tüketilmiş dijital ürünlerdir.

## 27. Google Play ürünleri

Play Console 2026 arayüzünde bunlar **One-time products** olarak yönetilir:

```text
Monetize with Play > Products > One-time products
```

Aynı ID'leri oluşturun.

Can paketleri tüketilebilir; reklamsız ürün tek seferlik kalıcı entitlement olarak tasarlanmalıdır.

## 28. Gerçek para için güvenlik notu — atlama

Mobil istemci içindeki satın alma callback'ine yüzde yüz güvenmek güvenli değildir. Modifiye edilmiş uygulama sahte teslim çağrısı yapabilir.

Yayından hemen önce önerilen üretim mimarisi:

```text
App
 ↓ satın alma transaction/token
Firebase Cloud Function / kendi backend'in
 ↓
Apple App Store Server API veya Google Play Developer API
 ↓ doğrulama
Backend entitlement kaydı
 ↓
Can teslimi / reklamsız hak
```

V7 istemci satın alma ve restore akışını hazırlar; büyük gelir beklenen canlı sürümde receipt/token doğrulamasını backend'e taşımak önemlidir.

---

# BÖLÜM F — APP STORE'DA PARA SANA NASIL GELİR?

## 29. Apple IAP para akışı

Oyuncu örneğin reklamsız sürümü satın alır:

```text
Oyuncu -> Apple ödeme sistemi -> App Store Connect finans raporu -> sizin banka hesabınız
```

Kart bilgisini siz almazsınız.

Apple'dan ödeme alabilmek için App Store Connect'te:

1. **Paid Apps Agreement** yürürlükte olmalı.
2. Vergi formları tamamlanmalı.
3. Banka hesabı eklenmeli.
4. İlgili ödeme eşiği ve fatura şartları sağlanmalı.

Apple, şartlar sağlandığında ödemeyi **işlemin ait olduğu mali ayın son gününden itibaren 45 gün içinde** dosyadaki ana banka hesabına gönderir.

Yeni/küçük geliştiriciler için **App Store Small Business Program** uygunluk koşulları sağlanırsa ücretli uygulama ve IAP komisyonu **%15**'e düşebilir; standart oran ve bölgesel özel koşullar sözleşmeye göre farklı olabilir. App Store Connect'teki yürürlükteki sözleşmenizi esas alın.

## 30. AdMob para akışı

```text
Reklamveren -> Google/AdMob -> AdMob gelir bakiyesi -> banka/ödeme yöntemi
```

Interstitial veya rewarded reklam için **reklam başına sabit para yoktur**.

Geliri etkileyenler:

- Kullanıcının ülkesi
- Reklamveren talebi
- Reklam formatı
- eCPM
- Fill rate
- Oyuncunun oturum süresi
- Geçerli/invalid trafik kalitesi

AdMob geliri aylık kesinleşir. Ödeme eşiği aşılmış ve payment hold yoksa normal döngüde ayın yaklaşık 21'i civarında ödeme çıkarılır.

## 31. Google Play IAP para akışı

Google Play satışları Play Console ödeme profilinde görünür. Google, Play geliştirici ödemelerini normalde **önceki ayın satışları için her ayın 15'inde başlatır**. İadeler/chargeback'ler ve geçerli ücretler düşülür. Google'ın hizmet ücreti tek sabit oran değildir; 2026'da bölge/program/yükleme tipine göre değişebilen yapı vardır. Kendi Play Console sözleşme ve fee ekranınızı esas alın.

## 32. Türkiye vergi konusu

Apple/Google'dan ödeme almak, Türkiye'deki vergi/muhasebe yükümlülüklerini ortadan kaldırmaz. Hesabı bireysel mi şirket üzerinden mi açacağınız, gelir vergisi/KDV/istisna uygulamaları gibi konular kişisel durumunuza bağlıdır. Canlı gelir başlamadan önce bir mali müşavirle kendi durumunuzu teyit edin.

---

# BÖLÜM G — APPLE APP STORE YAYINI

## 33. Mac zorunluluğu

Windows'ta Android build alabilirsiniz; fakat normal iOS archive/signing/App Store yükleme süreci için macOS + Xcode gerekir.

2026 App Store yüklemelerinde Apple'ın güncel SDK/Xcode minimumunu kullanın. Rehber tarihi itibarıyla Xcode 26+ ve iOS 26 SDK gereklidir.

## 34. Mac'te Flutter ortamı

Mac'te:

```bash
flutter doctor
```

Xcode lisansı/command line tools eksikse tamamlayın.

Projeyi Mac'e alın.

Eğer `ios/` klasörü henüz yoksa proje kökünde:

```bash
flutter create --platforms=ios .
```

Sonra:

```bash
flutter pub get
cd ios
pod install
cd ..
```

## 35. Xcode signing

```bash
open ios/Runner.xcworkspace
```

Xcode:

```text
Runner > TARGETS > Runner > Signing & Capabilities
```

- Team: Apple Developer hesabınızı seçin.
- Bundle Identifier: kalıcı ID'niz.
- Automatically manage signing: başlangıç için açabilirsiniz.
- Sign in with Apple capability: ekli olmalı.

## 36. iOS deployment target

Firebase'in güncel Flutter önkoşullarıyla uyumlu olacak şekilde iOS deployment target'ı en az desteklenen seviyeye ayarlayın. V7 Firebase kurulumu için yayın gününde FlutterFire dokümantasyonundaki minimumu kontrol edin.

## 37. App Store Connect'te app record oluştur

https://appstoreconnect.apple.com

Önce Agreements bölümünde Account Holder'ın güncel sözleşmeleri imzalamış olması gerekir.

Sonra:

```text
Apps > + > New App
```

- Platform: iOS
- Name: Kelime Fatihi
- Primary language: Turkish
- Bundle ID: oluşturduğunuz App ID
- SKU: örneğin `kelime-fatihi-ios-001`
- User Access: uygun seçeneğiniz

## 38. Paid Apps Agreement + banka + vergi

App Store Connect Business/Agreements bölümünde:

1. Paid Apps Agreement'i kabul edin.
2. Tax formlarını doldurun.
3. Banking bölümüne ödeme alacağınız banka hesabını ekleyin.

Bunu yapmadan IAP geliri size ödenmez.

## 39. Gizlilik politikasını internette yayınla

Projede:

```text
docs/PRIVACY_POLICY_TEMPLATE_TR.md
```

hazırdır.

Placeholder'ları gerçek bilgilerinizle değiştirin ve örneğin:

```text
https://siteniz.com/kelime-fatihi/gizlilik
```

gibi herkese açık HTTPS URL'de yayınlayın.

App Store Connect, iOS uygulamaları için Privacy Policy URL ister.

Kodun Hesap ekranında ayrıca uygulama içi gizlilik politikası görünümü vardır.

## 40. App Privacy formu

App Store Connect:

```text
App Privacy > Get Started
```

Gerçek veri akışınıza göre yanıtlayın.

V7 için en az değerlendireceğiniz veri sınıfları:

### Firebase Auth
- User ID
- Email address (sağlayıcı paylaşırsa)
- Name (sağlayıcı paylaşırsa)
- Amaç: App Functionality / authentication / cloud backup
- Kullanıcıya linked olabilir

### Firestore
- Game progress / app activity benzeri oyun ilerleme verileri
- Kullanıcı UID'sine bağlı
- Amaç: App Functionality

### AdMob
AdMob SDK'nin güncel data disclosure dokümantasyonuna göre device identifiers, advertising data, diagnostics, usage vb. kategorileri değerlendirin. Uygulamanızda gerçekten kullanılan izin/consent durumuyla aynı cevapları verin.

### IAP
Apple'ın StoreKit ödeme altyapısını kullanırsınız; kart verisini siz toplamıyorsunuz. Yine de kendi sunucunuza transaction ID/token gönderirseniz bunu privacy beyanınıza dahil edin.

## 41. ATT kararı

V7 varsayılan olarak AppTrackingTransparency izin penceresini zorlamaz.

IDFA ile cross-app tracking/personalisasyon kullanmaya karar verirseniz:

- ATT entegrasyonu,
- `NSUserTrackingUsageDescription`,
- AdMob privacy messaging,
- App Privacy “tracking” cevapları

birbiriyle uyumlu olmalıdır.

Sadece daha fazla reklam geliri için rastgele ATT eklemeyin; uygulamanın gerçek veri davranışına göre karar verin.

## 42. Mağaza metni

Taslak:

```text
docs/STORE_LISTING_TR.md
```

App Store Connect'te:

- Description
- Subtitle
- Keywords
- Support URL
- Marketing URL (opsiyonel)
- Copyright
- Category: Games / Word benzeri uygun kategori

doldurun.

## 43. Ekran görüntüleri

Gerçek iPhone/simulator'dan en az şu ekranları çekin:

1. Ana ekran
2. Günün Kelimesi
3. Sonsuz Fetih harf çemberi
4. Bonus kelime listesi + combo
5. Fetih Haritası
6. Günlük görevler
7. Mağaza / reklamsız sürüm
8. İstatistikler

App Store Connect'in o gün kabul ettiği cihaz boyutlarına uygun ekran görüntülerini yükleyin.

## 44. Yaş derecelendirmesi

App Store Connect > App Information altında güncel yaş derecelendirme sorularını tamamlayın. Reklam ve IAP içeren bir oyun olduğundan cevapları gerçek davranışa göre verin.

## 45. IAP'leri review'a hazırla

`kf_can_5`, `kf_can_20`, `kf_can_50`, `kf_reklamsiz` ürünlerinde eksik metadata kalmamalı ve durum **Ready to Submit** olmalıdır.

İlk consumable ve ilk non-consumable ürününüzü ilk app version submission ile birlikte ekleyin.

## 46. TestFlight öncesi release build

Mac'te önce:

```bash
flutter analyze
flutter test
```

Sonra release IPA:

```bash
flutter build ipa --release \
  --dart-define=ADMOB_IOS_INTERSTITIAL=CANLI_INTERSTITIAL_ID \
  --dart-define=ADMOB_IOS_REWARDED=CANLI_REWARDED_ID \
  --dart-define=SUPPORT_EMAIL=GERCEK_DESTEK_MAILINIZ
```

İsterseniz Xcode ile de:

```text
Product > Archive
```

yapabilirsiniz.

## 47. Xcode Organizer ile upload

Archive bittikten sonra Organizer:

```text
Distribute App > App Store Connect > Upload
```

Akışı tamamlayın.

Build App Store Connect'e yüklenir ve Apple tarafında “processing” sürecinden geçer.

## 48. TestFlight

App Store Connect > TestFlight:

1. Build'in processing bitmesini bekleyin.
2. Internal Testing grubuna kendinizi/test ekibinizi ekleyin.
3. Fiziksel iPhone'da TestFlight'tan kurun.
4. Özellikle şu testleri yapın:
   - Uçak modunda uygulama açılıyor mu?
   - Offline bölüm bitiyor mu?
   - Offline yeni bölüm açılıyor mu?
   - Google giriş online çalışıyor mu?
   - Apple giriş online çalışıyor mu?
   - İki cihaz arasında seviye geliyor mu?
   - Apple hesap silme çalışıyor mu?
   - Consumable can satın alma sandbox'ta çalışıyor mu?
   - Reklamsız ürün satın alınca interstitial kesiliyor mu?
   - Restore Purchases sonrası reklamsız hak geri geliyor mu?
   - Rewarded ad sonunda +1 can geliyor mu?
   - Interstitial bölüm ortasında değil, yalnızca doğal geçişte çıkıyor mu?

## 49. App Review notes

Review Notes alanına net bilgi yazın. Örnek:

```text
Kelime Fatihi hesap olmadan tamamen oynanabilir. Google/Apple girişleri yalnızca bulut seviye yedeği için opsiyoneldir.
Sonsuz Fetih bölümleri offline çalışır.
Can paketleri consumable IAP'dir.
Reklamsız Sürüm (kf_reklamsiz) non-consumable'dır ve yalnızca zorunlu interstitial reklamları kaldırır.
Ödüllü reklam kullanıcı isteğiyle +1 can verir.
Hesap silme: Ana ekran > Hesap > Hesabı ve bulut yedeğini sil.
Satın alma restore: Ana ekran > Mağaza > Satın Almaları Geri Yükle.
```

## 50. Build'i seç ve review'a gönder

App Store Connect:

```text
Apps > Kelime Fatihi > iOS version
```

- Build bölümünde yüklediğiniz build'i seçin.
- Gerekli IAP ürünlerini submission'a ekleyin.
- Tüm metadata/Privacy/Age Rating alanlarının tamamlandığını kontrol edin.
- **Add for Review**.
- Draft Submission'a gidin.
- **Submit for Review**.

Apple inceleme başladıktan sonra durum `In Review` olur.

Onaylanınca release biçiminize göre manuel veya otomatik yayınlayın.

---

# BÖLÜM H — GOOGLE PLAY YAYINI

## 51. Google Play geliştirici hesabı

Geniş dağıtım için Android Developer/Play Console hesabı oluşturun. **23 Temmuz 2026 itibarıyla full distribution için tek seferlik kayıt ücreti 25 USD'dir.**

Kişisel veya organizasyon hesabı seçimi legal kimliği etkiler.

## 52. Android 2026 target API

31 Ağustos 2026'dan itibaren yeni mobil uygulama ve güncellemeler için Android 16 / API 36 hedefi gereklidir. İlk yayına çok yakın olduğumuz için projeyi doğrudan API 36 hedefleyecek biçimde hazırlamak mantıklıdır.

## 53. Release keystore oluştur

Örnek:

```powershell
keytool -genkeypair -v -keystore kelime-fatihi-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kelime-fatihi
```

Şifreleri ve `.jks` dosyasını güvenli yedekleyin. GitHub/public ZIP'e koymayın.

Flutter/Android resmi signing yapılandırmasına göre `key.properties` ve Gradle release signing ayarını yapın.

## 54. Play Console app oluştur

Play Console > Create app:

- Kelime Fatihi
- Game
- Free
- Turkish
- Gerekli beyanları kabul edin.

## 55. One-time products oluştur

Aynı ürün ID'leri:

```text
kf_can_5
kf_can_20
kf_can_50
kf_reklamsiz
```

Play Console 2026 ürün arayüzünde her ürün için purchase option/price/availability yapılandırın.

## 56. Android AAB al

```powershell
flutter analyze
flutter test
flutter build appbundle --release `
  --dart-define=ADMOB_ANDROID_INTERSTITIAL=CANLI_INTERSTITIAL_ID `
  --dart-define=ADMOB_ANDROID_REWARDED=CANLI_REWARDED_ID `
  --dart-define=SUPPORT_EMAIL=GERCEK_DESTEK_MAILINIZ
```

AAB tipik olarak:

```text
build/app/outputs/bundle/release/app-release.aab
```

altında oluşur.

## 57. Play test kanalları

Önce Internal Testing yapın.

Yeni kişisel Play geliştirici hesapları için üretim erişimi öncesi kapalı test gereksinimi uygulanabilir. 13 Kasım 2023 sonrası oluşturulan kişisel hesaplarda resmi mevcut gereksinim en az 12 tester'ın 14 gün kesintisiz opt-in olduğu closed testtir.

## 58. Data Safety / Ads / Content rating

Play Console'da:

- Data safety
- Ads declaration
- Content rating
- Target audience
- App access
- Privacy policy URL
- Financial/IAP declarations

gibi tüm bölümleri gerçek davranışa göre doldurun.

Firebase + AdMob + IAP kullandığınızı unutmayın.

---

# BÖLÜM I — OFFLINE / METRO TESTİ

Bu testi release candidate üzerinde mutlaka yapın.

## 59. Android offline test

1. Uygulamayı online açın.
2. Sonsuz Fetih ekranına girin.
3. Telefon/emülatörde Airplane Mode açın.
4. Uygulamayı tamamen kapatın.
5. Yeniden açın.
6. Bölüm oynayın.
7. Bonus kelime bulun.
8. Bölümü tamamlayın.
9. Yeni bölüme geçin.
10. Uygulamayı kapatıp tekrar açın.

Beklenen:

```text
✅ Uygulama açılır
✅ Sözlük çalışır
✅ Bölüm üretimi çalışır
✅ Bonus +1 çalışır
✅ Can/altın çalışır
✅ Günlük görevler cihaz verisiyle çalışır
✅ Bölüm kaydı korunur
✅ Reklam beklenmez
✅ Firebase login/sync yapılamaz ama oyun kilitlenmez
✅ IAP kullanılamaz ama oyun kilitlenmez
```

## 60. iPhone offline test

Aynı senaryoyu TestFlight build'i fiziksel iPhone'da Airplane Mode ile tekrarlayın.

**Bu test geçmeden mağazaya göndermeyin.**

---

# BÖLÜM J — SON YAYIN CHECKLIST

## Kod

- [ ] `flutter analyze` hatasız.
- [ ] `flutter test` hatasız.
- [ ] Android release AAB gerçek cihazda test edildi.
- [ ] iOS TestFlight build fiziksel iPhone'da test edildi.
- [ ] `com.example...` paket kimliği kalmadı.

## Firebase

- [ ] `flutterfire configure` gerçek proje ile çalıştırıldı.
- [ ] Google Auth enabled.
- [ ] Apple Auth enabled.
- [ ] Android SHA-1/SHA-256 eklendi.
- [ ] iOS Google URL scheme eklendi.
- [ ] Sign in with Apple capability eklendi.
- [ ] Firestore rules deploy edildi.
- [ ] Hesap silme test edildi.

## AdMob

- [ ] Android App ID canlı.
- [ ] iOS App ID canlı.
- [ ] Android interstitial canlı ID.
- [ ] Android rewarded canlı ID.
- [ ] iOS interstitial canlı ID.
- [ ] iOS rewarded canlı ID.
- [ ] UMP mesajları yayınlandı.
- [ ] Debug'da test ads; release'de canlı ads doğrulandı.

## IAP

- [ ] `kf_can_5` consumable.
- [ ] `kf_can_20` consumable.
- [ ] `kf_can_50` consumable.
- [ ] `kf_reklamsiz` non-consumable.
- [ ] Reklamsız hedef Türkiye fiyatı ~150 TL.
- [ ] Restore Purchases test edildi.
- [ ] Apple sandbox IAP test edildi.
- [ ] Google Play test purchase test edildi.
- [ ] Üretim için transaction/receipt backend doğrulama planı tamamlandı.

## App Store

- [ ] Apple Developer membership aktif.
- [ ] Paid Apps Agreement aktif.
- [ ] Tax ve banking tamam.
- [ ] App record var.
- [ ] Privacy Policy HTTPS URL canlı.
- [ ] App Privacy cevapları doğru.
- [ ] Age Rating tamam.
- [ ] Screenshots tamam.
- [ ] Description/keywords/support URL tamam.
- [ ] Build seçildi.
- [ ] İlk consumable + non-consumable IAP submission'a eklendi.
- [ ] Review Notes yazıldı.
- [ ] Add for Review -> Submit for Review yapıldı.

## Google Play

- [ ] Full distribution developer account aktif.
- [ ] API 36 target hazır.
- [ ] Release signing güvenli.
- [ ] Data Safety/Ads/Content Rating tamam.
- [ ] Closed testing şartı gerekiyorsa 12 tester / 14 gün tamam.
- [ ] Production access alındı.

---

# En kritik üç hata

1. **Test AdMob ID'leriyle canlıya çıkmak** veya canlı reklamlarını kendiniz tıklamak.
2. **`com.example...` bundle ID ile Firebase/App Store kaydı açıp sonra değiştirmeye çalışmak.**
3. **Gerçek para IAP'yi yalnızca istemci callback'ine güvenerek büyük ölçekte çalıştırmak.**

Bu üçü yayın/gelir sürecinde en çok problem çıkarabilecek alanlardır.
