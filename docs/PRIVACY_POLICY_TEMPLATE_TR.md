# Kelime Fatihi — Gizlilik Politikası Taslağı

> **Yayın öncesi zorunlu:** `[GELİŞTİRİCİ/ŞİRKET ADI]`, `[DESTEK E-POSTASI]`, `[WEB SİTESİ]` ve tarihi gerçek bilgilerinizle değiştirin. Bu taslak hukuki danışmanlık değildir.

**Son güncelleme:** [TARİH]

Kelime Fatihi (“Uygulama”), **[GELİŞTİRİCİ/ŞİRKET ADI]** tarafından sunulur.

## 1. Hesap ve bulut yedeği
Google veya Apple ile giriş isteğe bağlıdır; uygulamanın temel işlevleri hesap olmadan kullanılabilir. Kullanıcı giriş yaptığında Firebase Authentication kullanıcı kimliği (UID), sağlayıcının paylaştığı ad/e-posta bilgileri ve Firebase Cloud Firestore üzerinde oyun ilerlemesi işlenebilir. Bulut yedeği; ulaşılan seviye, tamamlanan bölüm sayısı, rekorlar ve taç ilerlemesi gibi oyun verilerini kapsar.

Can, altın ve benzeri tüketilebilir cihaz ekonomisi varsayılan olarak bulut yedeğine kopyalanmaz.

## 2. Yerel oyun verileri
Bölüm durumu, bulunan kelimeler, can, altın, görevler, giriş serisi, ipuçları ve ayarlar cihaz üzerinde saklanabilir. Oyunun temel kelime modları ve sözlüğü çevrimdışı çalışır.

## 3. Reklamlar
Uygulamanın ücretsiz sürümü Google Mobile Ads/AdMob kullanır. Google ve reklam ortakları, reklam sunma, ölçüm, dolandırıcılık önleme ve izin verilen durumlarda kişiselleştirme amacıyla cihaz/reklam tanımlayıcıları, yaklaşık teknik bilgiler ve reklam etkileşimi gibi verileri işleyebilir. Gerekli bölgelerde Google User Messaging Platform (UMP) aracılığıyla gizlilik tercihleri sunulur.

Reklamsız sürümü satın alan kullanıcılara zorunlu bölüm sonu reklamları gösterilmez. Kullanıcı isterse ödüllü reklamı can kazanmak için gönüllü olarak izleyebilir.

## 4. Uygulama içi satın almalar
Can paketleri ve reklamsız sürüm Apple App Store veya Google Play ödeme altyapısı üzerinden satılır. Uygulama kredi kartı veya banka kartı bilgilerini doğrudan almaz. Mağaza işlem/ürün bilgileri satın almayı teslim etmek, geri yüklemek, dolandırıcılığı önlemek ve gerektiğinde işlemi doğrulamak için işlenebilir.

## 5. Hesap silme
Hesap ekranındaki **“Hesabı ve bulut yedeğini sil”** seçeneği kullanıcı hesabının ve geliştiricinin Firebase/Firestore üzerinde tuttuğu hesap bağlantılı oyun ilerlemesinin silinmesini başlatır. Apple ile giriş yapan kullanıcılarda gerekli yeniden kimlik doğrulama/token iptal akışı uygulanır. Yasal olarak saklanması gereken kayıtlar varsa yürürlükteki mevzuata uygun şekilde tutulabilir.

Cihazdaki hesapla ilişkilendirilmemiş yerel oyun kaydı, uygulama verileri silinene kadar cihazda kalabilir.

## 6. Veri saklama ve güvenlik
Bulut yedeği kullanıcı hesabı aktif olduğu sürece veya silme talebi alınana kadar tutulabilir. Firestore güvenlik kuralları oyuncunun yalnızca kendi `players/{uid}` belgesine erişmesine izin verecek şekilde yapılandırılmalıdır. İnternet aktarımında ilgili platformların TLS/HTTPS altyapıları kullanılır.

## 7. Çocuklar ve yaş derecelendirmesi
Uygulamanın hedef yaş kitlesi, reklam ayarları ve mağaza yaş derecelendirmesi gerçek dağıtım planına göre doldurulmalıdır. Çocuklara yönelik dağıtım seçilirse Apple, Google Play Families/COPPA ve ilgili yerel çocuk gizliliği kuralları ayrıca değerlendirilmelidir.

## 8. Üçüncü taraf hizmetleri
Uygulama aşağıdaki üçüncü taraf altyapıları kullanabilir:

- Firebase Authentication
- Firebase Cloud Firestore
- Google Mobile Ads / AdMob ve UMP
- Apple App Store / StoreKit
- Google Play Billing

Bu hizmetlerin kendi gizlilik politikaları ve şartları da geçerlidir.

## 9. İletişim
Gizlilik, hesap silme veya destek talepleri:

- E-posta: **[DESTEK E-POSTASI]**
- Web: **[WEB SİTESİ]**
