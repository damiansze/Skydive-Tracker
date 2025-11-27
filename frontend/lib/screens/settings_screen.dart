import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import 'profile_screen.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);
  
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final metricProvider = StateNotifierProvider<MetricNotifier, String>((ref) {
  return MetricNotifier();
});

class MetricNotifier extends StateNotifier<String> {
  MetricNotifier() : super('metric'); // 'metric' or 'imperial'
  
  void setMetric(String metric) {
    state = metric;
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    final profileAsync = ref.read(profileNotifierProvider);
    
    profileAsync.whenData((profile) async {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // TODO: Upload image to backend and get URL
        // For now, we'll just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bild-Upload wird noch implementiert'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final metric = ref.watch(metricProvider);
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          // Profile Section
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil bearbeiten'),
            subtitle: const Text('Name, Lizenz und Profilbild ändern'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
              if (result == true) {
                ref.read(profileNotifierProvider.notifier).refresh();
              }
            },
          ),
          const Divider(),
          
          // Profile Picture Upload
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Profilbild ändern'),
            subtitle: const Text('Neues Profilbild auswählen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickImage,
          ),
          const Divider(),
          
          // Metric Selection
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Metrik'),
            subtitle: Text(metric == 'metric' ? 'Metrisch (m)' : 'Imperial (ft)'),
            trailing: DropdownButton<String>(
              value: metric,
              items: const [
                DropdownMenuItem(value: 'metric', child: Text('Metrisch (m)')),
                DropdownMenuItem(value: 'imperial', child: Text('Imperial (ft)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(metricProvider.notifier).setMetric(value);
                }
              },
            ),
          ),
          const Divider(),
          
          // Theme Selection
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Design'),
            subtitle: Text(_getThemeModeText(themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Hell'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dunkel'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
        ],
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
}
