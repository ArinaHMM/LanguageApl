// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class GptChatPage extends StatefulWidget {
//   @override
//   _GptChatPageState createState() => _GptChatPageState();
// }

// class _GptChatPageState extends State<GptChatPage> {
//   final TextEditingController _controller = TextEditingController();
//   List<String> _messages = [];

// Future<String> _fetchResponse(String message) async {
//   const String apiKey = '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'; // Вставьте ваш ключ API

//   try {
//     print('Отправка запроса к API...');
//     final response = await http.post(
//       Uri.parse('https://api.openai.com/v1/chat/completions'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $apiKey',
//       },
//       body: jsonEncode({
//         'model': 'gpt-3.5-turbo',
//         'messages': [
//           {'role': 'user', 'content': message},
//         ],
//       }),
//     );

//     print('Статус ответа: ${response.statusCode}');
//     print('Тело ответа: ${response.body}');

//     if (response.statusCode == 200) {
//       final jsonResponse = jsonDecode(response.body);
//       return jsonResponse['choices'][0]['message']['content'];
//     } else {
//       throw Exception('Ошибка при получении ответа от API: ${response.body}');
//     }
//   } catch (e) {
//     print('Ошибка: $e'); // Вывод ошибки
//     throw Exception('Ошибка при выполнении запроса: $e');
//   }
// }



//   void _sendMessage() async {
//     final message = _controller.text;
//     if (message.isNotEmpty) {
//       setState(() {
//         _messages.add(message);
//         _controller.clear();
//       });

//       try {
//         final response = await _fetchResponse(message);
//         setState(() {
//           _messages.add(response);
//         });
//       } catch (e) {
//         setState(() {
//           _messages.add('Ошибка: $e');
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Чат с ChatGPT'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(_messages[index]),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(hintText: 'Введите ваше сообщение...'),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
