// lib/pages/GamePages/AntonymPage.dart
import 'package:flutter/material.dart';
import 'dart:math';

class AntonymMatchingPage extends StatefulWidget {
  final String languageCode;

  const AntonymMatchingPage({Key? key, required this.languageCode})
      : super(key: key);

  @override
  _AntonymMatchingPageState createState() => _AntonymMatchingPageState();
}

class WordPair {
  final String word;
  final String antonym;
  bool isMatched;
  WordPair(this.word, this.antonym, {this.isMatched = false});
}

class _AntonymMatchingPageState extends State<AntonymMatchingPage> {
  // --- Цвета и стили ---
  final Color appBarColor =
      const Color.fromARGB(255, 255, 162, 40); // Бирюзовый
  final Color backgroundColor =
      const Color.fromARGB(255, 252, 194, 70); // Очень светло-бирюзовый
  final Color cardColor = Colors.white;
  final Color selectedCardColor =
      const Color.fromARGB(255, 253, 137, 28); // Светло-желтый для выбранной
  final Color matchedCardColor =
      const Color(0xFFA5D6A7); // Светло-зеленый для совпавшей
  final Color textColor = const Color(0xFF004D40); // Темно-бирюзовый для текста
  final Color matchedTextColor = Colors.grey.shade600;
  // ---------------------

  late List<WordPair> _allPairs;
  List<SelectableItem> _displayItemsWithState = [];

  int? _selectedIndex1;
  int? _selectedIndex2;
  int _score = 0;
  bool _ignoreTaps = false;

  final Map<String, List<WordPair>> _antonymsByLanguage = {
    'english': [
      WordPair('HOT', 'COLD'),
      WordPair('BIG', 'SMALL'),
      /* ... другие ... */ WordPair('UP', 'DOWN'),
      WordPair('OPEN', 'CLOSED'),
      WordPair('FAST', 'SLOW'),
      WordPair('HAPPY', 'SAD')
    ],
    'spanish': [
      WordPair('CALIENTE', 'FRÍO'),
      WordPair('GRANDE', 'PEQUEÑO'),
      /* ... */ WordPair('ARRIBA', 'ABAJO'),
      WordPair('ABIERTO', 'CERRADO'),
      WordPair('RÁPIDO', 'LENTO'),
      WordPair('FELIZ', 'TRISTE')
    ],
    'german': [
      WordPair('HEISS', 'KALT'),
      WordPair('GROß', 'KLEIN'),
      /* ... */ WordPair('OBEN', 'UNTEN'),
      WordPair('OFFEN', 'GESCHLOSSEN'),
      WordPair('SCHNELL', 'LANGSAM'),
      WordPair('FRÖHLICH', 'TRAURIG')
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _allPairs = List<WordPair>.from(_antonymsByLanguage[widget.languageCode] ??
        _antonymsByLanguage['english']!);
    if (_allPairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Нет антонимов для игры на языке: ${widget.languageCode}'),
            backgroundColor: Colors.red),
      );
      Navigator.of(context).pop();
      return;
    }

    List<String> tempDisplay = [];
    for (var pair in _allPairs) {
      pair.isMatched = false;
      tempDisplay.add(pair.word);
      tempDisplay.add(pair.antonym);
    }
    tempDisplay.shuffle(Random());

    _displayItemsWithState =
        tempDisplay.map((text) => SelectableItem(text: text)).toList();

    _selectedIndex1 = null;
    _selectedIndex2 = null;
    _score = 0;
    _ignoreTaps = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _onCardTap(int index) {
    if (_ignoreTaps ||
        _displayItemsWithState[index].isMatched ||
        _selectedIndex1 == index) return;

    setState(() {
      if (_selectedIndex1 == null) {
        _selectedIndex1 = index;
        _displayItemsWithState[index].isSelected = true;
      } else {
        // _selectedIndex2 будет null здесь по логике
        _selectedIndex2 = index;
        _displayItemsWithState[index].isSelected = true;
        _ignoreTaps = true;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (_selectedIndex1 == null || _selectedIndex2 == null) return;

    final item1 = _displayItemsWithState[_selectedIndex1!];
    final item2 = _displayItemsWithState[_selectedIndex2!];
    bool matchFound = false;

    for (var pair in _allPairs) {
      if (!pair.isMatched &&
          ((pair.word == item1.text && pair.antonym == item2.text) ||
              (pair.word == item2.text && pair.antonym == item1.text))) {
        matchFound = true;
        pair.isMatched = true; // Отмечаем пару как совпавшую
        item1.isMatched = true; // Отмечаем элементы отображения как совпавшие
        item2.isMatched = true;
        _score++;
        break;
      }
    }

    // Сбрасываем выделение и состояние через некоторое время
    Future.delayed(Duration(milliseconds: matchFound ? 300 : 700), () {
      if (mounted) {
        setState(() {
          item1.isSelected = false;
          item2.isSelected = false;
          _selectedIndex1 = null;
          _selectedIndex2 = null;
          _ignoreTaps = false;

          if (_score == _allPairs.length) {
            _showGameEndDialog();
          }
        });
      }
    });
  }

  // lib/pages/GamePages/AntonymPage.dart

// ... (весь остальной код класса _AntonymMatchingPageState до этого метода) ...

  void _showGameEndDialog() {
    if (!mounted) return;
    showDialog(
      context: context, // <--- БЫЛ ПРОПУЩЕН
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // <--- БЫЛ ПРОПУЩЕН (и параметр context)
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('🎉 Поздравляем! 🎉',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          content: Text(
              'Вы нашли все пары антонимов! Ваш итоговый счет: $_score / ${_allPairs.length}'),
          actions: <Widget>[
            TextButton(
              child: Text('Играть снова',
                  style: TextStyle(
                      color: appBarColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Используем dialogContext
                _initializeGame();
              },
            ),
            TextButton(
              child: Text('В меню игр',
                  style: TextStyle(color: Colors.grey.shade700)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Используем dialogContext
                // Если ViewGamesPage - это предыдущий экран в стеке:
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  // Если нужно перейти по имени маршрута (например, если стек другой)
                  // Navigator.pushReplacementNamed(context, '/games'); // Замените '/games' на ваш путь к ViewGamesPage
                }
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
        title: Text('Найди антоним: $langDisplayName',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: appBarColor,
        elevation: 0,
      ),
      body: _displayItemsWithState.isEmpty
          ? Center(
              child: Text("Загрузка игры для языка: ${widget.languageCode}..."))
          : Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Счет: $_score / ${_allPairs.length}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        if (_score == _allPairs.length)
                          Icon(Icons.celebration_rounded,
                              color: Colors.amber.shade700, size: 28)
                      ],
                    )),
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 700
                        ? 4
                        : (constraints.maxWidth > 450 ? 3 : 2);
                    double childAspectRatio = 2.2; // Для более широких карточек
                    if (crossAxisCount == 2) childAspectRatio = 1.8;

                    return GridView.builder(
                      padding: const EdgeInsets.all(12.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: _displayItemsWithState.length,
                      itemBuilder: (context, index) {
                        final item = _displayItemsWithState[index];
                        return _buildAntonymCard(item, index);
                      },
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Начать заново"),
                    onPressed: _initializeGame,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: appBarColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildAntonymCard(SelectableItem item, int index) {
    Color bgColor = cardColor;
    Color fgColor = textColor;
    double elevation = 3.0;
    BorderSide border = BorderSide.none;

    if (item.isMatched) {
      bgColor = matchedCardColor.withOpacity(0.6);
      fgColor = matchedTextColor;
      elevation = 1.0;
    } else if (item.isSelected) {
      bgColor = selectedCardColor;
      fgColor = Colors.black87;
      elevation = 6.0;
      border = BorderSide(color: Colors.amber.shade800, width: 2.5);
    }

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Card(
        elevation: elevation,
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedContainer(
          // Для плавной смены цвета/тени
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
              // Если хотите градиент для невыбранных
              // gradient: !item.isSelected && !item.isMatched ? LinearGradient(...) : null,
              ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FittedBox(
                // Чтобы текст вмещался
                fit: BoxFit.scaleDown,
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        item.isSelected ? FontWeight.bold : FontWeight.w500,
                    color: fgColor,
                    decoration: item.isMatched
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: Colors.redAccent.withOpacity(0.7),
                    decorationThickness: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final Map<String, String> _languageOptions = {
    'english': 'Англ.',
    'german': 'Нем.',
    'spanish': 'Исп.',
  };
}

// Модель для элемента отображения в игре "Найди пару"
class SelectableItem {
  final String text;
  bool isSelected;
  bool isMatched;

  SelectableItem(
      {required this.text, this.isSelected = false, this.isMatched = false});
}
