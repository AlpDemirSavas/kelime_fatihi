import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/game_controller.dart';
import '../core/game_theme.dart';
import '../core/turkish_text.dart';
import '../models/word_feedback.dart';
import '../widgets/animated_background.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/dismissible_banner_ad.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  String current = '';
  bool celebrate = false;
  bool _adsPrepared = false;
  DateTime _now = DateTime.now();
  Timer? _countdownTimer;

  // iPhone Türkçe Q sıralaması. Tuşlar FittedBox ile küçültülmez; her satır
  // ekran genişliğini paylaşır ve görünen yüzeyin tamamı dokunma alanıdır.
  static const rows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'ı', 'o', 'p', 'ğ', 'ü'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ş', 'i'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', 'ö', 'ç'],
  ];

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Duration get _nextDailyIn {
    final tomorrow = DateTime(_now.year, _now.month, _now.day + 1);
    return tomorrow.difference(_now);
  }

  String get _nextDailyLabel {
    final seconds = _nextDailyIn.inSeconds.clamp(0, 24 * 60 * 60);
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_adsPrepared) return;
    _adsPrepared = true;
    unawaited(GameScope.of(context).prepareGameplayAds());
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final guesses = game.dailyGuesses;

    return Scaffold(
      bottomNavigationBar: DismissibleBannerAd(
        ads: game.ads,
        isAdFree: game.isAdFree,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Günün Kelimesi'),
        actions: [
          if (game.dailyFinished)
            IconButton(
              tooltip: 'Sonucu kopyala',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: game.dailyShareText()),
                );
                if (mounted) _toast('Sonuç panoya kopyalandı.');
              },
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: CelebrationOverlay(
        active: celebrate,
        child: AnimatedBackground(
          accent: GameTheme.mint,
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 46),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniStat(
                          label: 'Günlük seri',
                          value: '🔥 ${game.dailyPuzzleStreak}',
                        ),
                        _MiniStat(
                          label: 'Seri rekoru',
                          value: '🏆 ${game.bestDailyPuzzleStreak}',
                        ),
                        _MiniStat(
                          label: 'Galibiyet',
                          value: '${game.dailyWins}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: GameTheme.gold,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Yeni kelimeye $_nextDailyLabel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '•  Ödül +30 🪙',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .58),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Column(
                      children: [
                        ...List.generate(6, (row) {
                          final word = row < guesses.length
                              ? guesses[row]
                              : row == guesses.length && !game.dailyFinished
                              ? current
                              : '';
                          final feedback = row < guesses.length
                              ? game.evaluateDaily(guesses[row])
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (col) {
                                final letter = col < word.length
                                    ? word[col]
                                    : '';
                                final state = feedback == null
                                    ? null
                                    : feedback[col].state;
                                return _DailyTile(
                                  letter: letter,
                                  state: state,
                                );
                              }),
                            ),
                          );
                        }),
                        if (game.dailyFinished) ...[
                          const SizedBox(height: 12),
                          Text(
                            game.dailyWon
                                ? 'Muhteşem! Bugünün kelimesini fethettin. 👑'
                                : 'Bugünün kelimesi: ${TurkishText.upper(game.dailyWord)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _ResultBadge(
                                icon: '🔥',
                                label: 'Seri',
                                value: '${game.dailyPuzzleStreak}',
                              ),
                              _ResultBadge(
                                icon: '🏆',
                                label: 'Rekor',
                                value: '${game.bestDailyPuzzleStreak}',
                              ),
                              _ResultBadge(
                                icon: '⏳',
                                label: 'Yeni kelime',
                                value: _nextDailyLabel,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!game.dailyFinished) _keyboard(game),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyboard(GameController game) {
    final keyStates = _dailyKeyboardStates(game);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        children: [
          _KeyboardRow(
            letters: rows[0],
            states: keyStates,
            onLetter: (letter) => _appendLetter(game, letter),
          ),
          const SizedBox(height: 4),
          _KeyboardRow(
            letters: rows[1],
            states: keyStates,
            horizontalInset: 8,
            onLetter: (letter) => _appendLetter(game, letter),
          ),
          const SizedBox(height: 4),
          _KeyboardRow(
            letters: rows[2],
            states: keyStates,
            horizontalInset: 28,
            onLetter: (letter) => _appendLetter(game, letter),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionKey(
                icon: Icons.backspace_outlined,
                tooltip: 'Sil · uzun basınca tamamını temizle',
                onTap: () {
                  if (current.isEmpty) return;
                  setState(
                    () => current = current.substring(0, current.length - 1),
                  );
                  HapticFeedback.selectionClick();
                },
                onLongPress: () {
                  if (current.isEmpty) return;
                  setState(() => current = '');
                  HapticFeedback.mediumImpact();
                },
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: current.length == 5 ? () => _submit(game) : null,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text(
                  'FETHET',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(172, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _appendLetter(GameController game, String letter) {
    // Daha önce "yok" olarak işaretlenen harfler renkli kalır ama kullanıcı
    // yeni kelime fikirleri deneyebilmek için hepsine tekrar basabilir.
    if (current.length >= 5) return;
    setState(() => current += letter);
    HapticFeedback.selectionClick();
    game.audio.select();
  }

  Map<String, LetterState> _dailyKeyboardStates(GameController game) {
    final states = <String, LetterState>{};

    for (final guess in game.dailyGuesses) {
      for (final feedback in game.evaluateDaily(guess)) {
        final oldState = states[feedback.letter];
        if (oldState == null ||
            _keyboardStateRank(feedback.state) >
                _keyboardStateRank(oldState)) {
          states[feedback.letter] = feedback.state;
        }
      }
    }

    return states;
  }

  int _keyboardStateRank(LetterState state) => switch (state) {
    LetterState.absent => 0,
    LetterState.present => 1,
    LetterState.correct => 2,
  };

  Future<void> _submit(GameController game) async {
    final wasFinished = game.dailyFinished;
    final error = await game.submitDaily(current);
    if (!mounted) return;
    if (error != null) {
      _toast(error);
      HapticFeedback.heavyImpact();
      return;
    }

    final justFinished = !wasFinished && game.dailyFinished;
    setState(() {
      current = '';
      celebrate = game.dailyWon;
    });

    if (justFinished) {
      if (game.dailyWon) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } else {
      HapticFeedback.lightImpact();
    }

    // Günlük tur yalnızca tamamlandığı anda bir kez reklam dener. Reklam hazır
    // değilse sonuç ekranı bekletilmez; sonraki reklam arka planda hazırlanır.
    if (justFinished) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      await game.showDailyEndAdIfAvailable();
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({required this.letter, required this.state});
  final String letter;
  final LetterState? state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      LetterState.correct => GameTheme.mint,
      LetterState.present => GameTheme.gold,
      LetterState.absent => const Color(0xFF2A3A4D),
      null => Colors.white.withValues(alpha: .055),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
        boxShadow: state == LetterState.correct
            ? [
                BoxShadow(
                  color: GameTheme.mint.withValues(alpha: .28),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        TurkishText.upper(letter),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: state == LetterState.present || state == LetterState.correct
              ? const Color(0xFF07111F)
              : Colors.white,
        ),
      ),
    );
  }
}

class _KeyboardRow extends StatelessWidget {
  const _KeyboardRow({
    required this.letters,
    required this.states,
    required this.onLetter,
    this.horizontalInset = 0,
  });

  final List<String> letters;
  final Map<String, LetterState> states;
  final ValueChanged<String> onLetter;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            for (var index = 0; index < letters.length; index++) ...[
              if (index > 0) const SizedBox(width: 3),
              Expanded(
                child: _Key(
                  label: TurkishText.upper(letters[index]),
                  state: states[letters[index]],
                  onTap: () => onLetter(letters[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.state});

  final String label;
  final VoidCallback onTap;
  final LetterState? state;

  @override
  Widget build(BuildContext context) {
    final background = switch (state) {
      LetterState.correct => GameTheme.mint,
      LetterState.present => GameTheme.gold,
      LetterState.absent => const Color(0xFF263140),
      null => Colors.white.withValues(alpha: .11),
    };
    final foreground = switch (state) {
      LetterState.correct || LetterState.present => const Color(0xFF07111F),
      LetterState.absent => Colors.white.withValues(alpha: .68),
      null => Colors.white,
    };

    return Semantics(
      button: true,
      label: '$label harfi',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 58,
            height: 50,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Text(
        '$icon $label: $value',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: .58),
          ),
        ),
      ],
    );
  }
}
