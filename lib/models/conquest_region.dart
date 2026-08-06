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


  // 8,000 bölümlük kampanyada her 100 bölüm için tek ve tekrar etmeyen
  // tarihî/coğrafi bir durak adı kullanılır. Renk/emoji temaları yalnızca
  // görsel çeşitlilik için döngüsel kalır.
  static const _regionNames = <String>[
    'Göbeklitepe',
    'Çatalhöyük',
    'Hattuşa',
    'Alacahöyük',
    'Gordion',
    'Truva',
    'Assos',
    'Bergama',
    'Sardes',
    'Efes',
    'Milet',
    'Priene',
    'Didyma',
    'Afrodisias',
    'Hierapolis',
    'Laodikeia',
    'Aizanoi',
    'Sagalassos',
    'Kibyra',
    'Termessos',
    'Perge',
    'Aspendos',
    'Side',
    'Olympos',
    'Phaselis',
    'Patara',
    'Letoon',
    'Xanthos',
    'Myra',
    'Knidos',
    'Kaunos',
    'Stratonikeia',
    'Lagina',
    'Zeugma',
    'Nemrut',
    'Arslantepe',
    'Harran',
    'Ani',
    'Akdamar',
    'Van Kalesi',
    'Hasankeyf',
    'Dara',
    'Mardin',
    'Diyarbakır Surları',
    'Harput',
    'Divriği',
    'Amasya',
    'Tokat',
    'Sivas',
    'Kayseri',
    'Kültepe',
    'Konya',
    'Sille',
    'Kubadabad',
    'Tarsus',
    'Anavarza',
    'Antakya',
    'Alanya',
    'Selge',
    'Yalvaç',
    'İznik',
    'Bursa',
    'Cumalıkızık',
    'Edirne',
    'İstanbul',
    'Rumeli Hisarı',
    'Anadolu Hisarı',
    'Safranbolu',
    'Amasra',
    'Sinop',
    'Sümela',
    'Trabzon',
    'Bayburt',
    'Erzurum',
    'İshak Paşa',
    'Çıldır',
    'Çifte Minareli Medrese',
    'Yakutiye Medresesi',
    'Zelve',
    'Göreme',
  ];

  int progressFor(int level) =>
      (level - startLevel + 1).clamp(0, regionSize).toInt();

  static const _themes =
      <({String subtitle, String emoji, Color accent})>[
        (
          subtitle: 'Taş şehirlerden kelime hazinelerine',
          emoji: '🏛️',
          accent: GameTheme.gold,
        ),
        (
          subtitle: 'Sisli vadiler ve eski kaleler',
          emoji: '🏰',
          accent: GameTheme.cyan,
        ),
        (
          subtitle: 'Nehirlerin arasında kadim sözcükler',
          emoji: '🌙',
          accent: GameTheme.mint,
        ),
        (
          subtitle: 'Kervanlarla taşınan gizli kelimeler',
          emoji: '🐫',
          accent: GameTheme.violet,
        ),
        (
          subtitle: 'Buzun altında saklı harfler',
          emoji: '❄️',
          accent: Color(0xFF86D9FF),
        ),
        (
          subtitle: 'Dalgalar, adalar ve sıcak meydan okumalar',
          emoji: '🌊',
          accent: Color(0xFF58E6D9),
        ),
        (
          subtitle: 'Kum fırtınasının içindeki kelimeler',
          emoji: '🏜️',
          accent: Color(0xFFFFB968),
        ),
        (
          subtitle: 'Yaprakların arasındaki gizli yollar',
          emoji: '🌿',
          accent: Color(0xFF72F29A),
        ),
        (
          subtitle: 'Bulutların üzerinde kelime avı',
          emoji: '☁️',
          accent: Color(0xFFB7C7FF),
        ),
        (
          subtitle: 'Fatihlerin en zorlu yüzlüğü',
          emoji: '👑',
          accent: GameTheme.gold,
        ),
      ];

  static ConquestRegion forLevel(int level) {
    final safeLevel = level.clamp(1, maxLevel).toInt();
    final regionIndex = (safeLevel - 1) ~/ regionSize;
    final theme = _themes[regionIndex % _themes.length];
    final start = regionIndex * regionSize + 1;
    final end = (start + regionSize - 1).clamp(1, maxLevel).toInt();
    return ConquestRegion(
      index: regionIndex,
      name: _regionNames[regionIndex],
      subtitle: theme.subtitle,
      emoji: theme.emoji,
      accent: theme.accent,
      startLevel: start,
      endLevel: end,
    );
  }
}
