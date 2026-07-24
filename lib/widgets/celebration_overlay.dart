import 'dart:math';

import 'package:flutter/material.dart';

import '../core/game_theme.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.child, this.active = false});
  final Widget child;
  final bool active;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.sizeOf(context),
              painter: _ConfettiPainter(_controller.value),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;
  static const colors = [
    GameTheme.cyan,
    GameTheme.gold,
    GameTheme.mint,
    GameTheme.violet,
    GameTheme.danger,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final random = Random(42);
    for (var i = 0; i < 90; i++) {
      final startX = size.width * (.15 + random.nextDouble() * .7);
      final velocityX = (random.nextDouble() - .5) * 250;
      final velocityY = -260 - random.nextDouble() * 250;
      final x = startX + velocityX * t;
      final y = size.height * .42 + velocityY * t + 480 * t * t;
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 10 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -7, 8, 14), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
