import 'dart:math';

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
  });

  final List<String> letters;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onLetterSelected;

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel> {
  final List<int> _selected = <int>[];
  Offset? _pointer;
  List<Offset> _centers = <Offset>[];
  double _hitRadius = 34;

  String get _word => _selected.map((i) => widget.letters[i]).join();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, 310.0);
        final center = Offset(size / 2, size / 2);
        final count = widget.letters.length;
        final nodeSize = count <= 7 ? 60.0 : count == 8 ? 52.0 : 46.0;
        _hitRadius = nodeSize / 2 + 4;
        final radius = size * (count <= 7 ? .34 : .37);
        _centers = List.generate(widget.letters.length, (i) {
          final angle = -pi / 2 + i * 2 * pi / widget.letters.length;
          return center + Offset(cos(angle), sin(angle)) * radius;
        });

        return SizedBox(
          width: size,
          height: size,
          child: Listener(
            onPointerDown: (event) => _updatePointer(event.localPosition, reset: true),
            onPointerMove: (event) => _updatePointer(event.localPosition),
            onPointerUp: (_) => _submit(),
            onPointerCancel: (_) => _clear(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WheelPainter(
                      centers: _centers,
                      selected: _selected,
                      pointer: _pointer,
                    ),
                  ),
                ),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    child: Text(
                      TurkishText.upper(_word),
                      key: ValueKey(_word),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: GameTheme.gold,
                      ),
                    ),
                  ),
                ),
                ...List.generate(widget.letters.length, (i) {
                  final c = _centers[i];
                  final selected = _selected.contains(i);
                  return Positioned(
                    left: c.dx - nodeSize / 2,
                    top: c.dy - nodeSize / 2,
                    width: nodeSize,
                    height: nodeSize,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? GameTheme.cyan : const Color(0xFF173B60),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.white.withValues(alpha: .16),
                          width: selected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: selected ? 24 : 10,
                            color: (selected ? GameTheme.cyan : Colors.black)
                                .withValues(alpha: .35),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        TurkishText.upper(widget.letters[i]),
                        style: TextStyle(
                          fontSize: count <= 7 ? 26 : count == 8 ? 23 : 21,
                          fontWeight: FontWeight.w900,
                          color: selected ? const Color(0xFF04121E) : Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updatePointer(Offset point, {bool reset = false}) {
    if (reset) _selected.clear();
    _pointer = point;
    for (var i = 0; i < _centers.length; i++) {
      if ((point - _centers[i]).distance <= _hitRadius && !_selected.contains(i)) {
        _selected.add(i);
        HapticFeedback.selectionClick();
        widget.onLetterSelected?.call();
        break;
      }
    }
    setState(() {});
  }

  void _submit() {
    final word = _word;
    if (word.isNotEmpty) widget.onSubmitted(word);
    _clear();
  }

  void _clear() {
    setState(() {
      _selected.clear();
      _pointer = null;
    });
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.centers, required this.selected, this.pointer});
  final List<Offset> centers;
  final List<int> selected;
  final Offset? pointer;

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
    final path = Path()..moveTo(centers[selected.first].dx, centers[selected.first].dy);
    for (final index in selected.skip(1)) {
      path.lineTo(centers[index].dx, centers[index].dy);
    }
    if (pointer != null) path.lineTo(pointer!.dx, pointer!.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = GameTheme.cyan.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => true;
}
