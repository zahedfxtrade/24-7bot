import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/data_service.dart';
import 'guards_screen.dart';
import 'attendance_screen.dart';
import 'payments_screen.dart';
import 'reports_screen.dart';
import 'tiffin_screen.dart';
import 'backup_restore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _loading = true;

  final List<Widget> _screens = [
    const GuardsScreen(),
    const AttendanceScreen(),
    const TiffinScreen(),
    const PaymentsScreen(),
    const ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DataService().load();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.navyBlue)),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'Guards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lunch_dining_outlined),
              activeIcon: Icon(Icons.lunch_dining),
              label: 'Tiffin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
        ),
      ),
      // Floating backup button visible on all tabs
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FloatingActionButton.small(
          heroTag: 'backup_fab',
          backgroundColor: AppColors.navyBlue,
          foregroundColor: AppColors.white,
          tooltip: 'Backup & Restore',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
          ),
          child: const Icon(Icons.backup_outlined, size: 20),
        ),
      ),
    );
  }
}
