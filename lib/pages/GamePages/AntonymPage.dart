import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AntonymMatchingPage extends StatefulWidget {
  @override
  _AntonymMatchingPageState createState() => _AntonymMatchingPageState();
}

class _AntonymMatchingPageState extends State<AntonymMatchingPage> {
  List<Map<String, String>> antonymPairs = [];
  List<String> leftOptions = [];
  List<String> rightOptions = [];
  List<bool> leftMatchStatus = [];
  List<bool> rightMatchStatus = [];
  bool isLoading = true;
  int currentPage = 0; // Текущая страница
  int totalMatchedPairs = 0; // Общее количество найденных пар
  final int pairsPerPage = 3; // Количество пар на одной странице

  @override
  void initState() {
    super.initState();
    _fetchRandomAntonyms();
  }

  Future<void> _fetchRandomAntonyms() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('antonyms').get();
      if (snapshot.docs.isNotEmpty) {
        // Получаем случайные пары антонимов
        List<Map<String, String>> tempPairs = [];
        for (var doc in snapshot.docs) {
          tempPairs.add({
            'word': doc['word'],
            'antonym': doc['antonym'],
          });
        }

        // Случайно выбираем 3 пары
        tempPairs.shuffle();
        antonymPairs = tempPairs.take(pairsPerPage).toList();

        // Генерируем варианты для левой и правой стороны
        leftOptions = antonymPairs.map((pair) => pair['word']!).toList();
        rightOptions = antonymPairs.map((pair) => pair['antonym']!).toList();
        
        // Перемешиваем правую сторону
        rightOptions.shuffle();

        leftMatchStatus = List.generate(leftOptions.length, (index) => false);
        rightMatchStatus = List.generate(rightOptions.length, (index) => false);

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Нет антонимов в коллекции "antonyms"'),
        ));
      }
    } catch (e) {
      print("Ошибка при получении данных: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _checkMatch(String selectedWord, String targetWord, int targetIndex) {
    // Находим пару антонимов по индексу
    final selectedPair = antonymPairs.firstWhere(
      (pair) => pair['word'] == selectedWord,
      orElse: () => {},
    );

    // Проверяем, является ли выбранный антоним правильным
    bool isCorrect = selectedPair['antonym'] == targetWord;

    // Обновляем статус для конкретной пары
    setState(() {
      if (isCorrect) {
        // Устанавливаем статус правильного сопоставления
        leftMatchStatus[antonymPairs.indexOf(selectedPair)] = true; // Устанавливаем true для правильной пары слева
        rightMatchStatus[targetIndex] = true; // Устанавливаем true для правильной пары справа
        totalMatchedPairs++; // Увеличиваем общее количество найденных пар

        // Если на текущей странице все пары найдены, загружаем новые антонимы
        if (!leftMatchStatus.contains(false)) {
          if (currentPage < (totalMatchedPairs ~/ pairsPerPage)) {
            // Переходим на следующую страницу
            currentPage++;
            _fetchRandomAntonyms();
          } else {
            // Если все пары найдены, выводим сообщение
            _showCompletionDialog();
          }
        }
      } else {
        // Если пара неправильная, показываем уведомление
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Неправильная пара!'),
        ));
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Молодец!'),
          content: Text('Ты нашел все пары! Продолжить?'),
          actions: <Widget>[
            TextButton(
              child: Text('Да'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалог
                setState(() {
                  currentPage = 0; // Сбрасываем страницу
                  totalMatchedPairs = 0; // Сбрасываем счетчик пар
                  _fetchRandomAntonyms(); // Загружаем новые антонимы
                });
              },
            ),
            TextButton(
              child: Text('Нет'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем диалог
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сопоставь антонимы'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: leftOptions.asMap().entries.map((entry) {
                      int index = entry.key;
                      String word = entry.value;
                      return Draggable<String>(
                        data: word,
                        child: _buildDraggableItem(word, leftMatchStatus[index] ? Colors.green : Colors.white),
                        feedback: _buildDraggableItem(word, Colors.white),
                        childWhenDragging: Container(),
                      );
                    }).toList(),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rightOptions.asMap().entries.map((entry) {
                      int index = entry.key;
                      String word = entry.value;
                      return DragTarget<String>(
                        builder: (context, candidateData, rejectedData) {
                          return _buildTargetItem(word, rightMatchStatus[index] ? Colors.green : Colors.white);
                        },
                        onAccept: (data) {
                          // Проверяем, подходит ли слово
                          _checkMatch(data, word, index);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDraggableItem(String word, Color backgroundColor) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Text(
        word,
        style: TextStyle(color: Colors.green, fontSize: 18),
      ),
    );
  }

  Widget _buildTargetItem(String word, Color backgroundColor) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        word,
        style: TextStyle(color: Colors.green, fontSize: 18),
      ),
    );
  }
}
