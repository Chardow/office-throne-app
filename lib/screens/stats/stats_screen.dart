// lib/screens/stats/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:office_throne/models/session_log.dart'; // Импортваме модела

class StatsScreen extends StatelessWidget {
  final List<SessionLog> logs; // Екранът получава списъка със записи

  const StatsScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    // Изчисляваме статистиките
    final double totalMoney = logs.fold(0, (sum, item) => sum + item.earnedMoney);
    final int totalDuration = logs.fold(0, (sum, item) => sum + item.durationInSeconds);
    final double totalWeight = logs.fold(0, (sum, item) => sum + item.weightInKg);
    // Избягваме делене на нула
    final double pricePerKg = totalWeight > 0 ? totalMoney / totalWeight : 0.0;

    // Метод за форматиране на времето
    String formatDuration(int totalSeconds) {
      final duration = Duration(seconds: totalSeconds);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}ч ${minutes}м';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансов отчет'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      // Ако няма записи, показваме съобщение
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'Все още нямаш запазени сесии.\nВреме е за работа!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView( // Използваме ListView, за да можем да скролираме
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildStatCard(
                  title: 'ОБЩО ЗАРАБОТЕНО',
                  value: '${totalMoney.toStringAsFixed(2)} лв.',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'ОБЩО ВРЕМЕ НА ТРОНА',
                  value: formatDuration(totalDuration),
                  icon: Icons.timer,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'ОБЩО ИЗХВЪРЛЕНО',
                  value: '${totalWeight.toStringAsFixed(1)} кг',
                  icon: Icons.scale,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'ЦЕНА НА КИЛОГРАМ',
                  value: '${pricePerKg.toStringAsFixed(2)} лв./кг',
                  icon: Icons.diamond,
                  color: Colors.purple,
                  isPrimary: true, // Правим тази карта по-открояваща се
                ),
              ],
            ),
    );
  }

  // Помощен метод за изграждане на красивите карти със статистика
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isPrimary = false,
  }) {
    return Card(
      elevation: 4,
      color: isPrimary ? color : null,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isPrimary ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}