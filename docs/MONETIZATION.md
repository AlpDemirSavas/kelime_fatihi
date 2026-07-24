# Kelime Fatihi V7 — Monetization

## Reklam modeli

- Ücretsiz kullanıcı: her tamamlanan Sonsuz Fetih bölümünün doğal geçişinde **önceden yüklenmişse** interstitial gösterilir.
- Offline veya reklam yüklenememişse oyun reklam beklemez; doğrudan sonuç ekranına geçer.
- `kf_reklamsiz` non-consumable ürününü alan kullanıcıya zorunlu interstitial gösterilmez.
- Reklamsız kullanıcı isterse +1 can için ödüllü reklamı gönüllü olarak izleyebilir.
- Debug build Google'ın resmi test ad unit ID'lerini kullanır.
- Release build `--dart-define` ile canlı interstitial/rewarded ID bekler.

### Release unit ID'leri

```bash
--dart-define=ADMOB_ANDROID_INTERSTITIAL=...
--dart-define=ADMOB_ANDROID_REWARDED=...
--dart-define=ADMOB_IOS_INTERSTITIAL=...
--dart-define=ADMOB_IOS_REWARDED=...
```

AdMob **App ID** ise native AndroidManifest.xml / iOS Info.plist tarafında ayrıca tanımlanmalıdır.

## Oyun ekonomisi

- 50 altın = +1 can
- Yeni bonus kelime = +1 altın
- Aynı bonus kelime aynı bölümde tekrar = 0 altın, can kaybı yok
- Hedef kelime = 0 altın
- Bölüm tamamlama = +5 altın
- Günlük görev/sandık ödülleri küçük kalır

## IAP ürünleri

- `kf_can_5` — consumable
- `kf_can_20` — consumable
- `kf_can_50` — consumable
- `kf_reklamsiz` — non-consumable, hedef Türkiye fiyatı yaklaşık 150 TL

Satın almaları geri yükleme mağaza ekranındadır. Non-consumable reklamsız hak geri yüklenebilir; tüketilmiş can paketleri restore edilmez.

## Üretim güvenliği

Mevcut mobil istemci StoreKit/Google Play Billing satın alma akışını ve teslimini destekler. Gerçek para gelirinin kötüye kullanıma karşı korunması için canlı üretimde transaction/receipt doğrulamasını backend'e taşımak önerilir:

```text
App -> backend -> Apple App Store Server API / Google Play Developer API -> entitlement
```

## Ödeme

- App Store IAP geliri Apple'ın App Store Connect sözleşme/banka/vergi sistemi üzerinden ödenir.
- Google Play IAP geliri Google Play ödeme profili üzerinden ödenir.
- AdMob geliri bu ikisinden ayrıdır ve AdMob Payments hesabına birikir.
