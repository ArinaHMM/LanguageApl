import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_languageapplicationmycourse_2/panels/admin_panel/routing/app_router.dart';

class ChatSummary {
  final String userId;
  final String userDisplayInfo;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final bool isReadBySupport;
  final int unreadBySupportCount;

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
  int _selectedIndex = 0;
  bool isNavigationRailExtended = false;

  final Color unreadColor = Colors.pinkAccent.shade200;
  final Color readColor = Colors.blueGrey.shade300;
  final Color titleColor = Colors.blueGrey.shade900;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    isNavigationRailExtended = screenWidth > 950;
    return Scaffold(
      body: Row(
        children: [
          // Навигационная панель - исправленная версия
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: isNavigationRailExtended 
                ? NavigationRailLabelType.none // Всегда none в расширенном режиме
                : NavigationRailLabelType.none,
            extended: isNavigationRailExtended,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: Text('Чаты'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Пользователи'),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
            ],
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildChatsContent();
      case 1:
        return _buildUsersContent();
      default:
        return _buildChatsContent();
    }
  }

  Widget _buildChatsContent() {
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
                return Center(
                  child: Text('Ошибка загрузки: ${snapshot.error}',
                      style: TextStyle(color: Colors.red.shade700)),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              return _buildChatList(snapshot.data!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersContent() {
    return const Center(child: Text('Список пользователей'));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 72, color: Colors.grey.shade400),
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

  Widget _buildChatList(List<ChatSummary> chats) {
    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 0.5, indent: 72, endIndent: 16, thickness: 0.5),
      itemBuilder: (context, index) {
        final chat = chats[index];
        final hasUnread = chat.unreadBySupportCount > 0;

        return Material(
          color: hasUnread ? unreadColor.withOpacity(0.08) : Colors.transparent,
          child: InkWell(
            onTap: () => _openChat(chat),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  _buildAvatar(chat),
                  const SizedBox(width: 16),
                  _buildChatInfo(chat),
                  const SizedBox(width: 10),
                  _buildTimestamp(chat),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(ChatSummary chat) {
    final hasUnread = chat.unreadBySupportCount > 0;

    return CircleAvatar(
      radius: 26,
      backgroundColor: hasUnread ? unreadColor : readColor,
      child: hasUnread
          ? Text(
              chat.unreadBySupportCount.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            )
          : Icon(Icons.person_outline_rounded,
              color: Colors.white.withOpacity(0.9), size: 28),
    );
  }

  Widget _buildChatInfo(ChatSummary chat) {
    final hasUnread = chat.unreadBySupportCount > 0;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat.userDisplayInfo,
            style: TextStyle(
                fontSize: 16,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                color: hasUnread ? unreadColor : titleColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            chat.lastMessage,
            style: TextStyle(
                fontSize: 14,
                color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(ChatSummary chat) {
    final hasUnread = chat.unreadBySupportCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatTimestamp(chat.lastMessageTimestamp),
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        ),
        if (hasUnread) ...[
          const SizedBox(height: 4),
          Icon(Icons.circle, color: unreadColor, size: 10)
        ]
      ],
    );
  }

  void _openChat(ChatSummary chat) {
    context.go(
      SupportRoutes.chatWithUser(chat.userId),
      extra: {'userEmail': chat.userDisplayInfo},
    );
  }

  Stream<List<ChatSummary>> _getChatSummariesStream() {
    return _firestore
        .collection('support_chats')
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = <ChatSummary>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['user_id'] ?? doc.id;
        final userInfo = await _getUserDisplayInfo(userId, data);

        chats.add(ChatSummary(
          userId: userId,
          userDisplayInfo: userInfo,
          lastMessage: data['lastMessageText'] ?? 'Нет сообщений',
          lastMessageTimestamp: data['lastMessageTimestamp'] ??
              Timestamp.fromMillisecondsSinceEpoch(0),
          isReadBySupport: data['isReadBySupport'] ?? true,
          unreadBySupportCount: data['unreadCountBySupport'] ?? 0,
        ));
      }

      return chats..sort(_sortChats);
    });
  }

  Future<String> _getUserDisplayInfo(
      String userId, Map<String, dynamic> data) async {
    String userInfo = data['userEmail'] ?? data['userDisplayName'] ?? userId;

    if (userInfo == userId) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userInfo = userData['email'] ??
              (userData['firstName'] != null
                  ? '${userData['firstName']} ${userData['lastName']}'.trim()
                  : userId);
        }
      } catch (e) {
        print("Error fetching user info: $e");
      }
    }

    return userInfo;
  }

  int _sortChats(ChatSummary a, ChatSummary b) {
    if (a.unreadBySupportCount > 0 && b.unreadBySupportCount == 0) return -1;
    if (a.unreadBySupportCount == 0 && b.unreadBySupportCount > 0) return 1;
    return b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp);
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return "Вчера";
    } else {
      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)}";
    }
  }
}
