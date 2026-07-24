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
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Gizlilik Politikası')),
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
                    'Hesap ekranındaki “Hesabı ve bulut yedeğini sil” seçeneği Firebase kullanıcı hesabını ve Firestore bulut ilerlemesini silmek için kullanılabilir. Cihazdaki bağımsız yerel oyun kaydı uygulama verileri silinene kadar cihazda kalabilir.',
              ),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('İletişim', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: GameTheme.cyan)),
                    const SizedBox(height: 7),
                    Text(
                      supportEmail.isEmpty
                          ? 'Yayın öncesi SUPPORT_EMAIL değeri eklenmelidir. Ayrıca App Store/Google Play ürün sayfasındaki destek bağlantısı kullanılabilir.'
                          : supportEmail,
                      style: TextStyle(color: Colors.white.withValues(alpha: .7)),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: GameTheme.cyan)),
            const SizedBox(height: 7),
            Text(body, style: TextStyle(color: Colors.white.withValues(alpha: .7), height: 1.45)),
          ],
        ),
      ),
    );
  }
}
