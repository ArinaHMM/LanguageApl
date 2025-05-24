import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/LearnPage.dart';

class ActionSelectionPage extends StatefulWidget {
  final String userId;

  const ActionSelectionPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ActionSelectionPageState createState() => _ActionSelectionPageState();
}

class _ActionSelectionPageState extends State<ActionSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Выбор действия")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Что вы хотите сделать?"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Начать с основ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LearnPage(),
                  ),
                );
              },
              child: const Text("Начать с основ"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
