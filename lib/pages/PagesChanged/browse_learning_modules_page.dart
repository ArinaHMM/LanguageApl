// lib/pages/browse_learning_modules_page.dart (или ваш путь)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/models/learning_module_model.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/learning_module_detail_page.dart';

class BrowseLearningModulesPage extends StatefulWidget {
  const BrowseLearningModulesPage({Key? key}) : super(key: key);

  @override
  _BrowseLearningModulesPageState createState() =>
      _BrowseLearningModulesPageState();
}

class _BrowseLearningModulesPageState extends State<BrowseLearningModulesPage> {
  // --- Состояние для навигации ---
  int _selectedIndex = 3; // Индекс для "Материал" в BottomNavigationBar

  // --- Цвета для навигации (можно вынести в общие константы темы) ---
  final Color learnPagePrimaryOrange = const Color(0xFFFFA726);
  final Color learnPageDarkOrange = const Color(0xFFF57C00);
  // --------------------------------

  String? _selectedLanguage;
  String? _selectedLevel;

  final Map<String, String> _languageOptions = {
    'english': 'Английский',
    'german': 'Немецкий',
    'spanish': 'Испанский',
  };
  final List<String> _levelOptions = [
    'Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'
  ];

  final Map<String, IconData> _topicIcons = {
    'waving_hand': Icons.front_hand_rounded,
    'family': Icons.family_restroom_rounded,
    'food': Icons.restaurant_rounded,
    'numbers': Icons.format_list_numbered_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'greetings': Icons.forum_rounded,
    'default': Icons.school_rounded,
  };

  IconData _getIconFromString(String? iconName) {
    if (iconName != null && _topicIcons.containsKey(iconName)) {
      return _topicIcons[iconName]!;
    }
    return _topicIcons['default']!;
  }

  // --- Метод навигации из ProfilePage ---
  void _onItemTapped(int index) {
    if (!mounted) return;

    // Если пользователь нажал на уже активную вкладку
    if (_selectedIndex == index) {
      return; 
    }

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
      case 2: // Чаты
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 3: // Материал (текущая страница)
        // Уже здесь, _selectedIndex обновлен
        break;
      case 4: // Профиль
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Учебные материалы',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange, // Цвет из вашего кода для этой страницы
        elevation: 2,
        automaticallyImplyLeading: false, // Убираем кнопку "назад", если это корневой экран вкладки
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getModulesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center( /* ... Сообщение "Нет модулей" ... */ );
                }

                final modules = snapshot.data!.docs
                    .map((doc) => LearningModule.fromFirestore(doc))
                    .toList();

                if (modules.isEmpty) {
                  return Center( /* ... Сообщение "Нет опубликованных модулей" ... */ );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    return _buildModuleCard(modules[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- ДОБАВЛЯЕМ BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: _buildBottomNavigationBar(),
      // ------------------------------------
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getModulesStream() {
    // ... (код как был)
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('learning_modules')
        .where('is_published', isEqualTo: true)
        .orderBy('created_at', descending: true);

    if (_selectedLanguage != null) {
      query = query.where('target_language', isEqualTo: _selectedLanguage);
    }
    if (_selectedLevel != null) {
      query = query.where('level', isEqualTo: _selectedLevel);
    }
    return query.snapshots();
  }

  Widget _buildFilterBar() {
    // ... (код как был)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Язык',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text('Все языки'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Все языки'),
                ),
                ..._languageOptions.entries.map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedLanguage = value),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: InputDecoration(
                labelText: 'Уровень',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text('Все уровни'),
              items: [
                 const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Все уровни'),
                ),
                ..._levelOptions.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedLevel = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(LearningModule module) {
    // ... (код как был)
     final cardColor = _getColorForLanguage(module.targetLanguage);
    final iconData = _getIconFromString(module.topicIcon);

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearningModuleDetailPage(module: module),
            ),
          );
        },
        splashColor: cardColor.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                 gradient: LinearGradient(
                  colors: [cardColor.withOpacity(0.85), cardColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconData, size: 38.0, color: Colors.white.withOpacity(0.95)),
                  const SizedBox(height: 6.0),
                  Text(
                    _languageOptions[module.targetLanguage] ?? module.targetLanguage.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5, 
                        shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.4))]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.titleRu,
                      style: TextStyle(
                        fontSize: 14.5, 
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[850],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    if (module.descriptionRu != null && module.descriptionRu!.isNotEmpty)
                      Text(
                        module.descriptionRu!,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey[700], height: 1.3),
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Chip(
                            avatar: Icon(Icons.bar_chart_rounded, size: 15, color: Colors.white.withOpacity(0.9)),
                            label: Text(
                              module.level,
                              style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w500), 
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: cardColor.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), 
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 15, color: cardColor.withOpacity(0.9)), 
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLanguage(String languageCode) {
    // ... (код как был)
     switch (languageCode.toLowerCase()) {
      case 'english':
        return Colors.blueAccent.shade700;
      case 'german':
        return Colors.orange.shade800;
      case 'spanish':
        return Colors.redAccent.shade700;
      default:
        return Colors.teal.shade600;
    }
  }

  // --- Метод для создания BottomNavigationBar из ProfilePage ---
  BottomNavigationBar _buildBottomNavigationBar() {
    Color selectedColor = learnPageDarkOrange;
    Color unselectedColor = learnPagePrimaryOrange.withOpacity(0.7);

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
            icon: const Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat_rounded, color: selectedColor),
            label: 'Чаты'),
        BottomNavigationBarItem( // Убедитесь, что иконка соответствует "Материал"
            icon: const Icon(Icons.book_outlined), // или Icons.menu_book, Icons.article_outlined
            activeIcon: Icon(Icons.book_rounded, color: selectedColor), // или Icons.menu_book_rounded
            label: 'Материал'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_pin_circle_outlined),
            activeIcon: Icon(Icons.person_pin_circle_rounded, color: selectedColor),
            label: 'Профиль'),
      ],
    );
  }
  // ---------------------------------------------------------
}