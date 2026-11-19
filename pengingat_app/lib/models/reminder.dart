enum Repeat { none, daily, weekly }

const kategori = ['Kuliah', 'Organisasi', 'Proyek', 'Pribadi'];

class Reminder {
  final int? id;
  final String title;
  final String note;
  final String category;
  final DateTime dateTime;
  final Repeat repeat;
  final int priority; // 0 rendah, 1 sedang, 2 tinggi
  final bool done;

  const Reminder({
    this.id,
    required this.title,
    this.note = '',
    this.category = 'Pribadi',
    required this.dateTime,
    this.repeat = Repeat.none,
    this.priority = 1,
    this.done = false,
  });

  Reminder copyWith({int? id, bool? done}) => Reminder(
        id: id ?? this.id,
        title: title,
        note: note,
        category: category,
        dateTime: dateTime,
        repeat: repeat,
        priority: priority,
        done: done ?? this.done,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'note': note,
        'category': category,
        'date_time': dateTime.millisecondsSinceEpoch,
        'repeat': repeat.index,
        'priority': priority,
        'done': done ? 1 : 0,
      };

  factory Reminder.fromMap(Map<String, Object?> m) => Reminder(
        id: m['id'] as int,
        title: m['title'] as String,
        note: m['note'] as String,
        category: m['category'] as String,
        dateTime: DateTime.fromMillisecondsSinceEpoch(m['date_time'] as int),
        repeat: Repeat.values[m['repeat'] as int],
        priority: m['priority'] as int,
        done: (m['done'] as int) == 1,
      );
}
