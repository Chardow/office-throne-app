// lib/models/session_log.dart

import 'package:hive/hive.dart';

part 'session_log.g.dart'; // Този файл ще бъде генериран

@HiveType(typeId: 0) // Уникално ID за този тип
class SessionLog {
  @HiveField(0) // Уникално ID за това поле
  final DateTime timestamp;

  @HiveField(1)
  final int durationInSeconds;

  @HiveField(2)
  final double earnedMoney;

  @HiveField(3)
  final double weightInKg;

  SessionLog({
    required this.timestamp,
    required this.durationInSeconds,
    required this.earnedMoney,
    required this.weightInKg,
  });
}