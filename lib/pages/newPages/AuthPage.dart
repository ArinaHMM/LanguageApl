// lib/pages/AuthPage.dart (или ваш путь)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_languageapplicationmycourse_2/database/auth/service.dart';
// Замените Toast на SnackBar для более нативного вида
// import 'package:toast/toast.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  AuthService authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final Color cardBackgroundColor = Colors.white.withOpacity(0.9);

  final String adminEmail = 'admin@mail.ru';
  final String supportEmail = 'support@mail.ru';

  // Объявляем контроллер и анимации, НО НЕ ИНИЦИАЛИЗИРУЕМ ИХ ЗДЕСЬ
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimationLogo;
  late Animation<Offset> _slideAnimationForm;

  final Color primaryOrange = const Color.fromARGB(255, 255, 132, 49);
  final Color accentOrange = const Color.fromARGB(255, 255, 160, 90);
  final Color darkOrange = const Color.fromARGB(255, 230, 100, 20);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 1200), // Общая длительность анимации
    );

    // --- ИНИЦИАЛИЗАЦИЯ АНИМАЦИЙ ПЕРЕНЕСЕНА СЮДА ---
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn, // Плавное появление для всего
      ),
    );

    _slideAnimationLogo =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      // Логотип "спускается"
      CurvedAnimation(
        parent: _animationController,
        // Можно использовать ту же кривую или другую для разных элементов
        curve:
            const Interval(0.0, 0.7, // Логотип анимируется в первые 70% времени
                curve: Curves.elasticOut),
      ),
    );

    _slideAnimationForm =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      // Форма "поднимается"
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
            0.3, 1.0, // Форма анимируется с задержкой, в последние 70% времени
            curve: Curves.elasticOut),
      ),
    );
    // --- КОНЕЦ ИНИЦИАЛИЗАЦИИ АНИМАЦИЙ ---

    _animationController.forward(); // Запускаем все анимации
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted)
      return; // Проверка, чтобы не вызывать на размонтированном виджете
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _performSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Логика для администратора и поддержки
    if (emailController.text.trim() == adminEmail) {
      await _trySignInAndNavigate(
          emailController.text.trim(), passController.text, '/navadmin',
          isAdminOrSupport: true);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (emailController.text.trim() == supportEmail) {
      await _trySignInAndNavigate(
          emailController.text.trim(),
          passController.text,
          '/prof1', // Убедитесь, что роут /prof1 существует
          isAdminOrSupport: true);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Вход для обычного пользователя
    await _trySignInAndNavigate(
        emailController.text.trim(),
        passController.text,
        '/profile'); // Убедитесь, что роут /profile существует

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _trySignInAndNavigate(
      String email, String password, String routeName,
      {bool isAdminOrSupport = false}) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user
            .reload(); // Обновляем данные пользователя (включая emailVerified)
        user = FirebaseAuth
            .instance.currentUser; // Получаем обновленного пользователя

        if (user == null) {
          // Дополнительная проверка
          if (mounted)
            _showSnackBar(
                'Не удалось получить данные пользователя после обновления.');
          return;
        }

        // Для админа и поддержки пропускаем проверку emailVerified, если это ваша логика
        // Иначе, они тоже должны будут подтверждать email.
        if (isAdminOrSupport || user.emailVerified) {
          await authService.updateUserLastLogin(user.uid);
          if (mounted) {
            _showSnackBar('Вы успешно вошли!', isError: false);
            // Используем pushNamedAndRemoveUntil для очистки стека навигации
            Navigator.pushNamedAndRemoveUntil(
                context, routeName, (route) => false);
          }
        } else {
          if (mounted) _showEmailNotVerifiedDialog(user);
        }
      } else {
        if (mounted)
          _showSnackBar('Не удалось получить данные пользователя после входа.');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email': // Часто эти две ошибки лучше объединить для пользователя
          message = 'Пользователь с таким email не найден.';
          break;
        case 'wrong-password':
          message = 'Неверный пароль.';
          break;
        case 'user-disabled':
          message = 'Аккаунт пользователя отключен.';
          break;
        case 'invalid-credential': // Firebase >= v10.0.0
          message = 'Неверный email или пароль.';
          break;
        default:
          message =
              'Ошибка входа. Попробуйте позже.'; // ${e.message} - может быть слишком техническим
          print("FirebaseAuthException: ${e.code} - ${e.message}");
      }
      if (mounted) _showSnackBar(message);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Произошла непредвиденная ошибка.');
        print("Непредвиденная ошибка входа: $e");
      }
    }
  }

  void _showEmailNotVerifiedDialog(User user) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Используем dialogContext
        bool sedangMengirim =
            false; // Для состояния кнопки "Отправить повторно"
        return StatefulBuilder(// Для обновления состояния кнопки внутри диалога
            builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0)),
            title: Row(
              children: [
                Icon(Icons.mark_email_unread_outlined, color: primaryOrange),
                const SizedBox(width: 10),
                const Text('Email не подтвержден'),
              ],
            ),
            content: Text(
                'Пожалуйста, проверьте вашу почту (${user.email}) и перейдите по ссылке для подтверждения. Без этого вход невозможен.'),
            actions: <Widget>[
              TextButton(
                child: sedangMengirim
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryOrange))
                    : Text('Отправить повторно',
                        style: TextStyle(color: primaryOrange)),
                onPressed: sedangMengirim
                    ? null
                    : () async {
                        setDialogState(() => sedangMengirim = true);
                        try {
                          await user.sendEmailVerification();
                          if (mounted)
                            _showSnackBar(
                                'Письмо для подтверждения отправлено повторно.',
                                isError: false);
                        } catch (e) {
                          if (mounted)
                            _showSnackBar(
                                'Ошибка при повторной отправке письма.');
                          print("Ошибка повторной отправки email: $e");
                        } finally {
                          if (mounted) {
                            // Проверка mounted перед вызовом Navigator.pop
                            Navigator.of(dialogContext).pop(); // Закрыть диалог
                          } else if (Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop();
                          }
                        }
                      },
              ),
              TextButton(
                child: Text('OK', style: TextStyle(color: primaryOrange)),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Закрыть диалог
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(// Используем Stack для наложения фона и контента
          children: [
        // --- ФОНОВОЕ ИЗОБРАЖЕНИЕ ---
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'images/background.png'), // Убедитесь, что путь верный
              fit: BoxFit.cover,
            ),
          ),
        ),
        // --- Полупрозрачный оверлей для улучшения читаемости (опционально) ---
        Container(
          color: primaryOrange.withOpacity(0.15), // Легкий оранжевый оттенок
        ),
        // --- Основной контент ---
        Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _slideAnimationLogo,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      "images/LingoQuest_logos.png", // Убедитесь, что путь верный
                      width: screenWidth *
                          0.55, // Немного уменьшил для баланса с фоном
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04), // Увеличил отступ
                SlideTransition(
                  position: _slideAnimationForm,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 10.0, // Немного больше тень
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              25.0)), // Более круглые углы
                      color: this
                          .cardBackgroundColor, // Полупрозрачный фон карточки
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 30.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Вход в LingoQuest",
                                style: TextStyle(
                                  fontSize: 26, // Немного увеличил
                                  fontWeight: FontWeight.bold,
                                  color: darkOrange,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              _buildAuthTextFormField(
                                controller: emailController,
                                labelText: 'Электронная почта',
                                hintText: 'email@example.com',
                                prefixIcon: Icons.alternate_email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Пожалуйста, введите email.';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                      .hasMatch(value)) {
                                    return 'Введите корректный email.';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              _buildAuthTextFormField(
                                controller: passController,
                                labelText: 'Пароль',
                                hintText: 'Введите ваш пароль',
                                prefixIcon: Icons.lock_person_outlined,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: primaryOrange,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Пожалуйста, введите пароль.';
                                  }
                                  // Можно добавить проверку на минимальную длину, если нужно
                                  // if (value.length < 6) {
                                  //   return 'Пароль должен быть не менее 6 символов.';
                                  // }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenHeight * 0.04),
                              _isLoading
                                  ? CircularProgressIndicator(
                                      color: primaryOrange)
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _performSignIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryOrange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          textStyle: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        child: const Text('ВОЙТИ'),
                                      ),
                                    ),
                              SizedBox(height: screenHeight * 0.025),
                              SizedBox(height: 20),
                              _outlinedGoogleButton(),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        // Navigator.popAndPushNamed(context, '/reg');
                                        // Лучше использовать pushReplacementNamed, если не хотите, чтобы пользователь вернулся на страницу входа
                                        Navigator.pushReplacementNamed(
                                            context, '/reg');
                                      },
                                child: Text(
                                  'Нет аккаунта? Зарегистрироваться',
                                  style: TextStyle(
                                    color: darkOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // Пользователь отменил вход
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        await authService.updateUserLastLogin(user.uid);
        _showSnackBar('Вы вошли через Google!', isError: false);
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (r) => false);
      }
    } catch (e) {
      print("Ошибка Google-входа: $e");
      _showSnackBar('Ошибка входа через Google');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _outlinedGoogleButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: darkOrange),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onPressed: _isLoading ? null : _signInWithGoogle,
      icon: Image.asset(
        'images/google_logo.png', // скачайте логотип Google и положите в assets
        height: 24,
        width: 24,
      ),
      label: const Text('Войти через Google'),
    );
  }

  Widget _buildAuthTextFormField({
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
      cursorColor: darkOrange, // Цвет курсора
      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: primaryOrange),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            Colors.orange.withOpacity(0.05), // Очень легкий оранжевый фон
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: accentOrange.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: primaryOrange, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        labelStyle: TextStyle(color: Colors.grey[800]),
        hintStyle: TextStyle(color: Colors.grey[600]),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      ),
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}
