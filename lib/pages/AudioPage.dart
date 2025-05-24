import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AudioMessage.dart'; // Импортируйте ваш виджет AudioMessageCreator

class AudioPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Аудио"),
        backgroundColor: const Color.fromARGB(255, 23, 180, 36),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Создайте аудиосообщение",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            AudioMessageCreator(), // Ваш виджет для создания аудио сообщений
          ],
        ),
      ),
    );
  }
}
