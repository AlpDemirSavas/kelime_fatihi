# Kelime Fatihi V7 — Yayın Adayı

- Google ve Apple hesabı ile opsiyonel giriş + Firebase bulut ilerleme yedeği.
- Hesap ekranında manuel yedekleme, çıkış ve App Store uyumlu hesap silme akışı.
- Bulut yalnızca ilerleme/istatistik verisini taşır; can/altın cihaz ekonomisini kopyalamaz.
- Sonsuz Fetih'te bu bölümde bulunan bonus kelimeler `KELİME +1` chip listesi olarak görünür.
- Bölüm sonlarında reklamsız kullanıcı değilse hazır interstitial gösterilir; reklam hazır değilse/offline ise oyun beklemeden devam eder.
- `kf_reklamsiz` adlı non-consumable ürün: yaklaşık 150 TL tek seferlik reklamsız sürüm.
- Satın almaları geri yükleme butonu eklendi.
- Debug build resmi Google test reklamlarını kullanır; release build canlı AdMob unit ID'lerini `--dart-define` ile bekler.
- Oyun çekirdeği tamamen offline kalır; Firebase/AdMob/IAP yalnızca ilgili özellik kullanılınca gerekir.
