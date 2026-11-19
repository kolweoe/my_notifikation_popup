enum TransactionType { income, expense }

class TransactionModel {
  final int? id;
  final TransactionType type;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final int characterId;

  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    this.characterId = 1,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String().substring(0, 10),
      'character_id': characterId,
    };
  }

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      characterId: map['character_id'] as int? ?? 1,
    );
  }
}
