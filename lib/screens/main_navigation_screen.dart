// lib/screens/main_navigation_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:office_throne/models/session_log.dart';
import 'package:office_throne/screens/home/home_screen.dart';
import 'package:office_throne/screens/leaderboard/leaderboard_screen.dart';
import 'package:office_throne/screens/settings/settings_screen.dart';
import 'package:office_throne/screens/stats/stats_screen.dart';
import 'package:office_throne/services/achievement_service.dart';
import 'package:office_throne/models/achievement.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final AchievementService _achievementService = AchievementService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAuditRequest();
    });
  }

  // --- ЛОГИКА ЗА СИСТЕМАТА ЗА ПРАВОСЪДИЕ ---

  Future<void> _checkForAuditRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('leaderboard').doc(user.uid);
    final snapshot = await userDocRef.get();

    if (snapshot.exists && (snapshot.data()?['audit_required'] == true)) {
      if (mounted) _showAuditDialog(userDocRef);
    }
  }

  void _showAuditDialog(DocumentReference userDocRef) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Заявка за одит на акаунта'),
        content: const SingleChildScrollView(
          child: Text(
            "Вашият акаунт е маркиран за проверка поради необичайна активност, докладвана от общността. За да поддържаме класацията честна, молим Ви да предоставите анонимизиран лог на Вашите сесии за преглед.\n\n"
            "Ако приемете, логовете Ви ще бъдат изпратени за еднократен преглед.\n\n"
            "Ако откажете, резултатът Ви в класацията ще бъде нулиран и ще бъдете временно отстранен за 30 дни.",
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('ОТХВЪРЛЯМ'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _handleAuditRejection(userDocRef);
            },
          ),
          TextButton(
            child: const Text('ПРИЕМАМ'),
            onPressed: () {
              Navigator.of(context).pop();
              _handleAuditAcceptance(userDocRef);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuditAcceptance(DocumentReference userDocRef) async {
    final logs = Hive.box<SessionLog>('sessions').values.toList();
    final batch = FirebaseFirestore.instance.batch();

    for (var log in logs) {
      final logDocRef = userDocRef.collection('session_audit_logs').doc();
      batch.set(logDocRef, {
        'timestamp': log.timestamp,
        'durationInSeconds': log.durationInSeconds,
        'earnedMoney': log.earnedMoney,
        'weightInKg': log.weightInKg,
      });
    }

    batch.update(userDocRef, {
      'audit_required': FieldValue.delete(),
      'audit_in_progress': true,
    });

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Логовете са изпратени за преглед. Благодарим!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _handleAuditRejection(DocumentReference userDocRef) async {
    final banEndDate = DateTime.now().add(const Duration(days: 30));
    await userDocRef.set({
      'audit_required': FieldValue.delete(),
      'score': 0,
      'banned_until': Timestamp.fromDate(banEndDate),
      'is_banned': true,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Резултатът Ви е нулиран. Моля, спазвайте правилата.'), backgroundColor: Colors.orange),
      );
    }
  }

  // --- ЛОГИКА ЗА СЪХРАНЯВАНЕ НА СЕСИИ И РЕЗУЛТАТ ---

  void _addLog(SessionLog log) async {
    try {
      final box = Hive.box<SessionLog>('sessions');
      await box.add(log);
    } catch (e) {
      print('Error saving log to Hive: $e');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final allLocalLogs = Hive.box<SessionLog>('sessions').values.toList();
    final double totalWeightInGrams = allLocalLogs.fold(0.0, (sum, item) => sum + item.weightInKg) * 1000;
    final double totalDurationInSeconds = allLocalLogs.fold(0.0, (sum, item) => sum + item.durationInSeconds);
    final double totalDurationInMinutes = totalDurationInSeconds / 60.0;
    
    final double score = totalDurationInMinutes > 0 ? totalWeightInGrams / totalDurationInMinutes : 0.0;
    
    try {
      final leaderboardDocRef = FirebaseFirestore.instance.collection('leaderboard').doc(user.uid);
      await leaderboardDocRef.set({
        'score': score,
        'last_updated': FieldValue.serverTimestamp(),
        'is_banned': false,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating leaderboard in Firestore: $e');
    }
      final newlyUnlocked = await _achievementService.checkAndUnlockAchievements(log);

  // Показваме нотификация за всяко ново постижение
  if (newlyUnlocked.isNotEmpty && mounted) {
    for (var achievement in newlyUnlocked) {
      // Изчакваме малко между всяка нотификация, ако са повече от една
      await Future.delayed(const Duration(milliseconds: 500));
      _showAchievementUnlocked(achievement);
    }
  }
  }

  // --- BUILD МЕТОД ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<SessionLog>('sessions').listenable(),
        builder: (context, box, _) {
          final logs = box.values.toList().cast<SessionLog>();
          final List<Widget> screens = [
            HomeScreen(onLogAdded: _addLog),
            StatsScreen(logs: logs),
            const LeaderboardScreen(),
            const SettingsScreen(),
          ];
          return IndexedStack(index: _selectedIndex, children: screens);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.chair_rounded), label: 'Трон'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Статистики'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Класация'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
  void _showAchievementUnlocked(Achievement achievement) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.amber[700],
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(achievement.icon, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ПОСТИЖЕНИЕ ОТКЛЮЧЕНО!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  achievement.name,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

}