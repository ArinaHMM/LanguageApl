// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:toast/toast.dart';

// class ChooseImagePage extends StatefulWidget {
//   final String id; // Переименован userId в id
//   final String email;
//   final String firstName;
//   final String lastName; // Сохраняем lastName
//   final String birthDate;
//   final String? selectedLanguage; // Новый параметр для выбранного языка

//   const ChooseImagePage({
//     Key? key,
//     required this.id,
//     required this.email,
//     required this.firstName,
//     required this.lastName,
//     required this.birthDate,
//     required this.selectedLanguage,
//   }) : super(key: key);

//   @override
//   _ChooseImagePageState createState() => _ChooseImagePageState();
// }

// class _ChooseImagePageState extends State<ChooseImagePage> {
//   File? _image;
//   final ImagePicker _picker = ImagePicker();
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final UsersCollection usersCollection = UsersCollection();

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
//       // Обновляем URL изображения и язык в Firestore, сохраняя lastName
//       await usersCollection.editUserCollection(
//         widget.id, // Передаем id
//         widget.firstName, // Передаем имя
//         widget.lastName, // Передаем lastName без изменений
//         email: widget.email, // Передаем email
//         image: downloadUrl,
//       );

//       Toast.show("Изображение и язык загружены");
//       Navigator.popAndPushNamed(context, '/profile');
//     } catch (e) {
//       Toast.show("Ошибка загрузки: ${e.toString()}");
//     }
//   }

//   Future<void> _handleSkip() async {
//     // Заглушка для изображения
//     String defaultImageUrl =
//         'https://firebasestorage.googleapis.com/v0/b/languageapl.appspot.com/o/inc.png?alt=media&token=9f670c1f-38b7-426d-8b53-7ce05bf39d98';

//     // Обновляем Firestore с заглушкой, сохраняя lastName
//     await _uploadImage(defaultImageUrl);
//   }

//   Future<void> _handleUpload() async {
//     if (_image == null) {
//       // Если изображение не выбрано, ставим заглушку
//       await _handleSkip();
//       return;
//     }

//     try {
//       String fileName = widget.id; // Используем id пользователя
//       Reference ref = _storage.ref().child("profile_images/$fileName");

//       // Загружаем файл в Firebase Storage
//       await ref.putFile(_image!);
//       String downloadUrl = await ref.getDownloadURL();

//       // Обновляем Firestore с загруженным изображением, сохраняя lastName
//       await _uploadImage(downloadUrl);
//     } catch (e) {
//       Toast.show("Ошибка загрузки: ${e.toString()}");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Выберите изображение")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _image == null
//                 ? const Text("Изображение не выбрано")
//                 : Container(
//                     width: 200, // Установите ширину контейнера
//                     height: 200, // Установите высоту контейнера
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey, width: 1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.file(
//                         _image!,
//                         fit: BoxFit
//                             .cover, // Обрезаем изображение для заполнения контейнера
//                       ),
//                     ),
//                   ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor:
//                     const Color.fromARGB(255, 4, 104, 43), // Цвет кнопки
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               onPressed: _pickImage,
//               child: const Text("Выбрать изображение"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor:
//                     const Color.fromARGB(255, 4, 104, 43), // Цвет кнопки
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               onPressed: _handleUpload,
//               child: const Text("Загрузить изображение"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _handleSkip,
//               child: const Text("Пропустить"),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
