// lib/services/achievement_service.dart

import 'package:flutter/material.dart';
import 'package:office_throne/models/achievement.dart';
import 'package:office_throne/models/session_log.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementService {
  static const String _unlockedAchievementsKey = 'unlocked_achievements';

  // Взима списък с ID-тата на вече отключените постижения
  Future<Set<String>> getUnlockedAchievementIds() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList(_unlockedAchievementsKey) ?? [];
    return unlockedIds.toSet();
  }

  // Проверява дали трябва да се отключат нови постижения
  Future<List<Achievement>> checkAndUnlockAchievements(SessionLog newLog) async {
    final unlockedIds = await getUnlockedAchievementIds();
    final List<Achievement> newlyUnlocked = [];

    // Взимаме всички логове за обща статистика
    final allLogs = Hive.box<SessionLog>('sessions').values.toList();
    
    // --- Логика за всяко постижение ---

    // 1. Първа вноска
    if (!unlockedIds.contains(AchievementId.firstSession.name)) {
      if (allLogs.length >= 1) {
        newlyUnlocked.add(allAchievements[AchievementId.firstSession]!);
      }
    }

    // 2. Редовен сътрудник
    if (!unlockedIds.contains(AchievementId.regularContributor.name)) {
      if (allLogs.length >= 5) {
        newlyUnlocked.add(allAchievements[AchievementId.regularContributor]!);
      }
    }
    
    // 3. Шампион в тежка категория
    if (!unlockedIds.contains(AchievementId.heavyweightChampion.name)) {
      if (newLog.weightInKg >= 1.0) {
        newlyUnlocked.add(allAchievements[AchievementId.heavyweightChampion]!);
      }
    }

    // 4. Маратонец
    if (!unlockedIds.contains(AchievementId.marathonMan.name)) {
      if (newLog.durationInSeconds >= 600) { // 10 минути
        newlyUnlocked.add(allAchievements[AchievementId.marathonMan]!);
      }
    }

    // 5. Демон на скоростта (на база последната сесия)
    if (!unlockedIds.contains(AchievementId.speedDemon.name)) {
      final durationInMinutes = newLog.durationInSeconds / 60.0;
      if (durationInMinutes > 0) {
        final efficiency = (newLog.weightInKg * 1000) / durationInMinutes;
        if (efficiency >= 150) {
          newlyUnlocked.add(allAchievements[AchievementId.speedDemon]!);
        }
      }
    }

    // 6. Финансист (на база общата сума)
    if (!unlockedIds.contains(AchievementId.financier.name)) {
      final totalMoney = allLogs.fold(0.0, (sum, item) => sum + item.earnedMoney);
      if (totalMoney >= 50.0) {
        newlyUnlocked.add(allAchievements[AchievementId.financier]!);
      }
    }

    // 7. Работохолик
    if (!unlockedIds.contains(AchievementId.workaholic.name)) {
      // weekday връща 6 за събота и 7 за неделя
      if (newLog.timestamp.weekday >= 6) {
        newlyUnlocked.add(allAchievements[AchievementId.workaholic]!);
      }
    }

    // Запазваме новите отключени постижения
    if (newlyUnlocked.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final updatedIds = unlockedIds.union(newlyUnlocked.map((a) => a.id.name).toSet());
      await prefs.setStringList(_unlockedAchievementsKey, updatedIds.toList());
    }

    return newlyUnlocked;
  }
}