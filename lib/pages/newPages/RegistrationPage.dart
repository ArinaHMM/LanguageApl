// lib/pages/RegistrationPage.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart'; // <-- ВАЖНО: Убедитесь, что UserRoles здесь или импортированы

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController birthEditingController = TextEditingController();
  DateTime? _selectedDate;
  UsersCollection usersCollection = UsersCollection();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color primaryOrange = const Color.fromARGB(255, 255, 132, 49);
  final Color accentOrange = const Color.fromARGB(255, 255, 160, 90);
  final Color darkOrange = const Color.fromARGB(255, 230, 100, 20);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      initialDate: _selectedDate ??
          DateTime.now().subtract(
              const Duration(days: 365 * 18)), // Начальная дата - 18 лет назад
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(
          const Duration(days: 365 * 6)), // Минимальный возраст - 6 лет
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryOrange, // Цвет шапки DatePicker
              onPrimary: Colors.white, // Цвет текста на шапке
            ),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        birthEditingController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDate == null) {
      _showSnackBar('Пожалуйста, выберите дату рождения.');
      return;
    }
    int age = DateTime.now().year - _selectedDate!.year;
    if (DateTime.now().month < _selectedDate!.month ||
        (DateTime.now().month == _selectedDate!.month && DateTime.now().day < _selectedDate!.day)) {
      age--;
    }
    if (age < 6) { _showSnackBar('Вы должны быть старше 6 лет.'); return; }
    if (age > 100) { _showSnackBar('Пожалуйста, укажите корректный возраст (до 100 лет).'); return; }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      User? user = userCredential.user;

      if (user != null) {
        String id = user.uid;
        
        // Опционально: отправить письмо для верификации email
        try {
          await user.sendEmailVerification();
          _showSnackBar('Письмо для подтверждения отправлено на ваш email.', isError: false);
        } catch (e) {
          print("Error sending verification email: $e");
          _showSnackBar('Не удалось отправить письмо для подтверждения email.');
        }

        // Использование вашего существующего метода addUserCollection,
        // который, как мы предположили, устанавливает базовые поля, включая роль 'user'.
        // Убедитесь, что он не создает languageSettings, так как язык еще не выбран.
        await usersCollection.addUserCollection( // Предполагаем, что этот метод создает базовый документ
          id,
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          emailController.text.trim(),
          birthEditingController.text,
          'default_avatar.png', // Или другой стандартный аватар
          null, // Передаем null или пустую строку для языка, т.к. он выбирается позже
        );

        // --- ДОБАВЛЕНИЕ/ОБНОВЛЕНИЕ ПОЛЕЙ ДЛЯ ЦЕЛЕЙ И СТРИКОВ ---
        // Используем SetOptions(merge: true) для добавления новых полей или обновления существующих,
        // не перезаписывая весь документ, если addUserCollection уже что-то создал.
        await FirebaseFirestore.instance.collection('users').doc(id).set({
          // Основные поля, которые могли быть установлены в addUserCollection,
          // здесь можно их подтвердить или установить, если addUserCollection их не ставит.
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'birthDate': birthEditingController.text,
          'profileImageUrl': 'default_avatar.png',
          'inventory': {}, 
          'role': UserRoles.user, // Явно устанавливаем роль пользователя
          'lives': 5,
          'lastRestored': Timestamp.now(),
          'registrationDate': Timestamp.now(), // Это должно быть установлено при создании документа
          
          // Поля для языковых настроек (будут null или пустыми до выбора языка)
          'languageSettings': null, // или UserLanguageSettings.empty().toMap() если модель это поддерживает и это нужно

          // Новые поля для целей и стриков
          'dailyGoalXp': 50,        // Начальная цель по XP
          'currentStreak': 0,       // Начальный стрик
          'lastGoalCompletionDate': null,
           // Нет выполненных целей
          'streakFreezes': 0,  
          'lastStreakCheckDate': Timestamp.now(),
          'leagueId': 'bronze',      
          'weeklyXp': 0,
          'unlockedAchievements': {},
          'totalXp': 0, 
          'lastGoalChangeDate':null,
          // Начальное количество заморозок
        }, SetOptions(merge: true));
        // ------------------------------------------------------

        if (mounted) {
          _showSnackBar('Регистрация успешна! Теперь выберите язык.', isError: false);
          Navigator.pushReplacementNamed(context, '/selectLanguage');
        }
      } else {
        if (mounted) _showSnackBar('Не удалось создать пользователя. Попробуйте снова.');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password': message = 'Пароль слишком простой. Минимум 6 символов.'; break;
        case 'email-already-in-use': message = 'Аккаунт с такой почтой уже существует.'; break;
        case 'invalid-email': message = 'Неверный адрес электронной почты.'; break;
        default: message = 'Ошибка регистрации. Попробуйте позже.'; // e.message может быть слишком техническим
          print("FirebaseAuthException on registration: ${e.code} - ${e.message}");
      }
      if (mounted) _showSnackBar(message);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Произошла неизвестная ошибка. Пожалуйста, попробуйте еще раз.');
        print("Ошибка регистрации: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI остается таким же, как вы предоставили)
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentOrange, primaryOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "images/LingoQuest_logo.png",
                            height: screenHeight * 0.08,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            "Создать аккаунт",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkOrange,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          _buildTextFormField(
                            controller: firstNameController,
                            labelText: 'Имя',
                            hintText: 'Введите ваше имя',
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Пожалуйста, введите имя.';
                              if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(value)) return 'Имя может содержать только буквы.';
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildTextFormField(
                            controller: lastNameController,
                            labelText: 'Фамилия',
                            hintText: 'Введите вашу фамилию',
                            prefixIcon: Icons.person_search_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Пожалуйста, введите фамилию.';
                              if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(value)) return 'Фамилия может содержать только буквы.';
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildTextFormField(
                            controller: emailController,
                            labelText: 'Почта',
                            hintText: 'example@mail.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Пожалуйста, введите email.';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) return 'Введите корректный email.';
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildTextFormField(
                            controller: passwordController,
                            labelText: 'Пароль',
                            hintText: 'Минимум 6 символов',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon( _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: primaryOrange,),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Пожалуйста, введите пароль.';
                              if (value.length < 6) return 'Пароль должен быть не менее 6 символов.';
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          TextFormField(
                            controller: birthEditingController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'Дата рождения',
                              hintText: 'Выберите дату',
                              prefixIcon: Icon(Icons.calendar_today_outlined, color: primaryOrange),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder( borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none,),
                              focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: primaryOrange, width: 2.0),),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Пожалуйста, выберите дату рождения.';
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          _isLoading
                              ? CircularProgressIndicator(color: primaryOrange)
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _registerUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryOrange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    child: const Text("Зарегистрироваться"),
                                  ),
                                ),
                          SizedBox(height: screenHeight * 0.02),
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.popAndPushNamed(context, '/auth'),
                            child: Text("Уже есть аккаунт? Войти", style: TextStyle(color: darkOrange, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
     return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: primaryOrange),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100], 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: primaryOrange, width: 2.0)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.redAccent, width: 2.0)),
        labelStyle: TextStyle(color: Colors.grey[700]),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}