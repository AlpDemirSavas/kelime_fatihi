class CompetitionPeriod {
  const CompetitionPeriod._();

  static String weekKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final monday = local.subtract(Duration(days: local.weekday - DateTime.monday));
    return '${monday.year.toString().padLeft(4, '0')}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }

  static String seasonKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}

class CompetitionScoring {
  const CompetitionScoring._();

  static const int levelBase = 100;
  static const int bonusWord = 10;
  static const int perfectConquest = 50;
  static const int dailyWin = 75;

  static int levelCompletion({
    required int bonusWords,
    required bool perfect,
  }) =>
      levelBase +
      bonusWords * bonusWord +
      (perfect ? perfectConquest : 0);
}

enum LeagueTier {
  bronze,
  silver,
  gold,
  diamond,
  conqueror;

  static LeagueTier forScore(int score) {
    if (score >= 25000) return LeagueTier.conqueror;
    if (score >= 15000) return LeagueTier.diamond;
    if (score >= 8000) return LeagueTier.gold;
    if (score >= 3000) return LeagueTier.silver;
    return LeagueTier.bronze;
  }

  String get title => switch (this) {
    LeagueTier.bronze => 'Bronz',
    LeagueTier.silver => 'Gümüş',
    LeagueTier.gold => 'Altın',
    LeagueTier.diamond => 'Elmas',
    LeagueTier.conqueror => 'Fatih',
  };

  String get emoji => switch (this) {
    LeagueTier.bronze => '🥉',
    LeagueTier.silver => '🥈',
    LeagueTier.gold => '🥇',
    LeagueTier.diamond => '💎',
    LeagueTier.conqueror => '👑',
  };

  int? get nextThreshold => switch (this) {
    LeagueTier.bronze => 3000,
    LeagueTier.silver => 8000,
    LeagueTier.gold => 15000,
    LeagueTier.diamond => 25000,
    LeagueTier.conqueror => null,
  };

  int get lowerThreshold => switch (this) {
    LeagueTier.bronze => 0,
    LeagueTier.silver => 3000,
    LeagueTier.gold => 8000,
    LeagueTier.diamond => 15000,
    LeagueTier.conqueror => 25000,
  };
}


class UsernameRules {
  const UsernameRules._();

  static const int minLength = 3;
  static const int maxLength = 18;

  static final RegExp _allowedCharacters = RegExp(
    r'^[A-Za-z0-9_ ÇĞİÖŞÜçğıöşü]+$',
  );

  // Kısa parçaları substring olarak engellemek masum adları yanlışlıkla
  // reddedebilir. Bu yüzden 3 harfli ağır ifadeler yalnız tam eşleşmede,
  // daha uzun ve açık ifadeler ise adın içinde de engellenir.
  static const Set<String> _blockedExact = <String>{
    'sik',
    'sex',
  };

  static const Set<String> _blockedFragments = <String>{
    'porno',
    'seks',
    'siktir',
    'orospu',
    'kaltak',
    'yarak',
    'vajina',
    'penis',
    'amcik',
    'amcık',
    'fahise',
    'fahişe',
    'tecavuz',
    'tecavüz',
    'eroin',
    'kokain',
  };

  static const Set<String> _reservedPrefixes = <String>{
    'kelimefatihi',
    'admin',
    'administrator',
    'moderator',
    'yonetici',
    'yönetici',
    'destek',
    'support',
    'sistem',
    'system',
  };

  static String sanitizeDisplay(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String normalize(String raw) {
    final display = sanitizeDisplay(raw);
    final lower = display
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();
    return lower.replaceAll(RegExp(r'[ _]+'), '_');
  }

  static String? validate(String raw) {
    final display = sanitizeDisplay(raw);
    if (display.length < minLength || display.length > maxLength) {
      return 'Fatih adı $minLength–$maxLength karakter olmalı.';
    }
    if (!_allowedCharacters.hasMatch(display)) {
      return 'Yalnızca harf, rakam, boşluk ve _ kullanabilirsin.';
    }
    if (!RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(display)) {
      return 'Fatih adında en az bir harf bulunmalı.';
    }
    if (display.startsWith('_') || display.endsWith('_')) {
      return 'Fatih adı _ ile başlayamaz veya bitemez.';
    }
    if (display.contains('__') ||
        display.contains('_ ') ||
        display.contains(' _')) {
      return 'Boşluk ve _ işaretlerini art arda kullanma.';
    }

    final normalized = normalize(display);
    final compact = normalized.replaceAll('_', '');
    if (_reservedPrefixes.any(compact.startsWith)) {
      return 'Bu Fatih adı kullanılamaz.';
    }
    if (_blockedExact.contains(compact) ||
        _blockedFragments.any(compact.contains)) {
      return 'Bu Fatih adı kullanılamaz.';
    }
    return null;
  }
}

class UsernameClaimResult {
  const UsernameClaimResult({this.username, this.error});

  final String? username;
  final String? error;

  bool get success => username != null && username!.isNotEmpty && error == null;
}

class SocialSyncResult {
  const SocialSyncResult({
    required this.friendCode,
    required this.weeklyScore,
    required this.seasonScore,
  });

  final String friendCode;
  final int weeklyScore;
  final int seasonScore;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.weeklyScore,
    required this.seasonScore,
    required this.weekKey,
    required this.seasonKey,
    required this.levelNumber,
    required this.perfectConquests,
  });

  final String uid;
  final String displayName;
  final int weeklyScore;
  final int seasonScore;
  final String weekKey;
  final String seasonKey;
  final int levelNumber;
  final int perfectConquests;

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> map) {
    String cleanName(Object? raw) {
      final value = (raw as String?)?.trim() ?? '';
      if (value.isEmpty) return 'Kelime Fatihi';
      return value.length <= 28 ? value : value.substring(0, 28);
    }

    return LeaderboardEntry(
      uid: uid,
      displayName: cleanName(map['displayName']),
      weeklyScore: (map['weeklyScore'] as num?)?.toInt() ?? 0,
      seasonScore: (map['seasonScore'] as num?)?.toInt() ?? 0,
      weekKey: map['weekKey'] as String? ?? '',
      seasonKey: map['seasonKey'] as String? ?? '',
      levelNumber: (map['levelNumber'] as num?)?.toInt() ?? 1,
      perfectConquests: (map['perfectConquests'] as num?)?.toInt() ?? 0,
    );
  }
}
