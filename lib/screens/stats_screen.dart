import 'package:flutter/material.dart';

import '../core/game_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final stats = [
      (
        'Fethedilen bölüm',
        '${game.levelsCompleted}',
        Icons.flag_rounded,
        GameTheme.gold,
      ),
      (
        'Bulunan hedef kelime',
        '${game.totalWordsFound}',
        Icons.spellcheck_rounded,
        GameTheme.cyan,
      ),
      (
        'En iyi combo',
        '×${game.bestCombo}',
        Icons.bolt_rounded,
        GameTheme.violet,
      ),
      (
        'Günlük galibiyet',
        '${game.dailyWins}',
        Icons.calendar_month_rounded,
        GameTheme.mint,
      ),
      (
        'En iyi giriş serisi',
        '${game.bestDailyStreak}',
        Icons.local_fire_department_rounded,
        GameTheme.danger,
      ),
      (
        'Açılan taç',
        '${game.crownsUnlocked}',
        Icons.workspace_premium_rounded,
        GameTheme.gold,
      ),
      (
        'Taç parçası',
        '${game.crownFragments % 5}/5',
        Icons.diamond_rounded,
        GameTheme.cyan,
      ),
      (
        'Ücretsiz ipucu',
        '${game.freeHints}',
        Icons.lightbulb_rounded,
        GameTheme.gold,
      ),
      (
        'Mevcut altın',
        '${game.coins}',
        Icons.monetization_on_rounded,
        GameTheme.gold,
      ),
      (
        'Mevcut can',
        '${game.hearts}',
        Icons.favorite_rounded,
        GameTheme.danger,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('İstatistikler'),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        accent: game.currentRegion.accent,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 28),
            children: [
              Text(
                'Fetih Günlüğün',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Her kelime, imparatorluğuna yeni bir taş ekler.',
                style: TextStyle(color: Colors.white.withValues(alpha: .58)),
              ),
              const SizedBox(height: 18),
              ...stats.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Icon(s.$3, color: s.$4),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.$1)),
                        Text(
                          s.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: GameTheme.cyan,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${game.dictionary.wordCount} kelimelik doğrulama sözlüğü',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${game.dictionary.levelWordCount} temiz bölüm kelimesi • ${game.dictionary.seedCount} benzersiz seviye tohumu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .58),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: game.soundEnabled,
                  onChanged: game.setSoundEnabled,
                  secondary: const Icon(
                    Icons.volume_up_rounded,
                    color: GameTheme.mint,
                  ),
                  title: const Text(
                    'Ses efektleri',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Harf, combo, sandık ve fetih sesleri tamamen cihazdan çalınır.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
