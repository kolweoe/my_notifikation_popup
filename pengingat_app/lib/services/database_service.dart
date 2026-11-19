import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quest.dart';
import '../models/character.dart';
import '../models/transaction.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'remindo.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Character
    await db.execute('''
      CREATE TABLE character (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT 'Hero',
        level INTEGER NOT NULL DEFAULT 1,
        current_xp INTEGER NOT NULL DEFAULT 0,
        total_xp INTEGER NOT NULL DEFAULT 0,
        coin INTEGER NOT NULL DEFAULT 100,
        focus INTEGER NOT NULL DEFAULT 10,
        energy INTEGER NOT NULL DEFAULT 10,
        wealth INTEGER NOT NULL DEFAULT 10,
        discipline INTEGER NOT NULL DEFAULT 10,
        room_level INTEGER NOT NULL DEFAULT 1,
        current_costume_id INTEGER,
        current_pet_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    // Quests
    await db.execute('''
      CREATE TABLE quests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        note TEXT,
        category TEXT NOT NULL DEFAULT 'Pribadi',
        difficulty TEXT NOT NULL DEFAULT 'normal',
        xp_reward INTEGER NOT NULL DEFAULT 60,
        coin_reward INTEGER NOT NULL DEFAULT 30,
        date_time TEXT NOT NULL,
        repeat_type TEXT NOT NULL DEFAULT 'once',
        is_alarm_enabled INTEGER NOT NULL DEFAULT 1,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        character_id INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (character_id) REFERENCES character(id) ON DELETE CASCADE
      )
    ''');

    // Quest History
    await db.execute('''
      CREATE TABLE quest_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quest_id INTEGER,
        title TEXT NOT NULL,
        category TEXT,
        difficulty TEXT,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        coin_earned INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        was_on_time INTEGER NOT NULL DEFAULT 1,
        character_id INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (quest_id) REFERENCES quests(id) ON DELETE SET NULL,
        FOREIGN KEY (character_id) REFERENCES character(id) ON DELETE CASCADE
      )
    ''');

    // Transactions (Wallet)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        character_id INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (character_id) REFERENCES character(id) ON DELETE CASCADE
      )
    ''');

    // Savings Goals
    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        character_id INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (character_id) REFERENCES character(id) ON DELETE CASCADE
      )
    ''');

    // Costumes
    await db.execute('''
      CREATE TABLE costumes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_path TEXT,
        price INTEGER NOT NULL DEFAULT 0,
        is_owned INTEGER NOT NULL DEFAULT 0,
        is_equipped INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    // Pets
    await db.execute('''
      CREATE TABLE pets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_path TEXT,
        price INTEGER NOT NULL DEFAULT 0,
        is_owned INTEGER NOT NULL DEFAULT 0,
        is_equipped INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    // Badges
    await db.execute('''
      CREATE TABLE badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon_path TEXT,
        is_unlocked INTEGER NOT NULL DEFAULT 0,
        unlocked_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    // Streak
    await db.execute('''
      CREATE TABLE streak (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT,
        character_id INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (character_id) REFERENCES character(id) ON DELETE CASCADE
      )
    ''');

    // Settings
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        popup_image_path TEXT,
        alarm_sound_path TEXT,
        is_dark_mode INTEGER NOT NULL DEFAULT 0,
        language TEXT NOT NULL DEFAULT 'id',
        character_id INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (character_id) REFERENCES character(id) ON DELETE CASCADE
      )
    ''');

    // Room Upgrades
    await db.execute('''
      CREATE TABLE room_upgrades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_level INTEGER NOT NULL,
        is_unlocked INTEGER NOT NULL DEFAULT 0,
        unlock_cost INTEGER NOT NULL DEFAULT 0,
        character_id INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (character_id) REFERENCES character(id) ON DELETE CASCADE
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_quests_date ON quests(date_time)');
    await db.execute('CREATE INDEX idx_quests_completed ON quests(is_completed)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');

    // ===== SEED DATA =====
    await db.insert('character', {
      'id': 1,
      'name': 'Hero',
      'level': 1,
      'current_xp': 0,
      'total_xp': 0,
      'coin': 100,
      'focus': 10,
      'energy': 10,
      'wealth': 10,
      'discipline': 10,
      'room_level': 1,
    });

    await db.insert('streak', {
      'character_id': 1,
      'current_streak': 0,
      'longest_streak': 0,
    });

    await db.insert('settings', {
      'character_id': 1,
      'language': 'id',
      'is_dark_mode': 0,
    });

    await db.insert('costumes', {
      'name': 'Default Outfit',
      'price': 0,
      'is_owned': 1,
      'is_equipped': 1,
    });

    await db.insert('pets', {
      'name': 'Kucing Abu',
      'price': 0,
      'is_owned': 1,
      'is_equipped': 1,
      'level': 1,
    });

    final badges = [
      {'name': 'First Quest', 'description': 'Menyelesaikan quest pertama'},
      {'name': '7-Day Streak', 'description': 'Menjaga streak selama 7 hari'},
      {'name': 'Early Bird', 'description': 'Menyelesaikan quest sebelum jam 8 pagi'},
      {'name': 'Hard Worker', 'description': 'Menyelesaikan 10 quest Hard'},
      {'name': 'Saver', 'description': 'Mencapai target tabungan pertama'},
    ];
    for (final b in badges) {
      await db.insert('badges', {...b, 'is_unlocked': 0});
    }

    final rooms = [
      {'room_level': 1, 'is_unlocked': 1, 'unlock_cost': 0},
      {'room_level': 2, 'is_unlocked': 0, 'unlock_cost': 200},
      {'room_level': 3, 'is_unlocked': 0, 'unlock_cost': 400},
      {'room_level': 4, 'is_unlocked': 0, 'unlock_cost': 700},
      {'room_level': 5, 'is_unlocked': 0, 'unlock_cost': 1100},
      {'room_level': 6, 'is_unlocked': 0, 'unlock_cost': 1600},
      {'room_level': 7, 'is_unlocked': 0, 'unlock_cost': 2200},
      {'room_level': 8, 'is_unlocked': 0, 'unlock_cost': 3000},
    ];
    for (final r in rooms) {
      await db.insert('room_upgrades', {...r, 'character_id': 1});
    }
  }

  // ==================== CHARACTER ====================
  static Future<Character> getCharacter() async {
    final db = await database;
    final maps = await db.query('character', where: 'id = ?', whereArgs: [1]);
    if (maps.isEmpty) {
      return const Character();
    }
    return Character.fromMap(maps.first);
  }

  static Future<void> updateCharacter(Character character) async {
    final db = await database;
    await db.update(
      'character',
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  // ==================== QUESTS ====================
  static Future<int> insertQuest(Quest quest) async {
    final db = await database;
    return await db.insert('quests', quest.toMap());
  }

  static Future<List<Quest>> getAllQuests({bool onlyActive = false}) async {
    final db = await database;
    final maps = await db.query(
      'quests',
      where: onlyActive ? 'is_completed = 0' : null,
      orderBy: 'date_time ASC',
    );
    return maps.map((m) => Quest.fromMap(m)).toList();
  }

  static Future<List<Quest>> getQuestsByRepeat(String repeatType) async {
    final db = await database;
    final maps = await db.query(
      'quests',
      where: 'repeat_type = ? AND is_completed = 0',
      whereArgs: [repeatType],
      orderBy: 'date_time ASC',
    );
    return maps.map((m) => Quest.fromMap(m)).toList();
  }

  static Future<void> updateQuest(Quest quest) async {
    final db = await database;
    await db.update(
      'quests',
      quest.toMap(),
      where: 'id = ?',
      whereArgs: [quest.id],
    );
  }

  static Future<void> deleteQuest(int id) async {
    final db = await database;
    await db.delete('quests', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> completeQuest(Quest quest, {bool wasOnTime = true}) async {
    final db = await database;
    final now = DateTime.now();

    // Update quest
    await db.update(
      'quests',
      {
        'is_completed': 1,
        'completed_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [quest.id],
    );

    // Insert history
    await db.insert('quest_history', {
      'quest_id': quest.id,
      'title': quest.title,
      'category': quest.category,
      'difficulty': quest.difficulty.name,
      'xp_earned': quest.xpReward,
      'coin_earned': quest.coinReward,
      'completed_at': now.toIso8601String(),
      'was_on_time': wasOnTime ? 1 : 0,
      'character_id': 1,
    });

    // Add XP & Coin to character
    final character = await getCharacter();
    int newXp = character.currentXp + quest.xpReward;
    int newTotalXp = character.totalXp + quest.xpReward;
    int newCoin = character.coin + quest.coinReward;
    int newLevel = character.level;

    // Level up check
    while (newXp >= character.xpToNextLevel) {
      newXp -= character.xpToNextLevel;
      newLevel++;
      newCoin += newLevel * 20; // bonus coin on level up
    }

    await updateCharacter(character.copyWith(
      currentXp: newXp,
      totalXp: newTotalXp,
      coin: newCoin,
      level: newLevel,
    ));

    // Update streak
    await _updateStreak();
  }

  static Future<void> _updateStreak() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query('streak', where: 'character_id = 1');
    if (maps.isEmpty) return;

    final current = maps.first;
    final lastDate = current['last_completed_date'] as String?;
    int currentStreak = current['current_streak'] as int? ?? 0;
    int longest = current['longest_streak'] as int? ?? 0;

    if (lastDate == today) return; // already counted today

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    if (lastDate == yesterday) {
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }

    if (currentStreak > longest) longest = currentStreak;

    await db.update(
      'streak',
      {
        'current_streak': currentStreak,
        'longest_streak': longest,
        'last_completed_date': today,
      },
      where: 'character_id = 1',
    );
  }

  // ==================== TRANSACTIONS ====================
  static Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }
}
