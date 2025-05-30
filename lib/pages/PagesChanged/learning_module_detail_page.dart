import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
// Замените на ваш путь к модели
import 'package:flutter_languageapplicationmycourse_2/models/learning_module_model.dart';

class LearningModuleDetailPage extends StatefulWidget {
  final LearningModule module;

  const LearningModuleDetailPage({Key? key, required this.module}) : super(key: key);

  @override
  _LearningModuleDetailPageState createState() => _LearningModuleDetailPageState();
}

class _LearningModuleDetailPageState extends State<LearningModuleDetailPage> {
  // AudioPlayer и _playingIndex нужны ТОЛЬКО если отображаются learningItems
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Этот метод используется только для learningItems
  Future<void> _playAudio(String? url, int index) async {
    if (url == null || url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аудиофайл отсутствует')),
      );
      return;
    }
    try {
      if (_playingIndex == index) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _playingIndex = null);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        if (mounted) setState(() => _playingIndex = index);
        _audioPlayer.onPlayerComplete.first.then((_) {
          if (mounted) setState(() => _playingIndex = null);
        });
      }
    } catch (e) {
      print("Error playing audio: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка воспроизведения аудио: $e')),
      );
      if (mounted) setState(() => _playingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarColor = _getColorForLanguage(widget.module.targetLanguage);
    // final Map<String, String> languageDisplayNames = {
    //   'english': 'Английский',
    //   'german': 'Немецкий',
    //   'spanish': 'Испанский',
    // };

    Widget bodyContent;

    // 1. Отображение старой структуры с learningItems
    if (widget.module.learningItems.isNotEmpty) {
      bodyContent = ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: widget.module.learningItems.length,
        itemBuilder: (context, index) {
          final item = widget.module.learningItems[index];
          // Передаем languageDisplayNames, если он нужен в _buildLearningItemTile
          return _buildLearningItemTile(item, index /*, languageDisplayNames */);
        },
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
      );
    }
    // 2. Отображение новой структуры контента
    else if (widget.module.contentImageUrl != null ||
               widget.module.textContent != null ||
               widget.module.translationNotes != null) {
      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              color: appBarColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(Icons.translate_rounded, widget.module.targetLanguage.toUpperCase(), appBarColor),
                    _buildInfoChip(Icons.bar_chart_rounded, widget.module.level, appBarColor),
                  ],
                ),
              ),
            ),
            if (widget.module.contentImageUrl != null && widget.module.contentImageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    widget.module.contentImageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(appBarColor),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 50),
                    ),
                  ),
                ),
              ),
            if (widget.module.textContent != null && widget.module.textContent!.isNotEmpty)
              _buildSection(
                title: 'Материал темы:',
                content: widget.module.textContent!,
                icon: Icons.article_outlined,
                iconColor: appBarColor,
              ),
            if (widget.module.translationNotes != null && widget.module.translationNotes!.isNotEmpty)
              _buildSection(
                title: 'Перевод / Заметки:',
                content: widget.module.translationNotes!,
                icon: Icons.lightbulb_outline_rounded,
                iconColor: Colors.amber.shade700,
                isNote: true,
              ),
          ],
        ),
      );
    }
    // 3. Если вообще нет контента
    else {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.content_paste_off_outlined, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Для этого модуля пока нет материалов.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.titleRu, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: appBarColor,
        elevation: 2,
      ),
      body: bodyContent,
    );
  }

  // Этот метод используется ТОЛЬКО для старой структуры с learningItems
  Widget _buildLearningItemTile(LearningItem item, int index /*, Map<String, String> langNames*/) {
    final langColor = _getColorForLanguage(widget.module.targetLanguage);
    bool isPlaying = _playingIndex == index;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias, // Для InkWell и эффектов
      child: InkWell( // Добавляем InkWell для лучшего UX на элементах списка
        onTap: () {
          // Можно добавить действие при нажатии на сам элемент, если нужно
          // Например, если есть аудио, можно воспроизвести его
          if (item.targetAudioUrl != null && item.targetAudioUrl!.isNotEmpty) {
             _playAudio(item.targetAudioUrl, index);
          }
        },
        splashColor: langColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText( // Позволяет копировать
                          item.targetText,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: langColor,
                          ),
                        ),
                         if (item.targetTranscription != null && item.targetTranscription!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              item.targetTranscription!,
                              style: TextStyle(fontSize: 14.0, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.targetAudioUrl != null && item.targetAudioUrl!.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_fill_rounded,
                        color: langColor,
                        size: 32,
                      ),
                      tooltip: isPlaying ? 'Остановить' : 'Воспроизвести',
                      onPressed: () => _playAudio(item.targetAudioUrl, index),
                    ),
                ],
              ),
              const SizedBox(height: 10.0),
              SelectableText( // Позволяет копировать
                item.russianText,
                style: TextStyle(fontSize: 16.0, color: Colors.grey[800], height: 1.4),
              ),
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      item.imageUrl!,
                      height: 180, // Немного увеличим высоту
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(langColor),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                           color: Colors.grey[200],
                           borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательные методы для новой структуры контента (из предыдущего ответа)
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    bool isNote = false,
  }) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            SelectableText( // Позволяет копировать текст
              content,
              style: TextStyle(
                fontSize: 16.0,
                color: isNote ? Colors.grey[800] : Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'english':
        return Colors.blueAccent.shade400;
      case 'german':
        return Colors.orange.shade700;
      case 'spanish':
        return Colors.redAccent.shade400;
      default:
        return Colors.teal.shade600;
    }
  }
}