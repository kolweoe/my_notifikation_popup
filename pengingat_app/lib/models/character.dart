class Character {
  final int id;
  final String name;
  final int level;
  final int currentXp;
  final int totalXp;
  final int coin;
  final int focus;
  final int energy;
  final int wealth;
  final int discipline;
  final int roomLevel;
  final int? currentCostumeId;
  final int? currentPetId;

  const Character({
    this.id = 1,
    this.name = 'Hero',
    this.level = 1,
    this.currentXp = 0,
    this.totalXp = 0,
    this.coin = 100,
    this.focus = 10,
    this.energy = 10,
    this.wealth = 10,
    this.discipline = 10,
    this.roomLevel = 1,
    this.currentCostumeId,
    this.currentPetId,
  });

  Character copyWith({
    int? id,
    String? name,
    int? level,
    int? currentXp,
    int? totalXp,
    int? coin,
    int? focus,
    int? energy,
    int? wealth,
    int? discipline,
    int? roomLevel,
    int? currentCostumeId,
    int? currentPetId,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      totalXp: totalXp ?? this.totalXp,
      coin: coin ?? this.coin,
      focus: focus ?? this.focus,
      energy: energy ?? this.energy,
      wealth: wealth ?? this.wealth,
      discipline: discipline ?? this.discipline,
      roomLevel: roomLevel ?? this.roomLevel,
      currentCostumeId: currentCostumeId ?? this.currentCostumeId,
      currentPetId: currentPetId ?? this.currentPetId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'current_xp': currentXp,
      'total_xp': totalXp,
      'coin': coin,
      'focus': focus,
      'energy': energy,
      'wealth': wealth,
      'discipline': discipline,
      'room_level': roomLevel,
      'current_costume_id': currentCostumeId,
      'current_pet_id': currentPetId,
    };
  }

  factory Character.fromMap(Map<String, Object?> map) {
    return Character(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? 'Hero',
      level: map['level'] as int? ?? 1,
      currentXp: map['current_xp'] as int? ?? 0,
      totalXp: map['total_xp'] as int? ?? 0,
      coin: map['coin'] as int? ?? 0,
      focus: map['focus'] as int? ?? 10,
      energy: map['energy'] as int? ?? 10,
      wealth: map['wealth'] as int? ?? 10,
      discipline: map['discipline'] as int? ?? 10,
      roomLevel: map['room_level'] as int? ?? 1,
      currentCostumeId: map['current_costume_id'] as int?,
      currentPetId: map['current_pet_id'] as int?,
    );
  }

  /// XP needed to reach the next level
  int get xpToNextLevel {
    if (level <= 1) return 100;
    if (level == 2) return 150;
    if (level == 3) return 200;
    if (level == 4) return 250;
    if (level == 5) return 300;
    if (level == 6) return 400;
    if (level == 7) return 500;
    if (level == 8) return 600;
    if (level == 9) return 700;
    if (level == 10) return 800;
    if (level == 11) return 1000;
    if (level == 12) return 1200;
    if (level == 13) return 1400;
    if (level == 14) return 1600;
    return 1800; // level 15+
  }

  double get xpProgress =>
      xpToNextLevel == 0 ? 0 : currentXp / xpToNextLevel;
}
