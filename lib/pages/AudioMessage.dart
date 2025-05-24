import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class AudioMessageCreator extends StatefulWidget {
  @override
  _AudioMessageCreatorState createState() => _AudioMessageCreatorState();
}

class _AudioMessageCreatorState extends State<AudioMessageCreator> {
  final TextEditingController textController = TextEditingController();
  final AudioPlayer audioPlayer = AudioPlayer();
  Uint8List? audioData;
  bool isLoading = false;
  String? errorMessage;

  Future<void> createAudioMessage() async {
    setState(() {
      isLoading = true;
      errorMessage = null; // Сбрасываем сообщение об ошибке
    });

    try {
      print('Начало получения аудиосообщения для текста: ${textController.text}');
      audioData = await fetchAudio(textController.text);
      print('Аудиоданные получены, длина: ${audioData?.length}');
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при создании аудиосообщения: ${e.toString()}';
      });
      print('Ошибка при создании аудиосообщения: $e'); // Лог ошибки
    } finally {
      setState(() {
        isLoading = false; // Завершаем загрузку
      });
    }
  }

  Future<Uint8List> fetchAudio(String text) async {
    final apiKey = '19212c1d69204a9eae33604b96f671e7'; // Ваш API ключ
    final url = 'https://api.voicerss.org/?key=$apiKey&hl=en-us&src=$text&f=16khz_16bit_mono';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes; // Возвращаем байты аудио
      } else {
        throw Exception('Не удалось получить аудио: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Ошибка при вызове API: $e'); // Лог ошибки API
    }
  }

  Future<void> playAudio(Uint8List audioData) async {
    try {
      await audioPlayer.setSource(BytesSource(audioData));
      await audioPlayer.resume();
      print('Аудио воспроизводится...');
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка воспроизведения аудио: $e'; // Устанавливаем сообщение об ошибке
      });
      print('Ошибка воспроизведения аудио: $e'); // Лог ошибки воспроизведения
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'Введите текст для аудио',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: isLoading ? null : createAudioMessage,
          child: isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text('Создать аудио'),
        ),
        if (audioData != null) ...[
          SizedBox(height: 10),
          Text('Аудио создано:'),
          ElevatedButton(
            onPressed: () {
              playAudio(audioData!);
            },
            child: Text('Воспроизвести'),
          ),
        ],
        if (errorMessage != null) ...[
          SizedBox(height: 10),
          Text(
            'Ошибка: $errorMessage',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
