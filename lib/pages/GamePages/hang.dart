// lib/pages/GamePages/hangman_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class HangmanPainter extends CustomPainter {
  final int errors;
  final int maxErrors;
  final Color lineColor;
  final Color bodyColor;
  final double strokeWidth;

  HangmanPainter({
    required this.errors,
    this.maxErrors = 7,
    this.lineColor = const Color(0xFF5D4037), 
    this.bodyColor = const Color(0xFF455A64), 
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = strokeWidth // Можно сделать тело чуть тоньше: strokeWidth - 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double w = size.width;
    double h = size.height;

    // Пропорции для рисования, чтобы виселица занимала большую часть высоты, но была по центру
    double gallowsBaseY = h * 0.9;
    double gallowsTopY = h * 0.1;
    double gallowsPoleX = w * 0.25;
    double gallowsArmEndX = w * 0.65;
    double ropeAttachX = w * 0.6; // Слегка смещаем веревку относительно конца балки
    double ropeTopY = gallowsTopY;
    double ropeBottomY = h * 0.25;

    // Голова
    double headRadius = h * 0.07;
    double headCenterX = ropeAttachX;
    double headCenterY = ropeBottomY + headRadius;

    // Тело
    double bodyTopY = headCenterY + headRadius;
    double bodyBottomY = h * 0.62;

    // Руки
    double armsY = h * 0.48; // чуть выше середины тела
    double leftArmEndX = w * 0.48;
    double rightArmEndX = w * 0.72;
    double armEndY = h * 0.58;

    // Ноги
    double legsTopY = bodyBottomY;
    double leftLegEndX = w * 0.53;
    double rightLegEndX = w * 0.67;
    double legEndY = h * 0.78;


    // 1. База виселицы
    canvas.drawLine(Offset(w * 0.05, gallowsBaseY), Offset(w * 0.95, gallowsBaseY), paint);

    // 2. Вертикальная стойка
    if (errors >= 1 || maxErrors > 0) { // Начинаем рисовать структуру сразу или с первой ошибки
      canvas.drawLine(Offset(gallowsPoleX, gallowsBaseY), Offset(gallowsPoleX, gallowsTopY), paint);
    }
    // 3. Горизонтальная балка
    if (errors >= 2 || maxErrors > 1) {
      canvas.drawLine(Offset(gallowsPoleX, gallowsTopY), Offset(gallowsArmEndX, gallowsTopY), paint);
    }
    // 4. Маленькая диагональная поддержка (опционально, для красоты)
    if (errors >= 3 || maxErrors > 2) {
        canvas.drawLine(Offset(gallowsPoleX + w*0.05, gallowsTopY + h*0.05), Offset(gallowsPoleX + w*0.15, gallowsTopY), paint..strokeWidth = strokeWidth*0.7);
    }
    // 5. Веревка
    if (errors >= 4 || maxErrors > 3) {
      paint.strokeWidth = strokeWidth * 0.7; // Веревка чуть тоньше
      canvas.drawLine(Offset(ropeAttachX, ropeTopY), Offset(ropeAttachX, ropeBottomY), paint);
      paint.strokeWidth = strokeWidth; // Возвращаем толщину
    }

    // Части человечка
    if (errors >= 1) { // Голова (после первой ошибки, если maxErrors=7, или после 5-й ошибки, если структура рисуется по этапам)
                      // Давайте привяжем появление частей человечка к конкретным номерам ошибок
      canvas.drawCircle(Offset(headCenterX, headCenterY), headRadius, bodyPaint);
    }
    if (errors >= 2) { // Тело
      canvas.drawLine(Offset(headCenterX, bodyTopY), Offset(headCenterX, bodyBottomY), bodyPaint);
    }
    if (errors >= 3) { // Левая рука
      canvas.drawLine(Offset(headCenterX, armsY), Offset(leftArmEndX, armEndY), bodyPaint);
    }
    if (errors >= 4) { // Правая рука
      canvas.drawLine(Offset(headCenterX, armsY), Offset(rightArmEndX, armEndY), bodyPaint);
    }
    if (errors >= 5) { // Левая нога
      canvas.drawLine(Offset(headCenterX, legsTopY), Offset(leftLegEndX, legEndY), bodyPaint);
    }
    if (errors >= 6) { // Правая нога
      canvas.drawLine(Offset(headCenterX, legsTopY), Offset(rightLegEndX, legEndY), bodyPaint);
    }
    if (errors >= maxErrors) { // Лицо при проигрыше
      bodyPaint.strokeWidth = 2;
      // Глаза X X
      canvas.drawLine(Offset(headCenterX - headRadius * 0.3, headCenterY - headRadius * 0.2), Offset(headCenterX - headRadius * 0.1, headCenterY + headRadius * 0.05), bodyPaint);
      canvas.drawLine(Offset(headCenterX - headRadius * 0.1, headCenterY - headRadius * 0.2), Offset(headCenterX - headRadius * 0.3, headCenterY + headRadius * 0.05), bodyPaint);
      canvas.drawLine(Offset(headCenterX + headRadius * 0.1, headCenterY - headRadius * 0.2), Offset(headCenterX + headRadius * 0.3, headCenterY + headRadius * 0.05), bodyPaint);
      canvas.drawLine(Offset(headCenterX + headRadius * 0.3, headCenterY - headRadius * 0.2), Offset(headCenterX + headRadius * 0.1, headCenterY + headRadius * 0.05), bodyPaint);
      // Рот (грустный)
      final mouthPath = Path();
      mouthPath.moveTo(headCenterX - headRadius * 0.35, headCenterY + headRadius * 0.3);
      mouthPath.quadraticBezierTo(headCenterX, headCenterY + headRadius * 0.45, headCenterX + headRadius * 0.35, headCenterY + headRadius * 0.3);
      canvas.drawPath(mouthPath, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) {
    return oldDelegate.errors != errors;
  }
}