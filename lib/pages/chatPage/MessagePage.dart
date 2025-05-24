import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.chat});

  @override
  State<MessagesPage> createState() => MessagesPageState();
  final DocumentSnapshot chat;
}

var oldSnapshot;
var oldMessagesSnapshot;

class MessagesPageState extends State<MessagesPage> {
  late Map<String, dynamic> chatData;
  var user;
  TextEditingController messageController = TextEditingController();
  final DateFormat formatter = DateFormat('hh:mm a');
  final ImagePicker _picker = ImagePicker(); // Инициализируем Image Picker

  @override
  void initState() {
    super.initState();
    chatData = widget.chat.data() as Map<String, dynamic>;
  }

  void sendMessage({String? imageUrl}) {
    String messageText = messageController.text;
    if (messageText.isNotEmpty || imageUrl != null) {
      FirebaseFirestore.instance.collection('messages').add({
        'chatId': chatData["chatId"],
        'messageText': messageText,
        'imageUrl':
            imageUrl ?? '', // Если изображение отправляется, сохраняем ссылку
        'senderId': currentUser,
        'timeStamp': DateTime.now().toIso8601String(),
      });
      messageController.clear();
    }
  }

  var currentUser = FirebaseAuth.instance.currentUser!.uid;

  // Получаем все сообщения для данного чата
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages() {
    var usersCollection = FirebaseFirestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: chatData["chatId"]);
    return usersCollection.snapshots();
  }

  // Получение данных пользователя
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) async {
    return user = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .first;
  }

  // Функция для выбора и загрузки изображения
  Future<void> pickAndUploadImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Создаем уникальное имя для файла на Firebase Storage
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('chat_images/$fileName');

      // Загружаем файл в Firebase Storage
      await storageRef.putFile(imageFile);

      // Получаем URL загруженного изображения
      String downloadUrl = await storageRef.getDownloadURL();

      // Отправляем сообщение с изображением
      sendMessage(imageUrl: downloadUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId =
        chatData['user1id'] == FirebaseAuth.instance.currentUser!.uid
            ? chatData['user2id']
            : chatData['user1id'];
    getUser(userId);
    return FutureBuilder(
      future: getUser(userId),
      builder: (context, snapshot) {
        oldSnapshot = snapshot;
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (!snapshot.hasData) {
            snapshot = oldSnapshot;
          }
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else if (snapshot.hasData) {
          var user = snapshot.data!.data();
          var userName = user?['firstName'] ?? 'No name';
          return Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  iconSize: 18,
                  alignment: Alignment.centerRight,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Text(
                  userName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                backgroundColor: Color.fromARGB(255, 56, 179, 76),
              ),
              body: Stack(children: [
                Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: getAllMessages(),
                        builder: (context, snapshot) {
                          oldMessagesSnapshot = snapshot;
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            if (!oldMessagesSnapshot.hasData) {
                              snapshot = oldMessagesSnapshot;
                            }
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData) {
                            return const Center(
                                child: Text('No documents found'));
                          } else {
                            List<QueryDocumentSnapshot> documents =
                                snapshot.data!.docs;

                            documents.sort((a, b) => a['timeStamp']
                                .toString()
                                .compareTo(b['timeStamp'].toString()));

                            return ListView.builder(
                              reverse:
                                  false, // Сообщения будут в порядке возрастания
                              itemCount: documents.length,
                              itemBuilder: (context, index) {
                                var messageData = documents[index];
                                if (messageData["senderId"] == currentUser) {
                                  return _messageSend(
                                      messageData["messageText"],
                                      messageData["timeStamp"],
                                      messageData["imageUrl"]);
                                } else {
                                  return _messageGet(
                                      messageData["messageText"],
                                      messageData["timeStamp"],
                                      messageData["imageUrl"]);
                                }
                              },
                            );
                          }
                        },
                      ),
                    ),
                    Container(
                      color: Color.fromARGB(255, 72, 112, 34),
                      height: 45,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.attach_file,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                            onPressed: pickAndUploadImage, // Выбор изображения
                          ),
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintStyle: TextStyle(
                                    color: Color.fromARGB(255, 158, 158, 158),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                                hintText: 'Введите сообщение',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) {},
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                            onPressed: () {
                              setState(() {
                                sendMessage();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ]));
        } else {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
      },
    );
  }

  // Виджет сообщения отправителя (с сообщением и/или изображением)
  Widget _messageSend(
      String? messageText, String? timeStamp, String? imageUrl) {
    DateTime dateTime = DateTime.parse(timeStamp!);
    String formattedTime = DateFormat('HH:mm').format(dateTime);
    return Container(
        alignment: Alignment.bottomRight,
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85),
            child: Card(
              color: Color.fromARGB(255, 48, 122, 26),
              shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                  )),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null &&
                          imageUrl.isNotEmpty) // Отображение изображения
                        Image.network(imageUrl),
                      Text(
                        messageText ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          formattedTime,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 241, 241, 241),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ]),
              ),
            )));
  }

  // Виджет сообщения получателя (с сообщением и/или изображением)
  Widget _messageGet(String? messageText, String? timeStamp, String? imageUrl) {
    DateTime dateTime = DateTime.parse(timeStamp!);
    String formattedTime = DateFormat('HH:mm').format(dateTime);
    return Container(
        alignment: Alignment.bottomLeft,
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85),
            child: Card(
              color: Color.fromARGB(255, 229, 229, 229),
              shape: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                  )),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null &&
                          imageUrl.isNotEmpty) // Отображение изображения
                        Image.network(imageUrl),
                      Text(
                        messageText ?? "",
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          formattedTime,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 92, 92, 92),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ]),
              ),
            )));
  }
}
