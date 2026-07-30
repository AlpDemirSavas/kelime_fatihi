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

  // Standart Türkçe Q dizilimi. q/w/x günlük cevaplarda nadiren kullanılsa
  // bile klavye düzeni iOS Türkçe Q ile aynı yerde kalır.
  static const rows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'ı', 'o', 'p', 'ğ', 'ü'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ş', 'i'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', 'ö', 'ç'],
  ];

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
                const SizedBox(height: 58),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MiniStat(
                          label: 'Giriş serisi',
                          value: '🔥 ${game.dailyStreak}',
                        ),
                        _MiniStat(
                          label: 'Galibiyet',
                          value: '${game.dailyWins}',
                        ),
                        _MiniStat(label: 'Ödül', value: '+30 🪙'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              padding: const EdgeInsets.only(bottom: 7),
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
                            const SizedBox(height: 14),
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
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (!game.dailyFinished) _keyboard(game),
                const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          for (final row in rows)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((letter) {
                  final state = keyStates[letter];
                  final disabled = state == LetterState.absent;

                  return _Key(
                    label: TurkishText.upper(letter),
                    state: state,
                    enabled: !disabled,
                    onTap: () {
                      if (current.length >= 5) return;
                      setState(() => current += letter);
                      HapticFeedback.selectionClick();
                      game.audio.select();
                    },
                  );
                }).toList(),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionKey(
                icon: Icons.backspace_outlined,
                onTap: () {
                  if (current.isEmpty) return;
                  setState(
                    () => current = current.substring(0, current.length - 1),
                  );
                },
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: current.length == 5 ? () => _submit(game) : null,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text(
                  'FETHET',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(minimumSize: const Size(150, 48)),
              ),
            ],
          ),
        ],
      ),
    );
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
    final error = await game.submitDaily(current);
    if (!mounted) return;
    if (error != null) {
      _toast(error);
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      current = '';
      celebrate = game.dailyWon;
    });
    if (game.dailyWon) HapticFeedback.mediumImpact();
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
      width: 54,
      height: 54,
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
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: state == LetterState.present || state == LetterState.correct
              ? const Color(0xFF07111F)
              : Colors.white,
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.enabled,
    this.state,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final LetterState? state;

  @override
  Widget build(BuildContext context) {
    final background = switch (state) {
      LetterState.correct => GameTheme.mint,
      LetterState.present => GameTheme.gold,
      LetterState.absent => const Color(0xFF202A35),
      null => Colors.white.withValues(alpha: .1),
    };
    final foreground = switch (state) {
      LetterState.correct || LetterState.present => const Color(0xFF07111F),
      LetterState.absent => Colors.white.withValues(alpha: .28),
      null => Colors.white,
    };

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 30,
            height: 42,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(onPressed: onTap, icon: Icon(icon));
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
