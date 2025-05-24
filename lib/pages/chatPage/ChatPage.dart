// ignore_for_file: unused_element, prefer_typing_uninitialized_variables, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/message_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/chatPage/MessagePage.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid.toString();
  final UsersCollection usersCollection = UsersCollection();
  var snapshots = FirebaseFirestore.instance.collection('chat').snapshots();

  final MessagesService _messagesService = MessagesService();

  Future<void> _deleteChat(String chatId) async {
    await _messagesService.deleteChatAndMessages(chatId);
  }
 Future<bool> _isSupportUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Получаем данные пользователя из Firestore
      final userDoc = await usersCollection.getUser(user.uid);
      return userDoc['roleId'] == '3'; // Предполагаем, что у пользователя есть поле 'role'
    }
    return false; // Если пользователь не найден
  }
  Widget _chatCard(BuildContext context, DocumentSnapshot docs) {
    final String otherUserId = docs['user1id'] == userId ? docs['user2id'] : docs['user1id'];
    final Future<DocumentSnapshot<Map<String,dynamic>>> userFuture = usersCollection.getUser(otherUserId);

    return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
      future: userFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!.data()!;
        final chats = docs.data() as Map<String, dynamic>;
        final userImage = user['image'];
        final userName = user['firstName'];

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => MessagesPage(chat: docs),
            ));
          }, 
          child: Card(
            color: Color.fromARGB(255, 42, 141, 22),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            elevation: 0,
            margin: const EdgeInsets.all(0),
            child: Container(
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Color.fromARGB(255, 26, 100, 11))),
              ),
              height: MediaQuery.of(context).size.height * 0.1,
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  const SizedBox(width: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      userImage,
                      height: MediaQuery.of(context).size.height * 0.09,
                      width: MediaQuery.of(context).size.height * 0.09,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 7),
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.white,
                         
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.72,
                        height: 45,
                        child: Text(
                          chats['messageText'] ?? "Начните общение!",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 215, 215, 215),
                            
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text("Чаты"),
        backgroundColor: Colors.green[700],leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                
                Navigator.popAndPushNamed(context, '/settings'); // Возврат на предыдущую страницу
              },
      ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: 2.5,
            alignment: Alignment.center,
            // child: const Image(
            //   image: AssetImage("images/LightThemeBackground.png"),
            // ),
            child: Container(
              height: 1000,
              width: 1000,
              color: Color.fromARGB(110, 132, 197, 106),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.only(top: 1),
            child: StreamBuilder(
              stream: snapshots,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Произошла ошибка: ${snapshot.error}'),
                  );
                }
                else if(snapshot.hasData){
                  final chatDocs = snapshot.data!.docs.where((element){
                  if(element['user1id'] == userId){
                    return true;
                  }
                  else if(element['user2id'] == userId){
                    return true;
                  }
                  else{
                  return false;
                  }
                  }
                  ).toList();
                  return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              return _chatCard(context, chatDocs[index]);
            });
                }
                else{
                  return const SizedBox();
                }
               }, 
              
              ),
            
          
            )
              ],
        ));
  }
}