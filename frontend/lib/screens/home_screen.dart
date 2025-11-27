import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'statistics_screen.dart';
import 'equipment_screen.dart';
import 'profile_screen.dart';
import '../providers/jump_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-load data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jumpNotifierProvider.notifier).refresh();
      ref.read(equipmentNotifierProvider.notifier).refresh();
      ref.read(profileNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const StatisticsScreen(),
      const EquipmentScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
