import 'package:flutter/material.dart';

import '../core/game_theme.dart';
import '../services/dictionary_service.dart';

class ConquestRegion {
  const ConquestRegion({
    required this.index,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.accent,
    required this.startLevel,
    required this.endLevel,
  });

  static const int regionSize = 100;
  static const int maxLevel = DictionaryService.maxLevel;
  static const int regionCount = maxLevel ~/ regionSize;

  final int index;
  final String name;
  final String subtitle;
  final String emoji;
  final Color accent;
  final int startLevel;
  final int endLevel;

  int progressFor(int level) => (level - startLevel + 1).clamp(0, regionSize).toInt();

  static const _themes = <({String name, String subtitle, String emoji, Color accent})>[
    (name: 'Anadolu', subtitle: 'Taş şehirlerden kelime hazinelerine', emoji: '🏛️', accent: GameTheme.gold),
    (name: 'Balkanlar', subtitle: 'Sisli vadiler ve eski kaleler', emoji: '🏰', accent: GameTheme.cyan),
    (name: 'Mezopotamya', subtitle: 'Nehirlerin arasında kadim sözcükler', emoji: '🌙', accent: GameTheme.mint),
    (name: 'İpek Yolu', subtitle: 'Kervanlarla taşınan gizli kelimeler', emoji: '🐫', accent: GameTheme.violet),
    (name: 'Kuzey Diyarı', subtitle: 'Buzun altında saklı harfler', emoji: '❄️', accent: Color(0xFF86D9FF)),
    (name: 'Akdeniz', subtitle: 'Dalgalar, adalar ve sıcak meydan okumalar', emoji: '🌊', accent: Color(0xFF58E6D9)),
    (name: 'Çöl Krallığı', subtitle: 'Kum fırtınasının içindeki kelimeler', emoji: '🏜️', accent: Color(0xFFFFB968)),
    (name: 'Zümrüt Orman', subtitle: 'Yaprakların arasındaki gizli yollar', emoji: '🌿', accent: Color(0xFF72F29A)),
    (name: 'Gökyüzü Adaları', subtitle: 'Bulutların üzerinde kelime avı', emoji: '☁️', accent: Color(0xFFB7C7FF)),
    (name: 'Taç Şehri', subtitle: 'Fatihlerin en zorlu yüzlüğü', emoji: '👑', accent: GameTheme.gold),
  ];

  static ConquestRegion forLevel(int level) {
    final safeLevel = level.clamp(1, maxLevel).toInt();
    final regionIndex = (safeLevel - 1) ~/ regionSize;
    final theme = _themes[regionIndex % _themes.length];
    final cycle = regionIndex ~/ _themes.length;
    final suffix = cycle == 0 ? '' : ' ${cycle + 1}';
    final start = regionIndex * regionSize + 1;
    final end = (start + regionSize - 1).clamp(1, maxLevel).toInt();
    return ConquestRegion(
      index: regionIndex,
      name: '${theme.name}$suffix',
      subtitle: theme.subtitle,
      emoji: theme.emoji,
      accent: theme.accent,
      startLevel: start,
      endLevel: end,
    );
  }
}
