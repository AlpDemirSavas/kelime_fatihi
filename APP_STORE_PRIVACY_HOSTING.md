# Kelime Fatihi — Privacy URL / Firebase Hosting / V17 Sosyal Ligler

Public privacy URL:

https://kelime-fatihi-cd8ca.web.app/privacy

V17 ile Fatihler Ligi, haftalık/sezon sıralaması, arkadaş kodu ve tek seferlik benzersiz “Fatih adı” özelliği eklendiği için gizlilik metni de güncellendi. Sosyal lige katılım isteğe bağlıdır; Google/Apple hesap adı ve e-posta leaderboard’da yayınlanmaz. Fatih adı hesap silinene kadar benzersiz olarak rezerve edilir.

## V17 release öncesi Firebase deploy

Proje kökünde:

```bash
npm install -g firebase-tools
firebase login
firebase use kelime-fatihi-cd8ca
firebase deploy --only firestore:rules,firestore:indexes,hosting
```

Alternatif olarak proje alias kullanmadan:

```bash
firebase deploy --only firestore:rules,firestore:indexes,hosting --project kelime-fatihi-cd8ca
```

Bu deploy şu V17 parçaları için gereklidir:

- `firestore.rules`: benzersiz Fatih adı rezervasyonu, sosyal profil, arkadaş kodu ve arkadaş listesi erişim kuralları
- `firestore.indexes.json`: haftalık ve sezon leaderboard sorgu indeksleri
- `usernames/{normalized}` + `username_owners/{uid}`: tek seferlik benzersiz Fatih adı rezervasyonu; e-posta içermez
- `hosting/privacy.html`: güncel gizlilik politikası

Deploy tamamlandıktan sonra gizlilik sayfasını tarayıcıda kontrol et:

https://kelime-fatihi-cd8ca.web.app/privacy

Bu adresi App Store Connect > App Privacy > Privacy Policy URL alanında kullan.

## Dosyalar

- `hosting/privacy.html`: yayınlanan gizlilik politikası
- `privacy.html`: aynı politikanın proje kökü kopyası
- `hosting/index.html`: Kelime Fatihi landing sayfası
- `firebase.json`: Hosting + Firestore deploy yapılandırması
- `firestore.rules`: Firestore güvenlik kuralları
- `firestore.indexes.json`: leaderboard indeksleri
- `.firebaserc`: varsayılan Firebase projesi

## Release notu

Firestore kuralları ve indeksleri deploy edilmeden uygulama build edilebilir ve offline oyun çalışır; ancak V17 sosyal lig özellikleri sunucuda yetki/index eksikliği nedeniyle boş veya senkron bekliyor görünebilir. Bu nedenle App Store build'i yayınlamadan önce Firebase deploy adımı tamamlanmalıdır.
