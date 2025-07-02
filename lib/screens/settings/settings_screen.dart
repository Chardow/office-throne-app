// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController();
  final _usernameController = TextEditingController();
  String _currentTag = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;

  // Зареждаме ставката
  final double currentRate = prefs.getDouble('hourly_rate') ?? 15.0;
  _hourlyRateController.text = currentRate.toString();

  // Зареждаме името от Firestore
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('leaderboard').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      _usernameController.text = userDoc.data()!['display_name'] ?? '';
      _currentTag = userDoc.data()!['tag'] ?? ''; // Зареждаме тага
    }
  }
  setState(() {
    _isLoading = false;
  });
}
Future<void> _saveUsername() async {
  final newName = _usernameController.text.trim();
  if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Името не може да е празно.'), backgroundColor: Colors.red),
      );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  setState(() { _isLoading = true; });

try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final leaderboardRef = FirebaseFirestore.instance.collection('leaderboard');
      String? finalTag;
      
      // Опитваме до 10 пъти да намерим свободен таг
      for (int i = 0; i < 100; i++) {
        final randomTag = (1000 + Random().nextInt(9000)).toString(); // Генерира 1000-9999
        final searchName = "${newName.toLowerCase()}#$randomTag";

        final query = leaderboardRef.where('search_name', isEqualTo: searchName);
        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          // Намерихме свободен таг!
          finalTag = randomTag;
          break;
        }
      }

      if (finalTag == null) {
        // Не успяхме да намерим свободен таг
        throw Exception("Не може да се намери уникален таг за това име. Моля, опитайте с друго.");
      }

      // Имаме уникален таг, записваме в документа на потребителя
      final userDocRef = leaderboardRef.doc(user.uid);
      transaction.set(userDocRef, {
        'display_name': newName,
        'tag': finalTag,
        'search_name': "${newName.toLowerCase()}#$finalTag",
      }, SetOptions(merge: true));

      // Обновяваме локалното състояние, за да се покаже новият таг
      _currentTag = finalTag;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Името е запазено успешно!'), backgroundColor: Colors.green),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Грешка: $e'), backgroundColor: Colors.red),
    );
  } finally {
    setState(() { _isLoading = false; });
  }
}
  // Метод за зареждане на запазената стойност
  Future<void> _loadHourlyRate() async {
    final prefs = await SharedPreferences.getInstance();
    // Зареждаме стойността. Ако я няма, използваме 15.0 като стойност по подразбиране.
    final double currentRate = prefs.getDouble('hourly_rate') ?? 15.0;
    setState(() {
      _hourlyRateController.text = currentRate.toString();
      _isLoading = false;
    });
  }

  // Метод за запазване на новата стойност
  Future<void> _saveHourlyRate() async {
    // Валидираме дали полето е попълнено правилно
    if (_formKey.currentState!.validate()) {
      final double newRate = double.parse(_hourlyRateController.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('hourly_rate', newRate);

      // Показваме приятно съобщение за успех
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Часовата ставка е запазена!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                    Text(
                      'Твоят прякор в класацията',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Потребителско име',
                         border: const OutlineInputBorder(),
                        suffixText: _currentTag.isNotEmpty ? '#$_currentTag' : null,
                        hintText: 'Напр. Кралят на Тоалетната',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveUsername,
                      child: const Text('ЗАПАЗИ ИМЕ'),
                    ),
                    const Divider(height: 40, thickness: 1),
                    
                  Text(
                    'Въведи своята часова ставка',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Тази стойност се използва за изчисляване на заработеното по време на сесия. Тя се пази само на твоето устройство.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _hourlyRateController,
                    decoration: const InputDecoration(
                      labelText: 'Часова ставка (лв./час)',
                      border: OutlineInputBorder(),
                      suffixText: 'лв.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    // Позволява само числа и една точка
                    inputFormatters: [
                       FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Моля, въведете стойност.';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Моля, въведете валидно число.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _saveHourlyRate,
                    icon: const Icon(Icons.save),
                    label: const Text('ЗАПАЗИ'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}