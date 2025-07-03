// lib/screens/achievements/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:office_throne/models/achievement.dart';
import 'package:office_throne/services/achievement_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievementService = AchievementService();
  late Future<Set<String>> _unlockedIdsFuture;

  @override
  void initState() {
    super.initState();
    _unlockedIdsFuture = _achievementService.getUnlockedAchievementIds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Постижения'),
      ),
      body: FutureBuilder<Set<String>>(
        future: _unlockedIdsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Грешка при зареждане на постиженията.'));
          }

          final unlockedIds = snapshot.data ?? {};
          final achievements = allAchievements.values.toList();
          
          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final isUnlocked = unlockedIds.contains(achievement.id.name);

              return ListTile(
                leading: Icon(
                  achievement.icon,
                  size: 40,
                  color: isUnlocked ? Colors.amber[700] : Colors.grey[400],
                ),
                title: Text(
                  achievement.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  achievement.description,
                  style: TextStyle(color: isUnlocked ? null : Colors.grey),
                ),
                trailing: isUnlocked
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.lock, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }
}