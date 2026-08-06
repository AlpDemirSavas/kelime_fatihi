import 'package:flutter/material.dart';

import '../core/game_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Gizlilik Politikası'),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 28),
            children: [
              const _PolicySection(
                title: 'Hesap ve bulut yedeği',
                body:
                    'Google veya Apple ile giriş tamamen isteğe bağlıdır. Giriş yapıldığında Firebase Authentication kullanıcı kimliği, varsa ad/e-posta ve Firestore üzerinde oyun ilerlemesi işlenir. Can ve altın bulut hesabına kopyalanmaz.',
              ),
              const _PolicySection(
                title: 'Sosyal ligler ve arkadaşlar',
                body:
                    'Fatihler Ligi tamamen isteğe bağlıdır. İlk katılımda kullanıcı bir kez benzersiz Fatih adı seçer; liderlik tablosunda Google/Apple hesap adı veya e-posta yerine bu ad gösterilir. Arkadaş kodu, haftalık/sezon puanı, bölüm seviyesi ve Kusursuz Fetih sayısı diğer giriş yapmış oyunculara gösterilebilir. Ligden ayrılınca sosyal profil ve arkadaş listesi silinir; Fatih adı yeniden katılımda tekrar sorulmaması ve başkası tarafından alınmaması için hesap silinene kadar rezerve kalır.',
              ),
              const _PolicySection(
                title: 'Şikâyet ve engelleme',
                body:
                    'Liderlik tablosundaki public Fatih adları için Şikâyet Et ve Kullanıcıyı Engelle seçenekleri bulunur. Şikâyet kaydında şikâyet eden ve edilen hesap kimlikleri, görünen Fatih adı, seçilen sabit şikâyet nedeni ve zaman bilgisi Firestore üzerinde işlenebilir. Serbest metin mesajı alınmaz. Engellenen kullanıcılar kendi sıralama ve arkadaş görünümünden gizlenir; engel daha sonra kaldırılabilir. Şikâyet kayıtları güvenlik ve kötüye kullanım incelemesi amacıyla gerekli süre boyunca saklanabilir.',
              ),
              const _PolicySection(
                title: 'Yerel oyun verileri',
                body:
                    'Bölüm, can, altın, görevler, giriş serisi, bulunan kelimeler, ipuçları ve ayarlar cihaz üzerinde saklanır. Oyunun temel modları internet olmadan çalışır.',
              ),
              const _PolicySection(
                title: 'Reklamlar',
                body:
                    'Ücretsiz sürüm Google Mobile Ads/AdMob kullanabilir. Reklam gizlilik tercihleri gerekli bölgelerde Google UMP üzerinden alınır. Reklamsız sürümü satın alan kullanıcıya zorunlu bölüm sonu reklamı gösterilmez. Ödüllü reklam isteğe bağlı kalır.',
              ),
              const _PolicySection(
                title: 'Uygulama içi satın almalar',
                body:
                    'Can paketleri ve reklamsız sürüm Apple App Store veya Google Play ödeme altyapısıyla satılır. Kelime Fatihi kart/banka bilgilerini doğrudan almaz. Mağaza işlem bilgileri satın almayı teslim etmek ve geri yüklemek için işlenebilir.',
              ),
              const _PolicySection(
                title: 'Hesabı silme',
                body:
                    'Hesap ekranındaki “Hesabı ve bulut yedeğini sil” seçeneği Firebase kullanıcı hesabını, Firestore bulut ilerlemesini, varsa kendi sosyal lig profilini/arkadaş listesini, kendi engel listesini, kullanıcının gönderdiği şikâyet kayıtlarını ve Fatih adı rezervasyonunu silmek için kullanılabilir. Başka kullanıcıların güvenlik/moderasyon amacıyla oluşturduğu şikâyet kayıtları gerekli süre boyunca saklanabilir. Cihazdaki bağımsız yerel oyun kaydı uygulama verileri silinene kadar cihazda kalabilir.',
              ),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İletişim',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: GameTheme.cyan,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      supportEmail.isEmpty
                          ? 'Yayın öncesi SUPPORT_EMAIL değeri eklenmelidir. Ayrıca App Store/Google Play ürün sayfasındaki destek bağlantısı kullanılabilir.'
                          : supportEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: GameTheme.cyan,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .7),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
