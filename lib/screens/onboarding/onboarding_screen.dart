// lib/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:office_throne/screens/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Метод, който се извиква, когато потребителят завърши обиколката
  void _onIntroEnd(context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: TextStyle(fontSize: 19.0),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Добре дошъл в Офис Трон!",
          body: "Превърни времето, прекарано в тоалетната, в измерима стойност и се състезавай с колеги и приятели!",
          image: const Icon(Icons.castle_rounded, size: 150, color: Colors.brown),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Засичай и печели",
          body: "Просто натисни 'Започни сесия'. Приложението ще изчисли колко 'печелиш' на база твоята часова ставка.",
          image: const Icon(Icons.timer_sharp, size: 150, color: Colors.blue),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Изкачи се в класацията",
          body: "Твоята ефективност (гр./мин) те изпраща в глобалната класация. Бъди най-ефективният рицар!",
          image: const Icon(Icons.shield_rounded, size: 150, color: Colors.amber),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Първо, настройка!",
          body: "За да започнеш, отиди в 'Настройки' и въведи своята часова ставка и потребителско име.",
          image: const Icon(Icons.settings, size: 150, color: Colors.grey),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // Позволяваме и пропускане
      showSkipButton: true,
      skip: const Text('Пропусни', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Към трона!', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}