// lib/screens/leaderboard/leaderboard_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  // --- ЛОГИКА ЗА ДОКЛАДВАНЕ ---

  void _showReportDialog(BuildContext context, String reportedUserId, String reportedUsername) {
    final reportReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Докладвай $reportedUsername'),
        content: TextField(
          controller: reportReasonController,
          decoration: const InputDecoration(hintText: 'Причина (по желание)'),
        ),
        actions: [
          TextButton(
            child: const Text('Отказ'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('ИЗПРАТИ ДОКЛАД'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _submitReport(reportedUserId, reportedUsername, reportReasonController.text);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(String reportedUserId, String reportedUsername, String reason) async {
    final reporter = FirebaseAuth.instance.currentUser;
    if (reporter == null) return;

    await FirebaseFirestore.instance.collection('reports').add({
      'reported_user_id': reportedUserId,
      'reported_username': reportedUsername,
      'reporter_user_id': reporter.uid,
      'reason': reason.trim().isNotEmpty ? reason.trim() : 'Без посочена причина',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'new',
    });
    // Забележка: Показването на SnackBar от StatelessWidget е по-сложно,
    // затова го премахнахме оттук, но може да се добави с други техники.
  }

  // --- BUILD МЕТОД ---

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('leaderboard')
        .where('is_banned', isEqualTo: false)
        .orderBy('score', descending: true)
        .limit(50);
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рицарите на Златния Трон'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Грешка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Класацията е все още празна.\nБъди първият рицар!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data() as Map<String, dynamic>;
              final displayName = data['display_name'] ?? "Рицар #${doc.id.substring(0, 6)}";
              final tag = data['tag'] ?? '';
              
              // Коригирана обработка на score
              final num scoreAsNum = data['score'] ?? 0.0;
              final double score = scoreAsNum.toDouble();

              final fullUsername = tag.isNotEmpty ? '$displayName#$tag' : displayName;
              final isCurrentUser = currentUserId == doc.id;

              Widget placeIcon;
              if (index == 0) {
                placeIcon = const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
              } else if (index == 1) {
                placeIcon = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 30);
              } else if (index == 2) {
                placeIcon = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 30);
              } else {
                placeIcon = Text('${index + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color));
              }
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: isCurrentUser ? Colors.brown.withOpacity(0.1) : null,
                elevation: isCurrentUser ? 4 : 1,
                shape: isCurrentUser ? RoundedRectangleBorder(side: BorderSide(color: Colors.brown.shade300, width: 1.5), borderRadius: BorderRadius.circular(12)) : null,
                child: ListTile(
                  onLongPress: !isCurrentUser ? () => _showReportDialog(context, doc.id, fullUsername) : null,
                  leading: SizedBox(width: 40, child: Center(child: placeIcon)),
                  title: Text(fullUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('${score.toStringAsFixed(1)} гр./мин', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}