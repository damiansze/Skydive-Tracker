import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../providers/database_provider.dart';
import '../services/freefall_detection_service.dart';
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

final timeFormatProvider = StateNotifierProvider<TimeFormatNotifier, String>((ref) {
  return TimeFormatNotifier();
});

class TimeFormatNotifier extends StateNotifier<String> {
  TimeFormatNotifier() : super('24h'); // '24h' or '12h'
  
  void setTimeFormat(String format) {
    state = format;
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
      if (profile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bitte erstelle zuerst ein Profil'),
            ),
          );
        }
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          final api = ref.read(apiServiceProvider);
          final pictureUrl = await api.uploadProfilePicture(image.path);
          
          // Update profile with new picture URL
          final updatedProfile = profile.copyWith(profilePictureUrl: pictureUrl);
          await ref.read(profileNotifierProvider.notifier).updateProfile(updatedProfile);
          
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profilbild erfolgreich hochgeladen'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Hochladen: $e'),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final metric = ref.watch(metricProvider);

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
            subtitle: const Text('Name und Lizenz ändern'),
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
          const Divider(),
          
          // Time Format Selection
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Uhrzeitformat'),
            subtitle: Text(ref.watch(timeFormatProvider) == '24h' ? '24 Stunden' : '12 Stunden (AM/PM)'),
            trailing: DropdownButton<String>(
              value: ref.watch(timeFormatProvider),
              items: const [
                DropdownMenuItem(
                  value: '24h',
                  child: Text('24 Stunden'),
                ),
                DropdownMenuItem(
                  value: '12h',
                  child: Text('12 Stunden (AM/PM)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(timeFormatProvider.notifier).setTimeFormat(value);
                }
              },
            ),
          ),
          const Divider(),
          
          // Freefall Detection Simulation Toggle (Debug/Testing)
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('Freefall-Simulation'),
            subtitle: const Text('Simulierte Sensordaten für Tests verwenden'),
            trailing: Switch(
              value: FreefallDetectionService.useSimulatedSensors,
              onChanged: (value) {
                FreefallDetectionService.setUseSimulation(value);
                setState(() {}); // Rebuild to update UI
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                        ? 'Simulation aktiviert - Neustart der App empfohlen'
                        : 'Simulation deaktiviert - Neustart der App empfohlen',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
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
