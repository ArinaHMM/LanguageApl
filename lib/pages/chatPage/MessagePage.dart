// lib/pages/chatPage/MessagePage.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';

// Модель сообщения (можно вынести, если еще не вынесена)
class Message {
  final String id;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Missing data for message ${doc.id}');
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

class MessagesPage extends StatefulWidget {
  final String chatId; // ID чата (например, user1UID_user2UID)
  final String?
      initialOtherUserName; // Имя собеседника для отображения в AppBar

  const MessagesPage({
    Key? key,
    required this.chatId,
    this.initialOtherUserName,
  }) : super(key: key);

  @override
  State<MessagesPage> createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UsersCollection _usersCollection = UsersCollection();
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Для получения текущего пользователя

  String? currentUserUID;
  String? otherUserId; // UID другого пользователя в этом чате
  String _appBarTitle = "Чат"; // Заголовок AppBar

  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    currentUserUID = _auth.currentUser?.uid;

    if (currentUserUID == null) {
      print("FATAL: currentUserUID is null in MessagesPage initState.");
      // Обработка ошибки, возможно, возврат на предыдущий экран
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
      return;
    }

    if (widget.initialOtherUserName != null &&
        widget.initialOtherUserName!.isNotEmpty) {
      _appBarTitle = widget.initialOtherUserName!;
    }
    _determineOtherUserIdAndLoadName();
    _markMessagesAsReadByCurrentUser(); // Если это чат поддержки, то помечаем как прочитанное поддержкой
  }

  Future<void> _determineOtherUserIdAndLoadName() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> chatDoc =
          await _firestore.collection('support_chats').doc(widget.chatId).get();

      if (chatDoc.exists && chatDoc.data() != null) {
        final data = chatDoc.data()!;
        String? user1 = data['user1id'] as String?;
        String? user2 = data['user2id'] as String?;

        if (user1 != null && user2 != null) {
          otherUserId = (user1 == currentUserUID) ? user2 : user1;
          if (widget.initialOtherUserName == null ||
              widget.initialOtherUserName!.isEmpty) {
            // Если имя не было передано, загружаем его
            DocumentSnapshot<Map<String, dynamic>>? otherUserDoc =
                await _usersCollection.getUser(otherUserId!);
            if (mounted && otherUserDoc != null && otherUserDoc.exists) {
              final otherUserData = otherUserDoc.data();
              setState(() {
                _appBarTitle = otherUserData?['firstName'] as String? ??
                    otherUserData?['email'] as String? ??
                    'Собеседник';
              });
            } else if (mounted) {
              setState(() => _appBarTitle = 'Собеседник');
            }
          }
        } else {
          print(
              "Error: user1id or user2id missing in chat doc ${widget.chatId}");
          if (mounted) setState(() => _appBarTitle = "Ошибка чата");
        }
      } else {
        print("Error: Chat document ${widget.chatId} does not exist.");
        if (mounted) setState(() => _appBarTitle = "Чат не найден");
      }
    } catch (e) {
      print("Error determining other user ID: $e");
      if (mounted) setState(() => _appBarTitle = "Ошибка загрузки");
    }
  }

  Future<void> _markMessagesAsReadByCurrentUser() async {
    if (currentUserUID == null || widget.chatId.isEmpty) return;
    // Этот метод нужно адаптировать в зависимости от того, кто текущий пользователь (клиент или поддержка)
    // и какое поле обновлять (isReadByUser или isReadBySupport)
    // Предположим, этот MessagesPage используется и клиентом, и поддержкой.
    // Если текущий пользователь - поддержка, обновляем isReadBySupport.
    // Если текущий пользователь - клиент, обновляем isReadByUser.

    // Сначала получим роль текущего пользователя
    UserModel? currentUserModel =
        await _usersCollection.getUserModel(currentUserUID!);
    bool isSupportAgent = currentUserModel?.role == UserRoles.support ||
        currentUserModel?.role == UserRoles.admin;

    Map<String, dynamic> updateData = {};
    if (isSupportAgent) {
      updateData['isReadBySupport'] = true;
      updateData['unreadCountBySupport'] = 0;
    } else {
      // Это обычный пользователь (клиент)
      updateData['isReadByUser'] = true;
      updateData['unreadCountByUser'] = 0;
    }

    try {
      final chatDocRef =
          _firestore.collection('support_chats').doc(widget.chatId);
      final chatDoc = await chatDocRef.get();
      if (chatDoc.exists) {
        // Обновляем только если есть что обновлять (например, были непрочитанные)
        bool needsUpdate = false;
        if (isSupportAgent &&
            (chatDoc.data()?['unreadCountBySupport'] ?? 0) > 0)
          needsUpdate = true;
        if (!isSupportAgent && (chatDoc.data()?['unreadCountByUser'] ?? 0) > 0)
          needsUpdate = true;

        if (needsUpdate) {
          await chatDocRef.update(updateData);
          print(
              "Messages in chat ${widget.chatId} marked as read by $currentUserUID");
        }
      }
    } catch (e) {
      print("Error marking messages as read in chat ${widget.chatId}: $e");
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage({String? imageUrl}) async {
    if (_isSending) return;
    final text = messageController.text.trim();
    if ((text.isEmpty && imageUrl == null) ||
        currentUserUID == null ||
        widget.chatId.isEmpty) {
      return;
    }
    setState(() => _isSending = true);
    messageController.clear();

    final messageData = {
      'senderId': currentUserUID,
      'text': text.isNotEmpty ? text : null,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      // Эти поля лучше обновлять в основном документе чата
      // 'isReadByUser': false, // Если отправитель - поддержка
      // 'isReadBySupport': false, // Если отправитель - пользователь
    };

    try {
      final chatDocRef =
          _firestore.collection('support_chats').doc(widget.chatId);
      await chatDocRef.collection('messages').add(messageData);

      // Обновляем информацию о последнем сообщении в основном документе чата
      UserModel? currentUserModel =
          await _usersCollection.getUserModel(currentUserUID!);
      bool sentBySupport = currentUserModel?.role == UserRoles.support ||
          currentUserModel?.role == UserRoles.admin;

      await chatDocRef.set({
        // Используем set с merge:true
        'lastMessageText': imageUrl != null ? "[Изображение]" : text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserUID,
        // Поля isRead и unreadCount обновляются для ПОЛУЧАТЕЛЯ
        if (sentBySupport) ...{
          'isReadByUser': false,
          'unreadCountByUser': FieldValue.increment(1),
          'isReadBySupport':
              true, // Сообщение от поддержки, оно прочитано поддержкой
          'unreadCountBySupport': 0, // Сбрасываем
        } else ...{
          // Отправлено пользователем
          'isReadBySupport': false,
          'unreadCountBySupport': FieldValue.increment(1),
          'isReadByUser': true, // Сообщение от пользователя, оно прочитано им
          'unreadCountByUser': 0, // Сбрасываем
        },
        // Убедимся, что user1id и user2id не перезаписываются, если они уже есть
        // Это лучше делать при создании чата в getOrCreateChatWithSupport
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error sending message: $e");
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка отправки: $e")));
      messageController.text =
          text; // Возвращаем текст, если не удалось отправить
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages() {
    if (widget.chatId.isEmpty) return Stream.empty();
    return _firestore
        .collection('support_chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Старые вверху, новые внизу
        .snapshots();
  }

  Future<void> pickAndUploadImage() async {
    if (_isSending) return;
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 65, maxWidth: 1200);
    if (pickedFile == null) return;

    setState(() => _isSending = true);
    File imageFile = File(pickedFile.path);
    String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${currentUserUID}_${Uri.file(pickedFile.path).pathSegments.last}';
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_images/${widget.chatId}/$fileName');

    try {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Загрузка изображения..."),
            duration: Duration(seconds: 2)));
      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();
      await sendMessage(imageUrl: downloadUrl);
    } catch (e) {
      print("Error uploading image: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Ошибка загрузки изображения: $e"),
            backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserUID == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Ошибка")),
          body: const Center(child: Text("Ошибка аутентификации.")));
    }

    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _appBarTitle,
            style: const TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 138, 42),
          elevation: 1,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: getAllMessages(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(child: Text('Ошибка: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(child: Text('Нет сообщений.'));

                  List<DocumentSnapshot<Map<String, dynamic>>> documents =
                      snapshot.data!.docs;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients &&
                        _scrollController.position.maxScrollExtent > 0) {
                      _scrollController
                          .jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 8.0),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      Message message;
                      try {
                        message = Message.fromFirestore(documents[index]);
                      } catch (e) {
                        print(
                            "Error parsing message from Firestore: ${documents[index].id}, error: $e");
                        return const SizedBox.shrink();
                      }

                      bool isMyMessage = message.senderId == currentUserUID;
                      return _buildMessageBubble(message, isMyMessage);
                    },
                  );
                },
              ),
            ),
            _buildMessageComposer(),
          ],
        ));
  }

  Widget _buildMessageComposer() {
    // ... (как было, но используем _isSending для блокировки)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              offset: const Offset(0, -1),
              blurRadius: 3,
              color: Colors.black.withOpacity(0.06))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.add_photo_alternate_outlined,
                  color: Colors.blueGrey.shade600), // Цвет изменен
              tooltip: "Прикрепить изображение",
              onPressed: _isSending ? null : pickAndUploadImage,
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration.collapsed(
                    hintText: 'Написать сообщение...',
                    hintStyle: TextStyle(color: Colors.grey.shade500)),
                minLines: 1,
                maxLines: 5,
                onSubmitted: _isSending ? null : (_) => sendMessage(),
                enabled: !_isSending, // Блокируем поле ввода во время отправки
              ),
            ),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ))
                  : Icon(Icons.send_rounded,
                      color: Colors.blueGrey.shade700), // Цвет изменен
              tooltip: "Отправить",
              onPressed: _isSending ? null : () => sendMessage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    // ... (как было, но с DateFormat для времени)
    DateTime messageTime = message.timestamp.toDate();
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
            color: isMyMessage
                ? const Color.fromARGB(255, 235, 116, 5)
                : const Color.fromARGB(255, 229, 229, 229),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18.0),
              topRight: const Radius.circular(18.0),
              bottomLeft: isMyMessage
                  ? const Radius.circular(18.0)
                  : const Radius.circular(4.0),
              bottomRight: isMyMessage
                  ? const Radius.circular(4.0)
                  : const Radius.circular(18.0),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(1, 2))
            ]),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment:
              isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    bottom: (message.text != null && message.text!.isNotEmpty)
                        ? 8.0
                        : 0.0),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12), // Скругление для картинки
                  child: Image.network(
                    message.imageUrl!,
                    height: MediaQuery.of(context).size.height *
                        0.28, // Чуть больше
                    width:
                        MediaQuery.of(context).size.width * 0.7, // Чуть больше
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                          height: MediaQuery.of(context).size.height * 0.28,
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: const Center(
                              child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          )));
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.broken_image_outlined,
                            size: 50, color: Colors.grey.shade500)),
                  ),
                ),
              ),
            if (message.text != null && message.text!.isNotEmpty)
              Text(
                message.text!,
                style: TextStyle(
                    color: isMyMessage ? Colors.white : Colors.black87,
                    fontSize: 15.5),
              ),
            const SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(messageTime),
              style: TextStyle(
                color: isMyMessage
                    ? Colors.white.withOpacity(0.85)
                    : Colors.black54.withOpacity(0.85),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
