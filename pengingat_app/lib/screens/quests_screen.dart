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
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(minutes: 5));
    QuestDifficulty difficulty = QuestDifficulty.normal;
    RepeatType repeat = RepeatType.once;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tambah Quest',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Quest',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(DateFormat('d MMM yyyy • HH:mm')
                          .format(selectedDate)),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (d == null) return;
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (t == null) return;
                        setModalState(() {
                          selectedDate = DateTime(
                              d.year, d.month, d.day, t.hour, t.minute);
                        });
                      },
                    ),
                    DropdownButtonFormField<QuestDifficulty>(
                      value: difficulty,
                      decoration: const InputDecoration(labelText: 'Kesulitan'),
                      items: const [
                        DropdownMenuItem(
                            value: QuestDifficulty.easy, child: Text('Easy')),
                        DropdownMenuItem(
                            value: QuestDifficulty.normal,
                            child: Text('Normal')),
                        DropdownMenuItem(
                            value: QuestDifficulty.hard, child: Text('Hard')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => difficulty = v!),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RepeatType>(
                      value: repeat,
                      decoration: const InputDecoration(labelText: 'Ulangi'),
                      items: const [
                        DropdownMenuItem(
                            value: RepeatType.once, child: Text('Sekali')),
                        DropdownMenuItem(
                            value: RepeatType.daily, child: Text('Harian')),
                        DropdownMenuItem(
                            value: RepeatType.weekly, child: Text('Mingguan')),
                      ],
                      onChanged: (v) => setModalState(() => repeat = v!),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          Navigator.pop(context, true);
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    final quest = Quest(
      title: titleController.text.trim(),
      dateTime: selectedDate,
      difficulty: difficulty,
      xpReward: Quest.getXpByDifficulty(difficulty),
      coinReward: Quest.getCoinByDifficulty(difficulty),
      repeatType: repeat,
      isAlarmEnabled: true,
    );

    final id = await DatabaseService.insertQuest(quest);
    final saved = quest.copyWith(id: id);
    await NotificationService.scheduleQuest(saved);
    _load();
  }

  Future<void> _complete(Quest quest) async {
    await NotificationService.cancel(quest.id!);
    await DatabaseService.completeQuest(quest);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '+${quest.xpReward} XP  +${quest.coinReward} Coin'),
          backgroundColor: Colors.green,
        ),
      );
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
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quests.isEmpty
              ? const Center(child: Text('Belum ada quest'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _quests.length,
                  itemBuilder: (_, i) {
                    final q = _quests[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(q.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${q.category} • ${q.difficulty.name} • ${DateFormat('d MMM HH:mm').format(q.dateTime)}\n+${q.xpReward} XP  +${q.coinReward} Coin',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () => _complete(q),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
