import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_languageapplicationmycourse_2/database/auth/service.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/LanguageLevelTestPage.dart';
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

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLifeRestoreTimer();
  }

  void _startLifeRestoreTimer() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _restoreLivesIfNeeded();
    });
  }

  Future<void> _restoreLivesIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        int lives = userDoc['lives'];
        Timestamp lastRestored = userDoc['lastRestored'];

        int minutesPassed =
            DateTime.now().difference(lastRestored.toDate()).inMinutes;

        if (minutesPassed >= 5) {
          lives++;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'lives': lives,
            'lastRestored': Timestamp.now(),
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 209, 255, 212), // Фон страницы
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                "images/LingoQuest_logo.png",
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width * 0.5,
              ),
              _buildTextField(firstNameController, 'Имя', 'Имя', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(lastNameController, 'Фамилия', 'Фамилия',
                  Icons.person_4_outlined),
              const SizedBox(height: 16),
              _buildTextField(emailController, 'Email', 'Email', Icons.email),
              const SizedBox(height: 16),
              _buildTextField(
                  passwordController, 'Пароль', 'Пароль', Icons.password,
                  obscureText: true),
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
                    prefixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.55,
                height: MediaQuery.of(context).size.height * 0.06,
                child: ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 4, 104, 43), // Цвет кнопки
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Зарегистрироваться"),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                child: const Text(
                  "Есть аккаунт? Войти",
                  style: TextStyle(color: Colors.black),
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
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(prefixIcon),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: const Color.fromARGB(255, 4, 104, 43),
                width: 2.0), // Цвет границы при фокусе
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: const Color.fromARGB(255, 4, 104, 43),
                width: 1.0), // Цвет границы по умолчанию
          ),
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    // Проверка на пустые поля
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        emailController.text.isEmpty ||
        birthEditingController.text.isEmpty) {
      Toast.show('Заполните все поля');
      return;
    }

    // Проверка на наличие цифр в имени и фамилии
    if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(firstNameController.text)) {
      Toast.show('Имя может содержать только буквы');
      return;
    }

    if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(lastNameController.text)) {
      Toast.show('Фамилия может содержать только буквы');
      return;
    }

    // Проверка на правильность формата email
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(emailController.text)) {
      Toast.show('Введите корректный email');
      return;
    }

    // Проверка на возраст (дата рождения)
    if (_selectedDate == null) {
      Toast.show('Выберите дату рождения');
      return;
    }

    int age = DateTime.now().year - _selectedDate!.year;
    if (DateTime.now().isBefore(DateTime(
        _selectedDate!.year + age, _selectedDate!.month, _selectedDate!.day))) {
      age--;
    }

    if (age < 6) {
      Toast.show('Вы должны быть старше 6 лет');
      return;
    } else if (age > 100) {
      Toast.show('Вы не можете быть старше 100 лет');
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      String id = userCredential.user!.uid;

      // Отладочные сообщения для проверки значений
      print("First Name: ${firstNameController.text}");
      print("Last Name: ${lastNameController.text}");
      print("Email: ${emailController.text}");
      print("Birth Date: ${birthEditingController.text}");

      // Добавляем пользователя в коллекцию
      await usersCollection.addUserCollection(
        id,
        firstNameController.text, // Имя
        lastNameController.text, // Фамилия
        emailController.text, // Email
        birthEditingController.text, // Дата рождения
        'Не указан', // Изображение
        'Advanced', // Язык (по умолчанию)
      );

      await FirebaseFirestore.instance.collection('users').doc(id).set({
        'lives': 5,
        'lastRestored': Timestamp.now(),
        'progress': 0, // Добавьте прогресс здесь
        'progressel': 0, // Добавьте прогресс здесь
        'progressint': 0, // Добавьте прогресс здесь
        'progressupint': 0, // Добавьте прогресс здесь
        'progressadv': 0, // Добавьте прогресс здесь
        'progressaudio': 0, // Добавьте прогресс здесь
      }, SetOptions(merge: true));

      // Обновление последнего входа пользователя
      await AuthService().updateUserLastLogin(id); // Добавлено здесь

      Toast.show('Вы успешно зарегистрировались');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LanguageLevelTestPage(
            userId: id,
            email: emailController.text,
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            birthDate: birthEditingController.text,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Пароль слишком простой.';
          break;
        case 'email-already-in-use':
          message = 'Электронная почта уже используется.';
          break;
        case 'invalid-email':
          message = 'Неверный адрес электронной почты.';
          break;
        default:
          message = 'Произошла ошибка. Пожалуйста, попробуйте еще раз.';
      }
      Toast.show(message);
    } catch (e) {
      Toast.show('Произошла ошибка. Пожалуйста, попробуйте еще раз.');
    }
  }
}
