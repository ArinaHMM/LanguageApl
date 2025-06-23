// lib/pages/achievements_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/models/app_data.dart'; // Убедитесь, что этот файл есть
import 'package:intl/intl.dart';

// Модель для данных достижения из справочника
class AchievementInfo {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isSecret;

  AchievementInfo.fromFirestore(DocumentSnapshot doc)
      : id = doc.id,
        name =
            (doc.data() as Map<String, dynamic>?)?['name'] as String? ?? '...',
        description =
            (doc.data() as Map<String, dynamic>?)?['description'] as String? ??
                '...',
        icon = (doc.data() as Map<String, dynamic>?)?['icon'] as String? ??
            'default_icon',
        isSecret =
            (doc.data() as Map<String, dynamic>?)?['isSecret'] as bool? ??
                false;
}

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final Color primaryOrange = const Color(0xFFF57C00);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        backgroundColor: primaryOrange,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFFF3E0),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // <-- ИЗМЕНЕНИЕ ЗДЕСЬ
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(color: primaryOrange));
          }
          final user = UserModel.fromFirestore(userSnapshot.data!);

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            // <-- ИЗМЕНЕНИЕ ЗДЕСЬ
            stream: FirebaseFirestore.instance
                .collection('achievements')
                .orderBy('order')
                .snapshots(),
            builder: (context, achievementsSnapshot) {
              if (!achievementsSnapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(color: primaryOrange));
              }

              final allAchievements = achievementsSnapshot.data!.docs
                  .map((doc) => AchievementInfo.fromFirestore(doc))
                  .toList();

              final unlockedAchievements = allAchievements
                  .where((ach) => user.unlockedAchievements.containsKey(ach.id))
                  .toList();

              final lockedAchievements = allAchievements
                  .where((ach) =>
                      !user.unlockedAchievements.containsKey(ach.id) &&
                      !ach.isSecret)
                  .toList();

              return Column(
                children: [
                  _Header(
                    unlockedCount: unlockedAchievements.length,
                    totalCount: allAchievements.length,
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: primaryOrange,
                    labelColor: primaryOrange,
                    unselectedLabelColor: Colors.grey.shade600,
                    tabs: [
                      Tab(text: 'Полученные (${unlockedAchievements.length})'),
                      Tab(text: 'Не полученные (${lockedAchievements.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _AchievementList(
                          achievements: unlockedAchievements,
                          user: user,
                          isUnlockedList: true,
                        ),
                        _AchievementList(
                          achievements: lockedAchievements,
                          user: user,
                          isUnlockedList: false,
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;

  const _Header(
      {Key? key, required this.unlockedCount, required this.totalCount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progress = totalCount > 0 ? unlockedCount / totalCount : 0;
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Text(
            'Ваш Зал Славы',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 40),
              const SizedBox(width: 16),
              Text(
                '$unlockedCount / $totalCount',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}

class _AchievementList extends StatelessWidget {
  final List<AchievementInfo> achievements;
  final UserModel user;
  final bool isUnlockedList;

  const _AchievementList({
    Key? key,
    required this.achievements,
    required this.user,
    required this.isUnlockedList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          isUnlockedList
              ? "Вы еще не получили ни одного достижения."
              : "Все достижения получены!",
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlockedDate = user.unlockedAchievements[achievement.id];
        return _AchievementCard(
          achievement: achievement,
          isUnlocked: isUnlockedList,
          unlockedDate: unlockedDate,
          icon: AppData.itemIcons[achievement.icon] ??
              AppData.itemIcons['default_icon']!,
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementInfo achievement;
  final bool isUnlocked;
  final Timestamp? unlockedDate;
  final IconData icon;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    this.unlockedDate,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isUnlocked ? 6 : 2,
      shadowColor: isUnlocked ? Colors.amber.withOpacity(0.5) : Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [Colors.amber.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnlocked ? null : Colors.grey.shade200,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    isUnlocked ? Colors.amber.shade600 : Colors.grey.shade400,
                child: Icon(
                  isUnlocked ? icon : Icons.lock_outline_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isUnlocked ? Colors.black87 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (isUnlocked && unlockedDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Получено: ${DateFormat('dd.MM.yyyy').format(unlockedDate!.toDate())}",
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
