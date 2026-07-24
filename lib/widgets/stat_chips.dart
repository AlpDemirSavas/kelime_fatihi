import 'package:flutter/material.dart';

import '../core/game_theme.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.subtitle,
  });
  final IconData icon;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TopStats extends StatelessWidget {
  const TopStats({
    super.key,
    required this.hearts,
    required this.coins,
    this.heartTimer,
  });
  final int hearts;
  final int coins;
  final String? heartTimer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatChip(
          icon: Icons.favorite_rounded,
          value: '$hearts',
          color: GameTheme.danger,
          subtitle: heartTimer,
        ),
        const SizedBox(width: 8),
        StatChip(
          icon: Icons.monetization_on_rounded,
          value: '$coins',
          color: GameTheme.gold,
        ),
      ],
    );
  }
}
