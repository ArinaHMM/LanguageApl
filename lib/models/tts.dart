
import 'dart:convert';
import 'dart:typed_data'; // Для Uint8List
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
class TtsService {
  static const String _voiceRssApiKey = '19212c1d69204a9eae33604b96f671e7';
  static String _mapLanguageCodeToVoiceRss(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'english':
        return 'en-US'; 
      case 'spanish':
        return 'es-ES'; 
      case 'german':
        return 'de-DE'; 
            default:
        return 'en-US'; 
    }
  }
  static Future<String?> synthesizeAndUpload(
      String text, 
      String targetLanguageCode, 
      String lessonId, 
      String taskId
  ) async {
    final String voiceRssLangCode = _mapLanguageCodeToVoiceRss(targetLanguageCode);
   
    final String voiceRssUrl =
        'https://api.voicerss.org/?key=$_voiceRssApiKey&hl=$voiceRssLangCode&src=${Uri.encodeComponent(text)}&c=MP3&f=44khz_16bit_stereo&b64=true';

    try {
      final response = await http.get(Uri.parse(voiceRssUrl));
      if (response.statusCode == 200) {
        if (response.body.startsWith('ERROR')) {
          print('VoiceRSS API Error: ${response.body}');
          throw Exception('VoiceRSS API Error: ${response.body}');
        }
                String base64Audio = response.body;
        if (base64Audio.startsWith('data:')) {
            base64Audio = base64Audio.substring(base64Audio.indexOf(',') + 1);
        }
        Uint8List audioBytes = base64Decode(base64Audio);
        final String fileName = 'lesson_tts_audio/$lessonId/$taskId/${Uuid().v4()}.mp3';
        final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        
        final UploadTask uploadTask = storageRef.putData(
            audioBytes, 
            SettableMetadata(contentType: 'audio/mpeg') // Указываем MIME тип
        );
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Audio uploaded to Firebase Storage: $downloadUrl');
        return downloadUrl;
      } else {
        print('Failed to get audio from VoiceRSS: ${response.statusCode} ${response.reasonPhrase}');
        throw Exception('Failed to get audio from VoiceRSS: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in synthesizeAndUpload: $e');
      return null; 
    }
  }
}