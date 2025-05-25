import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_languageapplicationmycourse_2/database/auth/service.dart'; // Убедитесь, что этот сервис вам все еще нужен в таком виде
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
// import 'package:flutter_languageapplicationmycourse_2/pages/newPages/LanguageLevelTestPage.dart'; // Пока не переходим сюда сразу
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

  // Таймер для жизней можно оставить, он не мешает логике регистрации
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
    // Эта логика должна срабатывать для ЗАЛОГИНЕННОГО пользователя.
    // На странице регистрации пользователь еще не залогинен (или только что зарегистрировался).
    // Возможно, эту логику лучше перенести в главный экран приложения или туда, где пользователь проводит время.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) { // Добавим проверку на верификацию
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        // ... остальная логика восстановления жизней
        int lives = userDoc['lives'];
        if (userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('lastRestored')) {
            Timestamp lastRestored = userDoc['lastRestored'];
            int minutesPassed = DateTime.now().difference(lastRestored.toDate()).inMinutes;
            if (minutesPassed >= 5 && lives < 5) { // Предположим, максимум 5 жизней
              lives++;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'lives': lives,
                'lastRestored': Timestamp.now(),
              });
            }
        } else {
            // Если lastRestored нет, возможно, это первый раз или ошибка
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'lastRestored': Timestamp.now(), // Устанавливаем начальное значение
            });
        }
      }
    }
  }

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
    // Ваши проверки полей
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

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        // ОТПРАВЛЯЕМ ПИСЬМО ДЛЯ ПОДТВЕРЖДЕНИЯ EMAIL
        await user.sendEmailVerification();

        String id = user.uid;

        await usersCollection.addUserCollection(
          id,
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          emailController.text.trim(),
          birthEditingController.text,
          'Не указан',
          'Beginner', // Установим начальный уровень, например
        );

        await FirebaseFirestore.instance.collection('users').doc(id).set({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'birthDate': birthEditingController.text,
          'profileImageUrl': 'Не указан',
          'languageLevel': 'Beginner', // Дублируем для консистентности или выбираем один источник правды
          'lives': 5,
          'lastRestored': Timestamp.now(),
          'progress': 0,
          'progressel': 0,
          'progressint': 0,
          'progressupint': 0,
          'progressadv': 0,
          'progressaudio': 0,
          'registrationDate': Timestamp.now(),
          // 'isEmailVerified': false, // Не обязательно, т.к. FirebaseAuth сам хранит это
        }, SetOptions(merge: true));

        // AuthService().updateUserLastLogin(id); // Пользователь еще не вошел, только зарегистрировался

        Navigator.pop(context); // Закрываем индикатор загрузки

        Toast.show(
            'Регистрация успешна! Мы отправили письмо для подтверждения на ${user.email}. Пожалуйста, подтвердите ваш email и затем войдите.',
            duration: Toast.lengthLong);

        // Перенаправляем на страницу входа
        Navigator.popAndPushNamed(context, '/auth');
      } else {
        Navigator.pop(context); // Закрываем индикатор загрузки
        Toast.show('Не удалось создать пользователя. Попробуйте снова.');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Закрываем индикатор загрузки
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
      Navigator.pop(context); // Закрываем индикатор загрузки
      Toast.show('Произошла неизвестная ошибка. Пожалуйста, попробуйте еще раз.');
      print("Ошибка регистрации: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
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
                width: MediaQuery.of(context).size.width * 0.7, // Немного увеличил ширину
                height: 50, // Фиксированная высота
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