// lib/pages/Exercises/speaking_practice_page.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_languageapplicationmycourse_2/models/voice_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart'; // Не нужен для speech_to_text, но может быть нужен для flutter_sound

class SpeakingPracticePage extends StatefulWidget {
  final SpeakingExercise exercise;
  final VoidCallback onNext; // Callback для перехода к следующему упражнению
  final VoidCallback? onPrevious; // Callback для перехода к предыдущему (опционально)


  const SpeakingPracticePage({
    Key? key,
    required this.exercise,
    required this.onNext,
    this.onPrevious,
  }) : super(key: key);

  @override
  _SpeakingPracticePageState createState() => _SpeakingPracticePageState();
}

class _SpeakingPracticePageState extends State<SpeakingPracticePage> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  bool _isProcessingRecognition = false;
  double _similarityScore = 0.0;
  bool _attemptMade = false; // Пытался ли пользователь записать ответ

  // Анимации
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  late AnimationController _micPulseController;
  late Animation<double> _micPulseAnimation;


  // --- Цвета ---
  final Color appBarColor = const Color.fromARGB(255, 228, 117, 13); // Бирюзовый
  final Color backgroundColor = const Color.fromARGB(255, 255, 175, 110);
  final Color textColorToSpeak = const Color(0xFF004D40);
  final Color recordButtonColor = Colors.red.shade500;
  final Color stopButtonColor = Colors.blueGrey.shade600;
  final Color playExampleButtonColor = const Color(0xFF00695C);
  final Color resultGoodColor = Colors.green.shade700;
  final Color resultOkayColor = Colors.orange.shade700;
  final Color resultBadColor = Colors.red.shade700;
  // -------------

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _scoreAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scoreAnimation = CurvedAnimation(
        parent: _scoreAnimationController, curve: Curves.elasticOut);
    
    _micPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _micPulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut));

    _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      if (mounted) setState(() => _playerState = s);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _speech.stop(); // Убедимся, что распознавание остановлено
    _scoreAnimationController.dispose();
    _micPulseController.dispose();
    super.dispose();
  }

  Future<void> _playExampleAudio() async {
    if (widget.exercise.audioUrlExample == null || widget.exercise.audioUrlExample!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Аудио-пример отсутствует.")));
      return;
    }
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      try {
        await _audioPlayer.play(UrlSource(widget.exercise.audioUrlExample!));
      } catch (e) {
        print("Error playing example audio: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка воспроизведения примера: $e")));
        }
      }
    }
  }

  Future<void> _toggleRecording() async {
    bool microphonePermission = await _requestMicrophonePermission();
    if (!microphonePermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Доступ к микрофону не предоставлен.")),
      );
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
           if (status == stt.SpeechToText.listeningStatus && mounted) {
             setState(() => _isListening = true);
           } else if (status == stt.SpeechToText.notListeningStatus && mounted && _isListening) {
             // Если остановилось само (например, по таймауту)
             setState(() => _isListening = false);
             if (_recognizedText.isNotEmpty || _attemptMade) _processRecognition(); // Обработка, если есть что обрабатывать или была попытка
           }
        },
        onError: (errorNotification) {
          print('Speech error: $errorNotification');
          if (mounted) {
            setState(() => _isListening = false);
             _showError("Ошибка распознавания");
          }
        },
        
      );

      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
          _similarityScore = 0.0;
          _attemptMade = true; // Пользователь начал попытку
          _isProcessingRecognition = false;
        });
        _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _recognizedText = result.recognizedWords;
              });
            }
          },
          localeId: widget.exercise.targetLanguage, // Например "en_US", "es_ES", "de_DE"
          listenFor: const Duration(seconds: 15), // Максимальная длительность записи
          pauseFor: const Duration(seconds: 4),   // Пауза перед остановкой, если нет речи
          partialResults: true, // Показывать промежуточные результаты (можно false)
          cancelOnError: true, // Отменять при ошибке
        );
      } else {
        print("Speech recognition not available");
        _showError("Не удалось! Попробуйте снова");
      }
    } else {
      // Пользователь нажал "Стоп"
      setState(() => _isListening = false);
      await _speech.stop();
      _processRecognition();
    }
  }

  void _processRecognition() {
    if (!_attemptMade) return; // Не обрабатываем, если не было попытки записи

    setState(() => _isProcessingRecognition = true);

    // Небольшая задержка, чтобы дать _recognizedText время обновиться после speech.stop()
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      String refText = widget.exercise.textToSpeak.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), ''); // Убираем знаки препинания для сравнения
      String recText = _recognizedText.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');

      double similarity = 0.0;
      if (recText.isNotEmpty && refText.isNotEmpty) {
        similarity = StringSimilarity.compareTwoStrings(recText, refText);
      }

      setState(() {
        _similarityScore = similarity;
        _isProcessingRecognition = false;
      });
      _scoreAnimationController.forward(from: 0.0);

      print("Эталон: ${widget.exercise.textToSpeak} (Clean: $refText)");
      print("Распознано: $_recognizedText (Clean: $recText)");
      print("Схожесть: $_similarityScore");
    });
  }
  
  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.75) return resultGoodColor;
    if (score >= 0.45) return resultOkayColor;
    return resultBadColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.exercise.title ?? 'Произношение', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: appBarColor,
        elevation: 2,
        leading: widget.onPrevious != null 
          ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: widget.onPrevious)
          : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Произнесите следующую фразу:",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColorToSpeak.withOpacity(0.9)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  widget.exercise.textToSpeak,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textColorToSpeak, height: 1.4, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (widget.exercise.audioUrlExample != null && widget.exercise.audioUrlExample!.isNotEmpty) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: Icon(
                  _playerState == PlayerState.playing ? Icons.pause_circle_filled_rounded : Icons.volume_up_rounded,
                  color: playExampleButtonColor, size: 26,
                ),
                label: Text(_playerState == PlayerState.playing ? "Пауза" : "Прослушать пример", style: TextStyle(color: playExampleButtonColor, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: playExampleButtonColor.withOpacity(0.6), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                onPressed: _playExampleAudio,
              ),
            ],
            const SizedBox(height: 35),
            
            _buildMicButton(),
            const SizedBox(height: 12),
            Center(child: Text(_isListening ? "Говорите сейчас..." : (_attemptMade && !_isProcessingRecognition ? "Нажмите для новой попытки" : "Нажмите на микрофон для начала записи"), style: TextStyle(color: Colors.grey.shade700, fontSize: 15))),

            const SizedBox(height: 30),

            if (_isProcessingRecognition)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Column(children: [CircularProgressIndicator(), SizedBox(height: 10), Text("Анализ вашего голоса...", style: TextStyle(color: Colors.orangeAccent))]),
              )),
            
            if (_attemptMade && !_isListening && !_isProcessingRecognition)
              _buildResultDisplay(),

            const SizedBox(height: 20),
             if (_attemptMade && !_isListening && !_isProcessingRecognition && _similarityScore >= 0) // Показываем кнопку Далее только после попытки
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text("Далее"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appBarColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: widget.onNext,
              ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton(){
    return Center(
      child: ScaleTransition(
        scale: _isListening ? _micPulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: FloatingActionButton.large(
          heroTag: 'mic_button_speak', // Уникальный heroTag
          onPressed: _toggleRecording,
          backgroundColor: _isListening ? stopButtonColor : recordButtonColor,
          elevation: 6,
          child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_none_rounded, size: 40, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    Color scoreColor = _getScoreColor(_similarityScore);
    String feedbackText;
    if (_similarityScore >= 0.85) feedbackText = "Отлично!";
    else if (_similarityScore >= 0.65) feedbackText = "Хорошо! Почти идеально.";
    else if (_similarityScore >= 0.40) feedbackText = "Неплохо, но можно лучше.";
    else if (_recognizedText.isEmpty && _attemptMade) feedbackText = "Не удалось распознать речь. Попробуйте еще раз в более тихом месте.";
    else feedbackText = "Стоит еще потренироваться.";


    return Column(
      children: [
        if (_recognizedText.isNotEmpty) ...[
          Text("Вы сказали:", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Text(
              _recognizedText,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text("Схожесть с эталоном:", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        ScaleTransition(
          scale: _scoreAnimation,
          child: Text(
            "${(_similarityScore * 100).toStringAsFixed(0)}%",
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: scoreColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(feedbackText, style: TextStyle(fontSize: 16, color: scoreColor, fontWeight: FontWeight.w500), textAlign: TextAlign.center,),
      ],
    );
  }
}