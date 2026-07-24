enum ChestRewardType { heart, coins, freeHint, crownFragment }

class ChestReward {
  const ChestReward({
    required this.type,
    required this.amount,
    required this.label,
  });
  final ChestRewardType type;
  final int amount;
  final String label;
}
