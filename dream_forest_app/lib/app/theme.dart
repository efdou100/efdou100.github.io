import 'package:flutter/material.dart';

/// 꿈의 숲 팔레트: 해 질 녘 잠든 숲. 깊은 청록 + 보랏빛 하늘 + 호박색 등불.
class Palette {
  static const night = Color(0xFF0C1820);
  static const deep = Color(0xFF13262E);
  static const dusk = Color(0xFF2A2348);
  static const panel = Color(0xF2122128);
  static const line = Color(0x3386D29A);
  static const ink = Color(0xFFEFF4E8);
  static const mute = Color(0xFF9DB3A8);
  static const moss = Color(0xFF6FC483);
  static const grass = Color(0xFF86D891);
  static const earth = Color(0xFF26383A);
  static const earthDark = Color(0xFF172527);
  static const wood = Color(0xFFA0703F);
  static const woodDark = Color(0xFF6E4726);
  static const amber = Color(0xFFF5B85C);
  static const gold = Color(0xFFFFD45E);
  static const cream = Color(0xFFF6EDD6);
  static const rose = Color(0xFFE86FA6);
  static const violet = Color(0xFFB993FF);
  static const sky = Color(0xFF8FD3FF);
  static const danger = Color(0xFFFF5A4F);
  static const cloak = Color(0xFF4FA06B);
  static const cloakDark = Color(0xFF357A50);
  static const skin = Color(0xFFF4D7B5);

  static const common = Color(0xFF9DB3A8);
  static const rare = Color(0xFF6FB7FF);
  static const epic = Color(0xFFC889FF);
}

const kDisplayFont = 'Jua';

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.night,
    colorScheme: base.colorScheme.copyWith(primary: Palette.amber, secondary: Palette.moss, surface: Palette.deep),
    textTheme: base.textTheme.apply(bodyColor: Palette.ink, displayColor: Palette.ink),
    splashFactory: InkSparkle.splashFactory,
  );
}

TextStyle display(double size, {Color color = Palette.ink, double? height, List<Shadow>? shadows}) =>
    TextStyle(fontFamily: kDisplayFont, fontSize: size, color: color, height: height, shadows: shadows);
