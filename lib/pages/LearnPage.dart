import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AdvancedPage/AdvancedLessonPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AudioPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AudiosPage/LessonAudioPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AddLesson/LessonPage1.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/UpperIntermediateLesson/UpIntermediarePage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/UpperUpInterPage/UpperUpPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/Video/VideoPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/api_service.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/UpperLesson/UpperLessonViewPage.dart';

class LearnPage extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _LearnPageState createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  int _selectedIndex = 0; // Index for bottom navigation bar
  String userLanguageLevel = ''; // User's language level
  int lives = 0; // User's lives
  Timer? _timer; // Timer for countdown
  int _remainingTime = 0; // Remaining time in seconds
  // ignore: unused_field
  String _timeString = "00:00"; // Display format for time
  int userProgress = 0;
  bool isAdmin = false; // Check if the user is admin
  // Using ValueNotifier to track the timer's state independently
  final ValueNotifier<int> _remainingTimeNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _fetchUserProgress();
    _getUserLanguageLevel();
    _fetchLastRestoredTime();
    _checkIfAdmin();
    // Fetch last restored time when page loads
  }

  Future<void> _checkIfAdmin() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email == 'admin@mail.ru') {
      setState(() {
        isAdmin = true; // Mark user as admin
      });
    }
  }

  Future<void> _deleteaddLesson(String lessonId) async {
    try {
      await FirebaseFirestore.instance
          .collection('addlessons')
          .doc(lessonId)
          .delete();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок удалён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении урока: $e')),
      );
    }
    setState(() {});
  }

  Future<void> _deleteaudioLesson(String lessonId) async {
    try {
      await FirebaseFirestore.instance
          .collection('addlessons')
          .doc(lessonId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок удалён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении урока: $e')),
      );
    }
    setState(() {});
  }

  Future<void> _deletevideoLesson(String lessonId) async {
    try {
      await FirebaseFirestore.instance
          .collection('videolessons')
          .doc(lessonId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок удалён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении урока: $e')),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    _remainingTimeNotifier.dispose(); // Dispose the ValueNotifier
    super.dispose();
  }

  Future<void> _fetchUserProgress() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final String id = currentUser.uid;

      // Получаем данные пользователя из Firestore
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (userSnapshot.exists) {
        final dynamic userProgressData = userSnapshot['progress'];

        // Проверяем, является ли прогресс картой, числом или списком
        if (userProgressData is Map<String, dynamic>) {
          // Если это карта, вы можете обрабатывать прогресс по урокам
          // Например, здесь сохраняем количество уроков или другие метрики
          // Если у вас есть конкретный ключ, который вы хотите получить:
          userProgress = userProgressData['someKey'] ??
              0; // Измените 'someKey' на ваш ключ

          // Если вы хотите хранить весь прогресс как карту
          // userProgressMap = userProgressData; // Если у вас есть отдельная переменная для карты прогресса
        } else if (userProgressData is int) {
          // Если это просто число
          setState(() {
            userProgress = userProgressData;
          });
        } else if (userProgressData is List<dynamic>) {
          // Если это список, вы можете обработать его как нужно
          setState(() {
            userProgress = userProgressData
                .length; // Например, устанавливаем прогресс как длину списка
          });
        } else {
          // В случае, если данных нет или тип другой
          setState(() {
            userProgress = 0; // Установите значение по умолчанию
          });
        }
      }
    }
  }

  Future<void> _fetchLastRestoredTime() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final String id = currentUser.uid;

      // Получить данные пользователя из Firestore
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (userSnapshot.exists) {
        lives =
            userSnapshot['lives'] ?? 0; // Получить текущее количество жизней
        Timestamp lastRestored =
            userSnapshot['lastRestored'] ?? Timestamp.now();
        DateTime nextRestoreTime = lastRestored
            .toDate()
            .add(const Duration(seconds: 10)); // Изменяем время на 10 секунд
        _remainingTime = nextRestoreTime.difference(DateTime.now()).inSeconds;

        // Предотвратить отрицательное значение для _remainingTime
        if (_remainingTime < 0) {
          _remainingTime = 0;
        }

        // Обновить ValueNotifier, чтобы отразить оставшееся время
        _remainingTimeNotifier.value = _remainingTime;

        // Обновить отображение времени
        _timeString = _formatTime(_remainingTime);

        if (_remainingTime > 0 && lives < 5) {
          // Условие изменено на lives < 5
          // Запускаем таймер для восстановления жизней, если осталось время и жизней меньше 5
          _startTimer();
        }
      }
    }
  }

  void _startTimer() {
    // Отменяем любой существующий таймер, чтобы предотвратить множественные таймеры
    _timer?.cancel();

    // Запускаем таймер только если жизней меньше 5
    if (lives < 5) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Обновляем оставшееся время, используя ValueNotifier
        if (_remainingTimeNotifier.value > 0) {
          _remainingTimeNotifier.value--;
        } else {
          _timer?.cancel(); // Останавливаем таймер, когда время истекло
          _restoreLife(); // Восстанавливаем жизнь, когда время истекло
        }
      });
    }
  }

  Future<void> _restoreLife() async {
    setState(() {});
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final String id = currentUser.uid;

      if (lives < 5) {
        lives++; // Увеличиваем количество жизней
        await FirebaseFirestore.instance.collection('users').doc(id).update({
          'lives': lives, // Обновляем жизни в Firestore
          'lastRestored':
              Timestamp.now(), // Обновляем время последнего восстановления
        });

        // Сбрасываем оставшееся время на 10 секунд для следующей жизни
        _remainingTime = 10; // Устанавливаем 10 секунд
        _remainingTimeNotifier.value =
            _remainingTime; // Обновляем ValueNotifier
        _timeString =
            _formatTime(_remainingTime); // Обновляем отображаемое время

        // Запускаем таймер для следующей жизни, если жизней меньше 5
        _startTimer();
      } else {
        // Если жизней уже 5, останавливаем таймер
        _timer?.cancel();
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = (seconds ~/ 60);
    seconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<bool> _deductLife() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final String id = currentUser.uid;

      if (lives > 0) {
        // Ensure lives count does not go negative
        lives--; // Decrease local lives count
        await FirebaseFirestore.instance.collection('users').doc(id).update({
          'lives': lives, // Update lives in Firestore
          'lastRestored': Timestamp.now(), // Update last restored time
        });

        // Update countdown timer
        _fetchLastRestoredTime(); // Refresh countdown after deduction
        setState(() {}); // Update UI
        return true; // Return true if life was successfully deducted
      }
    }
    return false; // Return false if there are no lives left
  }

  Future<void> _getUserLanguageLevel() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final String id = currentUser.uid;

      // Get user data from Firestore
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (userSnapshot.exists) {
        setState(() {
          userLanguageLevel = userSnapshot['language'] ?? '';
          lives = userSnapshot['lives'] ?? 0; // Get number of lives
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
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
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Пользователь не найден"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Учить"),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pushReplacementNamed(
        //         context, '/profile'); // Возврат на предыдущую страницу
        //   },
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя панель с курсом и статусом
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.school,
                            size: 32,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Изучение английского языка',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Восстановление',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                  ValueListenableBuilder<int>(
                                    valueListenable: _remainingTimeNotifier,
                                    builder: (context, remainingTime, child) {
                                      return Text(
                                        _formatTime(remainingTime),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 8),
                      _StatusInfo(
                          icon: Icons.heart_broken_rounded, count: lives),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _AudioMessageCard(),

            // Основная область контента
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lessons list
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: FutureBuilder(
                          future: fetchLessonsFromFirestore(),
                          builder: (context,
                              AsyncSnapshot<List<Map<String, dynamic>>>
                                  snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text("Ошибка: ${snapshot.error}"));
                            } else {
                              final lessons = snapshot.data ?? [];
                              return Column(
                                children: [
                                  for (var lesson in lessons)
                                    _LessonCard(
                                        title: lesson['title'],
                                        icon: Icons.book,
                                        onTap: () async {
                                          bool lifeDeducted =
                                              await _deductLife();
                                          if (lifeDeducted) {
                                            await fetchAndSaveQuestions(
                                                lesson['id']);
                                            Navigator.pushNamed(
                                                context, '/lesson',
                                                arguments: lesson['id']);
                                          } else {
                                            // Показать сообщение о недостатке жизней
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Недостаточно жизней для прохождения урока')),
                                            );
                                          }
                                        })
                                ],
                              );
                            }
                          },
                        ),
                      ),

                      // Вторая строка карточек
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: FutureBuilder(
                          future: fetchAddLessonsFromFirestore(),
                          builder: (context,
                              AsyncSnapshot<List<Map<String, dynamic>>>
                                  snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text("Ошибка: ${snapshot.error}"));
                            } else {
                              final addLessons = snapshot.data ?? [];
                              return GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.40,
                                  crossAxisSpacing:
                                      3.0, // Уменьшено расстояние по горизонтали
                                  mainAxisSpacing: 2.0,
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: addLessons.length,
                                itemBuilder: (context, index) {
                                  final lesson = addLessons[index];
                                  return FutureBuilder(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth
                                            .instance.currentUser?.uid)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text(
                                            'Ошибка: ${snapshot.error}');
                                      } else if (!snapshot.hasData ||
                                          !(snapshot.data?.exists ?? false)) {
                                        return const Text(
                                            'Нет данных о пользователе');
                                      }

                                      // Извлекаем данные пользователя
                                      final userData = snapshot.data!;
                                      final isAdmin = userData['email'] ==
                                          'admin@mail.ru'; // Проверяем, является ли пользователь администратором

                                      // Извлекаем прогресс пользователя
                                      final userProgressData =
                                          userData['progress'] ?? {};
                                      int lessonProgress = 0;

                                      if (userProgressData
                                          is Map<String, dynamic>) {
                                        lessonProgress =
                                            userProgressData[lesson['id']] ?? 0;
                                      } else if (userProgressData is int) {
                                        lessonProgress = userProgressData;
                                      }

                                      return Container(
                                        height: 150,
                                        child: Column(
                                          children: [
                                            _AddLessonCard(
                                              title: lesson['lessonName'] ??
                                                  'Без названия',
                                              lessonId: lesson['id'] ?? '',
                                              progress: lessonProgress,
                                              onTap: () async {
                                                bool lifeDeducted =
                                                    await _deductLife();
                                                if (lifeDeducted) {
                                                  if (lesson['id'] != null &&
                                                      lesson['id'] != '') {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            LessonPage1(
                                                          lessonId:
                                                              lesson['id'],
                                                          lessonLevel: lesson[
                                                              'level'], // Передаем уровень урока
                                                          onProgressUpdated:
                                                              (progress) {
                                                            setState(() {
                                                              lessonProgress =
                                                                  progress;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Нет доступных уроков')),
                                                    );
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Недостаточно жизней для прохождения урока')),
                                                  );
                                                }
                                              },
                                            ),
                                            if (isAdmin) // Отображаем кнопку удаления, если пользователь администратор
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  _deleteaddLesson(lesson[
                                                      'id']); // Ваша логика удаления
                                                },
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: const Text(
                                  "Уроки для Elementary",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 700, // Ограничьте высоту GridView
                                child: FutureBuilder(
                                  future: fetchUpperLessonsFromFirestore(),
                                  builder: (context,
                                      AsyncSnapshot<List<Map<String, dynamic>>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Ошибка: ${snapshot.error}"));
                                    } else {
                                      final upperLessons = snapshot.data ?? [];

                                      return GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: upperLessons.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          String lessonLevel =
                                              upperLessons[index]['level'] ??
                                                  '';
                                          bool isAccessible =
                                              _checkLessonAccess(lessonLevel);
                                          // Получаем прогресс для текущего урока
                                          int progress = upperLessons[index]
                                                  ['progress'] ??
                                              0;

                                          return Container(
                                            height: 200,
                                            child: Stack(
                                              children: [
                                                _UpperLessonCard(
                                                  title: upperLessons[index]
                                                          ['title'] ??
                                                      'Урок',
                                                  lessonId: upperLessons[index]
                                                          ['id'] ??
                                                      '',
                                                  onTap: () async {
                                                    bool lifeDeducted =
                                                        await _deductLife();
                                                    if (lifeDeducted) {
                                                      if (isAccessible) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                UpperLessonPage(
                                                              lessonId:
                                                                  upperLessons[
                                                                          index]
                                                                      ['id'],
                                                              onProgressUpdated:
                                                                  (newProgress) {
                                                                setState(() {
                                                                  // Обновляем прогресс для текущего урока
                                                                  upperLessons[
                                                                              index]
                                                                          [
                                                                          'progress'] =
                                                                      newProgress;
                                                                });
                                                              },
                                                              lessonLevel: upperLessons[
                                                                          index]
                                                                      [
                                                                      'languageLevel'] ??
                                                                  '',
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Урок не доступен на вашем уровне: $lessonLevel'),
                                                          ),
                                                        );
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Недостаточно жизней для прохождения урока'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  isAccessible: isAccessible,
                                                  progress:
                                                      progress, // Отображаем текущий прогресс
                                                ),
                                                if (isAdmin)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () {},
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: const Text(
                                  "Уроки для Intermediate",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 400, // Ограничьте высоту GridView
                                child: FutureBuilder(
                                  future: fetchUpperInterLessonsFromFirestore(),
                                  builder: (context,
                                      AsyncSnapshot<List<Map<String, dynamic>>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Ошибка: ${snapshot.error}"));
                                    } else {
                                      final upperinterLessons =
                                          snapshot.data ?? [];
                                      int lessonProgress =
                                          0; // Инициализация переменной прогресса

                                      // Извлекаем прогресс пользователя
                                      final userProgressData = snapshot
                                          .data; // Замените на актуальный вызов, если нужно
                                      if (userProgressData
                                          is List<Map<String, dynamic>>) {
                                        // Пример, как получить прогресс конкретного урока
                                        lessonProgress = userProgressData
                                                .isNotEmpty
                                            ? userProgressData[0]['progress'] ??
                                                0
                                            : 0; // Здесь можно установить логику для получения прогресса
                                      }

                                      return GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing:
                                              8.0, // Уменьшено расстояние по горизонтали
                                          mainAxisSpacing: 8.0,
                                        ),
                                        itemCount: upperinterLessons.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          String lessonLevel =
                                              upperinterLessons[index]
                                                      ['level'] ??
                                                  '';
                                          bool isAccessible =
                                              _checkLessonAccess(lessonLevel);
                                          // Получаем прогресс для текущего урока
                                          int progress =
                                              upperinterLessons[index]
                                                      ['progress'] ??
                                                  0;

                                          return Container(
                                            height: 200,
                                            child: Stack(
                                              children: [
                                                _UpperInterLessonCard(
                                                  title:
                                                      upperinterLessons[index]
                                                              ['title'] ??
                                                          'Урок',
                                                  lessonId:
                                                      upperinterLessons[index]
                                                              ['id'] ??
                                                          '',
                                                  onTap: () async {
                                                    bool lifeDeducted =
                                                        await _deductLife();
                                                    if (lifeDeducted) {
                                                      if (isAccessible) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                UpperInterLessonPage(
                                                              lessonId:
                                                                  upperinterLessons[
                                                                          index]
                                                                      ['id'],
                                                              onProgressUpdated:
                                                                  (newProgress) {
                                                                setState(() {
                                                                  lessonProgress =
                                                                      newProgress; // Обновляем прогресс
                                                                });
                                                              },
                                                              languageLevel:
                                                                  upperinterLessons[
                                                                              index]
                                                                          [
                                                                          'languageLevel'] ??
                                                                      '',
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Урок не доступен на вашем уровне: $lessonLevel'),
                                                          ),
                                                        );
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Недостаточно жизней для прохождения урока'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  isAccessible: isAccessible,
                                                  progress:
                                                      progress, // Отображаем текущий прогресс
                                                ),
                                                if (isAdmin)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () {},
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: const Text(
                                  "Уроки для Upper Intermediate",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 400, // Ограничьте высоту GridView
                                child: FutureBuilder(
                                  future:
                                      fetchUpperUpInterLessonsFromFirestore(),
                                  builder: (context,
                                      AsyncSnapshot<List<Map<String, dynamic>>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Ошибка: ${snapshot.error}"));
                                    } else {
                                      final upperupinterupLessons =
                                          snapshot.data ?? [];
                                      int lessonProgress =
                                          0; // Инициализация переменной прогресса

                                      // Извлекаем прогресс пользователя
                                      final userProgressData = snapshot
                                          .data; // Замените на актуальный вызов, если нужно
                                      if (userProgressData
                                          is List<Map<String, dynamic>>) {
                                        // Пример, как получить прогресс конкретного урока
                                        lessonProgress = userProgressData
                                                .isNotEmpty
                                            ? userProgressData[0]['progress'] ??
                                                0
                                            : 0; // Здесь можно установить логику для получения прогресса
                                      }

                                      return GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing:
                                              8.0, // Уменьшено расстояние по горизонтали
                                          mainAxisSpacing: 8.0,
                                        ),
                                        itemCount: upperupinterupLessons.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          String lessonLevel =
                                              upperupinterupLessons[index]
                                                      ['level'] ??
                                                  '';
                                          bool isAccessible =
                                              _checkLessonAccess(lessonLevel);
                                          // Получаем прогресс для текущего урока
                                          int progress =
                                              upperupinterupLessons[index]
                                                      ['progress'] ??
                                                  0;

                                          return Container(
                                            height: 200,
                                            child: Stack(
                                              children: [
                                                _UpperUpInterLessonCard(
                                                  title: upperupinterupLessons[
                                                          index]['title'] ??
                                                      'Урок',
                                                  lessonId:
                                                      upperupinterupLessons[
                                                              index]['id'] ??
                                                          '',
                                                  onTap: () async {
                                                    bool lifeDeducted =
                                                        await _deductLife();
                                                    if (lifeDeducted) {
                                                      if (isAccessible) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                UpperUpInterLessonPage(
                                                              lessonId:
                                                                  upperupinterupLessons[
                                                                          index]
                                                                      ['id'],
                                                              onProgressUpdated:
                                                                  (newProgress) {
                                                                setState(() {
                                                                  lessonProgress =
                                                                      newProgress; // Обновляем прогресс
                                                                });
                                                              },
                                                              languageLevel:
                                                                  upperupinterupLessons[
                                                                              index]
                                                                          [
                                                                          'languageLevel'] ??
                                                                      '',
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Урок не доступен на вашем уровне: $lessonLevel'),
                                                          ),
                                                        );
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Недостаточно жизней для прохождения урока'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  isAccessible: isAccessible,
                                                  progress:
                                                      progress, // Отображаем текущий прогресс
                                                ),
                                                if (isAdmin)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () {},
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: const Text(
                                  "Уроки для Advanced",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 400, // Ограничьте высоту GridView
                                child: FutureBuilder(
                                  future: fetchAdvancedLessonsFromFirestore(),
                                  builder: (context,
                                      AsyncSnapshot<List<Map<String, dynamic>>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Ошибка: ${snapshot.error}"));
                                    } else {
                                      final advancedLessons =
                                          snapshot.data ?? [];
                                      int lessonProgress =
                                          0; // Инициализация переменной прогресса

                                      // Извлекаем прогресс пользователя
                                      final userProgressData = snapshot
                                          .data; // Замените на актуальный вызов, если нужно
                                      if (userProgressData
                                          is List<Map<String, dynamic>>) {
                                        // Пример, как получить прогресс конкретного урока
                                        lessonProgress = userProgressData
                                                .isNotEmpty
                                            ? userProgressData[0]['progress'] ??
                                                0
                                            : 0; // Здесь можно установить логику для получения прогресса
                                      }

                                      return GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: advancedLessons.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          String lessonLevel =
                                              advancedLessons[index]['level'] ??
                                                  '';
                                          bool isAccessible =
                                              _checkLessonAccess(lessonLevel);
                                          // Получаем прогресс для текущего урока
                                          int progress = advancedLessons[index]
                                                  ['progress'] ??
                                              0;

                                          return Container(
                                            height: 200,
                                            child: Stack(
                                              children: [
                                                _AdvancedLessonCard(
                                                  title: advancedLessons[index]
                                                          ['title'] ??
                                                      'Урок',
                                                  lessonId:
                                                      advancedLessons[index]
                                                              ['id'] ??
                                                          '',
                                                  onTap: () async {
                                                    bool lifeDeducted =
                                                        await _deductLife();
                                                    if (lifeDeducted) {
                                                      if (isAccessible) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                AdvancedLessonPage(
                                                              lessonId:
                                                                  advancedLessons[
                                                                          index]
                                                                      ['id'],
                                                              onProgressUpdated:
                                                                  (newProgress) {
                                                                setState(() {
                                                                  lessonProgress =
                                                                      newProgress; // Обновляем прогресс
                                                                });
                                                              },
                                                              languageLevel:
                                                                  advancedLessons[
                                                                              index]
                                                                          [
                                                                          'languageLevel'] ??
                                                                      '',
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Урок не доступен на вашем уровне: $lessonLevel'),
                                                          ),
                                                        );
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Недостаточно жизней для прохождения урока'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  isAccessible: isAccessible,
                                                  progress:
                                                      progress, // Отображаем текущий прогресс
                                                ),
                                                if (isAdmin)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () {},
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Секция аудиоуроков

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: const Text(
                                  "Аудио уроки",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Оберните GridView в SizedBox с фиксированной высотой
                              SizedBox(
                                height: 400, // Ограничьте высоту GridView
                                child: FutureBuilder(
                                  future: fetchAudioLessonsFromFirestore(),
                                  builder: (context,
                                      AsyncSnapshot<List<Map<String, dynamic>>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Ошибка: ${snapshot.error}"));
                                    } else {
                                      final audioLessons = snapshot.data ?? [];
                                      return GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: audioLessons.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(), // Отключите прокрутку
                                        itemBuilder: (context, index) {
                                          String lessonLevel =
                                              audioLessons[index]
                                                      ['languageLevel'] ??
                                                  '';
                                          bool isAccessible =
                                              _checkLessonAccess(lessonLevel);
                                          int progress = audioLessons[index]
                                                  ['progress'] ??
                                              0;

                                          return Container(
                                            height: 200,
                                            child: Stack(
                                              children: [
                                                _AudioLessonCard(
                                                  title: audioLessons[index]
                                                          ['title'] ??
                                                      'Урок',
                                                  lessonId: audioLessons[index]
                                                          ['id'] ??
                                                      '',
                                                  onTap: () async {
                                                    bool lifeDeducted =
                                                        await _deductLife();
                                                    if (lifeDeducted) {
                                                      if (isAccessible) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                AudioLessonPage(
                                                              lessonId:
                                                                  audioLessons[
                                                                          index]
                                                                      ['id'],
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Урок не доступен на вашем уровне: $lessonLevel'),
                                                          ),
                                                        );
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Недостаточно жизней для прохождения урока'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  isAccessible: isAccessible,
                                                  progress: progress,
                                                ),
                                                if (isAdmin) // Отображаем кнопку удаления, если пользователь администратор
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () {
                                                        _deleteaudioLesson(
                                                            audioLessons[index]
                                                                ['id']);
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

// Секция видеоуроков
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: const Text(
                                  "Видео уроки",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Оберните GridView в SizedBox с фиксированной высотой
                              SizedBox(
                                height: 400, // Ограничьте высоту GridView
                                child: FutureBuilder(
                                  future:
                                      fetchVideoLessonsFromFirestore(), // Функция для получения видеоуроков из Firestore
                                  builder: (context,
                                      AsyncSnapshot<List<Map<String, dynamic>>>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              "Ошибка: ${snapshot.error}"));
                                    } else {
                                      final videoLessons = snapshot.data ?? [];
                                      return GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: videoLessons.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(), // Отключите прокрутку
                                        itemBuilder: (context, index) {
                                          String lessonLevel =
                                              videoLessons[index]
                                                      ['languageLevel'] ??
                                                  '';
                                          bool isAccessible = _checkLessonAccess(
                                              lessonLevel); // Проверка доступа к уроку
                                          int progress = videoLessons[index]
                                                  ['progress'] ??
                                              0;

                                          return Container(
                                            height: 200,
                                            child: Stack(
                                              children: [
                                                _VideoLessonCard(
                                                  title: videoLessons[index]
                                                          ['title'] ??
                                                      'Видео урок',
                                                  lessonId: videoLessons[index]
                                                          ['id'] ??
                                                      '',
                                                  onTap: () async {
                                                    bool lifeDeducted =
                                                        await _deductLife(); // Снятие жизни при прохождении урока
                                                    if (lifeDeducted) {
                                                      if (isAccessible) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                VideoLessonPage(
                                                              lessonId:
                                                                  videoLessons[
                                                                          index]
                                                                      ['id'],
                                                              title: videoLessons[
                                                                      index][
                                                                  'title'], // Передаем title если нужно
                                                              videoUrl:
                                                                  videoLessons[
                                                                          index]
                                                                      [
                                                                      'videoUrl'], // Передаем ссылку на видео
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Урок не доступен на вашем уровне: $lessonLevel'),
                                                          ),
                                                        );
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Недостаточно жизней для прохождения урока'),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  isAccessible: isAccessible,
                                                  progress: progress,
                                                ),
                                                if (isAdmin) // Отображаем кнопку удаления, если пользователь администратор
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red),
                                                      onPressed: () {
                                                        _deletevideoLesson(
                                                            videoLessons[index]
                                                                ['id']);
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
              ),
            )
          ],
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Учиться',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad), // Icon for "Read"
            label: 'Играть',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Уведомления',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[700],
        onTap: _onItemTapped,
      ),
    );
  }

  // Method to check lesson access
  bool _checkLessonAccess(String requiredLevel) {
    const levels = [
      "Beginner",
      "Elementary",
      "Intermediate",
      "Upper Intermediate",
      "Advanced"
    ];

    int userLevelIndex = levels.indexOf(userLanguageLevel);
    int requiredLevelIndex = levels.indexOf(requiredLevel);

    // Урок доступен, если индекс уровня пользователя больше или равен требуемому
    return userLevelIndex >= requiredLevelIndex;
  }
}

class _VideoLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;
  final VoidCallback onTap;
  final bool isAccessible;
  final int progress;

  _VideoLessonCard({
    required this.title,
    required this.lessonId,
    required this.onTap,
    required this.isAccessible,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Отображение прогресса
              // LinearProgressIndicator(
              //   value: progress / 100,
              //   backgroundColor: Colors.grey[300],
              //   color: isAccessible ? Colors.green : Colors.red,
              // ),
              const SizedBox(height: 8),
              // Text(
              //   '$progress% завершено',
              //   style: TextStyle(
              //     fontSize: 14,
              //     color: Colors.grey[600],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> fetchVideoLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('videolessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

Future<List<Map<String, dynamic>>> fetchAudioLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('audiolessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

Future<List<Map<String, dynamic>>> fetchUpperLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('upperlessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

Future<List<Map<String, dynamic>>>
    fetchUpperUpInterLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('upperupinterlessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

Future<List<Map<String, dynamic>>> fetchAdvancedLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('advancedlessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

Future<List<Map<String, dynamic>>> fetchUpperInterLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('upperinterlessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

Future<List<Map<String, dynamic>>> fetchAddLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('addlessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

class _AudioMessageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green[600],
          child: const Icon(Icons.mic, color: Colors.white, size: 32),
        ),
        title: const Text(
          'Узнать как говорить',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AudioPage()),
          );
        },
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final IconData icon;
  final int count;

  const _StatusInfo({Key? key, required this.icon, required this.count})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Colors.white,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

// Пример класса для отображения аудиоурока
class _AudioLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;
  final bool isAccessible;
  final int progress; // Поле для прогресса
  final VoidCallback onTap;

  const _AudioLessonCard({
    required this.title,
    required this.lessonId,
    required this.onTap,
    required this.isAccessible,
    this.progress = 0, // Значение по умолчанию
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green[600],
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: isAccessible
                ? onTap
                : () {
                    // Если урок не доступен, показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Урок не доступен на вашем уровне.'),
                      ),
                    );
                  },
          ),
          // Отображение прогресса
          LinearProgressIndicator(
            value: progress / 100, // Преобразуем прогресс в диапазон от 0 до 1
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Прогресс: $progress%', // Отображаем прогресс
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Пример класса для отображения статуса

// Пример класса для создания аудио сообщения

// Пример класса для карточки урока
// Обновленный метод для отображения карточек уроков с процентом выполнения
class _LessonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LessonCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isLevelSufficient(String userLevel, String lessonLevel) {
  const levels = [
    "Beginner",
    "Elementary",
    "Intermediate",
    "Upper Intermediate",
    "Advanced"
  ];
  int userLevelIndex = levels.indexOf(userLevel);
  int lessonLevelIndex = levels.indexOf(lessonLevel);

  return userLevelIndex >= lessonLevelIndex;
}

class _UpperLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;
  final bool isAccessible;
  final int progress; // Поле для прогресса
  final VoidCallback onTap;

  const _UpperLessonCard({
    required this.title,
    required this.lessonId,
    required this.onTap,
    required this.isAccessible,
    this.progress = 0, // Значение по умолчанию
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: const Color.fromARGB(
                  255, 13, 116, 13), // Цвет для UpperLesson
              child: const Icon(Icons.book,
                  color: Colors.white, size: 32), // Иконка для UpperLesson
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: isAccessible
                ? onTap
                : () {
                    // Если урок не доступен, показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Урок не доступен на вашем уровне.'),
                      ),
                    );
                  },
          ),
          // Отображение прогресса
          LinearProgressIndicator(
            value: progress / 100, // Преобразуем прогресс в диапазон от 0 до 1
            backgroundColor: Colors.grey[300],
            color: const Color.fromARGB(255, 25, 190, 47),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Прогресс: $progress%', // Отображаем прогресс
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;
  final int progress; // Прогресс
  final VoidCallback onTap;

  const _AddLessonCard({
    Key? key,
    required this.title,
    required this.lessonId,
    required this.progress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                height: 8,
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.black,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 100 ? Colors.green : Colors.yellow,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Прогресс: $progress%',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperInterLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;
  final bool isAccessible;
  final int progress; // Поле для прогресса
  final VoidCallback onTap;

  const _UpperInterLessonCard({
    required this.title,
    required this.lessonId,
    required this.onTap,
    required this.isAccessible,
    this.progress = 0, // Значение по умолчанию
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: const Color.fromARGB(
                  255, 19, 167, 44), // Цвет для UpperLesson
              child: const Icon(Icons.book,
                  color: Colors.white, size: 32), // Иконка для UpperLesson
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: isAccessible
                ? onTap
                : () {
                    // Если урок не доступен, показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Урок не доступен на вашем уровне.'),
                      ),
                    );
                  },
          ),
          // Отображение прогресса
          LinearProgressIndicator(
            value: progress / 100, // Преобразуем прогресс в диапазон от 0 до 1
            backgroundColor: Colors.grey[300],
            color: const Color.fromARGB(255, 25, 190, 47),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Прогресс: $progress%', // Отображаем прогресс
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperUpInterLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;
  final bool isAccessible;
  final int progress; // Поле для прогресса
  final VoidCallback onTap;

  const _UpperUpInterLessonCard({
    required this.title,
    required this.lessonId,
    required this.onTap,
    required this.isAccessible,
    this.progress = 0, // Значение по умолчанию
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor:
                  Color.fromARGB(255, 19, 167, 44), // Цвет для UpperLesson
              child: const Icon(Icons.book,
                  color: Colors.white, size: 32), // Иконка для UpperLesson
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: isAccessible
                ? onTap
                : () {
                    // Если урок не доступен, показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Урок не доступен на вашем уровне.'),
                      ),
                    );
                  },
          ),
          // Отображение прогресса
          LinearProgressIndicator(
            value: progress / 100, // Преобразуем прогресс в диапазон от 0 до 1
            backgroundColor: Colors.grey[300],
            color: Color.fromARGB(255, 19, 167, 44),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Прогресс: $progress%', // Отображаем прогресс
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;
  final bool isAccessible;
  final int progress; // Поле для прогресса
  final VoidCallback onTap;

  const _AdvancedLessonCard({
    required this.title,
    required this.lessonId,
    required this.onTap,
    required this.isAccessible,
    this.progress = 0, // Значение по умолчанию
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor:
                  Color.fromARGB(255, 19, 167, 44), // Цвет для UpperLesson
              child: const Icon(Icons.book,
                  color: Colors.white, size: 32), // Иконка для UpperLesson
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: isAccessible
                ? onTap
                : () {
                    // Если урок не доступен, показываем сообщение
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Урок не доступен на вашем уровне.'),
                      ),
                    );
                  },
          ),
          // Отображение прогресса
          LinearProgressIndicator(
            value: progress / 100, // Преобразуем прогресс в диапазон от 0 до 1
            backgroundColor: Colors.grey[300],
            color: Color.fromARGB(255, 19, 167, 44),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Прогресс: $progress%', // Отображаем прогресс
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
