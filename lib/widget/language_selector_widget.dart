
// lib/widgets/language_selector_widget.dart
import 'package:flutter/material.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final List<String> availableLanguages;
  final String currentLanguageCode;
  final Function(String newLanguageCode) onLanguageSelected;

  const LanguageSelectorWidget({
    Key? key,
    required this.availableLanguages,
    required this.currentLanguageCode,
    required this.onLanguageSelected,
  }) : super(key: key);

  String _getDisplayName(String code) {
    switch (code.toLowerCase()) {
      case 'english': return 'EN';
      case 'spanish': return 'ES';
      case 'german': return 'DE';
      case 'french': return 'FR';
      // Добавьте другие языки, если нужно
      default: return code.isNotEmpty ? code.toUpperCase().substring(0, 2) : "??";
    }
  }

  String _getFullDisplayName(String code) {
    switch (code.toLowerCase()) {
      case 'english': return 'Английский';
      case 'spanish': return 'Испанский';
      case 'german': return 'Немецкий';
      case 'french': return 'Французский';
      default: return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (availableLanguages.isEmpty) {
      return SizedBox.shrink();
    }
    return Padding( // Добавил отступ для лучшего вида в AppBar
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getDisplayName(currentLanguageCode),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
        onSelected: onLanguageSelected,
        itemBuilder: (BuildContext context) {
          return availableLanguages.map((String langCode) {
            return PopupMenuItem<String>(
              value: langCode,
              child: Text(_getFullDisplayName(langCode)),
            );
          }).toList();
        },
      ),
    );
  }
}