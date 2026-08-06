import 'dart:math';

import 'package:flutter/material.dart';

import '../core/game_theme.dart';

enum CelebrationIntensity { normal, milestone, region }

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.child,
    this.active = false,
    this.intensity = CelebrationIntensity.normal,
  });

  final Widget child;
  final bool active;
  final CelebrationIntensity intensity;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reduceMotion &&
        widget.active &&
        (!oldWidget.active || oldWidget.intensity != widget.intensity)) {
      _controller.duration = switch (widget.intensity) {
        CelebrationIntensity.normal => const Duration(milliseconds: 950),
        CelebrationIntensity.milestone => const Duration(milliseconds: 1450),
        CelebrationIntensity.region => const Duration(milliseconds: 1850),
      };
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
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.sizeOf(context),
              painter: _ConfettiPainter(
                _controller.value,
                intensity: widget.intensity,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, {required this.intensity});

  final double t;
  final CelebrationIntensity intensity;

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

    final particleCount = switch (intensity) {
      CelebrationIntensity.normal => 34,
      CelebrationIntensity.milestone => 76,
      CelebrationIntensity.region => 120,
    };
    final spread = switch (intensity) {
      CelebrationIntensity.normal => .48,
      CelebrationIntensity.milestone => .66,
      CelebrationIntensity.region => .82,
    };
    final random = Random(42 + intensity.index * 113);

    for (var i = 0; i < particleCount; i++) {
      final startX = size.width * (.5 - spread / 2 + random.nextDouble() * spread);
      final velocityX = (random.nextDouble() - .5) *
          (intensity == CelebrationIntensity.region ? 360 : 260);
      final velocityY = -230 - random.nextDouble() *
          (intensity == CelebrationIntensity.normal ? 190 : 300);
      final x = startX + velocityX * t;
      final y = size.height * .43 + velocityY * t + 500 * t * t;
      final alpha = (1 - t).clamp(0.0, 1.0).toDouble();
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: alpha);
      final width = intensity == CelebrationIntensity.region ? 9.0 : 8.0;
      final height = intensity == CelebrationIntensity.normal ? 12.0 : 15.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 10 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-width / 2, -height / 2, width, height),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }

    if (intensity == CelebrationIntensity.region) {
      final ringT = Curves.easeOutCubic.transform(t.clamp(0.0, .72) / .72);
      final ringAlpha = (1 - t).clamp(0.0, 1.0).toDouble() * .45;
      canvas.drawCircle(
        Offset(size.width / 2, size.height * .38),
        30 + 170 * ringT,
        Paint()
          ..color = GameTheme.gold.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.intensity != intensity;
}
