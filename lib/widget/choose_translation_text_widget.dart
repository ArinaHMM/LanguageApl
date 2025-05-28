// lib/widgets/exercises/choose_translation_text_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart'; // Убедитесь, что путь к модели Exercise верный
// import 'package:audioplayers/audioplayers.dart'; // Раскомментируйте, если будете использовать аудио

class ChooseTranslationTextWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(String selectedAnswer) onAnswerSelected;
  final bool showResult;
  final String? userAnswer;
  final String interfaceLanguageCode;

  const ChooseTranslationTextWidget({
    Key? key,
    required this.exercise,
    required this.onAnswerSelected,
    required this.showResult,
    this.userAnswer,
    required this.interfaceLanguageCode,
  }) : super(key: key);

  @override
  _ChooseTranslationTextWidgetState createState() => _ChooseTranslationTextWidgetState();
}

class _ChooseTranslationTextWidgetState extends State<ChooseTranslationTextWidget> with SingleTickerProviderStateMixin {
  String? _selectedOption;
  // final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showResult && widget.userAnswer != null) {
      _selectedOption = widget.userAnswer;
    }
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // Future<void> _playAudio(String? url) async {
  //   if (url != null && url.isNotEmpty) {
  //     try {
  //       await _audioPlayer.stop();
  //       await _audioPlayer.play(UrlSource(url));
  //     } catch (e) {
  //       print("Error playing audio: $e");
  //     }
  //   }
  // }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(String option) {
    if (widget.showResult) return;
    _animationController.forward().then((_) => _animationController.reverse());
    setState(() {
      _selectedOption = option;
    });
    widget.onAnswerSelected(option);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.getLocalizedOptionTexts(widget.interfaceLanguageCode);
    final correctAnswer = widget.exercise.getLocalizedCorrectAnswer(widget.interfaceLanguageCode);

    // Проверка на наличие текста вопроса или GIF, чтобы было что отображать
    bool hasQuestionContent = (widget.exercise.questionText != null && widget.exercise.questionText!.isNotEmpty) ||
                              (widget.exercise.gifUrl != null && widget.exercise.gifUrl!.isNotEmpty);

    if (!hasQuestionContent || options.isEmpty) {
      return Center(child: Text("Ошибка данных упражнения: отсутствует вопрос или варианты.", style: TextStyle(color: Colors.red)));
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Выравниваем по центру, если мало контента
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Блок с вопросом, GIF (если есть) и аудио кнопкой
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          margin: const EdgeInsets.only(bottom: 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column( // Обернули в Column для GIF и текста вопроса
            mainAxisSize: MainAxisSize.min, // Чтобы Column не растягивался без необходимости
            children: [
              // --- НАЧАЛО БЛОКА ДЛЯ GIF ---
              if (widget.exercise.gifUrl != null && widget.exercise.gifUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0), // Скругление для GIF
                    child: Image.network(
                      widget.exercise.gifUrl!,
                      height: 180, // Задайте подходящую высоту для GIF
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[600]!),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print("Error loading GIF: $error");
                        return SizedBox(
                          height: 180, 
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 48),
                                SizedBox(height: 8),
                                Text("Не удалось загрузить GIF", style: TextStyle(color: Colors.grey[600]))
                              ],
                            )
                          )
                        );
                      },
                    ),
                  ),
                ),
              // --- КОНЕЦ БЛОКА ДЛЯ GIF ---

              // Текст вопроса и кнопка аудио
              if (widget.exercise.questionText != null && widget.exercise.questionText!.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center, // Выравнивание по центру для текста и кнопки
                  children: [
                    Expanded(
                      child: Padding( // Добавил отступ, если есть кнопка аудио
                        padding: EdgeInsets.only(left: (widget.exercise.audioUrl != null && widget.exercise.audioUrl!.isNotEmpty) ? 0 : 30.0), // Центрируем текст если нет аудио
                        child: Text(
                          widget.exercise.questionText!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: (widget.exercise.gifUrl != null && widget.exercise.gifUrl!.isNotEmpty) ? 22 : 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal[900],
                          ),
                        ),
                      ),
                    ),
                    if (widget.exercise.audioUrl != null && widget.exercise.audioUrl!.isNotEmpty)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // _playAudio(widget.exercise.audioUrl);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Воспроизведение аудио (в разработке)")));
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.volume_up_rounded, color: Colors.teal[600], size: 30),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),

        // Варианты ответов (остаются без изменений, код из предыдущего ответа)
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              bool isSelected = _selectedOption == option;
              bool? isCorrectOption;

              Color tileColor = Colors.white;
              Color borderColor = Colors.grey.shade300;
              Color textColor = Colors.black87;
              double elevation = 2.0;
              IconData? trailingIconData;
              Color? trailingIconColor;

              if (widget.showResult) {
                isCorrectOption = (option == correctAnswer);
                if (isSelected) {
                  tileColor = isCorrectOption ? Colors.green.shade50 : Colors.red.shade50;
                  borderColor = isCorrectOption ? Colors.green.shade700 : Colors.red.shade700;
                  textColor = isCorrectOption ? Colors.green.shade900 : Colors.red.shade900;
                  elevation = 4.0;
                  trailingIconData = isCorrectOption ? Icons.check_circle_rounded : Icons.cancel_rounded;
                  trailingIconColor = isCorrectOption ? Colors.green.shade700 : Colors.red.shade700;
                } else if (isCorrectOption) {
                  tileColor = Colors.green.shade50.withOpacity(0.5);
                  borderColor = Colors.green.shade300;
                } else { 
                   borderColor = Colors.grey.shade300;
                }
              } else if (isSelected) {
                tileColor = Colors.teal.shade50;
                borderColor = Colors.teal.shade500;
                textColor = Colors.teal.shade900;
                elevation = 4.0;
              }
              
              return ScaleTransition(
                scale: isSelected && !widget.showResult ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                child: Card(
                  elevation: elevation,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: borderColor, width: 2.2),
                  ),
                  child: InkWell(
                    onTap: () => _handleTap(option),
                    borderRadius: BorderRadius.circular(12.0),
                    splashColor: borderColor.withOpacity(0.3),
                    highlightColor: borderColor.withOpacity(0.1),
                    child: Container(
                      decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (trailingIconData != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Icon(trailingIconData, color: trailingIconColor, size: 26),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}