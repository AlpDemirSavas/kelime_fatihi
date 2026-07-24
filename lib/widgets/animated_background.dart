import 'dart:math';

import 'package:flutter/material.dart';

import '../core/game_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.child,
    this.accent = GameTheme.cyan,
  });

  final Widget child;
  final Color accent;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Background is quantized to ~30 FPS. Gameplay gestures can still be
        // rendered at the device's native frame rate.
        final t = (_controller.value * 420).floor() / 420.0;
        return RepaintBoundary(
          child: CustomPaint(
            painter: _NebulaPainter(t, widget.accent),
            isComplex: true,
            willChange: true,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _NebulaPainter extends CustomPainter {
  _NebulaPainter(this.t, this.accent);
  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GameTheme.midnight, GameTheme.ocean, Color(0xFF15133A)],
        ).createShader(rect),
    );

    final blobs = [
      (accent, .28, .22, .44),
      (GameTheme.violet, .76, .34, .34),
      (GameTheme.gold, .42, .82, .30),
    ];

    for (var i = 0; i < blobs.length; i++) {
      final b = blobs[i];
      final phase = t * 2 * pi + i * 2.1;
      final center = Offset(
        size.width * (b.$2 + sin(phase) * .08),
        size.height * (b.$3 + cos(phase * .83) * .06),
      );
      final radius = size.shortestSide * b.$4;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [b.$1.withValues(alpha: .18), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final starPaint = Paint()..color = Colors.white.withValues(alpha: .18);
    for (var i = 0; i < 28; i++) {
      final x = ((i * 97.0 + t * 20) % 101) / 101 * size.width;
      final y = ((i * 53.0 + t * 12) % 103) / 103 * size.height;
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.5 : .8, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.accent != accent;
}
