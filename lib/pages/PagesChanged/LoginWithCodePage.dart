import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginWithCodePage extends StatefulWidget {
  @override
  _LoginWithCodePageState createState() => _LoginWithCodePageState();
}

class _LoginWithCodePageState extends State<LoginWithCodePage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  String _message = '';

  final String serverUrl = 'http://localhost:3000'; // Замени на адрес сервера

  Future<void> sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Введите email');
      return;
    }

    final response = await http.post(
      Uri.parse('$serverUrl/send-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      setState(() {
        _codeSent = true;
        _message = 'Код отправлен на $email';
      });
    } else {
      setState(() => _message = data['error'] ?? 'Ошибка отправки кода');
    }
  }

  Future<void> verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (email.isEmpty || code.isEmpty) {
      setState(() => _message = 'Введите email и код');
      return;
    }

    final response = await http.post(
      Uri.parse('$serverUrl/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      setState(() => _message = 'Вход выполнен успешно!');
      // Тут можно перейти на следующий экран или сохранить сессию
    } else {
      setState(() => _message = data['error'] ?? 'Неверный код');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Вход по Email + коду')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_codeSent)
              TextField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Код подтверждения'),
                keyboardType: TextInputType.number,
              ),
            SizedBox(height: 20),
            if (!_codeSent)
              ElevatedButton(
                onPressed: sendCode,
                child: Text('Получить код'),
              ),
            if (_codeSent)
              ElevatedButton(
                onPressed: verifyCode,
                child: Text('Войти'),
              ),
            SizedBox(height: 20),
            Text(_message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
