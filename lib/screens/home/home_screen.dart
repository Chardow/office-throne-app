// lib/screens/home/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:office_throne/models/session_log.dart';
import 'package:office_throne/screens/log_session/log_session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreen extends StatefulWidget {
  final Function(SessionLog) onLogAdded;
  const HomeScreen({super.key, required this.onLogAdded});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Добавяме 'SingleTickerProviderStateMixin' за анимацията
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isSessionActive = false;
  Timer? _timer;
  int _secondsPassed = 0;
  double _earnedMoney = 0.0;

  // Контролер за анимацията
  AnimationController? _animationController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController!.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void _startSession() async {
    final prefs = await SharedPreferences.getInstance();
    final double hourlyRate = prefs.getDouble('hourly_rate') ?? 15.0;

    setState(() {
      _isSessionActive = true;
    });
    
    _animationController?.forward(); // Стартираме анимацията

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsPassed++;
        double moneyPerSecond = hourlyRate / 3600;
        _earnedMoney += moneyPerSecond;
      });
    });
  }

  void _stopSession() async {
    _timer?.cancel();
    _animationController?.reset(); // Спираме и нулираме анимацията

    final int sessionSeconds = _secondsPassed;
    final double sessionMoney = _earnedMoney;

    setState(() {
      _isSessionActive = false;
      _secondsPassed = 0;
      _earnedMoney = 0.0;
    });

    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LogSessionScreen(
          secondsPassed: sessionSeconds,
          earnedMoney: sessionMoney,
        ),
      ),
    );

    if (result != null && result is double) {
      final double weight = result;
      final newLog = SessionLog(
        timestamp: DateTime.now(),
        durationInSeconds: sessionSeconds,
        earnedMoney: sessionMoney,
        weightInKg: weight,
      );
      widget.onLogAdded(newLog);
    }
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Премахваме AppBar, за да имаме повече контрол върху целия екран
      body: Container(
        // 1. Градиентен фон
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade50,
              Colors.brown.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround, // Разпределяме елементите
                children: [
                  // Горен блок - или заглавие, или данните от сесията
                  _isSessionActive
                      ? _buildSessionData()
                      : _buildIdleHeader(),
                  
                  // Долен блок - бутонът
                  _buildActionButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Уиджети, изнесени в отделни методи за по-добра четимост

  Widget _buildIdleHeader() {
    return Column(
      children: [
        // 2. По-добра икона
        Icon(
          Icons.castle_rounded, // Икона на замък, която прилича на трон
          size: 120,
          color: Colors.brown.shade700,
        ),
        const SizedBox(height: 20),
        const Text(
          'Тронната зала Ви очаква',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Всяка секунда е от значение... и има цена.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.brown.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionData() {
    return ScaleTransition(
      // 3. Анимация
      scale: _pulseAnimation!,
      child: Column(
        children: [
          // 5. Карти за данните
          _buildInfoCard(
            label: 'ВРЕМЕТРАЕНЕ',
            value: _formatDuration(_secondsPassed),
            valueSize: 60,
          ),
          const SizedBox(height: 30),
          _buildInfoCard(
            label: 'ЗАРАБОТЕНО',
            value: '+ ${_earnedMoney.toStringAsFixed(2)} лв.',
            valueSize: 48,
            valueColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    double valueSize = 48,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w900,
              color: valueColor ?? Colors.black87,
              fontFamily: 'monospace', // Моноширен шрифт за числата, за да не "скачат"
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: () {
        if (_isSessionActive) {
          _stopSession();
        } else {
          _startSession();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isSessionActive ? Colors.red.shade700 : Colors.brown.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
      child: Text(
        _isSessionActive ? "ПРИКЛЮЧИ И ОТЧЕТИ" : "ЗАПОЧНИ СЕСИЯ",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}