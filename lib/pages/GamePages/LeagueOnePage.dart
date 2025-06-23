// lib/pages/leagues_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/LeaguesPage.dart';

class LeaguesPage extends StatefulWidget {
  final String? leagueIdToShow;
  const LeaguesPage({
    Key? key,
    this.leagueIdToShow, // Добавляем в конструктор
  }) : super(key: key);

  @override
  _LeaguesPageState createState() => _LeaguesPageState();
}

class _LeaguesPageState extends State<LeaguesPage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 2;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _swordAnimationController;

  // Цветовая палитра в оранжевом стиле
  final Color primaryOrange = const Color(0xFFF57C00); // Глубокий оранжевый
  final Color accentOrange = const Color(0xFFFFA726); // Светлый оранжевый
  final Color backgroundColor = const Color(0xFFFFF3E0); // Очень светлый фон
  final Color darkTextColor = const Color(0xFF3A3A3A);

  @override
  void initState() {
    super.initState();
    _swordAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swordAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (!mounted || _selectedIndex == index)
      return; // Не переходим, если мы уже на этой вкладке

    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0: // Путь
        Navigator.pushReplacementNamed(context, '/learn');
        break;
      case 1: // Игры
        Navigator.pushReplacementNamed(context, '/games');
        break;
      case 2: // Лига
        if (widget.leagueIdToShow != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LeaguesPage()));
        }
        break;
      case 3: // Материал
        Navigator.pushReplacementNamed(context, '/modules_view');
        break;
      case 4: // Профиль
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

   @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(appBar: _buildSimpleAppBar("Рейтинг Лиги"), body: const Center(child: Text("Пожалуйста, войдите.")));
    }

    // ========== ГЛАВНАЯ ЛОГИКА РАЗДЕЛЕНИЯ ==========
    // Если ID лиги передан через конструктор, строим контент для этой лиги.
    if (widget.leagueIdToShow != null) {
      return _buildLeagueContent(widget.leagueIdToShow!, currentUser.uid);
    } 
    // Иначе, загружаем данные текущего пользователя, чтобы узнать его лигу.
    else {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
            return Scaffold(
              appBar: _buildSimpleAppBar("Загрузка..."),
              body: Center(child: CircularProgressIndicator(color: primaryOrange)),
              bottomNavigationBar: _buildBottomNavigationBar(),
            );
          }
          final currentUserModel = UserModel.fromFirestore(userSnapshot.data!);
          final userLeagueId = currentUserModel.leagueId;

          if (userLeagueId == null || userLeagueId.isEmpty) {
            return Scaffold(
              appBar: _buildSimpleAppBar("Рейтинг Лиги"),
              body: const Center(child: Text("Вы еще не состоите в лиге.")),
              bottomNavigationBar: _buildBottomNavigationBar(),
            );
          }
          // Строим контент для лиги текущего пользователя.
          return _buildLeagueContent(userLeagueId, currentUser.uid);
        },
      );
    }
  }
   AppBar _buildSimpleAppBar(String title) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: primaryOrange,
      centerTitle: true,
    );
  }

  /// Динамический и анимированный AppBar, который показывает информацию о лиге.
 

  /// Основной виджет, который строит контент страницы для указанной лиги
  Widget _buildLeagueContent(String leagueId, String currentUserId) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAnimatedAppBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .where('leagueId', isEqualTo: leagueId)
            .orderBy('weeklyXp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, leagueSnapshot) {
          if (leagueSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryOrange));
          }
          if (leagueSnapshot.hasError) {
            return Center(child: Text("Ошибка загрузки рейтинга: ${leagueSnapshot.error}"));
          }
          if (!leagueSnapshot.hasData || leagueSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("В этой лиге пока нет игроков."));
          }

          final playersDocs = leagueSnapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            itemCount: playersDocs.length,
            separatorBuilder: (context, index) {
              if (index == 4) {
                return _ZoneDivider(text: "Зона Повышения", color: Colors.green.shade600);
              }
              if (playersDocs.length > 10 && index == playersDocs.length - 6) {
                return _ZoneDivider(text: "Зона Понижения", color: Colors.red.shade600);
              }
              return const SizedBox.shrink();
            },
            itemBuilder: (context, index) {
              final playerModel = UserModel.fromFirestore(playersDocs[index]);
              final isCurrentUser = playerModel.uid == currentUserId;
              
              return AnimatedPlayerCard(
                player: playerModel,
                rank: index + 1,
                isCurrentUser: isCurrentUser,
                accentColor: accentOrange,
                primaryColor: primaryOrange,
                index: index,
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  BottomNavigationBar _buildBottomNavigationBar() {
    Color selectedColor = primaryOrange;
    Color unselectedColor = accentOrange.withOpacity(0.8);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: Colors.white,
      elevation: 15.0,
      iconSize: 28,
      selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 12, color: selectedColor),
      unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500, fontSize: 11.5, color: unselectedColor),
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.terrain_outlined),
            activeIcon: Icon(Icons.terrain_rounded, color: selectedColor),
            label: 'Путь'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.extension_outlined),
            activeIcon: Icon(Icons.extension_rounded, color: selectedColor),
            label: 'Игры'),
        BottomNavigationBarItem(
            icon: const Icon(Icons
                .shield_outlined), // Заменил gas_meter на shield для большей логичности
            activeIcon: Icon(Icons.shield, color: selectedColor),
            label: 'Лига'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book, color: selectedColor),
            label: 'Материал'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_pin_circle_outlined),
            activeIcon:
                Icon(Icons.person_pin_circle_rounded, color: selectedColor),
            label: 'Профиль'),
      ],
    );
  }

  AppBar _buildAnimatedAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: primaryOrange,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Анимация мечей
          AnimatedBuilder(
            animation: _swordAnimationController,
            builder: (context, child) {
              final angle = (0.2 * _swordAnimationController.value) - 0.1;
              return Transform.rotate(
                angle: angle,
                child: Icon(Icons.shield,
                    color: Colors.white.withOpacity(0.8), size: 28),
              );
            },
          ),
          const SizedBox(width: 12),
          const Text("Рейтинг Лиги",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white)),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _swordAnimationController,
            builder: (context, child) {
              final angle = (-0.2 * _swordAnimationController.value) + 0.1;
              return Transform.rotate(
                angle: angle,
                child: Icon(Icons.shield,
                    color: Colors.white.withOpacity(0.8), size: 28),
              );
            },
          ),
        ],
      ),
      actions: [
        Tooltip(
          message: 'Посмотреть все лиги',
          child: IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AllLeaguesPage()));
            },
          ),
        ),
      ],
    );
  }
}

// Отдельный виджет для карточки игрока с анимацией
class AnimatedPlayerCard extends StatefulWidget {
  final UserModel player;
  final int rank;
  final bool isCurrentUser;
  final Color primaryColor;
  final Color accentColor;
  final int index;

  const AnimatedPlayerCard({
    Key? key,
    required this.player,
    required this.rank,
    required this.isCurrentUser,
    required this.primaryColor,
    required this.accentColor,
    required this.index,
  }) : super(key: key);

  @override
  _AnimatedPlayerCardState createState() => _AnimatedPlayerCardState();
}

class _AnimatedPlayerCardState extends State<AnimatedPlayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _PlayerCard(
          player: widget.player,
          rank: widget.rank,
          isCurrentUser: widget.isCurrentUser,
          primaryColor: widget.primaryColor,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }
}

// Статический виджет карточки (для рендеринга)
class _PlayerCard extends StatelessWidget {
  final UserModel player;
  final int rank;
  final bool isCurrentUser;
  final Color primaryColor;
  final Color accentColor;

  const _PlayerCard({
    required this.player,
    required this.rank,
    required this.isCurrentUser,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isCurrentUser ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isCurrentUser
            ? BorderSide(color: accentColor, width: 2.5)
            : BorderSide.none,
      ),
      color: isCurrentUser
          ? Colors.orange.shade100.withOpacity(0.5)
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Ранг игрока
            SizedBox(
              width: 40,
              child: Text(
                "$rank",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
            ),
            // Аватар с короной для лидера
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: player.profileImageUrl != null &&
                          player.profileImageUrl!.startsWith('http')
                      ? NetworkImage(player.profileImageUrl!)
                      : null,
                  child: player.profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                if (rank == 1)
                  Positioned(
                    top: -16,
                    left: 5,
                    child: _PulsingCrown(color: accentColor),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            // Имя
            Expanded(
              child: Text(
                "${player.firstName} ${player.lastName}".trim(),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            // XP
            Text(
              "${player.weeklyXp} XP",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет для разделителя зон
class _ZoneDivider extends StatelessWidget {
  final String text;
  final Color color;
  const _ZoneDivider({Key? key, required this.text, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(child: Divider(color: color.withOpacity(0.5), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Divider(color: color.withOpacity(0.5), thickness: 1)),
        ],
      ),
    );
  }
}

// Виджет для пульсирующей короны
class _PulsingCrown extends StatefulWidget {
  final Color color;
  const _PulsingCrown({Key? key, required this.color}) : super(key: key);

  @override
  __PulsingCrownState createState() => __PulsingCrownState();
}

class __PulsingCrownState extends State<_PulsingCrown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Icon(Icons.emoji_events, color: widget.color, size: 30),
    );
  }
}
