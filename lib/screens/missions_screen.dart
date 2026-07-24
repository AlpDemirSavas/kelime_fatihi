import 'package:flutter/material.dart';

import '../core/game_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Günlük Görevler')),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        accent: GameTheme.mint,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 72, 18, 30),
            children: [
              Text('Bugünün Emirleri', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Her gün 3 görev yenilenir. Ödüller küçük tutulur; asıl fetih ekonomisi bölüm ve bonus kelimelerden gelir.',
                style: TextStyle(color: Colors.white.withValues(alpha: .62)),
              ),
              const SizedBox(height: 18),
              for (final mission in game.dailyMissions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              mission.claimed
                                  ? Icons.check_circle_rounded
                                  : mission.completed
                                      ? Icons.redeem_rounded
                                      : Icons.flag_circle_rounded,
                              color: mission.completed ? GameTheme.gold : GameTheme.cyan,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                mission.title,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                            Text(
                              '+${mission.reward} 🪙',
                              style: const TextStyle(color: GameTheme.gold, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: mission.progress / mission.target,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${mission.progress}/${mission.target}'),
                            const Spacer(),
                            if (mission.completed && !mission.claimed)
                              FilledButton(
                                onPressed: () async {
                                  final claimed = await game.claimMission(mission.id);
                                  if (context.mounted && claimed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('+${mission.reward} altın alındı!')),
                                    );
                                  }
                                },
                                child: const Text('AL'),
                              )
                            else if (mission.claimed)
                              const Text('ALINDI', style: TextStyle(color: GameTheme.mint, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
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
