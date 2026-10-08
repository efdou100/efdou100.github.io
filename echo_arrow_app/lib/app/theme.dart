import 'package:flutter/material.dart';

/// 디자인 토큰. 밤의 숲이 바탕이고, 게임 요소(달빛·메아리)만 빛난다.
class Palette {
  static const night = Color(0xFF10163F);
  static const nightDeep = Color(0xFF080B22);
  static const dusk = Color(0xFF1B2462);
  static const duskHi = Color(0xFF26317A);
  static const line = Color(0x2EA0B4FF);
  static const ink = Color(0xFFEEF2FF);
  static const inkSoft = Color(0xFFA7B2DE);
  static const moon = Color(0xFFFFD36B);
  static const moonDeep = Color(0xFFE09A2E);
  static const echo = Color(0xFF7EF0FF);
  static const echoDeep = Color(0xFF2A9BB0);
  static const moss = Color(0xFF6FD39B);
  static const blossom = Color(0xFFFF9FC8);
  static const violet = Color(0xFFB38CFF);
  static const danger = Color(0xFFFF6F86);

  /// 화살 순서별 색: 0 = 지금 화살, 1~ = 메아리
  static const shot = [Color(0xFFFFD36B), Color(0xFF7EF0FF), Color(0xFFB9A4FF), Color(0xFF8DFFB5), Color(0xFFFF9FC8), Color(0xFFFFB37E)];
}

/// 간격(4의 배수)과 글자 크기 체계
class Space {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
}

class TypeScale {
  static const caption = 12.0, body = 14.0, label = 17.0, title = 22.0, display = 30.0, hero = 44.0;
}

class Fonts {
  static const ko = 'Jua';
  static const num = 'Fredoka';
}

TextStyle ko(double size, {Color color = Palette.ink, double height = 1.25, List<Shadow>? shadows}) =>
    TextStyle(fontFamily: Fonts.ko, fontSize: size, color: color, height: height, shadows: shadows);

TextStyle numStyle(double size, {Color color = Palette.ink, FontWeight weight = FontWeight.w600}) =>
    TextStyle(fontFamily: Fonts.num, fontSize: size, color: color, fontWeight: weight, fontFeatures: const [FontFeature.tabularFigures()]);

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark, fontFamily: Fonts.ko);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.night,
    colorScheme: const ColorScheme.dark(primary: Palette.moon, secondary: Palette.echo, surface: Palette.dusk, error: Palette.danger),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
