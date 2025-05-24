// import 'package:flutter/material.dart';
// import 'package:flutter_languageapplicationmycourse_2/pages/ProfilePage.dart';
// import 'package:flutter_languageapplicationmycourse_2/pages/newPages/LearningPacePage.dart';

// class LanguageReasonsPage extends StatefulWidget {
//   final String userId;
//   final String email;
//   final String firstName;
//   final String lastName;
//   final String birthDate;
//   const LanguageReasonsPage({
//     Key? key,
//     required this.userId,
//     required this.email,
//     required this.firstName,
//     required this.lastName,
//     required this.birthDate,
//   }) : super(key: key);
//   @override
//   _LanguageReasonsPageState createState() => _LanguageReasonsPageState();
// }


// class _LanguageReasonsPageState extends State<LanguageReasonsPage> {
//   final List<String> reasons = [
//     "Путешествия",
//     "Общение с друзьями",
//     "Работа",
//     "Учеба",
//     "Другие причины"
//   ];

//   int? selectedReasonIndex;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Причины изучения языка")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             const Text("Почему вы хотите изучать язык?"),
//             ...List.generate(reasons.length, (index) {
//               return RadioListTile(
//                 title: Text(reasons[index]),
//                 value: index,
//                 groupValue: selectedReasonIndex,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedReasonIndex = value;
//                   });
//                 },
//               );
//             }),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 if (selectedReasonIndex != null) {
//                   // Переход на следующую страницу
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ProfilePage(),
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
// }
