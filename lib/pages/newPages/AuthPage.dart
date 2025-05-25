import 'package:firebase_auth/firebase_auth.dart'; // Добавлен импорт
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/database/auth/service.dart';
import 'package:toast/toast.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  AuthService authService = AuthService();
  bool visibility = true;

  final String adminEmail = 'admin@mail.ru';
  final String supportEmail = 'support@mail.ru';

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> _performSignIn() async {
    if (emailController.text.isEmpty || passController.text.isEmpty) {
      Toast.show("Заполните поля");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 5,
            color: Colors.green, // Используем зеленый, как в кнопке
          ),
        );
      },
    );

    try {
      // Логика для администратора и поддержки
      // Важно: Если admin/support тоже обычные Firebase юзеры, их email тоже должен быть верифицирован.
      // Либо для них должна быть отдельная логика входа, не требующая emailVerified.
      if (emailController.text.trim() == adminEmail) {
         // Предполагаем, что админ тоже логинится через Firebase
        await _trySignInAndNavigate(emailController.text.trim(), passController.text, '/navadmin', isAdminOrSupport: true);
        return;
      }

      if (emailController.text.trim() == supportEmail) {
        // Предполагаем, что поддержка тоже логинится через Firebase
        await _trySignInAndNavigate(emailController.text.trim(), passController.text, '/prof1', isAdminOrSupport: true);
        return;
      }

      // Вход для обычного пользователя
      await _trySignInAndNavigate(emailController.text.trim(), passController.text, '/profile');

    } catch (e) {
      // Эта секция catch может быть излишней, если все ошибки обрабатываются в _trySignInAndNavigate
      Navigator.pop(context); // Закрыть индикатор загрузки, если он еще открыт
      Toast.show('Произошла ошибка: ${e.toString()}');
    }
  }

  Future<void> _trySignInAndNavigate(String email, String password, String routeName, {bool isAdminOrSupport = false}) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Перезагружаем пользователя, чтобы получить актуальный статус emailVerified
        await user.reload();
        user = FirebaseAuth.instance.currentUser; // Обновляем ссылку

        if (user!.emailVerified) {
          await authService.updateUserLastLogin(user.uid);
          Navigator.pop(context); // Закрыть индикатор загрузки
          Toast.show('Вы успешно вошли');
          Navigator.popAndPushNamed(context, routeName);
        } else {
          // Email не подтвержден
          Navigator.pop(context); // Закрыть индикатор загрузки
          _showEmailNotVerifiedDialog(user);
        }
      } else {
        // Маловероятно, но на всякий случай
        Navigator.pop(context);
        Toast.show('Не удалось получить данные пользователя после входа.');
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Закрыть индикатор загрузки
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Пользователь с таким email не найден.';
          break;
        case 'wrong-password':
          message = 'Неверный пароль.';
          break;
        case 'invalid-email':
           message = 'Некорректный формат email.';
           break;
        case 'user-disabled':
           message = 'Аккаунт пользователя отключен.';
           break;
        case 'invalid-credential': // Общая ошибка для неверных данных (Firebase Auth >= vX.X)
           message = 'Неверный email или пароль.';
           break;
        default:
          message = 'Ошибка входа: ${e.message}';
      }
      Toast.show(message);
    } catch (e) {
        Navigator.pop(context);
        Toast.show('Произошла непредвиденная ошибка: ${e.toString()}');
    }
  }


  void _showEmailNotVerifiedDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Email не подтвержден'),
          content: Text(
              'Пожалуйста, проверьте вашу почту (${user.email}) и перейдите по ссылке для подтверждения email. Без этого вход невозможен.'),
          actions: <Widget>[
            TextButton(
              child: Text('Отправить письмо повторно'),
              onPressed: () async {
                try {
                  await user.sendEmailVerification();
                  Toast.show('Письмо для подтверждения отправлено повторно.');
                } catch (e) {
                  Toast.show('Ошибка при повторной отправке: $e');
                  print("Ошибка повторной отправки email: $e");
                }
                Navigator.of(context).pop(); // Закрыть диалог
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/LingoQuest_logo.png",
                    width: MediaQuery.of(context).size.width * 0.8, // Немного уменьшил для баланса
                    height: MediaQuery.of(context).size.height * 0.25,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  _buildAuthTextField(
                    controller: emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _buildAuthTextField(
                    controller: passController,
                    labelText: 'Пароль', // Изменил на русский
                    prefixIcon: Icons.password,
                    obscureText: visibility,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          visibility = !visibility;
                        });
                      },
                      icon: Icon(
                        visibility ? Icons.visibility : Icons.visibility_off,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                  SizedBox(
                    height: 50, // Фиксированная высота
                    width: MediaQuery.of(context).size.width * 0.7, // Как на странице регистрации
                    child: ElevatedButton(
                      onPressed: _performSignIn, // Используем новую функцию
                      child: const Text('ВОЙТИ!', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  InkWell(
                    highlightColor: Colors.transparent, // Убрал цвет подсветки
                    splashColor: Colors.green.withOpacity(0.1), // Легкий сплеш
                    onTap: () {
                      Navigator.popAndPushNamed(context, '/reg');
                    },
                    child: const Text(
                      'Нет аккаунта? Зарегистрироваться', // Более явный текст
                      style: TextStyle(color: Color.fromARGB(255, 5, 77, 7), decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательный виджет для полей ввода на странице авторизации
  Widget _buildAuthTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        cursorColor: Colors.black,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.black),
          hintText: labelText, // Используем labelText как hintText для простоты
          hintStyle: const TextStyle(color: Color.fromARGB(137, 73, 73, 73)),
          prefixIcon: Icon(prefixIcon, color: Colors.green),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.green, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.green, width: 1.0),
          ),
        ),
      ),
    );
  }
}