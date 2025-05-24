// import 'package:flutter/material.dart';

// class TranslatePage extends StatefulWidget {
//   @override
//   _TranslatePageState createState() => _TranslatePageState();
// }

// class _TranslatePageState extends State<TranslatePage> {
//   String _translatedText = ""; // Переменная для хранения перевода

//   // Метод для получения перевода выделенного текста
//   String _getTranslation(String selectedText) {
//     // Здесь вы можете реализовать вашу логику перевода
//     // Например, простой пример:
//     switch (selectedText.toLowerCase()) {
//       case 'hello':
//         return 'Привет';
//       case 'world':
//         return 'Мир';
//       // Добавьте больше переводов по мере необходимости
//       default:
//         return 'Перевод не найден';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Перевод текста"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Заголовок с инструкцией
//             Text(
//               "Выделите слово или предложение для перевода:",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),

//             // SelectableText для выделения текста
//             SelectableText(
//               "Hello, world! This is a sample text for translation. You can select any word or sentence here.",
//               style: TextStyle(fontSize: 16),
//               onSelectionChanged: (selection, cause) {
//                 if (selection.baseOffset != selection.extentOffset) {
//                   // Получаем выделенный текст
//                   final selectedText = selection.base.text.substring(
//                     selection.baseOffset,
//                     selection.extentOffset,
//                   );
//                   // Получаем перевод
//                   final translation = _getTranslation(selectedText);
//                   setState(() {
//                     _translatedText = translation; // Обновляем перевод
//                   });
//                 } else {
//                   setState(() {
//                     _translatedText =
//                         ""; // Сбрасываем перевод, если ничего не выбрано
//                   });
//                 }
//               },
//             ),
//             SizedBox(height: 20),

//             // Отображение перевода
//             Text(
//               "Перевод: $_translatedText",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
