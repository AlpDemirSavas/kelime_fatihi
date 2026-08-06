import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../core/game_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_chips.dart';
import 'account_screen.dart';
import 'conquest_map_screen.dart';
import 'conquest_screen.dart';
import 'daily_screen.dart';
import 'missions_screen.dart';
import 'stats_screen.dart';
import 'store_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final region = game.currentRegion;
    final claimable = game.loading
        ? 0
        : game.dailyMissions.where((m) => m.completed && !m.claimed).length;

    return Scaffold(
      bottomNavigationBar: _HomeBottomBar(
        onMap: () => _open(context, const ConquestMapScreen()),
        onStore: () => _open(context, const StoreScreen()),
        onStats: () => _open(context, const StatsScreen()),
        onAccount: () => _open(context, const AccountScreen()),
      ),
      body: AnimatedBackground(
        accent: region.accent,
        child: SafeArea(
          child: game.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KELİME',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: GameTheme.cyan,
                                      letterSpacing: 6,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              Text(
                                'FATİHİ',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontSize: 42),
                              ),
                            ],
                          ),
                        ),
                        TopStats(
                          hearts: game.hearts,
                          coins: game.coins,
                          heartTimer:
                              game.hearts < GameController.maxNaturalHearts
                              ? game.nextHeartLabel
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Harfleri birleştir, dünyayı fethet, serini ve tacını büyüt.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ModeCard(
                      eyebrow: 'HER GÜN TEK MEYDAN OKUMA',
                      title: 'Günün Kelimesi',
                      subtitle: game.dailyFinished
                          ? (game.dailyWon
                                ? 'Bugünün tacı senin 👑'
                                : 'Yarın yeniden dene')
                          : '5 harf • 6 deneme • Herkese aynı kelime',
                      icon: Icons.calendar_month_rounded,
                      accent: GameTheme.mint,
                      badge: '🔥 ${game.dailyStreak} gün',
                      onTap: () => _open(context, const DailyScreen()),
                    ),
                    const SizedBox(height: 16),
                    _ModeCard(
                      eyebrow: '${region.emoji} ${region.name.toUpperCase()}',
                      title: 'Sonsuz Fetih',
                      subtitle: game.campaignCompleted
                          ? '8.000 bölümün tamamı fethedildi 👑'
                          : '8.000 benzersiz çember • Kusursuz Fetih • Bonus Hazinesi • Combo',
                      icon: Icons.auto_awesome_rounded,
                      accent: region.accent,
                      badge: game.campaignCompleted
                          ? '8.000/8.000'
                          : 'Bölüm ${game.levelNumber}',
                      onTap: () => _open(context, const ConquestScreen()),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${game.dailyStreak} günlük giriş serisi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  game.streakRewardMessage.isNotEmpty
                                      ? game.streakRewardMessage
                                      : '7 gün: +5 altın • 30 gün: +20 altın • Bir gün kaçırırsan seri sıfırlanır.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      onTap: () => _open(context, const MissionsScreen()),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: GameTheme.gold.withValues(alpha: .12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.task_alt_rounded,
                              color: GameTheme.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Günlük Görevler',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  claimable > 0
                                      ? '$claimable ödül seni bekliyor!'
                                      : 'Bugünün 3 görevini tamamla.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (claimable > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: GameTheme.gold,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$claimable',
                                style: const TextStyle(
                                  color: Color(0xFF2A2000),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    GlassCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.offline_bolt_rounded,
                            color: GameTheme.cyan,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Metro modu hazır: oyun, sözlük, bölümler, görevler ve kayıtlar internetsiz çalışır. Yalnızca reklam ve gerçek para mağazası internet ister.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .72),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (game.ads.privacyOptionsRequired) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: game.ads.showPrivacyOptions,
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: const Text('Reklam gizlilik seçenekleri'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: ScaleTransition(
            scale: Tween(begin: .975, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: page,
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.badge,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -20,
            child: Icon(icon, size: 125, color: accent.withValues(alpha: .08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      eyebrow,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Icon(icon, color: accent, size: 34),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: .68)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'OYNA',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: accent),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeBottomBar extends StatelessWidget {
  const _HomeBottomBar({
    required this.onMap,
    required this.onStore,
    required this.onStats,
    required this.onAccount,
  });

  final VoidCallback onMap;
  final VoidCallback onStore;
  final VoidCallback onStats;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF11172A).withValues(alpha: .96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomItem(
                icon: Icons.map_rounded,
                label: 'Harita',
                onTap: onMap,
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.storefront_rounded,
                label: 'Mağaza',
                onTap: onStore,
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.bar_chart_rounded,
                label: 'İstatistik',
                onTap: onStats,
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.account_circle_rounded,
                label: 'Hesap',
                onTap: onAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: GameTheme.cyan, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
