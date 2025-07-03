// lib/models/achievement.dart

import 'package:flutter/material.dart';

// Enum за ID-тата на постиженията. Така избягваме "магически" стрингове.
enum AchievementId {
  firstSession,
  regularContributor,
  heavyweightChampion,
  marathonMan,
  speedDemon,
  financier,
  workaholic,
}

class Achievement {
  final AchievementId id;
  final String name;
  final String description;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

// Централен регистър на всички възможни постижения в играта
final Map<AchievementId, Achievement> allAchievements = {
  AchievementId.firstSession: const Achievement(
    id: AchievementId.firstSession,
    name: "Първа вноска",
    description: "Запиши първата си успешна сесия.",
    icon: Icons.flag,
  ),
  AchievementId.regularContributor: const Achievement(
    id: AchievementId.regularContributor,
    name: "Редовен сътрудник",
    description: "Запиши 5 сесии.",
    icon: Icons.repeat,
  ),
  AchievementId.heavyweightChampion: const Achievement(
    id: AchievementId.heavyweightChampion,
    name: "Шампион в тежка категория",
    description: "Запиши сесия с над 1.0 кг.",
    icon: Icons.fitness_center,
  ),
  AchievementId.marathonMan: const Achievement(
    id: AchievementId.marathonMan,
    name: "Маратонец",
    description: "Прекарай повече от 10 минути в една сесия.",
    icon: Icons.timer_outlined,
  ),
  AchievementId.speedDemon: const Achievement(
    id: AchievementId.speedDemon,
    name: "Демон на скоростта",
    description: "Постигни ефективност над 150 гр./мин.",
    icon: Icons.flash_on,
  ),
  AchievementId.financier: const Achievement(
    id: AchievementId.financier,
    name: "Финансист",
    description: "Заработи общо 50 лв. от сесии.",
    icon: Icons.monetization_on,
  ),
  AchievementId.workaholic: const Achievement(
    id: AchievementId.workaholic,
    name: "Работохолик",
    description: "Запиши сесия през уикенда.",
    icon: Icons.work_history,
  ),
};