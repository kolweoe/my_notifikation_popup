import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reminder.dart';

class DbService {
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'pengingat.db'),
      version: 1,
      onCreate: (db, v) => db.execute('''
        CREATE TABLE reminders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          note TEXT NOT NULL,
          category TEXT NOT NULL,
          date_time INTEGER NOT NULL,
          repeat INTEGER NOT NULL,
          priority INTEGER NOT NULL,
          done INTEGER NOT NULL
        )'''),
    );
    return _db!;
  }

  static Future<int> insert(Reminder r) async =>
      (await _database).insert('reminders', r.toMap());

  static Future<void> setDone(int id, bool done) async =>
      (await _database).update('reminders', {'done': done ? 1 : 0},
          where: 'id = ?', whereArgs: [id]);

  static Future<void> delete(int id) async =>
      (await _database).delete('reminders', where: 'id = ?', whereArgs: [id]);

  static Future<List<Reminder>> all() async {
    final rows = await (await _database)
        .query('reminders', orderBy: 'done ASC, date_time ASC');
    return rows.map(Reminder.fromMap).toList();
  }
}
