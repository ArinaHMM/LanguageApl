// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:toast/toast.dart';

// class ProfilePage1 extends StatefulWidget {
//   const ProfilePage1({Key? key}) : super(key: key);

//   @override
//   _ProfilePage1State createState() => _ProfilePage1State();
// }

// class _ProfilePage1State extends State<ProfilePage1> {
//   int _selectedIndex = 1;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   late User currentUser;
//   late DocumentSnapshot<Map<String, dynamic>> userData;
//   File? _image;
//   final ImagePicker _picker = ImagePicker();
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   @override
//   void initState() {
//     super.initState();
//     currentUser = _auth.currentUser!;
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });

//     switch (index) {
      
//       case 0:
//         Navigator.pushReplacementNamed(context, '/chat1');
//         break;
//       case 1:
//        Navigator.pushReplacementNamed(context, '/prof1');
//         break;
//     }
//   }

//   Future<void> _editProfile(String field, String currentValue) async {
//     TextEditingController controller =
//         TextEditingController(text: currentValue);
//     String? newValue;

//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Изменить $field'),
//           content: TextField(
//             controller: controller,
//             decoration: InputDecoration(hintText: 'Введите новое значение'),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Отмена'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Сохранить'),
//               onPressed: () {
//                 newValue = controller.text;

//                 if (newValue?.isNotEmpty == true) {
//                   _updateUserData(field, newValue!);
//                 }

//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _updateUserData(String field, String newValue) async {
//     if (field == 'firstName') {
//       await UsersCollection().editUserCollection(
//         currentUser.uid,
//         newValue,
//         userData.data()!['lastName'],
//         birthDate: userData.data()!['birthDate'],
//         email: userData.data()!['email'],
//         image: userData.data()!['image'],
//         language: userData.data()!['language'],
//       );
//     } else if (field == 'lastName') {
//       await UsersCollection().editUserCollection(
//         currentUser.uid,
//         userData.data()!['firstName'],
//         newValue,
//         birthDate: userData.data()!['birthDate'],
//         email: userData.data()!['email'],
//         image: userData.data()!['image'],
//         language: userData.data()!['language'],
//       );
//     } else if (field == 'birthDate') {
//       await UsersCollection().editUserCollection(
//         currentUser.uid,
//         userData.data()!['firstName'],
//         userData.data()!['lastName'],
//         birthDate: newValue,
//         email: userData.data()!['email'],
//         image: userData.data()!['image'],
//         language: userData.data()!['language'],
//       );
//     }

//     setState(() {});
//   }

//   Future<void> _changePassword() async {
//     TextEditingController controller = TextEditingController();
//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Сменить пароль'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: controller,
//                 decoration:
//                     const InputDecoration(hintText: 'Введите новый пароль'),
//                 obscureText: true,
//               ),
//               const SizedBox(height: 10),
//               const Text('Вы уверены, что хотите изменить пароль?'),
//             ],
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Отмена'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Изменить'),
//               onPressed: () async {
//                 String newPassword = controller.text;
//                 if (newPassword.isNotEmpty) {
//                   await _auth.currentUser!.updatePassword(newPassword);
//                   Navigator.of(context).pop();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Пароль успешно изменен')),
//                   );
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//     }
//   }

//   Future<void> _uploadImage(String? downloadUrl) async {
//     try {
//       await UsersCollection().editUserCollection(
//         currentUser.uid,
//         userData.data()!['firstName'],
//         userData.data()!['lastName'],
//         birthDate: userData.data()!['birthDate'],
//         email: userData.data()!['email'],
//         image: downloadUrl,
//         language: userData.data()!['language'],
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Ошибка загрузки: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _handleUpload() async {
//     if (_image == null) return;

//     try {
//       String fileName = currentUser.uid;
//       Reference ref = _storage.ref().child("profile_images/$fileName");

//       await ref.putFile(_image!);
//       String downloadUrl = await ref.getDownloadURL();

//       await _uploadImage(downloadUrl);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Ошибка загрузки: ${e.toString()}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//       future: UsersCollection().getUser(currentUser.uid),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (snapshot.hasError) {
//           return Center(child: Text("Ошибка: ${snapshot.error}"));
//         }
//         if (!snapshot.hasData || !snapshot.data!.exists) {
//           return const Center(child: Text("Пользователь не найден"));
//         }

//         userData = snapshot.data!;
//         return Scaffold(
//           appBar: AppBar(
//             title: const Text("Профиль"),
//             leading: IconButton(
//               icon: Icon(Icons.arrow_back),
//               onPressed: () {
//                 Navigator.pushReplacementNamed(
//                     context, '/profile'); // Возврат на предыдущую страницу
//               },
//             ),
//             backgroundColor: Colors.green[700],
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.logout),
//                 onPressed: () async {
//                   await FirebaseAuth.instance.signOut();
//                   Navigator.pushReplacementNamed(context, '/auth');
//                 },
//               ),
//             ],
//           ),
//           body: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: GestureDetector(
//                     onTap: _pickImage,
//                     child: CircleAvatar(
//                       radius: 50,
//                       backgroundImage: _image == null
//                           ? NetworkImage(userData.data()!['image'])
//                           : FileImage(_image!) as ImageProvider,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Spacer(flex: 2),
//                     ElevatedButton(
//                       onPressed: _handleUpload,
//                       style: ElevatedButton.styleFrom(
//                         foregroundColor: Colors.white,
//                         backgroundColor: Colors.green, // Цвет текста
//                       ),
//                       child: const Text('Загрузить новое изображение'),
//                     ),
//                     const Spacer(flex: 1),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 GestureDetector(
//                   onTap: () =>
//                       _editProfile('firstName', userData.data()!['firstName']),
//                   child: Text(
//                     "${userData.data()!['firstName']} ${userData.data()!['lastName']}",
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: () => _editProfile('email', userData.data()!['email']),
//                   child: Text(
//                     userData.data()!['email'],
//                     style: const TextStyle(fontSize: 16, color: Colors.grey),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 const Divider(height: 40),
//                 GestureDetector(
//                   onTap: () =>
//                       _editProfile('birthDate', userData.data()!['birthDate']),
//                   child: _buildUserInfoTile(Icons.calendar_today,
//                       'Дата рождения', userData.data()!['birthDate']),
//                 ),
//                 GestureDetector(
//                   onTap: () =>
//                       _editProfile('lastName', userData.data()!['lastName']),
//                   child: _buildUserInfoTile(
//                       Icons.person, 'Фамилия', userData.data()!['lastName']),
//                 ),
//                 _buildUserInfoTile(Icons.bookmark_added_outlined,
//                     'Уровень владения', userData.data()!['language']),
//                 const SizedBox(height: 20),
//                 Center(
//                   child: ElevatedButton(
//                     onPressed: _changePassword,
//                     style: ElevatedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       backgroundColor: Colors.green,
//                     ),
//                     child: const Text('Сменить пароль'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           bottomNavigationBar: _buildBottomNavigationBar(),
//         );
//       },
//     );
//   }

//   ListTile _buildUserInfoTile(IconData icon, String title, String subtitle) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.green),
//       title: Text(title, style: const TextStyle(color: Colors.green)),
//       subtitle: Text(subtitle, style: const TextStyle(color: Colors.black87)),
//       tileColor: Colors.green[50],
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       contentPadding: const EdgeInsets.all(10),
//     );
//   }

//   BottomNavigationBar _buildBottomNavigationBar() {
//     return BottomNavigationBar(
//       items: const <BottomNavigationBarItem>[
//         BottomNavigationBarItem(
//           icon: Icon(Icons.message),
//           label: 'Чат',
//         ),
//                BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Профиль',
//         ),
//       ],
//       currentIndex: _selectedIndex,
//       selectedItemColor: Colors.green[700],
//       onTap: _onItemTapped,
//     );
//   }
// }
