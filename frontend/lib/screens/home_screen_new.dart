import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement.dart';
import '../config/api_config.dart';

class HomeScreenNew extends ConsumerWidget {
  const HomeScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final achievementsAsync = ref.watch(achievementProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(profileNotifierProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              profileAsync.when(
                data: (profile) => profile != null 
                    ? _buildProfileSection(context, profile)
                    : _buildEmptyProfileSection(context),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Fehler beim Laden: $error'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Achievements Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    achievementsAsync.when(
                      data: (achievements) => _buildAchievementsGrid(context, achievements),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Fehler beim Laden: $error'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, Profile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: profile.profilePictureUrl != null
                ? NetworkImage(
                    profile.profilePictureUrl!.startsWith('http')
                        ? profile.profilePictureUrl!
                        : '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}${profile.profilePictureUrl!}',
                  )
                : null,
            onBackgroundImageError: profile.profilePictureUrl != null
                ? (exception, stackTrace) {
                    // Handle image loading errors gracefully
                  }
                : null,
            child: profile.profilePictureUrl == null
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // License Info
          if (profile.licenseType != null || profile.licenseNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile.licenseType != null) ...[
                    Text(
                      profile.licenseType!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile.licenseNumber != null) const Text(
                      ' • ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                  if (profile.licenseNumber != null)
                    Text(
                      profile.licenseNumber!,
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyProfileSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kein Profil vorhanden',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bitte erstelle ein Profil in den Einstellungen',
            style: TextStyle(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context, List<Achievement> achievements) {
    final unlockedAchievements = achievements.where((a) => a.unlocked).toList();
    final lockedAchievements = achievements.where((a) => !a.unlocked).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unlockedAchievements.isNotEmpty) ...[
          const Text(
            'Freigeschaltet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: unlockedAchievements.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(context, unlockedAchievements[index], true);
            },
          ),
          const SizedBox(height: 24),
        ],
        
        if (lockedAchievements.isNotEmpty) ...[
          const Text(
            'Noch nicht freigeschaltet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: lockedAchievements.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(context, lockedAchievements[index], false);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement, bool unlocked) {
    return Card(
      elevation: unlocked ? 4 : 1,
      color: unlocked ? null : Colors.grey[200],
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.7,
        child: InkWell(
          onTap: unlocked ? null : () {
            // Show requirement info in a dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Text(achievement.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (achievement.requirement != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'So erreichst du es:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.requirement!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Schließen'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? null : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!unlocked && achievement.requirement != null) ...[
                  const SizedBox(height: 4),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
