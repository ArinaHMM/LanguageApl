// lib/support_panel/pages/support_chat_page.dart
import 'dart:io'; // Для File, если будете использовать image_picker на мобильных
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Для UserCredential (если нужно)
import 'package:firebase_storage/firebase_storage.dart'; // Для загрузки изображений
import 'package:flutter_languageapplicationmycourse_2/admin_panel/auth/admin_auth_service.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/routing/app_router.dart'; // Для SupportRoutes
import 'package:image_picker/image_picker.dart'; // Для выбора изображений
import 'package:intl/intl.dart'; // Для форматирования времени

// Модель сообщения (можно вынести в отдельный файл models/message_model.dart)
class Message {
  final String id;
  final String senderId;
  final String? text; // Текст может быть null, если это изображение
  final String? imageUrl; // URL изображения может быть null
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
    if (data == null) {
      // Обработка случая, когда данные отсутствуют, чтобы избежать ошибки
      // Можно выбросить исключение или вернуть "пустое" сообщение
      throw StateError('Missing data for message ${doc.id}');
    }
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

class SupportChatPage extends StatefulWidget {
  final String userId; // UID клиента пользователя
  final String? userEmail; // Email клиента (для отображения)

  const SupportChatPage({Key? key, required this.userId, this.userEmail}) : super(key: key);

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminAuthService _authService = AdminAuthService(); // Или ваш SupportAuthService
  final UsersCollection _usersCollection = UsersCollection(); // Для получения имени пользователя
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String? _supportAgentId;
  String _headerTitle = "Чат";
  bool _isSending = false; // Для блокировки кнопки отправки во время отправки

  @override
  void initState() {
    super.initState();
    _supportAgentId = _authService.currentUser?.uid;
    
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      _headerTitle = "Чат с ${widget.userEmail}";
    } else {
      // Если email не передан, пытаемся загрузить имя пользователя
      _fetchUserNameForHeader();
    }
    
    _markMessagesAsRead();

    // Слушатель для автоматической прокрутки при появлении новых сообщений
    _getMessagesStream().listen((snapshot) {
      if (mounted && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.position.maxScrollExtent > 0) { // Прокручиваем только если есть что скроллить
             _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _fetchUserNameForHeader() async {
    try {
      DocumentSnapshot<Map<String,dynamic>>? userDoc = await _usersCollection.getUser(widget.userId);
      if (mounted && userDoc != null && userDoc.exists) {
        final data = userDoc.data();
        final firstName = data?['firstName'] as String?;
        final lastName = data?['lastName'] as String?;
        if (firstName != null && firstName.isNotEmpty) {
          setState(() {
            _headerTitle = "Чат с $firstName ${lastName ?? ''}".trim();
          });
        } else {
           setState(() {
            _headerTitle = "Чат с ${widget.userId.substring(0,6)}..."; // Показываем часть UID, если имени нет
          });
        }
      } else {
         if (mounted) setState(() => _headerTitle = "Чат с клиентом");
      }
    } catch (e) {
      print("Error fetching user name for chat header: $e");
      if (mounted) setState(() => _headerTitle = "Чат с клиентом");
    }
  }


  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    if (widget.userId.isEmpty) return;
    try {
      // Обновляем только если есть непрочитанные сообщения от пользователя
      final chatDocRef = _firestore.collection('support_chats').doc(widget.userId);
      final chatDoc = await chatDocRef.get();
      if (chatDoc.exists && (chatDoc.data()?['unreadCountBySupport'] ?? 0) > 0) {
        await chatDocRef.update({
          'isReadBySupport': true,
          'unreadCountBySupport': 0,
          'lastReadBySupportTimestamp': FieldValue.serverTimestamp(),
        });
        print("Messages marked as read by support for chat with ${widget.userId}");
      }
    } catch (e) {
      print("Error marking messages as read by support for ${widget.userId}: $e");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getMessagesStream() {
    if (widget.userId.isEmpty) return Stream.empty();
    return _firestore
        .collection('support_chats')
        .doc(widget.userId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Старые вверху, новые внизу
        .snapshots();
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    if (_isSending) return; // Предотвращаем двойную отправку
    final text = _messageController.text.trim();
    if ((text.isEmpty && imageUrl == null) || _supportAgentId == null) {
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();

    final messageData = {
      'senderId': _supportAgentId,
      'text': text.isNotEmpty ? text : null,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isReadByUser': false, // Новое сообщение не прочитано пользователем
    };

    try {
      final chatDocRef = _firestore.collection('support_chats').doc(widget.userId);
      
      await chatDocRef.collection('messages').add(messageData);

      await chatDocRef.set({ // Используем set с merge:true для создания документа чата, если его нет
        'lastMessageText': imageUrl != null ? "[Изображение]" : text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': _supportAgentId,
        'user_id': widget.userId,
        if (widget.userEmail != null && widget.userEmail!.isNotEmpty) 'userEmail': widget.userEmail,
        'isReadBySupport': true, // Сообщение от поддержки, оно прочитано поддержкой
        'isReadByUser': false,
        'unreadCountByUser': FieldValue.increment(1),
        'unreadCountBySupport': 0, // Сбрасываем, т.к. поддержка только что ответила
      }, SetOptions(merge: true));

    } catch (e) {
      print("Error sending message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки сообщения: $e'), backgroundColor: Colors.red),
        );
        _messageController.text = text; // Возвращаем текст в поле, если отправка не удалась
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  Future<void> _pickAndSendImage() async {
    if (_isSending) return;
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      setState(() => _isSending = true);
      File imageFile = File(pickedFile.path);
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_supportAgentId}_${Uri.file(pickedFile.path).pathSegments.last}';
      Reference storageRef = FirebaseStorage.instance.ref().child('support_chat_images/${widget.userId}/$fileName');
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Загрузка изображения..."), duration: Duration(seconds: 2),));

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(imageUrl: downloadUrl);

    } catch (e) {
      print("Error picking/uploading image: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка загрузки изображения: $e"), backgroundColor: Colors.red,));
    } finally {
       if (mounted) setState(() => _isSending = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8.0, // Отступ для статус-бара
            left: 8.0, right: 16.0, bottom: 12.0
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, // Цвет фона как у Scaffold
            boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 1))]
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueGrey.shade700, size: 22),
                tooltip: "Назад к списку чатов",
                onPressed: () => context.go(SupportRoutes.dashboard),
              ),
              Expanded(
                child: Text(
                  _headerTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Можно добавить иконку информации о пользователе здесь
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getMessagesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка загрузки сообщений: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Нет сообщений в этом чате.\nНапишите первое сообщение!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                  )
                );
              }

              final messagesDocs = snapshot.data!.docs;
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                itemCount: messagesDocs.length,
                itemBuilder: (context, index) {
                  Message message;
                  try {
                    message = Message.fromFirestore(messagesDocs[index]);
                  } catch (e) {
                    print("Error parsing message doc ${messagesDocs[index].id}: $e");
                    return const SizedBox.shrink(); // Пропускаем сообщение с ошибкой
                  }
                  
                  final bool isMyMessage = message.senderId == _supportAgentId;
                  return _buildMessageBubble(message, isMyMessage);
                },
              );
            },
          ),
        ),
        _buildMessageComposer(),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    DateTime messageTime = message.timestamp.toDate();
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blueGrey.shade700 : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18.0),
            topRight: const Radius.circular(18.0),
            bottomLeft: isMyMessage ? const Radius.circular(18.0) : const Radius.circular(4.0),
            bottomRight: isMyMessage ? const Radius.circular(4.0) : const Radius.circular(18.0),
          ),
           boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(1,2)
            )
           ]
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: (message.text != null && message.text!.isNotEmpty) ? 8.0 : 0.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    message.imageUrl!,
                    // Ограничиваем высоту изображения в чате
                    height: MediaQuery.of(context).size.height * 0.25,
                    width: MediaQuery.of(context).size.width * 0.65,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.25,
                        width: MediaQuery.of(context).size.width * 0.65,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2,))
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        height: 80, width: 80, 
                        color: Colors.grey.shade200, 
                        child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey.shade500)
                      ),
                  ),
                ),
              ),
            if(message.text != null && message.text!.isNotEmpty)
              Text(
                message.text!,
                style: TextStyle(color: isMyMessage ? Colors.white : Colors.black87, fontSize: 15.5),
              ),
            const SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(messageTime), // Используем intl для форматирования
              style: TextStyle(
                color: isMyMessage ? Colors.white.withOpacity(0.8) : Colors.black54.withOpacity(0.8),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [ BoxShadow(offset: const Offset(0, -1), blurRadius: 3, color: Colors.black.withOpacity(0.06))],
      ),
      child: SafeArea( // Добавляем SafeArea для нижнего отступа на некоторых устройствах
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.add_photo_alternate_outlined, color: Colors.blueGrey.shade600),
              tooltip: "Прикрепить изображение",
              onPressed: _pickAndSendImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration.collapsed(
                  hintText: 'Написать сообщение...',
                  hintStyle: TextStyle(color: Colors.grey.shade500)
                ),
                minLines: 1,
                maxLines: 5,
                onSubmitted: _isSending ? null : (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: Colors.blueGrey.shade700),
              tooltip: "Отправить",
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}