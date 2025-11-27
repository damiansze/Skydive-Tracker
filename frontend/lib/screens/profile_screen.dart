import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseTypeController = TextEditingController();
  
  final ProfileService _profileService = ProfileService();
  Profile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final profile = await _profileService.getProfile();
    setState(() {
      _profile = profile;
      if (profile != null) {
        _nameController.text = profile.name;
        _licenseNumberController.text = profile.licenseNumber ?? '';
        _licenseTypeController.text = profile.licenseType ?? '';
      }
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _profileService.createOrUpdateProfile(
        name: _nameController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim().isEmpty
            ? null
            : _licenseNumberController.text.trim(),
        licenseType: _licenseTypeController.text.trim().isEmpty
            ? null
            : _licenseTypeController.text.trim(),
      );

      setState(() {
        _isEditing = false;
      });

      await _loadProfile();

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
  void dispose() {
    _nameController.dispose();
    _licenseNumberController.dispose();
    _licenseTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                  _profile?.name.isNotEmpty == true
                      ? _profile!.name[0].toUpperCase()
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
            if (_profile != null)
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
                                '${_profile!.totalJumps}',
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
  }
}
