# Kelime Fatihi — Privacy URL / Firebase Hosting

Hazırlanan public privacy URL:

https://kelime-fatihi-cd8ca.web.app/privacy

Bu URL, Firebase Hosting deploy işleminden sonra aktif olur.

## İlk kurulum / deploy

Proje kökünde:

```bash
npm install -g firebase-tools
firebase login
firebase use kelime-fatihi-cd8ca
firebase deploy --only hosting
```

Alternatif olarak proje alias kullanmadan doğrudan:

```bash
firebase deploy --only hosting --project kelime-fatihi-cd8ca
```

Deploy tamamlandıktan sonra tarayıcıda kontrol et:

https://kelime-fatihi-cd8ca.web.app/privacy

Bu adresi App Store Connect > App Privacy > Privacy Policy URL alanına gir.

## Dosyalar

- `hosting/privacy.html`: yayınlanan gizlilik politikası
- `hosting/index.html`: basit Kelime Fatihi landing sayfası
- `firebase.json`: Hosting yapılandırması
- `.firebaserc`: varsayılan Firebase projesi

## Not

Gizlilik politikasının içeriği değiştiğinde hem uygulama içindeki açıklamalar hem de `hosting/privacy.html` birlikte gözden geçirilmelidir.
