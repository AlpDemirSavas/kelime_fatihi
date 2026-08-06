import 'package:flutter/material.dart';

import '../core/game_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final systemReduced = game.systemReduceMotion;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Oyun Ayarları'),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        accent: game.currentRegion.accent,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 28),
            children: [
              GlassCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile.adaptive(
                  value: game.hapticsEnabled,
                  onChanged: game.setHapticsEnabled,
                  secondary: const Icon(
                    Icons.vibration_rounded,
                    color: GameTheme.cyan,
                  ),
                  title: const Text(
                    'Titreşim',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    game.hapticsEnabled
                        ? 'Harf seçimi, doğru/yanlış cevap ve ödüllerde dokunsal geri bildirim açık.'
                        : 'Oyun içindeki tüm dokunsal geri bildirimler kapalı.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .58),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.motion_photos_off_rounded, color: GameTheme.mint),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Animasyonlar',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MotionOption(
                      title: 'Tam',
                      subtitle: 'Kelime uçuşu, konfeti, pulse ve geçiş efektlerinin tamamını kullanır.',
                      selected: !game.reduceMotionEnabled,
                      onTap: () => game.setReduceMotionEnabled(false),
                    ),
                    const SizedBox(height: 8),
                    _MotionOption(
                      title: 'Azaltılmış',
                      subtitle: 'Hareketli efektleri kapatır veya sadeleştirir; oyun akışı ve geri bildirimler korunur.',
                      selected: game.reduceMotionEnabled,
                      onTap: () => game.setReduceMotionEnabled(true),
                    ),
                  ],
                ),
              ),
              if (systemReduced) ...[
                const SizedBox(height: 14),
                GlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.accessibility_new_rounded,
                        color: GameTheme.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sistem hareket azaltma açık',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cihazındaki erişilebilirlik tercihi önceliklidir. Burada “Tam” seçili olsa bile Kelime Fatihi hareketli efektleri otomatik olarak azaltır.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .62),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Bu ayarlar yalnızca görsel/dokunsal geri bildirimi değiştirir; bölüm, kelime, ödül, can ve ilerleme verilerine dokunmaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .48),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotionOption extends StatelessWidget {
  const _MotionOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? GameTheme.mint.withValues(alpha: .11)
              : Colors.white.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? GameTheme.mint.withValues(alpha: .5)
                : Colors.white.withValues(alpha: .08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? GameTheme.mint
                  : Colors.white.withValues(alpha: .46),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .58),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
