import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart'; // Убедитесь, что путь верный
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toast/toast.dart'; // ToastContext().init(context) нужно будет вызвать в build

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4; // Для BottomNavigationBar
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser; // Сделаем nullable для безопасности
  DocumentSnapshot<Map<String, dynamic>>? userDataSnapshot; // Для хранения снепшота

  File? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    // ToastContext().init(context); // Перенесено в build метод, чтобы context был доступен
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Не переходить, если уже на этой вкладке
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/learn');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/games');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 4:
        // Уже на странице профиля
        break;
    }
  }

  // Получение данных пользователя из снепшота
  Map<String, dynamic>? get _userData => userDataSnapshot?.data();

  Future<void> _pickImage() async {
    if (_isUploadingImage) return;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      Toast.show("Ошибка выбора изображения: $e", duration: Toast.lengthLong);
    }
  }

  Future<void> _uploadAndSaveImage() async {
    if (_pickedImageFile == null || currentUser == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      String fileName = currentUser!.uid;
      Reference ref = FirebaseStorage.instance.ref().child("profile_images/$fileName.jpg"); // Добавим расширение

      UploadTask uploadTask = ref.putFile(_pickedImageFile!, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await UsersCollection().updateUserCollection(currentUser!.uid, {'image': downloadUrl});

      setState(() {
        _pickedImageFile = null; // Сбрасываем выбранное изображение после успешной загрузки
        // userDataSnapshot будет обновлен FutureBuilder'ом
      });
      Toast.show("Фото профиля обновлено!");
    } catch (e) {
      Toast.show("Ошибка загрузки фото: ${e.toString()}", duration: Toast.lengthLong);
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _editProfileField(String fieldKey, String currentFieldValue) async {
    TextEditingController controller = TextEditingController(text: currentFieldValue);
    String? newValue;

    // Для даты рождения используем DatePicker
    if (fieldKey == 'birthDate') {
      DateTime initialDate;
      try {
        List<String> parts = currentFieldValue.split('/');
        initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch (e) {
        initialDate = DateTime.now();
      }

      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (pickedDate != null) {
        newValue = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      } else {
        return; // Пользователь отменил выбор даты
      }
    } else {
      // Для текстовых полей
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Изменить ${fieldKey == "firstName" ? "Имя" : "Фамилию"}'), // Пример
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Введите новое значение'),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Отмена'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: const Text('Сохранить'),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    newValue = controller.text.trim();
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    }
    
    if (newValue != null && newValue != currentFieldValue) {
      try {
        // Валидация для имени и фамилии (только буквы)
        if ((fieldKey == 'firstName' || fieldKey == 'lastName') && !RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(newValue!)) {
          Toast.show('${fieldKey == "firstName" ? "Имя" : "Фамилия"} может содержать только буквы и пробелы.');
          return;
        }
        await UsersCollection().updateUserCollection(currentUser!.uid, {fieldKey: newValue});
        Toast.show("${fieldKey == "firstName" ? "Имя" : fieldKey == "lastName" ? "Фамилия" : "Дата рождения"} обновлен(а)!");
        // FutureBuilder обновит UI
      } catch (e) {
        Toast.show("Ошибка обновления данных: $e", duration: Toast.lengthLong);
      }
    }
  }


  Future<void> _changePassword() async {
    TextEditingController passwordController = TextEditingController();
    if (currentUser == null) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Сменить пароль'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(hintText: 'Введите новый пароль'),
                obscureText: true,
                autofocus: true,
              ),
              const SizedBox(height: 10),
              const Text('Пароль должен содержать минимум 6 символов.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Изменить'),
              onPressed: () async {
                String newPassword = passwordController.text;
                if (newPassword.isNotEmpty && newPassword.length >= 6) {
                  try {
                    await currentUser!.updatePassword(newPassword);
                    Navigator.of(dialogContext).pop(); // Закрыть диалог
                    Toast.show('Пароль успешно изменен. Пожалуйста, войдите снова с новым паролем.');
                    await _auth.signOut(); // Разлогинить пользователя
                    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false); // Переход на страницу входа
                  } on FirebaseAuthException catch (e) {
                     Navigator.of(dialogContext).pop(); // Закрыть диалог при ошибке
                    String message = "Ошибка смены пароля.";
                    if (e.code == 'weak-password') {
                      message = 'Новый пароль слишком простой.';
                    } else if (e.code == 'requires-recent-login') {
                      message = 'Эта операция требует недавнего входа. Пожалуйста, войдите снова и попробуйте еще раз.';
                      // Здесь можно инициировать процесс re-authentication
                    }
                    Toast.show(message, duration: Toast.lengthLong);
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    Toast.show('Неизвестная ошибка при смене пароля.', duration: Toast.lengthLong);
                  }
                } else {
                  Toast.show('Пароль не может быть пустым и должен содержать минимум 6 символов.');
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildProfileImage(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth * 0.18;
    ImageProvider<Object> profileImageProvider;

    if (_pickedImageFile != null) {
      profileImageProvider = FileImage(_pickedImageFile!);
    } else {
      final imageUrl = _userData?['image'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        profileImageProvider = NetworkImage(imageUrl);
      } else {
        profileImageProvider = const AssetImage('images/default_avatar.png'); // Убедитесь, что этот файл есть в assets
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: profileImageProvider,
          backgroundColor: Colors.grey[200], // Фон, если изображение не загрузилось
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.camera_alt, color: Colors.white, size: screenWidth * 0.05),
              ),
            ),
          ),
        ),
        if (_isUploadingImage)
          Container(
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context); // Инициализация Toast
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Профиль"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Выйти",
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: UsersCollection().getUser(currentUser?.uid ?? 'fallback_uid'), // Используем fallback, если currentUser null
        builder: (context, snapshot) {
          if (currentUser == null) { // Если пользователь не аутентифицирован
             WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
            });
            return const Center(child: Text("Пользователь не аутентифицирован."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка загрузки данных: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Данные пользователя не найдены."));
          }

          userDataSnapshot = snapshot.data; // Сохраняем снепшот

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox( // Ограничиваем максимальную ширину контента на больших экранах
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileImage(context),
                    SizedBox(height: screenHeight * 0.02),
                    if (_pickedImageFile != null && !_isUploadingImage)
                      ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: const Text('Сохранить фото'),
                        onPressed: _uploadAndSaveImage,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    if (_pickedImageFile != null && !_isUploadingImage) SizedBox(height: screenHeight * 0.02),
                    
                    Text(
                      "${_userData?['firstName'] ?? 'Имя'} ${_userData?['lastName'] ?? 'Фамилия'}",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      _userData?['email'] ?? 'email@example.com',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    _EditableInfoCard(
                      title: "Имя",
                      value: _userData?['firstName'] ?? '',
                      icon: Icons.person_outline,
                      onEdit: () => _editProfileField('firstName', _userData?['firstName'] ?? ''),
                    ),
                    _EditableInfoCard(
                      title: "Фамилия",
                      value: _userData?['lastName'] ?? '',
                      icon: Icons.person_search_outlined,
                      onEdit: () => _editProfileField('lastName', _userData?['lastName'] ?? ''),
                    ),
                     _EditableInfoCard(
                      title: "Дата рождения",
                      value: _userData?['birthDate'] ?? '',
                      icon: Icons.calendar_today_outlined,
                      onEdit: () => _editProfileField('birthDate', _userData?['birthDate'] ?? ''),
                    ),
                    _InfoCard(
                      title: "Уровень языка",
                      value: _userData?['languageLevel'] ?? 'Не указан', // Предполагаем, что поле называется languageLevel
                      icon: Icons.translate_outlined,
                    ),
                    
                    SizedBox(height: screenHeight * 0.03),
                    SizedBox(
                      width: double.infinity, // Растянуть на всю доступную ширину (внутри ConstrainedBox)
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.lock_outline),
                        label: const Text('Сменить пароль'),
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                          textStyle: TextStyle(fontSize: screenHeight * 0.018)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Чтобы все метки были видны
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Учиться'),
        BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Играть'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Уведомления'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey[600],
      onTap: _onItemTapped,
    );
  }
}

// Вспомогательные виджеты для карточек информации
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[600]),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87)),
      ),
    );
  }
}

class _EditableInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

  const _EditableInfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[600]),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87)),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: Colors.blueGrey[400]),
          tooltip: "Редактировать",
          onPressed: onEdit,
        ),
      ),
    );
  }
}