// lib/screens/log_session/log_session_screen.dart

import 'package:flutter/material.dart';

class LogSessionScreen extends StatefulWidget {
  final int secondsPassed;
  final double earnedMoney;

  const LogSessionScreen({
    super.key,
    required this.secondsPassed, // Изискваме тези данни да бъдат подадени
    required this.earnedMoney,
  });

  @override
  State<LogSessionScreen> createState() => _LogSessionScreenState();
}

class _LogSessionScreenState extends State<LogSessionScreen> {
  double _weightInKg = 0.5; // Начална стойност на слайдера

  // Метод за форматиране на времето (дублираме го тук за удобство)
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доклад от сесията'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Разпъни елементите по ширина
          children: [
            // Показваме данните от предишния екран
            Text(
              'Времетраене: ${_formatDuration(widget.secondsPassed)}',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Заработено: ${widget.earnedMoney.toStringAsFixed(2)} лв.',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Етикет за слайдера
            Text(
              'Тегло на товара: ${_weightInKg.toStringAsFixed(1)} кг',
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Слайдер за теглото
            Slider(
              value: _weightInKg,
              min: 0.1,
              max: 2.0,
              divisions: 19, // (2.0 - 0.1) / 0.1 = 19 стъпки
              label: _weightInKg.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _weightInKg = value;
                });
              },
            ),
            const SizedBox(height: 40),

            const Spacer(), // Заема цялото останало празно място, бутайки бутона надолу

            // Бутон за запазване
            ElevatedButton(
              onPressed: () {
                // TODO: Тук ще запазваме данните и ще затваряме екрана
                Navigator.of(context).pop(_weightInKg);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'ЗАПАЗИ В ДНЕВНИКА',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}