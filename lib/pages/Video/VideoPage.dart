import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoLessonPage extends StatefulWidget {
  final String lessonId;
  final String title;
  final String videoUrl;

  const VideoLessonPage({
    Key? key,
    required this.lessonId,
    required this.title,
    required this.videoUrl,
  }) : super(key: key);

  @override
  _VideoLessonPageState createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends State<VideoLessonPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Инициализация видео контроллера
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
      });

    // Слушатель состояния плеера
    _controller.addListener(() {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    // Освобождаем ресурсы контроллера
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF0C9869),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent.shade100, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Титульная часть
                  Text(
                    'ID урока: ${widget.lessonId}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Плеер с видео
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: VideoPlayer(_controller),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Кнопка воспроизведения/паузы
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: _isPlaying
                            ? Colors.redAccent
                            : Color(0xFF0C9869),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 28,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isPlaying ? 'Пауза' : 'Воспроизвести',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onPressed: () {
                        setState(() {
                          if (_isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Полоса прокрутки
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.greenAccent.shade700,
                      bufferedColor: Colors.grey.shade400,
                      backgroundColor: Colors.black12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
