// lib/pages/GamePages/Game.dart (или ваш путь к MemoryGamePage)
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MemoryGamePage extends StatefulWidget {
  final String languageCode;

  const MemoryGamePage({
    Key? key,
    required this.languageCode,
  }) : super(key: key);

  @override
  _MemoryGamePageState createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage>
    with TickerProviderStateMixin {
  // --- Цвета и стили ---
  final Color appBarColor = const Color.fromARGB(255, 252, 153, 72); // Голубой
  final Color backgroundColor =
      const Color.fromARGB(255, 255, 212, 131); // Очень светло-голубой
  final Color cardBackColor =
      const Color.fromARGB(255, 252, 115, 24); // Ярко-голубой для рубашки
  final Color cardFrontColor = Colors.white;
  final Color matchedCardColor =
      const Color(0xFFA5D6A7); // Светло-зеленый для совпавших
  final Color textColor =
      const Color.fromARGB(255, 245, 111, 33); // Темно-синий для текста
  // ---------------------

  late List<MemoryItem> _gameItemsWithState; // Содержит элементы и их состояние
  final Map<String, List<String>> _itemsByLanguage = {
    'english': [
      'APPLE',
      'HOUSE',
      'CAR',
      'BOOK',
      'TREE',
      'SUN',
      'DOG',
      'CAT'
    ], // 8 уникальных элементов для 16 карточек
    'spanish': [
      'MANZANA',
      'CASA',
      'COCHE',
      'LIBRO',
      'ÁRBOL',
      'SOL',
      'PERRO',
      'GATO'
    ],
    'german': [
      'APFEL',
      'HAUS',
      'AUTO',
      'BUCH',
      'BAUM',
      'SONNE',
      'HUND',
      'KATZE'
    ],
  };

  List<int> _flippedCardIndices = [];
  int _pairsFound = 0;
  bool _ignoreTaps = false;
  int _moves = 0;

  // Для анимации
  Map<int, AnimationController> _flipControllers = {};
  Map<int, Animation<double>> _flipAnimations = {};

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    for (var controller in _flipControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeGame() {
    List<String> baseItems = List<String>.from(
        _itemsByLanguage[widget.languageCode] ?? _itemsByLanguage['english']!);
    if (baseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Нет слов для игры "Запомни" на языке: ${widget.languageCode}'),
            backgroundColor: Colors.red),
      );
      Navigator.of(context).pop();
      return;
    }

    // Создаем пары
    List<String> fullItemList = [...baseItems, ...baseItems];
    fullItemList.shuffle(Random());

    _gameItemsWithState = List.generate(fullItemList.length,
        (index) => MemoryItem(content: fullItemList[index]));

    // Инициализация контроллеров анимации
    _flipControllers.forEach((key, controller) => controller.dispose());
    _flipControllers = {};
    _flipAnimations = {};

    for (int i = 0; i < _gameItemsWithState.length; i++) {
      _flipControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _flipAnimations[i] = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipControllers[i]!, curve: Curves.easeInOut),
      );
    }

    _flippedCardIndices = [];
    _pairsFound = 0;
    _moves = 0;
    _ignoreTaps = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _onCardTap(int index) {
    if (_ignoreTaps ||
        _gameItemsWithState[index].isFlipped ||
        _gameItemsWithState[index].isMatched ||
        _flippedCardIndices.length >= 2) {
      return;
    }

    _flipControllers[index]?.forward();
    setState(() {
      _gameItemsWithState[index].isFlipped = true;
      _flippedCardIndices.add(index);
    });

    if (_flippedCardIndices.length == 2) {
      _moves++;
      _ignoreTaps = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        // Увеличил задержку для просмотра
        _checkMatch();
      });
    }
  }

  void _checkMatch() {
    if (!mounted || _flippedCardIndices.length < 2) return;

    final index1 = _flippedCardIndices[0];
    final index2 = _flippedCardIndices[1];

    if (_gameItemsWithState[index1].content ==
        _gameItemsWithState[index2].content) {
      // Пара найдена
      setState(() {
        _gameItemsWithState[index1].isMatched = true;
        _gameItemsWithState[index2].isMatched = true;
      });
      _pairsFound++;
      if (_pairsFound == _gameItemsWithState.length / 2) {
        _showGameEndDialog(won: true);
      }
    } else {
      // Не совпало - переворачиваем обратно
      _flipControllers[index1]?.reverse();
      _flipControllers[index2]?.reverse();
      // Задержка перед сбросом isFlipped, чтобы анимация успела завершиться
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _gameItemsWithState[index1].isFlipped = false;
            _gameItemsWithState[index2].isFlipped = false;
          });
        }
      });
    }

    _flippedCardIndices = [];
    // Даем небольшую паузу перед разблокировкой нажатий, чтобы анимации успели завершиться
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _ignoreTaps = false);
    });
  }

  void _showGameEndDialog({required bool won}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(won ? '🎉 Поздравляем! 🎉' : 'Попробуйте еще!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green.shade700 : Colors.red.shade700)),
          content: Text(won
              ? 'Вы нашли все пары за $_moves ходов!'
              : 'Не сдавайтесь, у вас получится!'),
          actions: <Widget>[
            TextButton(
              child: Text('Играть снова',
                  style: TextStyle(
                      color: appBarColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
            ),
            TextButton(
              child: Text('В меню игр',
                  style: TextStyle(color: Colors.grey.shade700)),
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
                Navigator.of(context).pop(); // Вернуться на страницу выбора игр
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langDisplayName =
        _languageOptions[widget.languageCode] ?? widget.languageCode;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Запомни: $langDisplayName',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: appBarColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
                child: Text("Ходы: $_moves",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500))),
          )
        ],
      ),
      body: _gameItemsWithState.isEmpty
          ? Center(
              child: Text("Загрузка игры для языка: ${widget.languageCode}..."))
          : LayoutBuilder(
              // Для адаптивности GridView
              builder: (context, constraints) {
                int crossAxisCount = 4;
                if (constraints.maxWidth < 350) crossAxisCount = 3;
                if (constraints.maxWidth >= 600) crossAxisCount = 5;
                if (constraints.maxWidth >= 800) crossAxisCount = 6;

                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.9, // Можно подбирать для лучшего вида
                  ),
                  itemCount: _gameItemsWithState.length,
                  itemBuilder: (context, index) {
                    return _buildAnimatedCard(index);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _initializeGame,
        icon: const Icon(Icons.refresh),
        label: const Text("Заново"),
        backgroundColor: appBarColor,
      ),
    );
  }

  Widget _buildAnimatedCard(int index) {
    final item = _gameItemsWithState[index];

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedBuilder(
        animation: _flipAnimations[index]!,
        builder: (context, child) {
          final angle =
              _flipAnimations[index]!.value * pi; // 0 to pi (180 degrees)
          final isFront = angle < (pi / 2); // Show front if angle < 90 degrees

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: item.isMatched
                  ? matchedCardColor.withOpacity(0.7)
                  : (isFront ? cardBackColor : cardFrontColor),
              child: Center(
                child: Transform(
                    // Обратный поворот для контента, чтобы он не был зеркальным
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(isFront ? 0 : pi),
                    child: item.isMatched
                        ? Icon(Icons.check_circle_outline_rounded,
                            color: Colors.green.shade900.withOpacity(0.9),
                            size: 40)
                        : (isFront
                            ? Icon(Icons.question_mark_rounded,
                                size: 40, color: Colors.white.withOpacity(0.9))
                            : FittedBox(
                                // Чтобы текст вмещался
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    item.content,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ))),
              ),
            ),
          );
        },
      ),
    );
  }

  final Map<String, String> _languageOptions = {
    'english': 'Англ.',
    'german': 'Нем.',
    'spanish': 'Исп.',
  };
}

// Простая модель для элемента игры с его состоянием
class MemoryItem {
  final String content;
  bool isFlipped;
  bool isMatched;

  MemoryItem(
      {required this.content, this.isFlipped = false, this.isMatched = false});
}
