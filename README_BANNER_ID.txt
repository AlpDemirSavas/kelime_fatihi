KELIME FATİHİ - CANLI IOS BANNER ID
===================================

AdMob iOS App ID:
ca-app-pub-7947363274814419~9478418238

Bu değer ios/Runner/Info.plist içinde GADApplicationIdentifier olarak bulunmalıdır.

AdMob iOS Banner Ad Unit ID:
ca-app-pub-7947363274814419/3373485363

Bu paket lib/services/ad_service.dart içinde bu banner ID'yi release varsayılanı
olarak ekler. CodeMagic tarafında ADMOB_IOS_BANNER verilmezse bile bu ID kullanılır.
İstenirse --dart-define=ADMOB_IOS_BANNER=... ile override edilebilir.

Debug/Profile buildlerde Google test reklam ID'leri kullanılmaya devam eder.
Reklamsız satın alma, consent, ATT, interstitial ve rewarded akışları değiştirilmemiştir.
