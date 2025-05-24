import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({Key? key}) : super(key: key);

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  String? _generatedCode;
  bool _codeSent = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _sendCode() async {
    final code = (100000 + Random().nextInt(899999)).toString();
    setState(() => _generatedCode = code);

    // Сохраняем в Firestore (в реальности нужно отправлять через SMTP или email API)
    await _firestore.collection('email_codes').doc(_emailController.text).set({
      'code': code,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _codeSent = true);

    // Заглушка: покажи код пользователю (в продакшене — отправить по email)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Код (в реальности приходит по email): $code'),
    ));
  }

  Future<void> _verifyCode() async {
    final snapshot = await _firestore
        .collection('email_codes')
        .doc(_emailController.text)
        .get();

    if (!snapshot.exists || snapshot['code'] != _codeController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный код')),
      );
      return;
    }

    try {
      final email = _emailController.text;
      final password = 'default_password'; // Можно сгенерировать и хранить

      try {
        // Попытка войти
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      } catch (e) {
        // Если пользователь не существует — зарегистрировать
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка входа')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Вход по Email + Код")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            if (_codeSent)
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: "Код из письма"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _codeSent ? _verifyCode : _sendCode,
              child: Text(_codeSent ? "Войти" : "Получить код"),
            ),
          ],
        ),
      ),
    );
  }
}
