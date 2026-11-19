import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/quests_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  await NotificationService.init();
  await DatabaseService.database; // init DB early
  runApp(const RemindoApp());
}

class RemindoApp extends StatelessWidget {
  const RemindoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remindo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7C3AED),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    QuestsScreen(),
    // Placeholder for center (+) - handled by FAB
    SizedBox(),
    // Wallet placeholder
    Center(child: Text('Wallet (Coming Soon)')),
    // Hero placeholder
    Center(child: Text('Hero (Coming Soon)')),
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Quests and trigger add
          setState(() => _currentIndex = 1);
        },
        backgroundColor: const Color(0xFF7C3AED),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', 0),
              _navItem(Icons.assignment_rounded, 'Quests', 1),
              const SizedBox(width: 48), // space for FAB
              _navItem(Icons.account_balance_wallet_rounded, 'Wallet', 3),
              _navItem(Icons.person_rounded, 'Hero', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF7C3AED) : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? const Color(0xFF7C3AED) : Colors.grey,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
