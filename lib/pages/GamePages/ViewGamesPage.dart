// lib/pages/GamePages/ViewGamesPage.dart
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/AntonymPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/Game.dart'; // MemoryGamePage
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/HangmanGame.dart';

class ViewGamesPage extends StatefulWidget {
  const ViewGamesPage({Key? key}) : super(key: key);

  @override
  _ViewGamesPageState createState() => _ViewGamesPageState();
}

class _ViewGamesPageState extends State<ViewGamesPage> {
  // --- Состояние для навигации ---
  int _selectedIndex = 1; // Игры - 2-й элемент (индекс 1)

  // --- Цвета для навигации (возьмем из вашего ProfilePage примера) ---
  final Color learnPagePrimaryOrange = const Color(0xFFFFA726);
  final Color learnPageDarkOrange = const Color(0xFFF57C00);
  // --------------------------------

  String? _selectedLanguage = 'english'; // Язык по умолчанию

  final Map<String, String> _languageOptions = {
    'english': 'Английский',
    'german': 'Немецкий',
    'spanish': 'Испанский',
  };

  // Цвета для страницы игр (остаются для контента страницы)
  final Color appBarColorGames = const Color.fromARGB(255, 252, 154, 26); // Зеленый для игр
  final Color backgroundColorGames = const Color(0xFFE8F5E9); // Светло-зеленый фон
  final Color primaryTextColorGames = const Color.fromARGB(255, 224, 126, 46); // Темно-зеленый текст
  final Gradient cardGradient1 = const LinearGradient(
    colors: [Color.fromARGB(255, 252, 141, 50), Color.fromARGB(255, 255, 198, 75)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
   final Gradient cardGradient2 = const LinearGradient(
    colors: [Color.fromARGB(255, 255, 146, 73),Color.fromARGB(255, 255, 194, 61)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
   final Gradient cardGradient3 = const LinearGradient(
    colors: [Color.fromARGB(255, 255, 134, 36), Color.fromARGB(255, 255, 164, 45)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  // --- Метод навигации из ProfilePage ---
  void _onItemTapped(int index) {
    if (!mounted) return;

    if (_selectedIndex == index) {
      return; // Ничего не делаем, если уже на этой вкладке
    }

    setState(() {
      _selectedIndex = index;
    });

    // Выполняем навигацию
    switch (index) {
      case 0: // Путь
        Navigator.pushReplacementNamed(context, '/learn');
        break;
      case 1: // Игры (текущая страница)
        // Мы уже на этой странице или переходим на нее. _selectedIndex обновлен.
        // Если мы уже здесь, ничего дополнительно делать не нужно.
        // Если это был переход с другой вкладки, setState уже обновил UI.
        break;
      case 2: // Чаты
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 3: // Материал (бывшие Настройки)
        Navigator.pushReplacementNamed(context, '/modules_view');
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
      backgroundColor: backgroundColorGames,
      appBar: AppBar(
        title: const Text('Выберите Игру',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: appBarColorGames,
        elevation: 4,
        centerTitle: true,
        automaticallyImplyLeading: false, // Убираем кнопку "назад" по умолчанию
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: 'Язык для игр',
                      labelStyle:
                          TextStyle(color: primaryTextColorGames.withOpacity(0.8)),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.language, color: appBarColorGames),
                    ),
                    icon:
                        Icon(Icons.arrow_drop_down_rounded, color: appBarColorGames),
                    items: _languageOptions.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value,
                            style: TextStyle(color: primaryTextColorGames)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                    builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  double childAspectRatio = constraints.maxWidth > 600 ? 1.1 : 0.9;
                  if (constraints.maxWidth < 400) {
                    crossAxisCount = 1;
                    childAspectRatio = 2.2;
                  }

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 18.0,
                    mainAxisSpacing: 18.0,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildGameCard(
                        context,
                        'Виселица',
                        Icons.sentiment_very_dissatisfied, // Иконка для виселицы
                        () {
                          if (_selectedLanguage == null) {
                            _showLanguageNotSelectedDialog(); return;
                          }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HangmanGamePage(
                                      languageCode: _selectedLanguage!)));
                        },
                        cardGradient1,
                      ),
                      _buildGameCard(
                        context,
                        'Запомни',
                        Icons.memory_rounded,
                        () {
                          if (_selectedLanguage == null) {
                             _showLanguageNotSelectedDialog(); return;
                          }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MemoryGamePage(
                                      languageCode: _selectedLanguage!)));
                        },
                        cardGradient2,
                      ),
                      _buildGameCard(
                        context,
                        'Найди пару',
                        Icons.compare_arrows_rounded,
                        () {
                          if (_selectedLanguage == null) {
                             _showLanguageNotSelectedDialog(); return;
                          }
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AntonymMatchingPage(
                                      languageCode: _selectedLanguage!)));
                        },
                        cardGradient3,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      // --- ДОБАВЛЯЕМ BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: _buildBottomNavigationBar(),
      // ------------------------------------
    );
  }

  void _showLanguageNotSelectedDialog() {
    // ... (код как был в предыдущем ответе)
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 10),
              const Text('Язык не выбран'),
            ],
          ),
          content: const Text('Пожалуйста, выберите язык, чтобы продолжить.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK',
                  style: TextStyle(
                      color: appBarColorGames, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameCard(BuildContext context, String title, IconData icon,
      VoidCallback onTap, Gradient gradient) {
    // ... (код как был в предыдущем ответе)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Card(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          clipBehavior: Clip.antiAlias, 
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48.0, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 12.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black26,
                            offset: Offset(1.0, 1.0),
                          ),
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      backgroundColor: Colors.white, // Фон навигационной панели
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
            icon: const Icon(Icons.extension_outlined), // Иконка для Игр
            activeIcon: Icon(Icons.extension_rounded, color: selectedColor),
            label: 'Игры'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat_rounded, color: selectedColor),
            label: 'Чаты'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined), // Иконка для Материал
            activeIcon: Icon(Icons.book_rounded, color: selectedColor),
            label: 'Материал'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_pin_circle_outlined),
            activeIcon:
                Icon(Icons.person_pin_circle_rounded, color: selectedColor),
            label: 'Профиль'),
      ],
    );
  }
  // ---------------------------------------------------------
}