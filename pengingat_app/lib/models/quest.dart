enum QuestDifficulty { easy, normal, hard }

enum RepeatType { once, daily, weekly }

class Quest {
  final int? id;
  final String title;
  final String note;
  final String category;
  final QuestDifficulty difficulty;
  final int xpReward;
  final int coinReward;
  final DateTime dateTime;
  final RepeatType repeatType;
  final bool isAlarmEnabled;
  final bool isCompleted;
  final DateTime? completedAt;
  final int characterId;

  const Quest({
    this.id,
    required this.title,
    this.note = '',
    this.category = 'Pribadi',
    this.difficulty = QuestDifficulty.normal,
    this.xpReward = 60,
    this.coinReward = 30,
    required this.dateTime,
    this.repeatType = RepeatType.once,
    this.isAlarmEnabled = true,
    this.isCompleted = false,
    this.completedAt,
    this.characterId = 1,
  });

  Quest copyWith({
    int? id,
    String? title,
    String? note,
    String? category,
    QuestDifficulty? difficulty,
    int? xpReward,
    int? coinReward,
    DateTime? dateTime,
    RepeatType? repeatType,
    bool? isAlarmEnabled,
    bool? isCompleted,
    DateTime? completedAt,
    int? characterId,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      dateTime: dateTime ?? this.dateTime,
      repeatType: repeatType ?? this.repeatType,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      characterId: characterId ?? this.characterId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'note': note,
      'category': category,
      'difficulty': difficulty.name,
      'xp_reward': xpReward,
      'coin_reward': coinReward,
      'date_time': dateTime.toIso8601String(),
      'repeat_type': repeatType.name,
      'is_alarm_enabled': isAlarmEnabled ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'character_id': characterId,
    };
  }

  factory Quest.fromMap(Map<String, Object?> map) {
    return Quest(
      id: map['id'] as int?,
      title: map['title'] as String,
      note: map['note'] as String? ?? '',
      category: map['category'] as String? ?? 'Pribadi',
      difficulty: QuestDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => QuestDifficulty.normal,
      ),
      xpReward: map['xp_reward'] as int? ?? 60,
      coinReward: map['coin_reward'] as int? ?? 30,
      dateTime: DateTime.parse(map['date_time'] as String),
      repeatType: RepeatType.values.firstWhere(
        (e) => e.name == map['repeat_type'],
        orElse: () => RepeatType.once,
      ),
      isAlarmEnabled: (map['is_alarm_enabled'] as int? ?? 1) == 1,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      characterId: map['character_id'] as int? ?? 1,
    );
  }

  static int getXpByDifficulty(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 30;
      case QuestDifficulty.normal:
        return 60;
      case QuestDifficulty.hard:
        return 120;
    }
  }

  static int getCoinByDifficulty(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 15;
      case QuestDifficulty.normal:
        return 30;
      case QuestDifficulty.hard:
        return 60;
    }
  }
}
