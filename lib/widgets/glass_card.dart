import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: Colors.white.withValues(alpha: .075),
            border: Border.all(color: Colors.white.withValues(alpha: .13)),
            boxShadow: [
              BoxShadow(
                blurRadius: 30,
                offset: const Offset(0, 16),
                color: Colors.black.withValues(alpha: .18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    return onTap == null ? card : InkWell(onTap: onTap, child: card);
  }
}
