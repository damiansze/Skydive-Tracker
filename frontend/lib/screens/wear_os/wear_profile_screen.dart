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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            // Profile Picture - smaller
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: profile.profilePictureUrl != null
                  ? NetworkImage(ApiConfig.buildAssetUrl(profile.profilePictureUrl!))
                  : null,
              child: profile.profilePictureUrl == null
                  ? Icon(Icons.person, size: 18, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // License + Jumps in one row
                  Row(
                    children: [
                      if (profile.licenseType != null) ...[
                        Text(
                          profile.licenseType!,
                          style: const TextStyle(fontSize: 9, color: Colors.white70),
                        ),
                        const Text(' • ', style: TextStyle(fontSize: 9, color: Colors.white70)),
                      ],
                      Text(
                        '${profile.totalJumps} Sprünge',
                        style: const TextStyle(fontSize: 9, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 20,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kein Profil', style: TextStyle(fontSize: 10)),
                Text('In App erstellen', style: TextStyle(fontSize: 8)),
              ],
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
        // Section Title - compact
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              const Text(
                'Achievements',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${unlocked.length}/${achievements.length}',
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        
        // Unlocked Achievements
        if (unlocked.isNotEmpty) ...[
          _buildAchievementGrid(context, unlocked, true),
          const SizedBox(height: 4),
        ],
        
        // Locked Achievements
        if (locked.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              'Gesperrt',
              style: TextStyle(fontSize: 8, color: Colors.grey),
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
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return GestureDetector(
          onTap: () => _showAchievementDetail(context, achievement),
          child: Card(
            elevation: unlocked ? 1 : 0,
            color: unlocked ? null : Colors.grey[300],
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.5,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
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
        contentPadding: const EdgeInsets.all(10),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              achievement.description,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
            ),
            if (!achievement.unlocked && achievement.requirement != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  achievement.requirement!,
                  style: const TextStyle(fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('OK', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

