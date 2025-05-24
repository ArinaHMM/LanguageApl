import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> fetchAudio(String text) async {
  // ignore: prefer_const_declarations
  final apiKey = '19212c1d69204a9eae33604b96f671e7'; // Ваш API ключ
  final url = 'https://api.voicerss.org/?key=$apiKey&hl=en-us&src=$text';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    // VoiceRSS возвращает аудио в виде raw данных
    // Для этого нужно сохранить файл на устройство и получить URL
    return response.body; // Это не URL, а аудиоданные
  } else {
    throw Exception('Не удалось получить аудио: ${response.reasonPhrase}');
  }
}
