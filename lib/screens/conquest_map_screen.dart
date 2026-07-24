import 'dart:math';

import 'package:flutter/material.dart';

import '../models/conquest_region.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';
import 'conquest_screen.dart';

class ConquestMapScreen extends StatelessWidget {
  const ConquestMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final current = game.currentRegion;
    final start = max(0, current.index - 2);
    final end = min(ConquestRegion.regionCount - 1, current.index + 5);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Fetih Haritası'),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        accent: current.accent,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 72, 18, 30),
            children: [
              Text(
                '10.000 bölümlük büyük sefer.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Her bölge 100 bölümden oluşur. İlk 10.000 bölümün harf çemberi imzası birbirinden farklıdır.',
                style: TextStyle(color: Colors.white.withValues(alpha: .62)),
              ),
              const SizedBox(height: 18),
              for (var index = start; index <= end; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RegionCard(
                    region: ConquestRegion.forLevel(index * ConquestRegion.regionSize + 1),
                    currentLevel: game.levelNumber,
                    onPlay: index == current.index && !game.campaignCompleted
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ConquestScreen()),
                            )
                        : null,
                  ),
                ),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        game.campaignCompleted
                            ? '10.000 bölümün tamamını fethettin. Bu gerçekten Kelime Fatihi seviyesi.'
                            : 'Nihai hedef: Bölüm 10.000 • Kalan ${10000 - game.levelNumber + 1} bölüm',
                        style: const TextStyle(fontWeight: FontWeight.w800),
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

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.region,
    required this.currentLevel,
    required this.onPlay,
  });

  final ConquestRegion region;
  final int currentLevel;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final completed = currentLevel > region.endLevel;
    final current = currentLevel >= region.startLevel && currentLevel <= region.endLevel;
    final locked = currentLevel < region.startLevel;
    final progress = completed ? ConquestRegion.regionSize : (current ? region.progressFor(currentLevel) - 1 : 0);

    return Opacity(
      opacity: locked ? .48 : 1,
      child: GlassCard(
        onTap: onPlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(region.emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                      Text(
                        region.subtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  completed
                      ? Icons.workspace_premium_rounded
                      : locked
                          ? Icons.lock_rounded
                          : Icons.play_arrow_rounded,
                  color: region.accent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress / ConquestRegion.regionSize,
                color: region.accent,
                backgroundColor: Colors.white.withValues(alpha: .08),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Bölüm ${region.startLevel}-${region.endLevel}',
                  style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12),
                ),
                const Spacer(),
                Text(
                  completed ? 'TAMAMLANDI' : current ? '$progress/${ConquestRegion.regionSize}' : 'KİLİTLİ',
                  style: TextStyle(
                    color: region.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
