// lib/screens/stats/stats_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:office_throne/models/session_log.dart';
import 'package:office_throne/screens/achievements/achievements_screen.dart';

class StatsScreen extends StatelessWidget {
  final List<SessionLog> logs;

  const StatsScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    // --- ИЗЧИСЛЕНИЯ НА ДАННИ ---

    // 1. Основни статистики
    final double totalMoney = logs.fold(0.0, (sum, item) => sum + item.earnedMoney);
    final int totalDuration = logs.fold(0, (sum, item) => sum + item.durationInSeconds);
    final double totalWeight = logs.fold(0.0, (sum, item) => sum + item.weightInKg);
    final double pricePerKg = totalWeight > 0 ? totalMoney / totalWeight : 0.0;

    // 2. Данни за графиката по дни от седмицата
    final Map<int, double> weeklyData = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var log in logs) {
      final day = log.timestamp.weekday;
      final durationInMinutes = log.durationInSeconds / 60.0;
      weeklyData[day] = (weeklyData[day] ?? 0) + durationInMinutes;
    }

    // Метод за форматиране на обща продължителност
    String formatTotalDuration(int totalSeconds) {
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
        actions: [
          IconButton(
            tooltip: 'Постижения',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AchievementsScreen()),
              );
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'Все още нямаш запазени сесии.\nВреме е за работа!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildStatCard(context,
                  title: 'ОБЩО ЗАРАБОТЕНО',
                  value: '${totalMoney.toStringAsFixed(2)} лв.',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildStatCard(context,
                  title: 'ОБЩО ВРЕМЕ НА ТРОНА',
                  value: formatTotalDuration(totalDuration),
                  icon: Icons.timer,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildStatCard(context,
                  title: 'ОБЩО ИЗХВЪРЛЕНО',
                  value: '${totalWeight.toStringAsFixed(1)} кг',
                  icon: Icons.scale,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildStatCard(context,
                  title: 'ЦЕНА НА КИЛОГРАМ',
                  value: '${pricePerKg.toStringAsFixed(2)} лв./кг',
                  icon: Icons.diamond,
                  color: Colors.purple,
                  isPrimary: true,
                ),
                _buildWeeklyChart(context, weeklyData),
                _buildFunFactsSection(context, logs),
              ],
            ),
    );
  }

  // --- ПОМОЩНИ МЕТОДИ ЗА ИЗГРАЖДАНЕ НА UI ---

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isPrimary = false,
  }) {
    return Card(
      elevation: isPrimary ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isPrimary ? color : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isPrimary ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.white : Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

 // В класа StatsScreen

// В класа StatsScreen

// В класа StatsScreen

// В класа StatsScreen

Widget _buildWeeklyChart(BuildContext context, Map<int, double> weeklyData) {
  final maxValue = weeklyData.values.fold(0.0, (max, v) => v > max ? v : max);
  if (maxValue == 0) return const SizedBox.shrink();

  final primaryColor = Theme.of(context).colorScheme.primary;
  final secondaryColor = Theme.of(context).colorScheme.secondary;
  final onSecondaryColor = Theme.of(context).colorScheme.onSecondary;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      Text('ПРОДУКТИВНОСТ ПО ДНИ (минути)', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(
              // ... (тази част си остава същата, както я коригирахме)
               touchTooltipData: BarTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipColor: (_) => secondaryColor.withOpacity(0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
                  return BarTooltipItem(
                    '${days[group.x.toInt()]}\n',
                    TextStyle(color: onSecondaryColor, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: '${(rod.toY).toStringAsFixed(0)} мин.',
                        style: TextStyle(color: onSecondaryColor, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              // --- НАПЪЛНО НОВА И ОПРОСТЕНА СЕКЦИЯ ---
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22, // Намаляваме резервираното място
                  // Предоставяме функция, която връща обикновен Text уиджет
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final style = TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Намаляваме размера, за да се събере
                    );
                    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
                    return Text(days[value.toInt()], style: style);
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: weeklyData[i + 1] ?? 0,
                    color: primaryColor,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }),
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildFunFactsSection(BuildContext context, List<SessionLog> logs) {
    if (logs.length < 2) return const SizedBox.shrink();

    final longestSession = logs.reduce((a, b) => a.durationInSeconds > b.durationInSeconds ? a : b);
    final mostProfitableSession = logs.reduce((a, b) => a.earnedMoney > b.earnedMoney ? a : b);

    String formatSingleDuration(int totalSeconds) {
      final duration = Duration(seconds: totalSeconds);
      final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds мин.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('ЗАБАВНИ ФАКТИ', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _buildFactTile(
          context: context,
          icon: Icons.military_tech_rounded,
          title: 'Твоят рекорд за най-дълга сесия:',
          value: formatSingleDuration(longestSession.durationInSeconds),
        ),
        _buildFactTile(
          context: context,
          icon: Icons.attach_money_rounded,
          title: 'Най-печелившата ти сесия:',
          value: '${mostProfitableSession.earnedMoney.toStringAsFixed(2)} лв.',
        ),
      ],
    );
  }

  Widget _buildFactTile({required BuildContext context, required IconData icon, required String title, required String value}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}