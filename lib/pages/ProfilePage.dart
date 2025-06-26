// lib/pages/ProfilePage.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_languageapplicationmycourse_2/database/auth/chatservice.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart'; // Убедитесь, что путь верный
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/achievements_page.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/chatPage/MessagePage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/InventoryPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/faq_page.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 4; // Профиль - 5-й элемент (индекс 4)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  final UsersCollection _usersCollection = UsersCollection();
  DocumentSnapshot<Map<String, dynamic>>? userDataSnapshot;
  UserModel? _currentUserModel;
  DateTime? _lastGoalChangeDate;
  bool _canChangeGoalToday = true;
  final int _baseRewardThreshold = 50; // Базовый порог для награды
  final Map<int, int> _goalRewards = {
    100: 1, // За цель 100 XP - 1 предмет
    150: 2, // За цель 150 XP - 2 предмета
    200: 3, // За цель 200 XP - 3 предмета
  };

  File? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  bool _isSavingGoal = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimationContent;

  // Цветовая палитра страницы Профиля (остается для контента страницы)
  final Color profilePagePrimaryOrange =
      const Color.fromARGB(255, 255, 132, 49);
  final Color profilePageAccentOrange = const Color.fromARGB(255, 255, 160, 90);
  final Color profilePageDarkOrangeButtonColor =
      const Color.fromARGB(255, 230, 100, 20);
  final Color darkText = const Color.fromARGB(255, 50, 50, 50);
  final Color lightText = Colors.white;
  final Color subtleOrange = const Color.fromARGB(255, 255, 240, 230);
  static const String SUPPORT_TEAM_UID = "V9hSE7mZldWy23FDNob0cS4F22G3";
  // --- ЦВЕТА ИЗ LEARNPAGE ДЛЯ НАВИГАЦИИ ---
  final Color learnPagePrimaryOrange = const Color(0xFFFFA726);
  final Color learnPageDarkOrange = const Color(0xFFF57C00);
  final ChatService _chatService = ChatService();
  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _loadUserData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimationContent =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _loadUserData() async {
    if (currentUser?.uid == null) return;
    try {
      userDataSnapshot = await _usersCollection.getUser(currentUser!.uid);
      if (userDataSnapshot != null && userDataSnapshot!.exists) {
        _currentUserModel = UserModel.fromFirestore(userDataSnapshot!);

        // Загружаем дату последнего изменения цели
        if (_currentUserModel?.lastGoalChangeDate != null) {
          _lastGoalChangeDate = _currentUserModel!.lastGoalChangeDate?.toDate();
          final now = DateTime.now();
          final lastChange = _lastGoalChangeDate!;
          _canChangeGoalToday = !(now.year == lastChange.year &&
              now.month == lastChange.month &&
              now.day == lastChange.day);
        }

        if (mounted &&
            _animationController.status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      print("Error loading user data in ProfilePage: $e");
      if (mounted) _showSnackBar("Ошибка загрузки данных профиля.");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (!mounted) return;

    // Если пользователь нажал на уже активную вкладку "Профиль" (индекс 4)
    if (_selectedIndex == index && index == 4) {
      return; // Ничего не делаем
    }

    // Обновляем состояние _selectedIndex, чтобы UI (BottomNavigationBar) отразил изменение.
    setState(() {
      _selectedIndex = index;
    });

    // Выполняем навигацию
    switch (index) {
      case 0: // Путь
        Navigator.pushReplacementNamed(context, '/learn');
        break;
      case 1: // Игры
        Navigator.pushReplacementNamed(context, '/games');
        break;
      case 2: // Чаты
        Navigator.pushReplacementNamed(context, '/league');
        break;
      case 3: // Настройки
        Navigator.pushReplacementNamed(context, '/modules_view');
        break;
      case 4: // Профиль
        // Мы уже на этой странице. _selectedIndex был обновлен.
        break;
    }
  }

  Map<String, dynamic>? get _userData => userDataSnapshot?.data();

  void _showSnackBar(String message,
      {bool isError = true, Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? Colors.redAccent.shade700
            : profilePagePrimaryOrange, // Используем цвет профиля для снэкбара
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(15, 5, 15, 10),
        duration: duration,
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_isUploadingImage) return;
    try {
      final pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 60,
          maxWidth: 1000,
          maxHeight: 1000);
      if (pickedFile != null) {
        setState(() {
          _pickedImageFile = File(pickedFile.path);
        });
        await _uploadAndSaveImage();
      }
    } catch (e) {
      _showSnackBar("Ошибка выбора изображения: ${e.toString()}");
    }
  }

  Future<void> _uploadAndSaveImage() async {
    if (_pickedImageFile == null || currentUser == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      String fileName = currentUser!.uid;
      Reference ref =
          FirebaseStorage.instance.ref().child("profile_images/$fileName.jpg");

      UploadTask uploadTask = ref.putFile(
          _pickedImageFile!, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await UsersCollection()
          .updateUserCollection(currentUser!.uid, {'image': downloadUrl});

      setState(() {
        _pickedImageFile = null;
      });
      _showSnackBar("Фото профиля обновлено!", isError: false);
    } catch (e) {
      _showSnackBar("Ошибка загрузки фото: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _giveReward(int rewardCount) async {
    if (currentUser == null || rewardCount <= 0) return;

    try {
      // Здесь должна быть логика добавления предметов в инвентарь пользователя
      // Например, увеличиваем счетчик случайных предметов
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'inventory.items': FieldValue.increment(rewardCount),
        'lastRewardDate': DateTime.now(),
      });
    } catch (e) {
      print("Ошибка при выдаче награды: $e");
      // Можно показать сообщение об ошибке, но не прерывать весь процесс
    }
  }

  Future<void> _editDailyGoal() async {
    if (_currentUserModel == null || !_canChangeGoalToday) return;

    // Проверяем, когда последний раз меняли цель
    if (_lastGoalChangeDate != null) {
      final now = DateTime.now();
      final lastChange = _lastGoalChangeDate!;
      _canChangeGoalToday = !(now.year == lastChange.year &&
          now.month == lastChange.month &&
          now.day == lastChange.day);

      if (!_canChangeGoalToday) {
        _showSnackBar(
            "Вы можете менять цель только раз в день. Попробуйте завтра!");
        return;
      }
    }

    TextEditingController goalController =
        TextEditingController(text: _currentUserModel!.dailyGoalXp.toString());
    final formKeyDialog = GlobalKey<FormState>();

    int? newGoal = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Изменить дневную цель XP',
              style: TextStyle(
                  color: profilePagePrimaryOrange,
                  fontWeight: FontWeight.bold)),
          content: Form(
            key: formKeyDialog,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: goalController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'XP в день',
                    hintText: 'Например: 50, 100, 150',
                    prefixIcon: Icon(Icons.flag_circle_outlined,
                        color: profilePagePrimaryOrange),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: profilePagePrimaryOrange)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите значение цели';
                    }
                    final int? goal = int.tryParse(value);
                    if (goal == null) {
                      return 'Введите корректное число';
                    }
                    if (goal < 10 || goal > 500) {
                      return 'Цель должна быть от 10 до 500 XP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (_goalRewards.keys
                    .any((g) => g > (_currentUserModel?.dailyGoalXp ?? 0)))
                  Text(
                    'Награда за более высокую цель:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ..._goalRewards.entries
                    .where((entry) =>
                        entry.key > (_currentUserModel?.dailyGoalXp ?? 0))
                    .map((entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.card_giftcard,
                              color: profilePagePrimaryOrange, size: 20),
                          title: Text(
                            '${entry.key} XP: +${entry.value} предмет',
                            style: TextStyle(fontSize: 14),
                          ),
                        )),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(dialogContext).pop(null),
            ),
            TextButton(
              child: Text('Сохранить',
                  style: TextStyle(
                      color: profilePagePrimaryOrange,
                      fontWeight: FontWeight.bold)),
              onPressed: () {
                if (formKeyDialog.currentState!.validate()) {
                  Navigator.of(dialogContext)
                      .pop(int.tryParse(goalController.text));
                }
              },
            ),
          ],
        );
      },
    );

    if (newGoal != null && newGoal != _currentUserModel!.dailyGoalXp) {
      setState(() => _isSavingGoal = true);
      try {
        // Проверяем, дает ли новая цель награду
        int reward = 0;
        if (newGoal > (_currentUserModel?.dailyGoalXp ?? 0)) {
          // Находим максимальную достигнутую цель, которая дает награду
          final eligibleRewards = _goalRewards.entries
              .where((entry) =>
                  entry.key <= newGoal &&
                  entry.key > (_currentUserModel?.dailyGoalXp ?? 0))
              .toList();

          if (eligibleRewards.isNotEmpty) {
            // Даем награду за самую высокую достигнутую цель
            final maxRewardEntry = eligibleRewards.last;
            reward = maxRewardEntry.value;

            // Обновляем инвентарь пользователя
            await _giveReward(reward);
          }
        }

        await _usersCollection.updateUserCollection(currentUser!.uid, {
          'dailyGoalXp': newGoal,
          'lastGoalChangeDate': DateTime.now(),
        });

        // Обновляем локальную модель
        if (mounted) {
          setState(() {
            _currentUserModel = _currentUserModel!.copyWith(
              dailyGoalXp: newGoal,
              lastGoalChangeDate: () => Timestamp.fromDate(DateTime
                  .now()), // Обертываем в ValueGetter и конвертируем в Timestamp
            );
            _lastGoalChangeDate = DateTime.now();
            _canChangeGoalToday = false;
          });

          String message = "Дневная цель обновлена: $newGoal XP!";
          if (reward > 0) {
            message += "\nВы получили $reward предмет(а) за новую цель!";
          }
          _showSnackBar(message,
              isError: false, duration: Duration(seconds: 4));
        }
      } catch (e) {
        _showSnackBar("Ошибка обновления цели: $e");
      } finally {
        if (mounted) setState(() => _isSavingGoal = false);
      }
    }
  }

  Future<void> _editProfileField(
      String fieldKey, String currentFieldValue, String title) async {
    TextEditingController controller =
        TextEditingController(text: currentFieldValue);
    String? newValueFromDialog;

    if (fieldKey == 'birthDate') {
      DateTime initialDate;
      try {
        if (currentFieldValue.isNotEmpty && currentFieldValue.contains('/')) {
          List<String> parts = currentFieldValue.split('/');
          initialDate = DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
        }
      } catch (e) {
        initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
        print("Ошибка парсинга даты '$currentFieldValue': $e");
      }

      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: profilePagePrimaryOrange, // Используем цвет профиля
                onPrimary: lightText,
                surface: Colors.white,
                onSurface: darkText,
              ),
              dialogBackgroundColor: Colors.white,
              buttonTheme:
                  const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );
      if (pickedDate != null) {
        newValueFromDialog =
            "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      } else {
        return;
      }
    } else {
      newValueFromDialog = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Изменить $title',
                style: TextStyle(
                    color: profilePagePrimaryOrange,
                    fontWeight: FontWeight.bold)), // Используем цвет профиля
            content: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Новое значение',
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color:
                            profilePagePrimaryOrange)), // Используем цвет профиля
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400)),
              ),
              validator: (value) {
                if ((fieldKey == 'firstName' || fieldKey == 'lastName') &&
                    value != null &&
                    value.isNotEmpty) {
                  if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$').hasMatch(value)) {
                    return 'Только буквы и пробелы.';
                  }
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            actions: <Widget>[
              TextButton(
                child:
                    const Text('Отмена', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(dialogContext).pop(null),
              ),
              TextButton(
                child: Text('Сохранить',
                    style: TextStyle(
                        color: profilePagePrimaryOrange,
                        fontWeight:
                            FontWeight.bold)), // Используем цвет профиля
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    if ((fieldKey == 'firstName' || fieldKey == 'lastName') &&
                        !RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s]+$')
                            .hasMatch(controller.text.trim())) {
                      _showSnackBar(
                          '$title может содержать только буквы и пробелы.');
                      return;
                    }
                    Navigator.of(dialogContext).pop(controller.text.trim());
                  } else {
                    _showSnackBar('Поле не может быть пустым.');
                  }
                },
              ),
            ],
          );
        },
      );
    }

    if (newValueFromDialog != null &&
        newValueFromDialog.isNotEmpty &&
        newValueFromDialog != currentFieldValue) {
      if (fieldKey == 'birthDate') {
        List<String> parts = newValueFromDialog.split('/');
        DateTime newBirthDate = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        int age = DateTime.now().year - newBirthDate.year;
        if (DateTime.now().month < newBirthDate.month ||
            (DateTime.now().month == newBirthDate.month &&
                DateTime.now().day < newBirthDate.day)) {
          age--;
        }
        if (age < 6) {
          _showSnackBar('Вы должны быть старше 6 лет.');
          return;
        } else if (age > 100) {
          _showSnackBar('Укажите корректный возраст (до 100 лет).');
          return;
        }
      }

      try {
        await UsersCollection().updateUserCollection(
            currentUser!.uid, {fieldKey: newValueFromDialog});
        _showSnackBar("$title обновлен(а)!", isError: false);
        setState(() {});
      } catch (e) {
        _showSnackBar("Ошибка обновления данных: $e");
      }
    }
  }

  Future<void> _changePassword() async {
    TextEditingController passwordController = TextEditingController();
    if (currentUser == null) return;
    final formKeyDialog = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool obscureText = true;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Сменить пароль',
                style: TextStyle(
                    color: profilePagePrimaryOrange,
                    fontWeight: FontWeight.bold)), // Используем цвет профиля
            content: Form(
              key: formKeyDialog,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Новый пароль',
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  profilePagePrimaryOrange)), // Используем цвет профиля
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400)),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey),
                        onPressed: () =>
                            setDialogState(() => obscureText = !obscureText),
                      ),
                    ),
                    obscureText: obscureText,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пароль не может быть пустым.';
                      }
                      if (value.length < 6) {
                        return 'Минимум 6 символов.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child:
                    const Text('Отмена', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: Text('Изменить',
                    style: TextStyle(
                        color: profilePagePrimaryOrange,
                        fontWeight:
                            FontWeight.bold)), // Используем цвет профиля
                onPressed: () async {
                  if (formKeyDialog.currentState!.validate()) {
                    String newPassword = passwordController.text;
                    Navigator.of(dialogContext).pop();
                    _showSnackBar('Попытка смены пароля...',
                        isError: false, duration: const Duration(seconds: 2));

                    try {
                      await currentUser!.updatePassword(newPassword);
                      _showSnackBar('Пароль успешно изменен. Войдите снова.',
                          isError: false);
                      await _auth.signOut();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/auth', (route) => false);
                      }
                    } on FirebaseAuthException catch (e) {
                      String message = "Ошибка смены пароля.";
                      if (e.code == 'weak-password') {
                        message = 'Новый пароль слишком простой.';
                      } else if (e.code == 'requires-recent-login') {
                        message =
                            'Требуется недавний вход. Пожалуйста, войдите снова и повторите операцию.';
                      } else {
                        message = 'Произошла ошибка Firebase: ${e.message}';
                      }
                      _showSnackBar(message);
                    } catch (e) {
                      _showSnackBar('Неизвестная ошибка при смене пароля: $e');
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarSize = screenWidth * 0.38;
    ImageProvider<Object> profileImageProvider;

    String? imageUrl = _userData?['image'] as String?;
    if (_pickedImageFile != null) {
      profileImageProvider = FileImage(_pickedImageFile!);
    } else if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        imageUrl.startsWith('http')) {
      profileImageProvider = NetworkImage(imageUrl);
    } else {
      profileImageProvider = const AssetImage('images/default_avatar.png');
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: profilePagePrimaryOrange
                  .withOpacity(0.3), // Используем цвет профиля
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4))
        ],
      ),
      child: CircleAvatar(
        radius: avatarSize / 2,
        backgroundColor: subtleOrange,
        onBackgroundImageError: imageUrl != null && imageUrl.startsWith('http')
            ? (exception, stackTrace) {
                print("Ошибка загрузки NetworkImage для аватара: $exception");
              }
            : null,
        backgroundImage: profileImageProvider,
        child: Stack(
          children: [
            if (_isUploadingImage)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: CircularProgressIndicator(
                        color: lightText, strokeWidth: 3)),
              ),
            if (!_isUploadingImage)
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: profilePagePrimaryOrange, // Используем цвет профиля
                  elevation: 3,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _pickImage,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(Icons.edit,
                          color: lightText, size: screenWidth * 0.05),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSupportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext bc) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Wrap(
            // Wrap для содержимого, если его будет больше
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.support_agent_rounded,
                    color: profilePagePrimaryOrange, size: 30),
                title: Text(
                  'Связаться с поддержкой',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkText),
                ),
                subtitle: const Text('Задайте ваш вопрос нашей команде'),
                onTap: () async {
                  Navigator.pop(context); // Закрываем bottom sheet
                  await _startChatWithSupport();
                },
              ),
              const Divider(height: 20, thickness: 1),
              ListTile(
                leading: Icon(Icons.help_outline_rounded,
                    color: Colors.grey.shade600),
                title: Text('Часто задаваемые вопросы (FAQ)',
                    style: TextStyle(color: Colors.grey.shade700)),
                onTap: () {
                  Navigator.pop(context); // Сначала закрываем BottomSheet
                  // Затем открываем новую страницу FAQ
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FaqPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  // ---------------------------------------------------------------

  // --- НОВЫЙ МЕТОD ДЛЯ НАЧАЛА ЧАТА С ПОДДЕРЖКОЙ ---
  Future<void> _startChatWithSupport() async {
    if (currentUser == null) {
      _showSnackBar("Для начала чата необходимо войти в систему.");
      return;
    }
    if (currentUser!.uid == SUPPORT_TEAM_UID) {
      _showSnackBar("Вы не можете начать чат с самим собой (поддержкой).");
      return;
    }

    try {
      // Используем ChatService для получения или создания документа чата
      // getOrCreateChatWithSupport должен вернуть DocumentSnapshot чата
      DocumentSnapshot chatDocSnapshot = await _chatService
          .getOrCreateChatWithSupport(currentUser!.uid, SUPPORT_TEAM_UID);

      String chatId = chatDocSnapshot.id; // ID документа чата
      String? supportUserName = "Поддержка"; // Имя по умолчанию

      // Опционально: получаем имя сотрудника поддержки для отображения в AppBar чата
      // Это можно сделать, если в ChatService вы не денормализуете имя поддержки в документ чата
      // или если хотите всегда свежее имя.
      try {
        UserModel? supportUserModel =
            await _usersCollection.getUserModel(SUPPORT_TEAM_UID);
        if (supportUserModel != null) {
          supportUserName =
              "${supportUserModel.firstName} ${supportUserModel.lastName}"
                  .trim();
          if (supportUserName.isEmpty) {
            supportUserName = supportUserModel.email;
          }
        }
      } catch (e) {
        print("Could not fetch support user name: $e");
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              chatId: chatId, // <--- ПЕРЕДАЕМ chatId
              initialOtherUserName:
                  supportUserName, // <--- ПЕРЕДАЕМ ИМЯ СОБЕСЕДНИКА (ПОДДЕРЖКИ)
            ),
          ),
        );
      }
    } catch (e) {
      print("Error starting/getting chat with support: $e");
      _showSnackBar("Не удалось начать чат с поддержкой. Попробуйте позже.");
    }
  }

  void _showComplaintForm() {
    final formKey = GlobalKey<FormState>();
    TextEditingController complaintController = TextEditingController();
    String? selectedCategory;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Сообщить о проблеме',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Опишите проблему, с которой вы столкнулись, и мы постараемся её решить',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Категория проблемы',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.category_outlined,
                              color: profilePagePrimaryOrange),
                        ),
                        value: selectedCategory,
                        items: const [
                          DropdownMenuItem(
                            value: 'technical',
                            child: Text('Техническая проблема'),
                          ),
                          DropdownMenuItem(
                            value: 'content',
                            child: Text('Ошибка в контенте'),
                          ),
                          DropdownMenuItem(
                            value: 'behavior',
                            child: Text('Проблема с пользователем'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Другое'),
                          ),
                        ],
                        onChanged: (value) {
                          selectedCategory = value;
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Пожалуйста, выберите категорию';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: complaintController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Опишите проблему',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, опишите проблему';
                          }
                          if (value.length < 10) {
                            return 'Описание должно быть более подробным';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: profilePagePrimaryOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _showSnackBar(
                                'Спасибо! Ваша жалоба отправлена администратору.',
                                isError: false,
                              );

                              try {
                                await FirebaseFirestore.instance
                                    .collection('complaints')
                                    .add({
                                  'userId': currentUser?.uid,
                                  'userEmail': currentUser?.email,
                                  'category': selectedCategory,
                                  'description': complaintController.text,
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'status': 'new',
                                });
                              } catch (e) {
                                print('Error submitting complaint: $e');
                              }
                            }
                          },
                          child: const Text(
                            'Отправить жалобу',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Мой Профиль",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF3A3A3A))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: darkText,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 28),
            tooltip: "Выйти",
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/auth', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  profilePageAccentOrange
                      .withOpacity(0.15), // Используем цвет профиля
                  Colors.orange.shade50,
                  Colors.white
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0])),
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: UsersCollection()
              .getUser(currentUser?.uid ?? 'SHOULD_NOT_HAPPEN_UID'),
          builder: (context, snapshot) {
            if (currentUser == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/auth', (route) => false);
                }
              });
              return Center(
                  child: CircularProgressIndicator(
                      color:
                          profilePagePrimaryOrange)); // Используем цвет профиля
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                userDataSnapshot == null) {
              return Center(
                  child: CircularProgressIndicator(
                      color:
                          profilePagePrimaryOrange)); // Используем цвет профиля
            } else if (snapshot.connectionState != ConnectionState.none &&
                _animationController.status == AnimationStatus.dismissed) {
              _animationController.forward();
            }

            if (snapshot.hasError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Ошибка загрузки данных профиля: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700])),
              ));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              userDataSnapshot = snapshot.data;
            } else if (userDataSnapshot == null &&
                snapshot.connectionState == ConnectionState.done) {
              return const Center(
                  child: Text("Данные пользователя не найдены."));
            }

            if (_userData == null) {
              return Center(
                  child: Text("Не удалось отобразить данные пользователя.",
                      style: TextStyle(color: Colors.grey[700])));
            }

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimationContent,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: kToolbarHeight - 10),
                            _buildProfileImage(context),
                            SizedBox(height: screenHeight * 0.025),
                            Text(
                              "${_userData?['firstName'] ?? 'Имя не указано'} ${_userData?['lastName'] ?? ''}"
                                  .trim(),
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                  letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            Text(
                              _userData?['email'] ?? 'email не указан',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[800]),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.04),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  // Карточка для Стрика (Ударного режима)
                                  _StatCard(
                                    icon: Icons.local_fire_department_rounded,
                                    title: "Стрик",
                                    // Используем данные из _currentUserModel, если он загружен
                                    value:
                                        "${_currentUserModel?.currentStreak ?? 0} дней",
                                    color: Colors.red.shade500,
                                    // onEdit: () { /* Можно добавить диалог с информацией о стрике */ },
                                  ),
                                  const SizedBox(width: 12),
                                  // Карточка для Дневной цели
                                  _StatCard(
                                    icon: Icons.flag_circle_rounded,
                                    title: "Дневная цель",
                                    // Используем данные из _currentUserModel, если он загружен
                                    value:
                                        "${_currentUserModel?.dailyGoalXp ?? 50} XP",
                                    color: Colors.blue.shade600,
                                    onEdit: _isSavingGoal
                                        ? null
                                        : _editDailyGoal, // Вызываем ваш метод редактирования
                                  ),
                                ],
                              ),
                            ),
                            _EditableInfoCard(
                              title: "Имя",
                              value: _userData?['firstName'] ?? '',
                              icon: Icons.badge_outlined,
                              onEdit: () => _editProfileField('firstName',
                                  _userData?['firstName'] ?? '', "Имя"),
                              primaryColor:
                                  profilePagePrimaryOrange, // Используем цвет профиля
                            ),
                            _EditableInfoCard(
                              title: "Фамилия",
                              value: _userData?['lastName'] ?? '',
                              icon: Icons.badge,
                              onEdit: () => _editProfileField('lastName',
                                  _userData?['lastName'] ?? '', "Фамилию"),
                              primaryColor:
                                  profilePagePrimaryOrange, // Используем цвет профиля
                            ),
                            _EditableInfoCard(
                              title: "Дата рождения",
                              value: _userData?['birthDate'] ?? '',
                              icon: Icons.celebration_outlined,
                              onEdit: () => _editProfileField(
                                  'birthDate',
                                  _userData?['birthDate'] ?? '',
                                  "Дату рождения"),
                              primaryColor:
                                  profilePagePrimaryOrange, // Используем цвет профиля
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            SizedBox(height: screenHeight * 0.03),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.report_problem_outlined,
                                    color: profilePagePrimaryOrange),
                                label: Text(
                                  'Сообщить о проблеме',
                                  style: TextStyle(
                                    color: profilePagePrimaryOrange,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: _showComplaintForm,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: profilePagePrimaryOrange,
                                      width: 2),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: profilePageAccentOrange,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.backpack_rounded,
                                    color: profilePagePrimaryOrange),
                                label: Text(
                                  'Мой инвентарь',
                                  style: TextStyle(
                                    color: profilePagePrimaryOrange,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const InventoryPage()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: profilePagePrimaryOrange,
                                      width: 2),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  foregroundColor:
                                      profilePageAccentOrange, // Цвет эффекта нажатия
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.emoji_events_rounded,
                                    color: profilePagePrimaryOrange),
                                label: Text(
                                  'Достижения',
                                  style: TextStyle(
                                    color: profilePagePrimaryOrange,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AchievementsPage()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: profilePagePrimaryOrange,
                                      width: 2),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  foregroundColor:
                                      profilePageAccentOrange, // Цвет эффекта нажатия
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.lock_person_outlined,
                                    color: lightText),
                                label: Text('Сменить пароль',
                                    style: TextStyle(
                                        color: lightText,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600)),
                                onPressed: _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      profilePageDarkOrangeButtonColor, // Используем цвет профиля
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSupportBottomSheet(context);
        },
        label: const Text('Поддержка',
            style: TextStyle(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.support_agent_rounded),
        backgroundColor:
            profilePagePrimaryOrange, // Используем цвет из палитры профиля
        foregroundColor: lightText,
        elevation: 4.0,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Расположение кнопки
      // ------------------------------------
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    Color selectedColor = learnPageDarkOrange; // Цвет из LearnPage
    Color unselectedColor =
        learnPagePrimaryOrange.withOpacity(0.7); // Цвет из LearnPage

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: Colors.white,
      elevation: 15.0,
      iconSize: 28,
      selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 12, color: selectedColor),
      unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500, fontSize: 11.5, color: unselectedColor),
      items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.terrain_outlined),
            activeIcon: Icon(Icons.terrain_rounded, color: selectedColor),
            label: 'Путь'),
        BottomNavigationBarItem(
            icon: Icon(Icons.extension_outlined),
            activeIcon: Icon(Icons.extension_rounded, color: selectedColor),
            label: 'Игры'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield, color: selectedColor),
            label: 'Лига'),
        BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book, color: selectedColor),
            label: 'Материал'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_circle_outlined),
            activeIcon:
                Icon(Icons.person_pin_circle_rounded, color: selectedColor),
            label: 'Профиль'),
      ],
    );
  }
}

// Вспомогательные виджеты для карточек информации
class _EditableInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;
  final Color primaryColor;

  const _EditableInfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onEdit,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.12),
                child: Icon(icon, color: primaryColor, size: 24),
                radius: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? "Не указано" : value,
                      style: TextStyle(
                          fontSize: 16.5,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onEdit; // Сделаем его необязательным

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.white,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
