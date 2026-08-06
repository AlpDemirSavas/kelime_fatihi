enum ChestRewardType { heart, coins, freeHint, crownFragment }

enum ChestRewardTier { scout, conquest, master, region }

class ChestReward {
  const ChestReward({
    required this.type,
    required this.amount,
    required this.label,
    this.tier = ChestRewardTier.scout,
  });

  final ChestRewardType type;
  final int amount;
  final String label;
  final ChestRewardTier tier;

  String get title => switch (tier) {
    ChestRewardTier.scout => 'Küçük Fetih Sandığı',
    ChestRewardTier.conquest => 'Fetih Sandığı',
    ChestRewardTier.master => 'Usta Sandığı',
    ChestRewardTier.region => 'Bölge Sandığı',
  };

  String get emoji => switch (tier) {
    ChestRewardTier.scout => '🎁',
    ChestRewardTier.conquest => '🧰',
    ChestRewardTier.master => '🏆',
    ChestRewardTier.region => '👑',
  };
}
