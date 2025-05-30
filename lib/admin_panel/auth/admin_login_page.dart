// lib/admin_panel/auth/admin_login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Для типа User
import 'package:flutter_languageapplicationmycourse_2/admin_panel/auth/admin_auth_service.dart';
// import 'package:go_router/go_router.dart'; // GoRouter не нужен здесь для явной навигации
// import 'package:flutter_languageapplicationmycourse_2/admin_panel/routing/app_router.dart'; // Не нужны для явной навигации

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AdminAuthService _authService = AdminAuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) { // Проверяем валидность формы
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final User? user = await _authService.signInWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // signInWithEmailPassword в AdminAuthService уже проверяет роль (admin или support)
    // и возвращает null, если роль не подходит или креды неверны.

    if (user == null && mounted) { // Если user == null, значит вход не удался
      setState(() {
        _errorMessage = "Вход не удался. Проверьте данные или права доступа.";
      });
    }
    // Если user != null, то вход УСПЕШЕН и роль ПОДХОДИТ (admin или support).
    // GoRouter (через GoRouterRefreshStream) должен автоматически среагировать
    // на изменение состояния аутентификации и выполнить redirect на нужный дашборд.
    // Никакой дополнительной навигации или проверки роли здесь не нужно.

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Цвет фона
      body: Center(
        child: SingleChildScrollView( // Позволяет прокручивать на маленьких экранах
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Чтобы карточка не растягивалась на весь экран
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Вход для персонала', // Общее название
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary, // Используем цвет темы
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Введите ваш email',
                          prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Введите email';
                          if (!value.contains('@') || !value.contains('.')) return 'Некорректный формат email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          hintText: 'Введите ваш пароль',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Введите пароль';
                          return null;
                        },
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: Theme.of(context).colorScheme.primary, // Используем цвет темы
                                // foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _signIn,
                              child: const Text('Войти'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}