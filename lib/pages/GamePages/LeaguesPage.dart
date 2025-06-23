// lib/pages/all_leagues_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/LeagueOnePage.dart';

// Простая модель для данных лиги
class LeagueInfo {
  final String id;
  final String name;
  final int order;
  final String? iconUrl;

  LeagueInfo({required this.id, required this.name, required this.order, this.iconUrl});

  factory LeagueInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LeagueInfo(
      id: doc.id,
      name: data['name'] as String? ?? 'Неизвестная лига',
      order: data['order'] as int? ?? 99,
      iconUrl: data['iconUrl'] as String?,
    );
  }
}

class AllLeaguesPage extends StatelessWidget {
  const AllLeaguesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryOrange = const Color(0xFFF57C00);
    final Color backgroundColor = const Color(0xFFFFF3E0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Все Лиги'),
        backgroundColor: primaryOrange,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leagues')
            .orderBy('order', descending: true) // Показываем от высшей к низшей
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryOrange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Лиги еще не созданы."));
          }

          final leagues = snapshot.data!.docs.map((doc) => LeagueInfo.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              // ================== ИЗМЕНЕНИЕ ЗДЕСЬ ==================
              // Оборачиваем карточку в InkWell для обработки нажатий
              return InkWell(
                onTap: () {
                  // Переходим на страницу рейтинга, передавая ID лиги
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaguesPage(leagueIdToShow: league.id),
                    ),
                  );
                },
                child: _LeagueCard(league: league),
              );
              // ===================================================
            },
          );
        },
      ),
    );
  }
}

// Виджет-карточка для одной лиги
class _LeagueCard extends StatelessWidget {
  final LeagueInfo league;
  const _LeagueCard({Key? key, required this.league}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white.withOpacity(0.9),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: league.iconUrl != null ? NetworkImage(league.iconUrl!) : null,
                child: league.iconUrl == null
                    ? Icon(Icons.shield_rounded, size: 40, color: Colors.orange.shade800)
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                league.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black38, offset: Offset(1.0, 1.0))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}