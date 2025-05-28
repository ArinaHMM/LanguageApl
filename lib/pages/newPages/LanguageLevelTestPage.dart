// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_languageapplicationmycourse_2/pages/newPages/ChoiseImagePage.dart';

// class LanguageLevelTestPage extends StatefulWidget {
//   final String userId;
//   final String email;
//   final String firstName;
//   final String lastName;
//   final String birthDate;

//   const LanguageLevelTestPage({
//     Key? key,
//     required this.userId,
//     required this.email,
//     required this.firstName,
//     required this.lastName,
//     required this.birthDate,
//   }) : super(key: key);

//   @override
//   _LanguageLevelTestPageState createState() => _LanguageLevelTestPageState();
// }

// class _LanguageLevelTestPageState extends State<LanguageLevelTestPage> {
//   final List<String> questions = [
//     "Насколько хорошо вы знаете английский?",
//     "Как часто вы говорите на английском?",
//     "Какой уровень вам кажется подходящим?",
//   ];

//   final List<String> answers = [
//     "Я новичок.", // Beginner
//     "Знаю основы.", // Elementary
//     "Могу поддержать простой разговор.", // Intermediate
//     "Могу поддержать сложный диалог.", // Upper Intermediate
//     "Могу подробно обсуждать темы.", // Advanced
//   ];
// final List<String> reasons = [
//     "Путешествия",
//     "Общение с друзьями",
//     "Работа",
//     "Учеба",
//     "Другие причины"
//   ];
//   final List<String> levels = [
//     "Beginner",
//     "Elementary",
//     "Intermediate",
//     "Upper Intermediate",
//     "Advanced"
//   ];

//   int selectedAnswerIndex = -1;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Проверка уровня языка")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(questions[0]),
//             ...List.generate(answers.length, (index) {
//               return RadioListTile(
//                 title: Text(answers[index]),
//                 value: index,
//                 groupValue: selectedAnswerIndex,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedAnswerIndex = value!;
//                   });
//                 },
//               );
//             }),
//             const SizedBox(height: 20),
//             ElevatedButton(
//                style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         const Color.fromARGB(255, 4, 104, 43), // Цвет кнопки
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//               onPressed: () {
//                 if (selectedAnswerIndex != -1) {
//                   // Update user's language level in Firestore
//                   _updateUserLanguageLevel(levels[selectedAnswerIndex]);

//                   // Navigate to the image selection page, passing user data
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ChooseImagePage(
//                         id: widget.userId,
//                         email: widget.email,
//                         firstName: widget.firstName,
//                         lastName: widget.lastName,
//                         birthDate: widget.birthDate,
//                         selectedLanguage: levels[selectedAnswerIndex],
//                       ),
//                     ),
//                   );
//                 }
//               },
//               child: const Text("Продолжить"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _updateUserLanguageLevel(String language) async {
//     final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

//     try {
//       // Update the user's language level in Firestore
//       await _firebaseFirestore.collection("users").doc(widget.userId).update({
//         'language': language,
//       });
//     } catch (e) {
//       print("Ошибка при обновлении уровня языка: $e");
//     }
//   }
// }
