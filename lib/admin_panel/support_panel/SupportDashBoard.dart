// lib/support_panel/pages/support_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
// Предполагается, что SupportRoutes определены в app_router.dart или support_layout.dart
import 'package:flutter_languageapplicationmycourse_2/admin_panel/routing/app_router.dart'; 
// Если UserModel нужен для получения более детальной информации о пользователе,
// но для ChatSummary мы можем использовать денормализованные данные.
// import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';

// Модель для представления сводки чата в списке
class ChatSummary {
  final String userId; // UID пользователя, с которым чат
  final String userDisplayInfo; // Email или имя пользователя
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final bool isReadBySupport; // Прочитано ли последнее сообщение поддержкой
  final int unreadBySupportCount; // Количество непрочитанных поддержкой сообщений в этом чате

  ChatSummary({
    required this.userId,
    required this.userDisplayInfo,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.isReadBySupport,
    required this.unreadBySupportCount,
  });
}

class SupportDashboardPage extends StatefulWidget {
  const SupportDashboardPage({Key? key}) : super(key: key);

  @override
  State<SupportDashboardPage> createState() => _SupportDashboardPageState();
}

class _SupportDashboardPageState extends State<SupportDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Цвета и стили ---
  final Color unreadColor = Colors.pinkAccent.shade200;
  final Color readColor = Colors.blueGrey.shade300;
  final Color titleColor = Colors.blueGrey.shade900;
  // ---------------------

  Stream<List<ChatSummary>> _getChatSummariesStream() {
    // Этот стрим слушает коллекцию 'support_chats'.
    // Предполагается, что в каждом документе чата есть денормализованные поля,
    // такие как 'userEmail', 'lastMessageText', 'lastMessageTimestamp',
    // 'isReadBySupport' и 'unreadCountBySupport'.
    return _firestore
        .collection('support_chats')
        .orderBy('lastMessageTimestamp', descending: true) // Сначала самые свежие
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<ChatSummary> summaries = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        String userId = data['user_id'] ?? doc.id; // ID пользователя из документа чата
        
        // Получаем отображаемое имя/email пользователя.
        // Если 'userDisplayInfo' денормализовано в документе чата, используем его.
        // Иначе, можно загрузить из коллекции 'users', но это доп. запрос.
        String userDisplayInfo = data['userEmail'] ?? data['userDisplayName'] ?? userId;
        
        if (userDisplayInfo == userId) {
          try {
            DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              userDisplayInfo = userData['email'] ?? (userData['firstName'] != null ? '${userData['firstName']} ${userData['lastName']}'.trim() : userId);
            }
          } catch (e) {
            print("Error fetching user info for chat with $userId: $e");
          }
        }

        summaries.add(ChatSummary(
          userId: userId,
          userDisplayInfo: userDisplayInfo,
          lastMessage: data['lastMessageText'] ?? 'Нет сообщений',
          lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.fromMillisecondsSinceEpoch(0), // Фоллбэк
          isReadBySupport: data['isReadBySupport'] ?? true, // Если поля нет, считаем прочитанным
          unreadBySupportCount: data['unreadCountBySupport'] ?? 0,
        ));
      }
      // Можно дополнительно отсортировать, например, непрочитанные вверху
      summaries.sort((a,b) {
        if (a.unreadBySupportCount > 0 && b.unreadBySupportCount == 0) return -1;
        if (a.unreadBySupportCount == 0 && b.unreadBySupportCount > 0) return 1;
        return b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp); // Затем по времени
      });
      return summaries;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Эта страница будет встроена в SupportLayout, поэтому свой Scaffold не нужен.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
          child: Text(
            "Активные чаты",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatSummary>>(
            stream: _getChatSummariesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Error in StreamBuilder: ${snapshot.error}");
                return Center(
                    child: Text('Ошибка загрузки списка чатов: ${snapshot.error}',
                        style: TextStyle(color: Colors.red.shade700)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 72, color: Colors.grey.shade400),
                        const SizedBox(height: 20),
                        Text(
                          'Нет активных чатов с пользователями.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final chatSummaries = snapshot.data!;

              return ListView.separated(
                itemCount: chatSummaries.length,
                separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 72, endIndent: 16, thickness: 0.5),
                itemBuilder: (context, index) {
                  final summary = chatSummaries[index];
                  bool hasUnread = summary.unreadBySupportCount > 0;

                  return Material( // Для InkWell эффекта
                    color: hasUnread ? unreadColor.withOpacity(0.08) : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Передаем email пользователя, если он есть, для отображения в заголовке чата
                        context.go(
                          SupportRoutes.chatWithUser(summary.userId),
                          extra: {'userEmail': summary.userDisplayInfo}
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: hasUnread ? unreadColor : readColor,
                              child: hasUnread
                                  ? Text(
                                      summary.unreadBySupportCount.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : Icon(Icons.person_outline_rounded, color: Colors.white.withOpacity(0.9), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    summary.userDisplayInfo,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                                        color: hasUnread ? unreadColor : titleColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    summary.lastMessage,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  // Простое форматирование времени
                                  _formatTimestamp(summary.lastMessageTimestamp),
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(height: 4),
                                  Icon(Icons.circle, color: unreadColor, size: 10)
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"; // Сегодня: HH:MM
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return "Вчера";
    } else {
      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)}"; // ДД.ММ.ГГ
    }
  }
}