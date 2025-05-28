// lib/pages/RegistrationPage.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_languageapplicationmycourse_2/database/auth/service.dart'; // Если не используется, можно удалить
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
// import 'package:flutter_languageapplicationmycourse_2/pages/SelectLanguagePage.dart'; // Этот импорт будет нужен, когда создадите файл
import 'package:toast/toast.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController birthEditingController = TextEditingController();
  DateTime? _selectedDate;
  UsersCollection usersCollection = UsersCollection();

  Timer? _timer; // Для логики восстановления жизней

  @override
  void initState() {
    super.initState();
    // Логика _startLifeRestoreTimer() на странице регистрации может быть избыточной,
    // так как пользователь еще не начал активно использовать жизни.
    // Рассмотрите перенос этой логики на активную страницу, например, LearnPage.
    // _startLifeRestoreTimer();
  }

  // void _startLifeRestoreTimer() {
  //   _timer = Timer.periodic(Duration(minutes: 1), (timer) {
  //     _restoreLivesIfNeeded();
  //   });
  // }

  // Future<void> _restoreLivesIfNeeded() async {
  //   // ... (ваша логика) ...
  //   // Лучше перенести эту логику
  // }

  @override
  void dispose() {
    _timer?.cancel();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    birthEditingController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        birthEditingController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _registerUser() async {
    // Ваши проверки полей (оставлены без изменений)
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        emailController.text.isEmpty ||
        birthEditingController.text.isEmpty) {
      Toast.show('Заполните все поля');
      return;
    }
    if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(firstNameController.text)) {
      Toast.show('Имя может содержать только буквы');
      return;
    }
    if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(lastNameController.text)) {
      Toast.show('Фамилия может содержать только буквы');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(emailController.text)) {
      Toast.show('Введите корректный email');
      return;
    }
    if (_selectedDate == null) {
      Toast.show('Выберите дату рождения');
      return;
    }
    int age = DateTime.now().year - _selectedDate!.year;
    if (DateTime.now().month < _selectedDate!.month ||
        (DateTime.now().month == _selectedDate!.month &&
            DateTime.now().day < _selectedDate!.day)) {
      age--;
    }
    if (age < 6) {
      Toast.show('Вы должны быть старше 6 лет');
      return;
    } else if (age > 100) {
      Toast.show('Вы не можете быть старше 100 лет');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        // --- Начало изменений ---
        String id = user.uid;

        // 1. Отправка письма для верификации (если это ваша стратегия)
        // Если верификация обязательна ПЕРЕД выбором языка, то после этого нужно перенаправить на /auth
        // и уже после успешного входа и верификации проверять, выбран ли язык.
        // Сейчас я предполагаю, что выбор языка идет сразу после регистрации.
        // await user.sendEmailVerification();

        // 2. Создание базового документа пользователя в Firestore.
        // НЕ создаем здесь 'languageSettings' или 'languageLevel'.
        // Это будет сделано на странице выбора языка.
        // Ваш usersCollection.addUserCollection должен создавать только основные поля.
        // Адаптируйте его, если он добавляет специфичные для языка поля.
        await usersCollection.addUserCollection(
          id,
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          emailController.text.trim(),
          birthEditingController.text,
          'Не указан', // Изображение по умолчанию
          '', // Язык/уровень оставляем пустым или ставим маркер типа 'not_selected'
        );

        // 3. Дополнительно, убедимся, что базовые поля, не зависящие от языка, созданы.
        // SetOptions(merge: true) поможет, если addUserCollection уже создал какие-то из этих полей.
        await FirebaseFirestore.instance.collection('users').doc(id).set({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': emailController.text.trim(), // Email уже есть от Auth, но для Firestore полезно
          'birthDate': birthEditingController.text,
          'profileImageUrl': 'Не указан', // Или ваше значение по умолчанию
          'lives': 5, // Начальное количество жизней
          'lastRestored': Timestamp.now(),
          'registrationDate': Timestamp.now(),
          // Убираем все поля, связанные с прогрессом по конкретным уровням или языком:
          // 'languageLevel': 'Beginner',
          // 'progress': 0, 'progressel': 0, и т.д.
        }, SetOptions(merge: true));

        Navigator.pop(context); // Закрываем индикатор загрузки

        // Сообщение пользователю
        // Если была отправка письма верификации, то здесь может быть другое сообщение.
        Toast.show('Регистрация успешна!', duration: Toast.lengthLong);

        // 4. Перенаправляем на страницу выбора языка.
        // Используем pushReplacementNamed, чтобы пользователь не мог вернуться на страницу регистрации.
        Navigator.pushReplacementNamed(context, '/selectLanguage');
        // --- Конец изменений ---

      } else {
        Navigator.pop(context);
        Toast.show('Не удалось создать пользователя. Попробуйте снова.');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Пароль слишком простой.';
          break;
        case 'email-already-in-use':
          message = 'Аккаунт с такой электронной почтой уже существует.';
          break;
        case 'invalid-email':
          message = 'Неверный адрес электронной почты.';
          break;
        default:
          message = 'Произошла ошибка регистрации: ${e.message}';
      }
      Toast.show(message);
    } catch (e) {
      Navigator.pop(context);
      Toast.show('Произошла неизвестная ошибка. Пожалуйста, попробуйте еще раз.');
      print("Ошибка регистрации: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context); // Инициализация Toast
    return Scaffold(
      // ... остальной UI без изменений ...
      backgroundColor: const Color.fromARGB(255, 209, 255, 212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "images/LingoQuest_logo.png",
                height: MediaQuery.of(context).size.height * 0.1,
              ),
              const SizedBox(height: 20),
              _buildTextField(firstNameController, 'Имя', 'Имя', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(lastNameController, 'Фамилия', 'Фамилия', Icons.person_4_outlined),
              const SizedBox(height: 16),
              _buildTextField(emailController, 'Email', 'Email', Icons.email),
              const SizedBox(height: 16),
              _buildTextField(passwordController, 'Пароль', 'Пароль', Icons.password, obscureText: true),
              const SizedBox(height: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: birthEditingController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: const InputDecoration(
                    labelText: 'Дата рождения',
                    hintText: 'Выберите дату рождения',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                     focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 4, 104, 43),
                          width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 4, 104, 43),
                          width: 1.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 50,
                child: ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 4, 104, 43),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Зарегистрироваться", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                child: const Text(
                  "Есть аккаунт? Войти",
                  style: TextStyle(color: Colors.black, decoration: TextDecoration.underline),
                ),
                onTap: () => Navigator.popAndPushNamed(context, '/auth'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData prefixIcon,
      {bool obscureText = false}) {
    // ... ваш UI для TextField без изменений ...
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(prefixIcon, color: Color.fromARGB(255, 4, 104, 43)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: const Color.fromARGB(255, 4, 104, 43),
                width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: const Color.fromARGB(255, 4, 104, 43),
                width: 1.0),
          ),
        ),
      ),
    );
  }
}