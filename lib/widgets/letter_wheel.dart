import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/game_theme.dart';
import '../core/turkish_text.dart';

class LetterWheel extends StatefulWidget {
  const LetterWheel({
    super.key,
    required this.letters,
    required this.onSubmitted,
    this.onLetterSelected,
    this.hapticsEnabled = true,
  });

  final List<String> letters;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onLetterSelected;
  final bool hapticsEnabled;

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel>
    with SingleTickerProviderStateMixin {
  final List<int> _selected = <int>[];

  Offset? _pointer;
  List<Offset> _centers = <Offset>[];
  double _hitRadius = 34;
  int? _activePointer;
  bool _reduceMotion = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  String get _word => _selected.map((i) => widget.letters[i]).join();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fastDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 110);
    final containerDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 140);
    final switchDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 120);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, 310.0);
        final center = Offset(size / 2, size / 2);
        final count = widget.letters.length;

        final nodeSize = count <= 7
            ? 60.0
            : count == 8
            ? 52.0
            : 46.0;

        _hitRadius = nodeSize / 2 + 4;
        final radius = size * (count <= 7 ? .34 : .37);

        _centers = List.generate(widget.letters.length, (i) {
          final angle = -pi / 2 + i * 2 * pi / widget.letters.length;
          return center + Offset(cos(angle), sin(angle)) * radius;
        });

        return SizedBox(
          width: size,
          height: size,
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              EagerGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                    (EagerGestureRecognizer instance) {},
                  ),
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final pulse = reduceMotion || _selected.isEmpty
                      ? 0.0
                      : sin(_pulseController.value * pi);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WheelPainter(
                            centers: _centers,
                            selected: _selected,
                            pointer: _pointer,
                            pulse: pulse,
                          ),
                        ),
                      ),
                      Center(
                        child: AnimatedScale(
                          duration: fastDuration,
                          curve: Curves.easeOutBack,
                          scale: reduceMotion || _word.isEmpty
                              ? 1
                              : 1.0 + pulse * .025,
                          child: AnimatedContainer(
                            duration: containerDuration,
                            constraints: BoxConstraints(maxWidth: size * .52),
                            padding: EdgeInsets.symmetric(
                              horizontal: _word.isEmpty ? 0 : 14,
                              vertical: _word.isEmpty ? 0 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: _word.isEmpty
                                  ? Colors.transparent
                                  : const Color(0xE6122C45),
                              borderRadius: BorderRadius.circular(18),
                              border: _word.isEmpty
                                  ? null
                                  : Border.all(
                                      color: GameTheme.gold.withValues(
                                        alpha: .45 + pulse * .25,
                                      ),
                                    ),
                              boxShadow: _word.isEmpty
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: GameTheme.cyan.withValues(
                                          alpha: .16 + pulse * .14,
                                        ),
                                        blurRadius: 18 + pulse * 9,
                                      ),
                                    ],
                            ),
                            child: AnimatedSwitcher(
                              duration: switchDuration,
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: Tween<double>(begin: .84, end: 1)
                                        .animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutBack,
                                          ),
                                        ),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                              child: FittedBox(
                                key: ValueKey(_word),
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  TurkishText.upper(_word),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: _word.length <= 6 ? 24 : 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: _word.length <= 6 ? 1.6 : 1.0,
                                    color: GameTheme.gold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: .55,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(widget.letters.length, (i) {
                        final c = _centers[i];
                        final selected = _selected.contains(i);
                        final selectedScale = selected && !reduceMotion
                            ? 1.1 + pulse * .035
                            : 1.0;

                        return Positioned(
                          left: c.dx - nodeSize / 2,
                          top: c.dy - nodeSize / 2,
                          width: nodeSize,
                          height: nodeSize,
                          child: AnimatedScale(
                            scale: selectedScale,
                            duration: fastDuration,
                            curve: Curves.easeOutBack,
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 100),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? GameTheme.cyan
                                    : const Color(0xFF173B60),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: .16),
                                  width: selected ? 3 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: selected ? 25 + pulse * 9 : 10,
                                    spreadRadius: selected ? 1.5 + pulse : 0,
                                    color: (selected ? GameTheme.cyan : Colors.black)
                                        .withValues(alpha: selected ? .42 : .38),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                TurkishText.upper(widget.letters[i]),
                                style: TextStyle(
                                  fontSize: count <= 7
                                      ? 26
                                      : count == 8
                                      ? 23
                                      : 21,
                                  fontWeight: FontWeight.w900,
                                  color: selected
                                      ? const Color(0xFF04121E)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    if (!_reduceMotion) _pulseController.repeat(reverse: true);
    _updatePointer(event.localPosition, reset: true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    _updatePointer(event.localPosition);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _submit();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _clear();
  }

  void _updatePointer(Offset point, {bool reset = false}) {
    if (reset) _selected.clear();
    _pointer = point;

    for (var i = 0; i < _centers.length; i++) {
      if ((point - _centers[i]).distance > _hitRadius) continue;

      if (_selected.length >= 2 && i == _selected[_selected.length - 2]) {
        _selected.removeLast();
        if (widget.hapticsEnabled) HapticFeedback.selectionClick();
        widget.onLetterSelected?.call();
        break;
      }

      if (!_selected.contains(i)) {
        _selected.add(i);
        if (widget.hapticsEnabled) HapticFeedback.selectionClick();
        widget.onLetterSelected?.call();
      }
      break;
    }

    setState(() {});
  }

  void _submit() {
    final word = _word;
    if (word.isNotEmpty) widget.onSubmitted(word);
    _clear();
  }

  void _clear() {
    _pulseController.stop();
    _pulseController.value = 0;
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _pointer = null;
    });
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.centers,
    required this.selected,
    required this.pulse,
    this.pointer,
  });

  final List<Offset> centers;
  final List<int> selected;
  final Offset? pointer;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      size.width * .47,
      Paint()
        ..color = Colors.white.withValues(alpha: .035)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      size.width * .47,
      Paint()
        ..color = Colors.white.withValues(alpha: .08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    if (selected.isEmpty) return;

    final path = Path()
      ..moveTo(centers[selected.first].dx, centers[selected.first].dy);
    for (final index in selected.skip(1)) {
      path.lineTo(centers[index].dx, centers[index].dy);
    }
    if (pointer != null) path.lineTo(pointer!.dx, pointer!.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = GameTheme.cyan.withValues(alpha: .17 + pulse * .08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22 + pulse * 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + pulse * 3),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(GameTheme.cyan, Colors.white, pulse * .16)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 + pulse * 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final spark = pointer ?? centers[selected.last];
    canvas.drawCircle(
      spark,
      5.5 + pulse * 2.5,
      Paint()
        ..color = Colors.white.withValues(alpha: .75 + pulse * .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.pointer != pointer ||
      oldDelegate.pulse != pulse ||
      oldDelegate.selected != selected;
}
