import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/wear_os/wear_scaffold.dart';
import 'wear_add_jump_screen.dart';
import 'wear_statistics_screen.dart';
import 'wear_profile_screen.dart';
import 'wear_settings_screen.dart';

/// Home screen for WearOS with circular menu
class WearHomeScreen extends ConsumerWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    // Smaller radius and button size for WearOS
    final radius = (size.width < size.height ? size.width : size.height) * 0.28;
    const buttonSize = 40.0;
    const buttonHalf = buttonSize / 2;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Center logo/title - smaller for WearOS
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.paragliding,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    'Skydive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Top - New Jump
            _buildMenuButton(
              context,
              position: Offset(centerX - buttonHalf, centerY - radius - buttonHalf),
              icon: Icons.add,
              label: 'Neu',
              color: Colors.green,
              buttonSize: buttonSize,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearAddJumpScreen()),
              ),
            ),
            
            // Right - Statistics
            _buildMenuButton(
              context,
              position: Offset(centerX + radius - buttonHalf, centerY - buttonHalf),
              icon: Icons.bar_chart,
              label: 'Stats',
              color: Colors.blue,
              buttonSize: buttonSize,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearStatisticsScreen()),
              ),
            ),
            
            // Bottom - Profile/Achievements
            _buildMenuButton(
              context,
              position: Offset(centerX - buttonHalf, centerY + radius - buttonHalf),
              icon: Icons.emoji_events,
              label: 'Profil',
              color: Colors.orange,
              buttonSize: buttonSize,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearProfileScreen()),
              ),
            ),
            
            // Left - Settings
            _buildMenuButton(
              context,
              position: Offset(centerX - radius - buttonHalf, centerY - buttonHalf),
              icon: Icons.settings,
              label: 'Setup',
              color: Colors.grey,
              buttonSize: buttonSize,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearSettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required Offset position,
    required IconData icon,
    required String label,
    required Color color,
    required double buttonSize,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WearButton(
            onPressed: onTap,
            backgroundColor: color,
            size: buttonSize,
            child: Icon(icon, color: Colors.white, size: buttonSize * 0.45),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }
}

