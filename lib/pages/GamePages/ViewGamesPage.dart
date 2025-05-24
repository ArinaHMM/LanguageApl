import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/AntonymPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/Game.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/HangmanGame.dart';
class GamesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Игры'),
        backgroundColor: Colors.green,
        leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pushReplacementNamed(context,'/profile'); // Возврат на предыдущую страницу
              },
      ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Количество карточек в строке
          crossAxisSpacing: 16.0, // Расстояние между колонками
          mainAxisSpacing: 16.0, // Расстояние между строками
          children: [
            _buildGameCard(context, 'Виселица', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HangmanGamePage()),
              );
            }),
            _buildGameCard(context, 'Запомни', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MemoryGamePage()),
              );
            }),
            _buildGameCard(context, 'Найди пару', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AntonymMatchingPage()),
              );
            }),
            
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 32, 129, 19), Color.fromARGB(255, 4, 170, 4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}