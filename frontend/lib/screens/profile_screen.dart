import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseTypeController = TextEditingController();
  
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _licenseNumberController.dispose();
    _licenseTypeController.dispose();
    super.dispose();
  }

  void _loadProfileData(Profile? profile) {
    if (profile != null) {
      _nameController.text = profile.name;
      _licenseNumberController.text = profile.licenseNumber ?? '';
      _licenseTypeController.text = profile.licenseType ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final existingProfile = ref.read(profileNotifierProvider).value;
    final profile = Profile(
      id: existingProfile?.id ?? '',
      name: _nameController.text.trim(),
      licenseNumber: _licenseNumberController.text.trim().isEmpty
          ? null
          : _licenseNumberController.text.trim(),
      licenseType: _licenseTypeController.text.trim().isEmpty
          ? null
          : _licenseTypeController.text.trim(),
      totalJumps: existingProfile?.totalJumps ?? 0,
      createdAt: existingProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(profileNotifierProvider.notifier).createOrUpdateProfile(profile);
      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return profileAsync.when(
      data: (profile) {
        // Load data into controllers when profile changes
        if (profile != null && !_isEditing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProfileData(profile);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveProfile,
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Icon
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      profile?.name.isNotEmpty == true
                          ? profile!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte geben Sie einen Namen ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // License Number
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Lizenznummer',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                
                // License Type
                TextFormField(
                  controller: _licenseTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Lizenztyp',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_membership),
                    hintText: 'z.B. A-Lizenz, B-Lizenz',
                  ),
                  enabled: _isEditing,
                ),
                const SizedBox(height: 24),
                
                // Statistics Card
                if (profile != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistiken',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${profile.totalJumps}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Gesamte Sprünge'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Fehler: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(profileNotifierProvider.notifier).refresh();
                },
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
