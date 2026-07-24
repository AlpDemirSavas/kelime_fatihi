enum MissionType { bonusWords, targetWords, levels, combo, noHintLevel }

class DailyMission {
  const DailyMission({
    required this.id,
    required this.type,
    required this.title,
    required this.target,
    required this.reward,
    required this.progress,
    required this.claimed,
  });

  final String id;
  final MissionType type;
  final String title;
  final int target;
  final int reward;
  final int progress;
  final bool claimed;

  bool get completed => progress >= target;

  DailyMission copyWith({int? progress, bool? claimed}) => DailyMission(
    id: id,
    type: type,
    title: title,
    target: target,
    reward: reward,
    progress: progress ?? this.progress,
    claimed: claimed ?? this.claimed,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'target': target,
    'reward': reward,
    'progress': progress,
    'claimed': claimed,
  };

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
    id: json['id'] as String,
    type: MissionType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => MissionType.targetWords,
    ),
    title: json['title'] as String,
    target: json['target'] as int,
    reward: json['reward'] as int,
    progress: json['progress'] as int? ?? 0,
    claimed: json['claimed'] as bool? ?? false,
  );
}
