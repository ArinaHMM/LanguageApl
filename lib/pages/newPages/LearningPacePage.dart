// import 'package:flutter/material.dart';
// import 'package:flutter_languageapplicationmycourse_2/pages/newPages/ActionSelectionPage.dart';

// class LearningPacePage extends StatefulWidget {
//   final String userId;

//   const LearningPacePage({Key? key, required this.userId}) : super(key: key);

//   @override
//   _LearningPacePageState createState() => _LearningPacePageState();
// }

// class _LearningPacePageState extends State<LearningPacePage> {
//   final List<String> paceOptions = [
//     "5 минут в день",
//     "10 минут в день",
//     "20 минут в день",
//     "30 минут в день"
//   ];

//   int? selectedPaceIndex;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Темп обучения")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             const Text("Какой темп обучения вам подходит?"),
//             ...List.generate(paceOptions.length, (index) {
//               return RadioListTile(
//                 title: Text(paceOptions[index]),
//                 value: index,
//                 groupValue: selectedPaceIndex,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedPaceIndex = value;
//                   });
//                 },
//               );
//             }),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 if (selectedPaceIndex != null) {
//                   // Переход на следующую страницу
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ActionSelectionPage(userId: widget.userId),
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
