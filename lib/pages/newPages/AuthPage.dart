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

  // Логин администратора
  final String adminEmail = 'admin@mail.ru'; // Логин администратора
  final String supportEmail = 'support@mail.ru'; // Логин администратора

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/LingoQuest_logo.png",
                    width: MediaQuery.of(context).size.width * 1,
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextField(
                      controller: emailController,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Email',
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(137, 73, 73, 73),
                        ),
                        labelStyle: const TextStyle(
                          color: Colors.black,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: TextField(
                      controller: passController,
                      style: const TextStyle(color: Colors.black),
                      obscureText: visibility,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Colors.black54,
                        ),
                        labelStyle: const TextStyle(
                          color: Colors.black,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                        prefixIcon: const Icon(
                          Icons.password,
                          color: Colors.green,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              visibility = !visibility;
                            });
                          },
                          icon: visibility
                              ? const Icon(Icons.visibility,
                                  color: Colors.green)
                              : const Icon(Icons.visibility_off,
                                  color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (emailController.text.isEmpty ||
                            passController.text.isEmpty) {
                          Toast.show("Заполните поля");
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 5,
                                  color: Colors.black,
                                ),
                              );
                            },
                          );
                          try {
                            // Проверка, является ли пользователь администратором
                            if (emailController.text == adminEmail) {
                              // Перенаправление на страницу администратора
                              Navigator.pop(
                                  context); // Закрыть индикатор загрузки
                              Navigator.popAndPushNamed(context,
                                  '/navadmin'); // Замените '/admin' на реальный маршрут администратора
                              return; // Прекратить выполнение
                            }
                           
                            var user = await authService.signIn(
                              emailController.text,
                              passController.text,
                            );
                            if (user != null) {
                              // Обновить время последнего входа
                              await authService.updateUserLastLogin(user.id!);
                              Toast.show('Вы успешно вошли');
                              Navigator.popAndPushNamed(context, '/profile');
                              
                            if (emailController.text == supportEmail) {
                              // Перенаправление на страницу администратора
                              Navigator.pop(
                                  context); // Закрыть индикатор загрузки
                              Navigator.popAndPushNamed(context,
                                  '/prof1'); 
                               // Прекратить выполнение
                            }
                            } else {
                              Toast.show('Неверный логин или пароль');
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            Toast.show('Произошла ошибка: $e');
                          }
                        }
                      },
                      child: const Text('ВОЙТИ!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  InkWell(
                    highlightColor: Colors.white,
                    onTap: () {
                      Navigator.popAndPushNamed(context, '/reg');
                    },
                    child: const Text(
                      'Регистрация',
                      style: TextStyle(color: Color.fromARGB(255, 5, 77, 7)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
