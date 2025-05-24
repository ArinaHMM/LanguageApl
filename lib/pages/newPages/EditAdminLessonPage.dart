import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminLearnPage extends StatefulWidget {
  @override
  _AdminLearnPageState createState() => _AdminLearnPageState();
}

class _AdminLearnPageState extends State<AdminLearnPage> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _editLesson(String lessonId, String currentName) async {
    TextEditingController lessonController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать урок'),
          content: TextField(
            controller: lessonController,
            decoration:
                InputDecoration(hintText: "Введите новое название урока"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (lessonController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('addlessons')
                        .doc(lessonId)
                        .update({'lessonName': lessonController.text});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Урок обновлён')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Ошибка при обновлении урока: $e')),
                    );
                  }
                  Navigator.of(context).pop();
                  setState(() {}); // Обновление интерфейса
                }
              },
              child: Text('Сохранить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteaddLesson(String lessonId) async {
    try {
      await FirebaseFirestore.instance
          .collection('addlessons')
          .doc(lessonId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Урок удалён')),
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
        SnackBar(content: Text('Урок удалён')),
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
        SnackBar(content: Text('Урок удалён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении урока: $e')),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Учить"),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(
                context, '/navadmin'); // Возврат на предыдущую страницу
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: fetchAddLessonsFromFirestore(),
                          builder: (context, snapshot) {
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
                                  childAspectRatio: 1,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: addLessons.length,
                                itemBuilder: (context, index) {
                                  final lesson = addLessons[index];
                                  return GestureDetector(
                                    onLongPress: () =>
                                        _deleteaddLesson(lesson['id']),
                                    child: Container(
                                      height: 150,
                                      child: Column(
                                        children: [
                                          _AddLessonCard(
                                            title: lesson['lessonName'] ??
                                                'Без названия',
                                            lessonId: lesson['id'] ?? '',
                                          ),
                                        ],
                                      ),
                                    ),
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
                                child: Text(
                                  "Аудио уроки",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 400,
                                child:
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                  future: fetchAudioLessonsFromFirestore(),
                                  builder: (context, snapshot) {
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
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final audioLesson =
                                              audioLessons[index];
                                          return GestureDetector(
                                            onLongPress: () =>
                                                _deleteaudioLesson(
                                                    audioLesson['id']),
                                            child: Container(
                                              height: 200,
                                              child: _AudioLessonCard(
                                                title: audioLesson['title'] ??
                                                    'Урок',
                                                lessonId:
                                                    audioLesson['id'] ?? '',
                                              ),
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
                                child: Text(
                                  "Видео уроки",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 400,
                                child:
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                  future: fetchVideoLessonsFromFirestore(),
                                  builder: (context, snapshot) {
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
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final videoLesson =
                                              videoLessons[index];
                                          return GestureDetector(
                                            onLongPress: () =>
                                                _deletevideoLesson(
                                                    videoLesson['id']),
                                            child: Container(
                                              height: 200,
                                              child: _VideoLessonCard(
                                                title: videoLesson['title'] ??
                                                    'Видео урок',
                                                lessonId:
                                                    videoLesson['id'] ?? '',
                                              ),
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

Future<List<Map<String, dynamic>>> fetchAddLessonsFromFirestore() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('addlessons').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
      .toList();
}

class _VideoLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;

  _VideoLessonCard({
    required this.title,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;

  const _AddLessonCard({
    Key? key,
    required this.title,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                height: 8,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

// Пример класса для отображения аудиоурока
class _AudioLessonCard extends StatelessWidget {
  final String title;
  final String lessonId;

  const _AudioLessonCard({
    required this.title,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Column(children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green[600],
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
            title: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )
        ]));
  }
}
