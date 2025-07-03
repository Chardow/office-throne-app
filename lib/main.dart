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
import 'package:provider/provider.dart';
import 'package:office_throne/providers/theme_provider.dart';

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
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const OfficeThroneApp(),
    ),
  );
}

class OfficeThroneApp extends StatelessWidget {
  // Вече НЕ приемаме параметър в конструктора
  const OfficeThroneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Офис Трон',
          // Дефинираме и светла, и тъмна тема
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.brown,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          // Избираме коя тема да се използва на база стойността от провайдъра
          themeMode: themeProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          
          home: showOnboarding 
                ? const OnboardingScreen() 
                : const MainNavigationScreen(),
        );
      },
    );
  }
}