import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../core/game_theme.dart';
import '../core/turkish_text.dart';
import '../models/chest_reward.dart';
import '../models/conquest_region.dart';
import '../services/audio_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/dismissible_banner_ad.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/stat_chips.dart';
import '../widgets/word_success_overlay.dart';
import 'conquest_map_screen.dart';
import 'store_screen.dart';

class ConquestScreen extends StatefulWidget {
  const ConquestScreen({super.key});

  @override
  State<ConquestScreen> createState() => _ConquestScreenState();
}

class _ConquestScreenState extends State<ConquestScreen>
    with SingleTickerProviderStateMixin {
  bool celebrate = false;
  CelebrationIntensity _celebrationIntensity = CelebrationIntensity.normal;
  String flash = '';
  String comboFlash = '';
  String _flyingWord = '';
  bool _flyingWordIsBonus = false;
  int _wordFlightTrigger = 0;
  bool _showSmartHint = false;
  AudioService? _audio;
  int? _musicRegion;
  bool _adsPrepared = false;
  Timer? _celebrationTimer;
  Timer? _smartHintTimer;
  late final AnimationController _attentionController;

  @override
  void initState() {
    super.initState();
    _attentionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = GameScope.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _attentionController.stop();
      _attentionController.value = 0;
    } else if (!_attentionController.isAnimating) {
      _attentionController.repeat(reverse: true);
    }
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
    if (_smartHintTimer == null) _scheduleSmartHint();
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _smartHintTimer?.cancel();
    _attentionController.dispose();
    _audio?.stopRegionTheme();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final level = game.currentLevel;
    final region = game.currentRegion;
    final chestIn = 5 - (game.levelsCompleted % 5);
    final remaining = game.remainingTargetWords;

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
                        '8.000 BÖLÜM FETHEDİLDİ',
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
      bottomNavigationBar: DismissibleBannerAd(
        ads: game.ads,
        isAdFree: game.isAdFree,
      ),
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
        intensity: _celebrationIntensity,
        child: WordSuccessOverlay(
          word: _flyingWord,
          trigger: _wordFlightTrigger,
          isBonus: _flyingWordIsBonus,
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
                              _AnimatedComboBadge(
                                count: game.comboCount,
                                accent: region.accent,
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
                            final isLastMissing = remaining == 1 && !found;
                            return _TargetWordChip(
                              text: game.hintDisplay(word),
                              found: found,
                              attention: isLastMissing,
                              accent: region.accent,
                              pulse: _attentionController,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                        child: remaining == 1
                            ? _LastWordBanner(
                                key: const ValueKey('last_word'),
                                pulse: _attentionController,
                                accent: region.accent,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('no_last_word'),
                              ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                        child: game.comboCount >= 2 && comboFlash.isNotEmpty
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
                      AnimatedSwitcher(
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                        child: game.lastRejectedWord.isEmpty
                            ? const SizedBox(height: 2)
                            : Container(
                                key: ValueKey(game.lastRejectedWord),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: GameTheme.danger.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: GameTheme.danger.withValues(
                                      alpha: .28,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: GameTheme.danger,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Son reddedilen: ${TurkishText.upper(game.lastRejectedWord)}',
                                      style: const TextStyle(
                                        color: GameTheme.danger,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      Center(
                        child: LetterWheel(
                          letters: level.letters,
                          onLetterSelected: game.audio.select,
                          hapticsEnabled: game.hapticsEnabled,
                          onSubmitted: (word) => _submit(game, word),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Harfleri karıştır',
                            onPressed: () async {
                              await game.shuffleLetters();
                              _resetSmartHintTimer();
                            },
                            icon: const Icon(Icons.shuffle_rounded),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: () => _showHintSheet(game),
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
                      AnimatedSwitcher(
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
                        child: _showSmartHint
                            ? Padding(
                                key: const ValueKey('smart_hint'),
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () => _showHintSheet(game),
                                    icon: const Icon(Icons.auto_awesome_rounded),
                                    label: const Text('Takıldın mı? Akıllı ipucu'),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('smart_hint_hidden'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _submit(GameController game, String word) async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final completedLevelNumber = game.currentLevel.number;
    final completedRegion = ConquestRegion.forLevel(completedLevelNumber);
    final result = await game.submitConquestWord(word);
    if (!mounted) return;

    if (result.isTarget) {
      game.audio.target();
      unawaited(game.hapticMedium());
      _triggerWordFlight(result.word, isBonus: false);
      _resetSmartHintTimer();
    } else if (result.isBonus) {
      game.audio.bonus();
      unawaited(game.hapticLight());
      _triggerWordFlight(result.word, isBonus: true);
      _resetSmartHintTimer();
      if (result.bonusTreasureOpened) {
        game.audio.chest();
        unawaited(game.hapticMedium());
      }
    } else if (!result.isDuplicate) {
      game.audio.invalid();
      unawaited(game.hapticHeavy());
    } else {
      unawaited(game.hapticSelection());
    }
    if (result.comboMessage.isNotEmpty) game.audio.combo();

    final milestone = result.completed &&
        game.isMilestoneLevel(completedLevelNumber);
    final regionCompleted = result.completed &&
        completedLevelNumber % ConquestRegion.regionSize == 0;

    setState(() {
      flash = result.message;
      comboFlash = result.comboMessage;
    });

    if (result.completed) {
      _startCelebration(
        regionCompleted
            ? CelebrationIntensity.region
            : milestone
            ? CelebrationIntensity.milestone
            : CelebrationIntensity.normal,
      );
    }

    if (result.noHearts || (result.lostHeart && game.hearts <= 0)) {
      await _showNoHeartDialog(game);
      return;
    }
    if (!result.completed) return;

    game.audio.victory();
    await Future<void>.delayed(
      reduceMotion
          ? const Duration(milliseconds: 80)
          : Duration(
              milliseconds: regionCompleted
                  ? 900
                  : milestone
                  ? 700
                  : 380,
            ),
    );
    if (!mounted) return;

    // Kritik sıra: ilerleme ve ödüller reklam açılmadan önce kalıcı olarak
    // commit edilir. Kullanıcı reklam sırasında uygulamayı kapatsa bile bir
    // sonraki açılışta sonraki seviyeden devam eder.
    final chest = await game.completeLevel();
    final milestoneReward = game.takePendingMilestoneReward();
    final perfectReward = game.takePendingPerfectReward();
    if (!mounted) return;

    await game.showLevelEndAdIfAvailable();
    if (!mounted) return;

    _musicRegion = game.currentRegion.index;
    game.audio.playRegionTheme(_musicRegion!);

    final perfectLine = perfectReward == null
        ? ''
        : '\n\n🏆 Kusursuz Fetih: ${perfectReward.message}';

    if (completedLevelNumber == ConquestRegion.maxLevel) {
      final milestoneMessage =
          milestoneReward?.message ?? '+50 altın ve +1 taç parçası';
      await _showCompletionDialog(
        title: '🏆 Büyük Sefer Tamamlandı!',
        message:
            '8.000. bölümü de tamamladın. Bölüm ödülü: +5 altın.\n\n'
            'Büyük sefer ödülü: $milestoneMessage$perfectLine',
      );
    } else if (regionCompleted) {
      await _showRegionConquest(
        region: completedRegion,
        rewardMessage: milestoneReward?.message,
        perfectMessage: perfectReward?.message,
      );
    } else {
      late final String dialogTitle;
      late final String dialogMessage;
      if (milestoneReward != null) {
        dialogTitle = '🎉 ${milestoneReward.title}';
        dialogMessage =
            'Bölüm ödülü: +5 altın.\n\n'
            'Kilometre taşı ödülü: ${milestoneReward.message}$perfectLine';
      } else if (perfectReward != null) {
        dialogTitle = '🏆 Kusursuz Fetih!';
        dialogMessage =
            'İpucu kullanmadan ve can kaybetmeden tamamladın.\n\n'
            'Bölüm ödülü: +5 altın\nKusursuz Fetih: ${perfectReward.message}';
      } else {
        dialogTitle = '👑 Bölüm Fethedildi!';
        dialogMessage =
            'Tüm hedef kelimeleri buldun. Bölüm ödülü: +5 altın.';
      }
      await _showCompletionDialog(title: dialogTitle, message: dialogMessage);
    }

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
      _resetSmartHintTimer();
    }
  }

  void _triggerWordFlight(String word, {required bool isBonus}) {
    if (word.isEmpty) return;
    setState(() {
      _flyingWord = word;
      _flyingWordIsBonus = isBonus;
      _wordFlightTrigger++;
    });
  }

  void _scheduleSmartHint() {
    _smartHintTimer?.cancel();
    _smartHintTimer = Timer(const Duration(seconds: 75), () {
      if (!mounted) return;
      final game = GameScope.of(context);
      if (game.campaignCompleted || game.remainingTargetWords == 0) return;
      setState(() => _showSmartHint = true);
    });
  }

  void _resetSmartHintTimer() {
    if (mounted && _showSmartHint) setState(() => _showSmartHint = false);
    _scheduleSmartHint();
  }

  void _startCelebration(CelebrationIntensity intensity) {
    _celebrationTimer?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (celebrate) setState(() => celebrate = false);
      return;
    }
    setState(() {
      _celebrationIntensity = intensity;
      celebrate = true;
    });
    final duration = switch (intensity) {
      CelebrationIntensity.normal => const Duration(milliseconds: 1050),
      CelebrationIntensity.milestone => const Duration(milliseconds: 1550),
      CelebrationIntensity.region => const Duration(milliseconds: 1950),
    };
    _celebrationTimer = Timer(duration, () {
      if (mounted) setState(() => celebrate = false);
    });
  }

  Future<void> _showCompletionDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('DEVAM'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRegionConquest({
    required ConquestRegion region,
    String? rewardMessage,
    String? perfectMessage,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('BÖLGE FETHEDİLDİ!'),
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: .72, end: 1),
          duration: MediaQuery.disableAnimationsOf(dialogContext)
              ? Duration.zero
              : const Duration(milliseconds: 650),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(region.emoji, style: const TextStyle(fontSize: 68)),
              const SizedBox(height: 8),
              Text(
                region.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: region.accent,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '100 bölümlük bölge tamamlandı. Haritada yeni fetih mührün açıldı.',
                textAlign: TextAlign.center,
              ),
              if (rewardMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Bölge ödülü: $rewardMessage',
                  style: const TextStyle(
                    color: GameTheme.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              if (perfectMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  '🏆 Kusursuz Fetih: $perfectMessage',
                  style: const TextStyle(
                    color: GameTheme.mint,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.flag_rounded),
            label: const Text('YENİ BÖLGEYE İLERLE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHintSheet(GameController game) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102238),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Akıllı İpucu',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 6),
              Text(
                'İpucu kullanmak Kusursuz Fetih hakkını kapatır.',
                style: TextStyle(color: Colors.white.withValues(alpha: .58)),
              ),
              const SizedBox(height: 10),
              _HintOption(
                icon: Icons.lightbulb_rounded,
                title: 'Bir harf aç',
                subtitle: game.freeHints > 0
                    ? '${game.freeHints} ücretsiz ipucun var'
                    : '25 altın',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _useHint(game, ConquestHintType.revealLetter);
                },
              ),
              _HintOption(
                icon: Icons.first_page_rounded,
                title: 'İlk harfi göster',
                subtitle: '20 altın',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _useHint(game, ConquestHintType.firstLetter);
                },
              ),
              _HintOption(
                icon: Icons.auto_awesome_rounded,
                title: 'İki harf aç',
                subtitle: '40 altın',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _useHint(game, ConquestHintType.revealTwoLetters);
                },
              ),
              _HintOption(
                icon: Icons.shuffle_rounded,
                title: 'Harfleri karıştır',
                subtitle: 'Ücretsiz · Kusursuz Fetih bozulmaz',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await game.shuffleLetters();
                  _resetSmartHintTimer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useHint(GameController game, ConquestHintType type) async {
    final result = await game.useHint(type);
    if (!mounted) return;
    _show(
      result.message.isNotEmpty
          ? result.message
          : 'Bu ipucu şu anda kullanılamıyor.',
    );
    if (result.used) _resetSmartHintTimer();
  }

  Future<void> _showChest(ChestReward reward) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('${reward.emoji} ${reward.title} Açıldı!'),
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: .72, end: 1),
          duration: MediaQuery.disableAnimationsOf(dialogContext)
              ? Duration.zero
              : const Duration(milliseconds: 520),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reward.emoji, style: const TextStyle(fontSize: 62)),
              const SizedBox(height: 8),
              Text(
                reward.label,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Her 5 bölümde sandık; 10, 50 ve 100. bölümlerde özel sandık görünümü kazanırsın.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GameTheme.gold.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: GameTheme.gold.withValues(alpha: .2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.redeem_rounded, color: GameTheme.gold),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Bonus Hazinesi',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            '${game.bonusTreasureProgress}/${GameController.bonusTreasureTarget}',
                            style: const TextStyle(
                              color: GameTheme.gold,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: game.bonusTreasureProgress /
                            GameController.bonusTreasureTarget,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '25 bonus kelimede +20 altın • Açılan hazine: ${game.bonusTreasuresOpened}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .58),
                          fontSize: 11,
                        ),
                      ),
                    ],
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


class _AnimatedComboBadge extends StatelessWidget {
  const _AnimatedComboBadge({required this.count, required this.accent});
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: .76, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: accent.withValues(alpha: .28)),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: .12), blurRadius: 14)],
        ),
        child: Text(
          '🔥 ×$count SERİ',
          style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
    );
  }
}

class _TargetWordChip extends StatelessWidget {
  const _TargetWordChip({
    required this.text,
    required this.found,
    required this.attention,
    required this.accent,
    required this.pulse,
  });
  final String text;
  final bool found;
  final bool attention;
  final Color accent;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    Widget chip(double value) => Transform.scale(
      scale: attention ? .985 + value * .03 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: found
              ? GameTheme.mint.withValues(alpha: .9)
              : attention
              ? accent.withValues(alpha: .11 + value * .07)
              : Colors.black.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: found
                ? GameTheme.mint
                : attention
                ? accent.withValues(alpha: .35 + value * .4)
                : Colors.white.withValues(alpha: .11),
            width: attention ? 1.5 : 1,
          ),
          boxShadow: attention
              ? [BoxShadow(color: accent.withValues(alpha: .08 + value * .14), blurRadius: 12 + value * 8)]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: found ? const Color(0xFF061A16) : Colors.white,
          ),
        ),
      ),
    );
    if (!attention || MediaQuery.disableAnimationsOf(context)) return chip(0);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => chip(pulse.value),
    );
  }
}

class _LastWordBanner extends StatelessWidget {
  const _LastWordBanner({super.key, required this.pulse, required this.accent});
  final Animation<double> pulse;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Center(
        child: Text(
          '✨ Son 1 kelime kaldı',
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => Center(
        child: Opacity(
          opacity: .72 + pulse.value * .28,
          child: Text(
            '✨ Son 1 kelime kaldı',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 12 + pulse.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _HintOption extends StatelessWidget {
  const _HintOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: GameTheme.cyan.withValues(alpha: .1),
        child: Icon(icon, color: GameTheme.cyan),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
