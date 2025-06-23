// lib/utils/app_data.dart

import 'package:flutter/material.dart';

// Класс-контейнер для хранения глобальных, статичных данных приложения
class AppData {
  
  // Статическое, публичное поле для хранения иконок предметов.
  // Теперь к нему можно обратиться из любого места в коде через AppData.itemIcons
  static const Map<String, IconData> itemIcons = {
    'streak_freeze_icon': Icons.ac_unit_rounded,
    'double_xp_icon': Icons.flash_on_rounded,
    'default_icon': Icons.help_outline_rounded,
  };

  // Сюда в будущем можно добавлять и другие глобальные данные,
  // например, цвета, константы для геймификации и т.д.
}