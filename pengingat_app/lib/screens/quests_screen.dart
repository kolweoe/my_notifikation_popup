import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/quest.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Quest> _quests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await DatabaseService.getAllQuests(onlyActive: true);
    if (mounted) {
      setState(() {
        _quests = data;
        _loading = false;
      });
    }
  }

  Future<void> _addQuest() async {
    final result = await showModalBottomSheet<Quest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddQuestSheet(),
    );

    if (result == null) return;

    try {
      final id = await DatabaseService.insertQuest(result);
      final saved = result.copyWith(id: id);

      final scheduled = await NotificationService.scheduleQuest(saved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(scheduled
                ? 'Quest disimpan & notifikasi dijadwalkan'
                : 'Quest disimpan (notifikasi gagal dijadwalkan)'),
            backgroundColor: scheduled ? Colors.green : Colors.orange,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan quest: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _complete(Quest quest) async {
    try {
      await NotificationService.cancel(quest.id!);
      await DatabaseService.completeQuest(quest);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('+${quest.xpReward} XP  +${quest.coinReward} Coin'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan quest: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E8FF),
      appBar: AppBar(
        title: const Text('Quest Board'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Epic'),
            Tab(text: 'Timed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuest,
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quests.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada quest.\nTekan tombol + untuk menambah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: _quests.length,
                  itemBuilder: (_, i) {
                    final q = _quests[i];
                    final color = q.difficulty == QuestDifficulty.hard
                        ? Colors.red
                        : q.difficulty == QuestDifficulty.normal
                            ? Colors.orange
                            : Colors.green;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 6,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(q.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${q.difficulty.name.toUpperCase()} • ${DateFormat('d MMM HH:mm').format(q.dateTime)}\n+${q.xpReward} XP  +${q.coinReward} Coin',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 28),
                          onPressed: () => _complete(q),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Separate widget supaya form lebih ringan & tidak lag
class _AddQuestSheet extends StatefulWidget {
  const _AddQuestSheet();

  @override
  State<_AddQuestSheet> createState() => _AddQuestSheetState();
}

class _AddQuestSheetState extends State<_AddQuestSheet> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 5));
  QuestDifficulty _difficulty = QuestDifficulty.normal;
  RepeatType _repeat = RepeatType.once;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (t == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;
    if (_saving) return;

    setState(() => _saving = true);

    final quest = Quest(
      title: _titleController.text.trim(),
      dateTime: _selectedDate,
      difficulty: _difficulty,
      xpReward: Quest.getXpByDifficulty(_difficulty),
      coinReward: Quest.getCoinByDifficulty(_difficulty),
      repeatType: _repeat,
      isAlarmEnabled: true,
    );

    Navigator.pop(context, quest);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tambah Quest',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Judul Quest',
                hintText: 'Contoh: Kerjakan tugas Algoritma',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_rounded),
              ),
            ),
            const SizedBox(height: 14),
            // Date & Time
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Waktu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.schedule_rounded),
                ),
                child: Text(
                  DateFormat('EEE, d MMM yyyy • HH:mm', 'id')
                      .format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Difficulty
            const Text('Tingkat Kesulitan',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                _diffChip('Easy', QuestDifficulty.easy, Colors.green),
                const SizedBox(width: 8),
                _diffChip('Normal', QuestDifficulty.normal, Colors.orange),
                const SizedBox(width: 8),
                _diffChip('Hard', QuestDifficulty.hard, Colors.red),
              ],
            ),
            const SizedBox(height: 14),
            // Repeat
            const Text('Pengulangan',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                _repeatChip('Sekali', RepeatType.once),
                const SizedBox(width: 8),
                _repeatChip('Harian', RepeatType.daily),
                const SizedBox(width: 8),
                _repeatChip('Mingguan', RepeatType.weekly),
              ],
            ),
            const SizedBox(height: 20),
            // Reward preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Reward: +${Quest.getXpByDifficulty(_difficulty)} XP  •  +${Quest.getCoinByDifficulty(_difficulty)} Coin',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Quest',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diffChip(String label, QuestDifficulty value, Color color) {
    final selected = _difficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? color : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _repeatChip(String label, RepeatType value) {
    final selected = _repeat == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _repeat = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF7C3AED).withOpacity(0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF7C3AED) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? const Color(0xFF7C3AED)
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
