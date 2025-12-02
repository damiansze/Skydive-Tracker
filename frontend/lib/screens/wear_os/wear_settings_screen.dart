import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/wear_os/wear_scaffold.dart';
import '../settings_screen.dart';

/// Settings screen for WearOS
class WearSettingsScreen extends ConsumerWidget {
  const WearSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final metric = ref.watch(metricProvider);
    final timeFormat = ref.watch(timeFormatProvider);

    return WearScaffold(
      title: 'Einstellungen',
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          // Theme
          _buildSettingCard(
            context,
            icon: Icons.brightness_6,
            title: 'Design',
            value: _getThemeModeText(themeMode),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
          const SizedBox(height: 8),
          
          // Metric
          _buildSettingCard(
            context,
            icon: Icons.straighten,
            title: 'Einheit',
            value: metric == 'metric' ? 'Metrisch' : 'Imperial',
            onTap: () => _showMetricDialog(context, ref, metric),
          ),
          const SizedBox(height: 8),
          
          // Time Format
          _buildSettingCard(
            context,
            icon: Icons.access_time,
            title: 'Zeitformat',
            value: timeFormat == '24h' ? '24h' : '12h',
            onTap: () => _showTimeFormatDialog(context, ref, timeFormat),
          ),
          const SizedBox(height: 16),
          
          // Info
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Skydive Tracker',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'v1.0.0 WearOS',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.dark:
        return 'Dunkel';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              context,
              title: 'System',
              selected: current == ThemeMode.system,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _buildDialogOption(
              context,
              title: 'Hell',
              selected: current == ThemeMode.light,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _buildDialogOption(
              context,
              title: 'Dunkel',
              selected: current == ThemeMode.dark,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricDialog(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              context,
              title: 'Metrisch (m)',
              selected: current == 'metric',
              onTap: () {
                ref.read(metricProvider.notifier).setMetric('metric');
                Navigator.pop(context);
              },
            ),
            _buildDialogOption(
              context,
              title: 'Imperial (ft)',
              selected: current == 'imperial',
              onTap: () {
                ref.read(metricProvider.notifier).setMetric('imperial');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeFormatDialog(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
              context,
              title: '24 Stunden',
              selected: current == '24h',
              onTap: () {
                ref.read(timeFormatProvider.notifier).setTimeFormat('24h');
                Navigator.pop(context);
              },
            ),
            _buildDialogOption(
              context,
              title: '12 Stunden (AM/PM)',
              selected: current == '12h',
              onTap: () {
                ref.read(timeFormatProvider.notifier).setTimeFormat('12h');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption(
    BuildContext context, {
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

