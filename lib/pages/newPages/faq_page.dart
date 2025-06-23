// lib/pages/faq_page.dart

import 'package:flutter/material.dart';

// Модель для хранения одного вопроса и ответа
class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

// Модель для категории вопросов
class FaqCategory {
  final String title;
  final IconData icon;
  final List<FaqItem> items;

  FaqCategory({required this.title, required this.icon, required this.items});
}

class FaqPage extends StatelessWidget {
  const FaqPage({Key? key}) : super(key: key);

  // Здесь мы определяем наш список вопросов и ответов
  static final List<FaqCategory> _faqData = [
    FaqCategory(
      title: "Общие вопросы",
      icon: Icons.question_answer_rounded,
      items: [
        FaqItem(
          question: "Что такое LingoQuest?",
          answer: "LingoQuest - это интерактивная платформа для изучения языков через уроки, игры и соревновательные лиги. Наша цель - сделать обучение увлекательным и эффективным!",
        ),
        FaqItem(
          question: "Как изменить язык, который я изучаю?",
          answer: "На главной странице 'Путь' в верхнем правом углу есть переключатель языков. Нажмите на него, чтобы выбрать другой язык из тех, что вы уже начали изучать.",
        ),
      ],
    ),
    FaqCategory(
      title: "Лиги, XP и Стрики",
      icon: Icons.shield_rounded,
      items: [
        FaqItem(
          question: "Как работают лиги?",
          answer: "Каждую неделю вы соревнуетесь с другими игроками в вашей лиге, зарабатывая XP. В конце недели лучшие игроки переходят в лигу выше, а худшие - опускаются ниже. Цель - достичь самой высокой лиги!",
        ),
        FaqItem(
          question: "Что такое стрик и как его не потерять?",
          answer: "Стрик (ударный режим) - это количество дней подряд, в которые вы выполняете свою дневную цель по XP. Чтобы не потерять стрик, выполняйте цель каждый день или используйте 'заморозку', если знаете, что пропустите день.",
        ),
        FaqItem(
          question: "Что такое 'заморозка стрика'?",
          answer: "Заморозка - это предмет, который автоматически спасает ваш стрик, если вы пропустили один день. Вы можете получить заморозки в магазине или за особые достижения.",
        ),
      ],
    ),
    FaqCategory(
      title: "Технические вопросы",
      icon: Icons.settings_rounded,
      items: [
        FaqItem(
          question: "У меня не загружается урок. Что делать?",
          answer: "Попробуйте перезапустить приложение и проверьте ваше интернет-соединение. Если проблема не решается, свяжитесь с нашей службой поддержки через кнопку на странице профиля.",
        ),
        FaqItem(
          question: "Как сбросить пароль?",
          answer: "На странице входа есть кнопка 'Забыли пароль?'. Нажмите на нее и следуйте инструкциям, которые придут на вашу электронную почту.",
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Цветовая палитра
    final Color primaryOrange = const Color(0xFFF57C00);
    final Color backgroundColor = const Color(0xFFFFF3E0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Частые вопросы (FAQ)'),
        backgroundColor: primaryOrange,
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _faqData.length,
        itemBuilder: (context, index) {
          final category = _faqData[index];
          return _FaqCategoryWidget(category: category);
        },
      ),
    );
  }
}

// Виджет для отображения целой категории
class _FaqCategoryWidget extends StatelessWidget {
  final FaqCategory category;

  const _FaqCategoryWidget({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок категории
          Row(
            children: [
              Icon(category.icon, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Список вопросов в виде карточек
          ...category.items.map((item) => _FaqExpansionCard(item: item)).toList(),
        ],
      ),
    );
  }
}

// Виджет для одной раскрывающейся карточки с вопросом
class _FaqExpansionCard extends StatefulWidget {
  final FaqItem item;

  const _FaqExpansionCard({Key? key, required this.item}) : super(key: key);

  @override
  __FaqExpansionCardState createState() => __FaqExpansionCardState();
}

class __FaqExpansionCardState extends State<_FaqExpansionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Чтобы градиент не вылезал за скругленные углы
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          children: [
            // Заголовок вопроса (всегда виден)
            ListTile(
              title: Text(
                widget.item.question,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3A3A3A)),
              ),
              trailing: Icon(
                _isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: Colors.orange.shade700,
              ),
            ),
            // Раскрывающийся ответ с анимацией
            AnimatedCrossFade(
              firstChild: Container(), // Пустой контейнер, когда свернуто
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  )
                ),
                child: Text(
                  widget.item.answer,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}