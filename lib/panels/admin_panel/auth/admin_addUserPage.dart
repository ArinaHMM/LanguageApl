// lib/admin_panel/pages/admin_add_user_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:go_router/go_router.dart';
import 'package:toast/toast.dart';
import '../../../database/collections/users_collections.dart';
import '../../../models/user_model.dart';
import 'admin_auth_service.dart';
import '../routing/app_router.dart';

class AdminAddUserPage extends StatefulWidget {
  const AdminAddUserPage({Key? key}) : super(key: key);

  @override
  State<AdminAddUserPage> createState() => _AdminAddUserPageState();
}

class _AdminAddUserPageState extends State<AdminAddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthDateController = TextEditingController();

  String _selectedRole = UserRoles.user;
  bool _isLoading = false;

  final AdminAuthService _adminAuthService = AdminAuthService();
  final UsersCollection _usersCollection = UsersCollection();

  @override
  void initState() {
    super.initState();
    ToastContext().init(context);
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final String? adminUidBeforeCreation = _adminAuthService.currentUser?.uid;
    print("Admin Add User: Current admin UID before creation: $adminUidBeforeCreation");

    try {
      // 1. Создаем пользователя в Firebase Authentication через ВТОРИЧНОЕ ПРИЛОЖЕНИЕ
      fb_auth.UserCredential? newUserCredential = await _adminAuthService.createAuthUserWithSecondaryApp( // <--- ИЗМЕНЕНИЕ ЗДЕСЬ
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print("Admin Add User: Newly created user UID (from secondary app): ${newUserCredential?.user?.uid}");
      // Проверяем currentUser в ОСНОВНОМ приложении. Он не должен измениться.
      print("Admin Add User: Current user UID in main app after Auth creation: ${_adminAuthService.currentUser?.uid}");


      if (newUserCredential?.user != null) {
        // 2. Создаем документ пользователя в Firestore для нового пользователя
        await _usersCollection.createUserDocument(
          uid: newUserCredential!.user!.uid,
          email: _emailController.text.trim(),
          role: _selectedRole,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: _birthDateController.text.trim(),
        );
        Toast.show("Пользователь успешно добавлен!", duration: Toast.lengthLong, gravity: Toast.bottom);

        if (mounted) {
          // Теперь сессия администратора должна быть нетронутой.
          // Прямой переход на страницу списка пользователей.
          print("Admin Add User: Navigating to manage users.");
          context.go(AdminRoutes.manageUsers);
        }
      } else {
        Toast.show("Не удалось создать пользователя в Firebase Auth.", duration: Toast.lengthLong, gravity: Toast.bottom);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage = "Ошибка Firebase Auth: ";
      if (e.code == 'email-already-in-use') {
        errorMessage += 'Этот email уже используется.';
      } else if (e.code == 'weak-password') {
        errorMessage += 'Пароль слишком слабый.';
      } else {
        errorMessage += e.message ?? 'Неизвестная ошибка.';
      }
      Toast.show(errorMessage, duration: Toast.lengthLong, gravity: Toast.bottom);
    } catch (e) {
      Toast.show("Общая ошибка: $e", duration: Toast.lengthLong, gravity: Toast.bottom);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ... (dispose, _selectBirthDate, build - остаются без изменений) ...
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text("Добавить нового пользователя", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Пароль должен быть не менее 6 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Фамилия', border: OutlineInputBorder()),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите фамилию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Дата рождения (ГГГГ-ММ-ДД)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectBirthDate(context),
                  )
                ),
                readOnly: true,
                onTap: () => _selectBirthDate(context),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите дату рождения';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Роль пользователя',
                  border: OutlineInputBorder(),
                ),
                items: UserRoles.allRoles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(UserRoles.displayRole(role)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите роль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Добавить пользователя'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _addUser,
                    ),
              const SizedBox(height: 16),
              TextButton(
                child: const Text('Отмена'),
                onPressed: _isLoading ? null : () {
                  context.go(AdminRoutes.manageUsers);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}