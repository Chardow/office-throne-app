// lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:office_throne/firebase_options.dart';
import 'package:office_throne/models/session_log.dart';
import 'package:office_throne/screens/main_navigation_screen.dart';
import 'package:office_throne/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- НОВА СТЪПКА: Глобална променлива ---
// Ще я инициализираме в main() и ще сме сигурни, че има стойност.
late bool showOnboarding;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- НОВА СТЪПКА: Инициализираме всичко ВЪТРЕ в main ---
  final prefs = await SharedPreferences.getInstance();
  // Проверяваме и присвояваме стойността на глобалната променлива
  showOnboarding = !(prefs.getBool('has_seen_onboarding') ?? false);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
    }
  }

  await Hive.initFlutter();
  Hive.registerAdapter(SessionLogAdapter());
  await Hive.openBox<SessionLog>('sessions');

  // Стартираме приложението без да подаваме параметри
  runApp(const OfficeThroneApp());
}

class OfficeThroneApp extends StatelessWidget {
  // Вече НЕ приемаме параметър в конструктора
  const OfficeThroneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Офис Трон',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      // Използваме глобалната променлива, за която сме сигурни, че е инициализирана
      home: showOnboarding 
            ? const OnboardingScreen() 
            : const MainNavigationScreen(),
    );
  }
}