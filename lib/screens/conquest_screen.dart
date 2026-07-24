import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/game_controller.dart';
import '../core/game_theme.dart';
import '../core/turkish_text.dart';
import '../models/chest_reward.dart';
import '../models/conquest_region.dart';
import '../services/audio_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/stat_chips.dart';
import 'conquest_map_screen.dart';
import 'store_screen.dart';

class ConquestScreen extends StatefulWidget {
  const ConquestScreen({super.key});

  @override
  State<ConquestScreen> createState() => _ConquestScreenState();
}

class _ConquestScreenState extends State<ConquestScreen> {
  bool celebrate = false;
  String flash = '';
  String comboFlash = '';
  AudioService? _audio;
  int? _musicRegion;
  bool _adsPrepared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = GameScope.of(context);
    _audio = game.audio;
    final regionIndex = game.currentRegion.index;
    if (_musicRegion != regionIndex) {
      _musicRegion = regionIndex;
      game.audio.playRegionTheme(regionIndex);
    }
    if (!_adsPrepared) {
      _adsPrepared = true;
      unawaited(game.prepareGameplayAds());
    }
  }

  @override
  void dispose() {
    _audio?.stopRegionTheme();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final level = game.currentLevel;
    final region = game.currentRegion;
    final chestIn = 5 - (game.levelsCompleted % 5);

    if (game.campaignCompleted) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Kelime Fatihi'),
        ),
        extendBodyBehindAppBar: true,
        body: AnimatedBackground(
          accent: region.accent,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 72)),
                      const SizedBox(height: 14),
                      Text(
                        '10.000 BÖLÜM FETHEDİLDİ',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Kelime Fatihi seferinin tamamını bitirdin. Bu noktaya ulaşmak oyunun en büyük başarısıdır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .68),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConquestMapScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('FETİH HARİTASINI GÖR'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${region.emoji} Bölüm ${level.number}'),
        actions: [
          IconButton(
            tooltip: 'Fetih Haritası',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConquestMapScreen()),
            ),
            icon: const Icon(Icons.map_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: TopStats(
                hearts: game.hearts,
                coins: game.coins,
                heartTimer: game.hearts < GameController.maxNaturalHearts
                    ? game.nextHeartLabel
                    : null,
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bonus_words',
        onPressed: () => _showBonusWords(game),
        backgroundColor: const Color(0xFF173B60),
        foregroundColor: GameTheme.gold,
        icon: const Icon(Icons.stars_rounded),
        label: Text(
          'Bonus ${game.bonusWords.length}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: CelebrationOverlay(
        active: celebrate,
        child: AnimatedBackground(
          accent: region.accent,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 54),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 92),
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Text(
                              region.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    region.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Bölge ${region.progressFor(level.number)}/${ConquestRegion.regionSize} • Sandığa $chestIn bölüm',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: .55,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (game.comboCount >= 2)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: region.accent.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  '×${game.comboCount} COMBO',
                                  style: TextStyle(
                                    color: region.accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kelime Bölgesi',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          Text(
                            '${game.foundWords.length}/${level.words.length}',
                            style: TextStyle(
                              color: region.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: level.words.map((word) {
                            final found = game.foundWords.contains(word);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: found
                                    ? GameTheme.mint.withValues(alpha: .9)
                                    : Colors.black.withValues(alpha: .2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: found
                                      ? GameTheme.mint
                                      : Colors.white.withValues(alpha: .11),
                                ),
                              ),
                              child: Text(
                                game.hintDisplay(word),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                  color: found
                                      ? const Color(0xFF061A16)
                                      : Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: comboFlash.isNotEmpty
                            ? Center(
                                key: ValueKey(comboFlash),
                                child: Text(
                                  comboFlash,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: GameTheme.gold,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: .7,
                                  ),
                                ),
                              )
                            : flash.isEmpty
                            ? const SizedBox(height: 30)
                            : Center(
                                key: ValueKey(flash),
                                child: Text(
                                  flash,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: region.accent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                      ),
                      Center(
                        child: LetterWheel(
                          letters: level.letters,
                          onLetterSelected: game.audio.select,
                          onSubmitted: (word) => _submit(game, word),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Harfleri karıştır',
                            onPressed: game.shuffleLetters,
                            icon: const Icon(Icons.shuffle_rounded),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final result = await game.useHint();
                              if (!mounted) return;
                              _show(
                                result.used
                                    ? (result.usedFreeHint
                                          ? 'Ücretsiz ipucu kullanıldı!'
                                          : 'Bir harf açıldı! −25 altın')
                                    : 'İpucu için 25 altın gerekiyor.',
                              );
                            },
                            icon: const Icon(Icons.lightbulb_rounded),
                            label: Text(
                              game.freeHints > 0
                                  ? 'İpucu · Ücretsiz ${game.freeHints}'
                                  : 'İpucu · 25',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(GameController game, String word) async {
    final result = await game.submitConquestWord(word);
    if (!mounted) return;

    if (result.isTarget) {
      game.audio.target();
      HapticFeedback.mediumImpact();
    } else if (result.isBonus) {
      game.audio.bonus();
      HapticFeedback.lightImpact();
    } else if (!result.isDuplicate) {
      game.audio.invalid();
      HapticFeedback.heavyImpact();
    }
    if (result.comboMessage.isNotEmpty) game.audio.combo();

    setState(() {
      flash = result.message;
      comboFlash = result.comboMessage;
      celebrate = result.completed;
    });

    if (result.noHearts) {
      await _showNoHeartDialog(game);
      return;
    }

    if (result.completed) {
      game.audio.victory();
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;

      // Zorunlu reklam yalnızca önceden yüklenmişse gösterilir. İnternet yoksa
      // veya reklam hazır değilse oyun hiçbir bekleme olmadan devam eder.
      await game.showLevelEndAdIfAvailable();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            game.currentLevel.number == 10000
                ? '🏆 Büyük Sefer Tamamlandı!'
                : '👑 Bölüm Fethedildi!',
          ),
          content: Text(
            game.currentLevel.number == 10000
                ? '10.000. bölümü de tamamladın. Son bölüm ödülü: +5 altın.'
                : 'Tüm hedef kelimeleri buldun. Bölüm ödülü: +5 altın.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('DEVAM'),
            ),
          ],
        ),
      );

      final chest = await game.completeLevel();
      if (!mounted) return;
      _musicRegion = game.currentRegion.index;
      game.audio.playRegionTheme(_musicRegion!);
      if (chest != null) {
        game.audio.chest();
        await _showChest(chest);
      }
      if (mounted) {
        setState(() {
          celebrate = false;
          flash = '';
          comboFlash = '';
        });
      }
    }
  }

  Future<void> _showChest(ChestReward reward) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🎁 Fetih Sandığı Açıldı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 8),
            Text(
              reward.label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('Her 5 bölümde bir yeni sandık kazanırsın.'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('AL'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNoHeartDialog(GameController game) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102238),
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 52,
              color: GameTheme.danger,
            ),
            const SizedBox(height: 10),
            const Text(
              'Canın tükendi',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reklam izleyebilir, mağazada 50 altın karşılığında 1 can alabilir veya can paketi satın alabilirsin.',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                final earned = await game.watchAdForHeart();
                if (sheetContext.mounted && earned) Navigator.pop(sheetContext);
              },
              icon: const Icon(Icons.ondemand_video_rounded),
              label: const Text('REKLAM İZLE · +1 CAN'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoreScreen()),
                );
              },
              child: const Text('MAĞAZAYA GİT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBonusWords(GameController game) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A2138),
      showDragHandle: true,
      builder: (sheetContext) {
        final words = game.sortedBonusWords;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: GameTheme.gold),
                    const SizedBox(width: 8),
                    Text(
                      'Bonus Kelimeler (${words.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Bu bölümde ilk kez bulduğun her bonus kelime +1 altın kazandırır.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                if (words.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Henüz bonus kelime bulmadın.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .6),
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: words.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.white.withValues(alpha: .08)),
                      itemBuilder: (_, index) {
                        final word = words[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x2235D8FF),
                            child: Icon(
                              Icons.add_rounded,
                              color: GameTheme.gold,
                            ),
                          ),
                          title: Text(
                            TurkishText.upper(word),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          trailing: const Text(
                            '+1 altın',
                            style: TextStyle(
                              color: GameTheme.gold,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
