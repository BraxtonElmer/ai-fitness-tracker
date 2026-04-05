import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/food_scan_screen.dart';
import 'screens/health_dashboard_screen.dart';

void main() {
  runApp(const FitCoreApp());
}

class FitCoreApp extends StatelessWidget {
  const FitCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitCore AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    FoodScanScreen(),
    HealthDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(LucideIcons.home, 0),
                _buildNavItem(LucideIcons.scan, 1),
                _buildNavItem(LucideIcons.activity, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Icon(
          icon,
          size: 20,
          color: isActive ? AppColors.accent : AppColors.mutedText,
        ),
      ),
    );
  }
}
