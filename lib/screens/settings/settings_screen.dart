// lib/screens/settings/settings_screen.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_throne/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLoading = true;
  String _currentTag = "";

  @override
  void initState() {
    super.initState();
    // Използваме addPostFrameCallback, за да сме сигурни, че context е наличен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    final double currentRate = prefs.getDouble('hourly_rate') ?? 15.0;
    _hourlyRateController.text = currentRate.toStringAsFixed(2);

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('leaderboard').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _usernameController.text = userDoc.data()!['display_name'] ?? '';
        _currentTag = userDoc.data()!['tag'] ?? '';
      }
    }
    
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  // В _SettingsScreenState

Future<void> _saveUsername() async {
  final newName = _usernameController.text.trim();
  if (newName.isEmpty) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Името не може да е празно.'), backgroundColor: Colors.red));
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (mounted) setState(() { _isLoading = true; });

  try {
    final leaderboardRef = FirebaseFirestore.instance.collection('leaderboard');
    String? finalTag;
    String finalSearchName = '';

    for (int i = 0; i < 20; i++) {
      final randomTag = (1000 + Random().nextInt(9000)).toString();
      final searchName = "${newName.toLowerCase()}#$randomTag";

      final snapshot = await leaderboardRef.where('search_name', isEqualTo: searchName).limit(1).get();

      if (snapshot.docs.isEmpty) {
        finalTag = randomTag;
        finalSearchName = searchName;
        break;
      }
    }

    if (finalTag == null) {
      throw Exception("Не може да се намери уникален таг за това име. Моля, опитайте с друго.");
    }
    
    final userDocRef = leaderboardRef.doc(user.uid);
    await userDocRef.set({
      'display_name': newName,
      'tag': finalTag,
      'search_name': finalSearchName,
    }, SetOptions(merge: true));

    // КОРЕКЦИЯТА Е ТУК:
    if (mounted) {
      setState(() {
        _currentTag = finalTag!; // Добавяме '!'
      });
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Името е запазено успешно!'), backgroundColor: Colors.green),
    );

  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Грешка: $e'), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) setState(() { _isLoading = false; });
  }
}
  
  Future<void> _saveHourlyRate() async {
    if (_formKey.currentState!.validate()) {
      final newRate = double.tryParse(_hourlyRateController.text.replaceAll(',', '.'));
      if (newRate == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('hourly_rate', newRate);
      
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Часовата ставка е запазена!'), backgroundColor: Colors.green));
      }
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- БЛОК ЗА ТЪМЕН РЕЖИМ ---
                  // Използваме Consumer, за да получим достъп до ThemeProvider
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return SwitchListTile(
                        title: const Text('Тъмен режим'),
                        secondary: Icon(
                          themeProvider.isDarkTheme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        ),
                        value: themeProvider.isDarkTheme,
                        onChanged: (value) {
                          themeProvider.setDarkTheme(value);
                        },
                      );
                    },
                  ),
                  const Divider(height: 30, thickness: 1),

                  // --- БЛОК ЗА ПОТРЕБИТЕЛСКО ИМЕ ---
                  Text('Твоят прякор в класацията', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Потребителско име',
                      border: const OutlineInputBorder(),
                      hintText: 'Напр. Кралят на Тоалетната',
                      suffixText: _currentTag.isNotEmpty ? '#$_currentTag' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveUsername,
                    child: const Text('ЗАПАЗИ ИМЕ'),
                  ),
                  const Divider(height: 40, thickness: 1),

                  // --- БЛОК ЗА ЧАСОВА СТАВКА ---
                  Text('Въведи своята часова ставка', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Тази стойност се пази само на твоето устройство.', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _hourlyRateController,
                    decoration: const InputDecoration(
                      labelText: 'Часова ставка (лв./час)',
                      border: OutlineInputBorder(),
                      suffixText: 'лв.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}'))],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Моля, въведете стойност.';
                      if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Моля, въведете валидно число.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _saveHourlyRate,
                    icon: const Icon(Icons.save),
                    label: const Text('ЗАПАЗИ СТАВКА'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}