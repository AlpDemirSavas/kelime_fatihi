import 'dart:math';

import 'package:flutter/material.dart';

import '../core/game_theme.dart';
import '../core/turkish_text.dart';

class WordSuccessOverlay extends StatefulWidget {
  const WordSuccessOverlay({
    super.key,
    required this.child,
    required this.word,
    required this.trigger,
    required this.isBonus,
  });

  final Widget child;
  final String word;
  final int trigger;
  final bool isBonus;

  @override
  State<WordSuccessOverlay> createState() => _WordSuccessOverlayState();
}

class _WordSuccessOverlayState extends State<WordSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant WordSuccessOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reduceMotion &&
        widget.trigger != oldWidget.trigger &&
        widget.word.isNotEmpty) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (!_controller.isAnimating && _controller.value == 0) {
                  return const SizedBox.shrink();
                }
                return _WordFlight(
                  word: widget.word,
                  progress: _controller.value,
                  isBonus: widget.isBonus,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _WordFlight extends StatelessWidget {
  const _WordFlight({
    required this.word,
    required this.progress,
    required this.isBonus,
  });

  final String word;
  final double progress;
  final bool isBonus;

  @override
  Widget build(BuildContext context) {
    final letters = TurkishText.upper(word).split('');
    final color = isBonus ? GameTheme.gold : GameTheme.mint;
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final startY = constraints.maxHeight * .66;
        final endY = constraints.maxHeight * .29;
        return Stack(
          children: [
            for (var i = 0; i < letters.length; i++)
              _flyingLetter(
                letter: letters[i],
                index: i,
                count: letters.length,
                centerX: centerX,
                startY: startY,
                endY: endY,
                color: color,
              ),
          ],
        );
      },
    );
  }

  Widget _flyingLetter({
    required String letter,
    required int index,
    required int count,
    required double centerX,
    required double startY,
    required double endY,
    required Color color,
  }) {
    final delay = min(.28, index * .035);
    final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
    final curved = Curves.easeOutCubic.transform(local);
    final spread = (index - (count - 1) / 2) * 23.0;
    final x = centerX + spread * (1 - curved);
    final y = startY + (endY - startY) * curved - sin(curved * pi) * 36;
    final opacity = local < .72
        ? 1.0
        : ((1 - local) / .28).clamp(0.0, 1.0).toDouble();
    final scale = .86 + .34 * sin(local * pi);

    return Positioned(
      left: x - 18,
      top: y - 18,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .94),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              letter,
              style: const TextStyle(
                color: Color(0xFF07111F),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
