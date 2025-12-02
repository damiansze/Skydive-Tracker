import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profile.dart';
import '../../models/achievement.dart';
import '../../providers/profile_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/wear_os/wear_scaffold.dart';
import '../../config/api_config.dart';

/// Profile and achievements screen for WearOS
class WearProfileScreen extends ConsumerWidget {
  const WearProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final achievementsAsync = ref.watch(achievementProvider);

    return WearScaffold(
      title: 'Profil',
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          // Profile Section
          profileAsync.when(
            data: (profile) => profile != null 
                ? _buildProfileCard(context, profile)
                : _buildNoProfile(context),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e', style: const TextStyle(fontSize: 10))),
          ),
          const SizedBox(height: 12),
          
          // Achievements Section
          achievementsAsync.when(
            data: (achievements) => _buildAchievements(context, achievements),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Profile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage: profile.profilePictureUrl != null
                  ? NetworkImage(ApiConfig.buildAssetUrl(profile.profilePictureUrl!))
                  : null,
              child: profile.profilePictureUrl == null
                  ? Icon(Icons.person, size: 28, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            const SizedBox(height: 8),
            
            // Name
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            
            // License
            if (profile.licenseType != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  profile.licenseType!,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            
            // Total Jumps
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.paragliding, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  '${profile.totalJumps} Sprünge',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProfile(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.person_outline,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            const Text(
              'Kein Profil',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              'In App erstellen',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, List<Achievement> achievements) {
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final locked = achievements.where((a) => !a.unlocked).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              const Text(
                'Achievements',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${unlocked.length}/${achievements.length}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        
        // Unlocked Achievements
        if (unlocked.isNotEmpty) ...[
          _buildAchievementGrid(context, unlocked, true),
          const SizedBox(height: 8),
        ],
        
        // Locked Achievements
        if (locked.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Noch nicht erreicht',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          _buildAchievementGrid(context, locked, false),
        ],
      ],
    );
  }

  Widget _buildAchievementGrid(BuildContext context, List<Achievement> achievements, bool unlocked) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return GestureDetector(
          onTap: () => _showAchievementDetail(context, achievement),
          child: Card(
            elevation: unlocked ? 2 : 0,
            color: unlocked ? null : Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.title,
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            if (!achievement.unlocked && achievement.requirement != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  achievement.requirement!,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

