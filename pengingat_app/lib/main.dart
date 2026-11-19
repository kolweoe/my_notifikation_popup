import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'models/reminder.dart';
import 'services/db_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  await NotificationService.init();
  runApp(const PengingatApp());
}

class PengingatApp extends StatelessWidget {
  const PengingatApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Pengingat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Reminder> _items = [];
  final _fmt = DateFormat('EEE, d MMM yyyy • HH:mm', 'id');

  @override
  void initState() {
    super.initState();
    NotificationService.requestPermissions();
    _load();
  }

  Future<void> _load() async {
    final data = await DbService.all();
    if (mounted) setState(() => _items = data);
  }

  Future<void> _add() async {
    final r = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormSheet(),
    );
    if (r == null) return;
    final id = await DbService.insert(r);
    await NotificationService.schedule(r.copyWith(id: id));
    _load();
  }

  Future<void> _toggle(Reminder r) async {
    final done = !r.done;
    await DbService.setDone(r.id!, done);
    if (done) {
      await NotificationService.cancel(r.id!);
    } else {
      await NotificationService.schedule(r.copyWith(done: false));
    }
    _load();
  }

  Future<void> _remove(Reminder r) async {
    await NotificationService.cancel(r.id!);
    await DbService.delete(r.id!);
    _load();
  }

  Color _prio(int p) =>
      [Colors.green, Colors.orange, Colors.red][p];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pengingat')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            icon: const Icon(Icons.add_alarm),
            label: const Text('Tambah')),
        body: _items.isEmpty
            ? const Center(child: Text('Belum ada pengingat'))
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final r = _items[i];
                  return Dismissible(
                    key: ValueKey(r.id),
                    background: Container(color: Colors.red),
                    onDismissed: (_) => _remove(r),
                    child: ListTile(
                      leading: Checkbox(
                          value: r.done, onChanged: (_) => _toggle(r)),
                      title: Text(r.title,
                          style: TextStyle(
                              decoration: r.done
                                  ? TextDecoration.lineThrough
                                  : null)),
                      subtitle: Text(
                          '${r.category} • ${_fmt.format(r.dateTime)}'
                          '${r.repeat == Repeat.none ? '' : ' • ${r.repeat.name}'}'),
                      trailing: Icon(Icons.circle,
                          size: 12, color: _prio(r.priority)),
                    ),
                  );
                },
              ),
      );
}

class _FormSheet extends StatefulWidget {
  const _FormSheet();
  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  String _cat = kategori.first;
  Repeat _repeat = Repeat.none;
  int _prio = 1;
  DateTime _when = DateTime.now().add(const Duration(minutes: 5));

  Future<void> _pick() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _when,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul')),
            TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Catatan')),
            const SizedBox(height: 8),
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(DateFormat('d MMM yyyy • HH:mm').format(_when)),
                onTap: _pick),
            DropdownButtonFormField<String>(
                value: _cat,
                items: kategori
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _cat = v!),
                decoration: const InputDecoration(labelText: 'Kategori')),
            DropdownButtonFormField<Repeat>(
                value: _repeat,
                items: const [
                  DropdownMenuItem(value: Repeat.none, child: Text('Sekali')),
                  DropdownMenuItem(value: Repeat.daily, child: Text('Harian')),
                  DropdownMenuItem(
                      value: Repeat.weekly, child: Text('Mingguan')),
                ],
                onChanged: (v) => setState(() => _repeat = v!),
                decoration: const InputDecoration(labelText: 'Ulangi')),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Rendah')),
                ButtonSegment(value: 1, label: Text('Sedang')),
                ButtonSegment(value: 2, label: Text('Tinggi')),
              ],
              selected: {_prio},
              onSelectionChanged: (s) => setState(() => _prio = s.first),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (_title.text.trim().isEmpty) return;
                Navigator.pop(
                    context,
                    Reminder(
                        title: _title.text.trim(),
                        note: _note.text.trim(),
                        category: _cat,
                        dateTime: _when,
                        repeat: _repeat,
                        priority: _prio));
              },
              child: const Text('Simpan'),
            ),
          ]),
        ),
      );
}
