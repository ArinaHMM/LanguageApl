import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class MemoryGamePage extends StatefulWidget {
  @override
  _MemoryGamePageState createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage> {
  List<String> words = [];
  List<String> shuffledWords = [];
  List<bool> flippedCards = List.filled(12, false);
  List<int> selectedIndexes = [];
  bool isLoading = true;
  bool gameFinished = false;

  @override
  void initState() {
    super.initState();
    _fetchRandomWords();
  }

  // Fetch 6 random words from Firestore and shuffle them
  Future<void> _fetchRandomWords() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('game').get();
      List<String> allWords =
          snapshot.docs.map((doc) => doc['word'] as String).toList();

      if (allWords.length >= 6) {
        Set<int> randomIndexes = _getRandomIndexes(
            allWords.length, 6); // Get 6 unique random indexes
        List<String> randomWords =
            randomIndexes.map((i) => allWords[i]).toList();

        words = [...randomWords, ...randomWords]; // Create pairs
        words.shuffle(); // Shuffle the words
        setState(() {
          shuffledWords = words;
          isLoading = false;
        });
      } else {
        // Handle if not enough words are in the database
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Недостаточно слов в базе данных для игры'),
        ));
      }
    } catch (e) {
      print("Ошибка при получении данных: $e");
    }
  }

  // Generate a set of unique random indexes
  Set<int> _getRandomIndexes(int max, int count) {
    final random = Random();
    Set<int> randomIndexes = {};
    while (randomIndexes.length < count) {
      randomIndexes.add(random.nextInt(max));
    }
    return randomIndexes;
  }

  void _onCardTap(int index) {
    if (selectedIndexes.length < 2 && !flippedCards[index]) {
      setState(() {
        flippedCards[index] = true;
        selectedIndexes.add(index);
      });

      if (selectedIndexes.length == 2) {
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            if (shuffledWords[selectedIndexes[0]] !=
                shuffledWords[selectedIndexes[1]]) {
              // If words don't match, flip both back
              flippedCards[selectedIndexes[0]] = false;
              flippedCards[selectedIndexes[1]] = false;
            } else {
              // Check if all pairs are found
              if (!flippedCards.contains(false)) {
                gameFinished = true;
              }
            }
            selectedIndexes.clear();
          });
        });
      }
    }
  }

  void _resetGame() {
    setState(() {
      flippedCards = List.filled(12, false);
      gameFinished = false;
      _fetchRandomWords(); // Fetch new random words for replay
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Игра на память'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : gameFinished
              ? _buildGameFinishedScreen(context)
              : _buildGameGrid(),
    );
  }

  Widget _buildGameGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3x4 grid of cards
        childAspectRatio: 0.85,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: shuffledWords.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _onCardTap(index),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: flippedCards[index]
                  ? Colors.white
                  : Color.fromARGB(255, 5, 148, 29),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                flippedCards[index] ? shuffledWords[index] : '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameFinishedScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Поздравляем! Вы нашли все пары!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            
            onPressed: _resetGame,
            child: Text('Сыграть еще'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 13, 136, 34),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: TextStyle(fontSize: 18),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context),
            child: Text('Назад'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Color.fromARGB(255, 86, 189, 117),
              textStyle: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
