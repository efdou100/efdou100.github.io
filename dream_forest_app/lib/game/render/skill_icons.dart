import 'dart:math' as math;
import 'dart:ui';

import '../../app/theme.dart';
import '../skills.dart';

Color rarityColor(Rarity r) => switch (r) {
  Rarity.common => const Color(0xFF7FD6B0),
  Rarity.rare => Palette.rare,
  Rarity.epic => Palette.epic,
};

String rarityLabel(Rarity r) => switch (r) {
  Rarity.common => '일반',
  Rarity.rare => '희귀',
  Rarity.epic => '영웅',
};

/// 스킬 아이콘을 벡터로 그려요. r 안에 꽉 차게.
void paintSkillIcon(Canvas c, String id, Rect r, {Color color = const Color(0xFFFFFFFF)}) {
  final s = r.shortestSide;
  c.save();
  c.translate(r.center.dx - s / 2, r.center.dy - s / 2);
  c.scale(s / 100);
  final fill = Paint()..color = color;
  final line = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void arrow(Offset from, Offset to, {double head = 16}) {
    c.drawLine(from, to, line);
    final a = math.atan2(to.dy - from.dy, to.dx - from.dx);
    c.drawPath(
      Path()
        ..moveTo(to.dx + math.cos(a) * 6, to.dy + math.sin(a) * 6)
        ..lineTo(to.dx + math.cos(a + 2.5) * head, to.dy + math.sin(a + 2.5) * head)
        ..lineTo(to.dx + math.cos(a - 2.5) * head, to.dy + math.sin(a - 2.5) * head)
        ..close(),
      fill,
    );
  }

  switch (id) {
    case 'multishot':
      arrow(const Offset(14, 38), const Offset(78, 38));
      arrow(const Offset(24, 64), const Offset(88, 64));
    case 'front':
      arrow(const Offset(16, 28), const Offset(80, 28), head: 13);
      arrow(const Offset(16, 50), const Offset(80, 50), head: 13);
      arrow(const Offset(16, 72), const Offset(80, 72), head: 13);
    case 'diagonal':
      arrow(const Offset(18, 50), const Offset(84, 50), head: 13);
      arrow(const Offset(18, 54), const Offset(76, 18), head: 13);
      arrow(const Offset(18, 46), const Offset(76, 82), head: 13);
    case 'back':
      arrow(const Offset(50, 50), const Offset(90, 50), head: 14);
      arrow(const Offset(50, 50), const Offset(10, 50), head: 14);
      c.drawCircle(const Offset(50, 50), 8, fill);
    case 'pierce':
      c.drawCircle(const Offset(52, 50), 18, line..strokeWidth = 6);
      line.strokeWidth = 8;
      arrow(const Offset(8, 50), const Offset(90, 50));
    case 'ricochet':
      line.strokeWidth = 7;
      c.drawPath(
        Path()
          ..moveTo(10, 78)
          ..lineTo(40, 26)
          ..lineTo(62, 70),
        line,
      );
      arrow(const Offset(62, 70), const Offset(88, 26), head: 14);
    case 'fire':
      final path = Path()
        ..moveTo(50, 8)
        ..cubicTo(62, 30, 84, 40, 80, 64)
        ..cubicTo(78, 84, 62, 94, 50, 94)
        ..cubicTo(34, 94, 20, 82, 20, 64)
        ..cubicTo(20, 48, 32, 42, 36, 30)
        ..cubicTo(42, 40, 44, 46, 48, 48)
        ..cubicTo(50, 34, 46, 22, 50, 8)
        ..close();
      c.drawPath(path, fill);
      c.drawPath(
        Path()
          ..moveTo(50, 56)
          ..cubicTo(60, 66, 62, 74, 60, 80)
          ..cubicTo(56, 88, 44, 88, 40, 80)
          ..cubicTo(38, 72, 46, 66, 50, 56)
          ..close(),
        Paint()..color = const Color(0x66000000),
      );
    case 'frost':
      line.strokeWidth = 7;
      for (var i = 0; i < 3; i++) {
        final a = i * math.pi / 3;
        final dx = math.cos(a) * 40, dy = math.sin(a) * 40;
        c.drawLine(Offset(50 - dx, 50 - dy), Offset(50 + dx, 50 + dy), line);
        for (final sgn in [-1.0, 1.0]) {
          final bx = 50 + dx * 0.6 * sgn, by = 50 + dy * 0.6 * sgn;
          c.drawLine(Offset(bx, by), Offset(bx + math.cos(a + sgn * 0.0 + 2.2) * 12 * sgn, by + math.sin(a + 2.2) * 12 * sgn), line);
          c.drawLine(Offset(bx, by), Offset(bx + math.cos(a - 2.2) * 12 * sgn, by + math.sin(a - 2.2) * 12 * sgn), line);
        }
      }
    case 'lightning':
      c.drawPath(
        Path()
          ..moveTo(58, 6)
          ..lineTo(22, 56)
          ..lineTo(46, 56)
          ..lineTo(38, 94)
          ..lineTo(78, 40)
          ..lineTo(54, 40)
          ..close(),
        fill,
      );
    case 'attack':
      c.drawPath(
        Path()
          ..moveTo(50, 6)
          ..lineTo(72, 40)
          ..lineTo(56, 40)
          ..lineTo(56, 86)
          ..lineTo(44, 86)
          ..lineTo(44, 40)
          ..lineTo(28, 40)
          ..close(),
        fill,
      );
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(28, 70, 44, 9), const Radius.circular(4)), fill);
    case 'haste':
      line.strokeWidth = 10;
      c.drawPath(
        Path()
          ..moveTo(18, 22)
          ..lineTo(46, 50)
          ..lineTo(18, 78),
        line,
      );
      c.drawPath(
        Path()
          ..moveTo(50, 22)
          ..lineTo(78, 50)
          ..lineTo(50, 78),
        line,
      );
    case 'crit':
      line.strokeWidth = 7;
      c.drawCircle(const Offset(50, 50), 32, line);
      c.drawCircle(const Offset(50, 50), 14, line);
      c.drawLine(const Offset(50, 4), const Offset(50, 24), line);
      c.drawLine(const Offset(50, 76), const Offset(50, 96), line);
      c.drawLine(const Offset(4, 50), const Offset(24, 50), line);
      c.drawLine(const Offset(76, 50), const Offset(96, 50), line);
      c.drawCircle(const Offset(50, 50), 5, fill);
    case 'orbit':
      // 가운데 별을 도는 구슬 세 개 + 기울어진 궤도
      c.save();
      c.translate(50, 50);
      c.rotate(-0.45);
      c.drawOval(const Rect.fromLTWH(-42, -17, 84, 34), line..strokeWidth = 4);
      c.restore();
      final star = Path();
      for (var i = 0; i < 8; i++) {
        final rr = i.isEven ? 14.0 : 6.0;
        final a = -math.pi / 2 + i * math.pi / 4;
        i == 0 ? star.moveTo(50 + math.cos(a) * rr, 50 + math.sin(a) * rr) : star.lineTo(50 + math.cos(a) * rr, 50 + math.sin(a) * rr);
      }
      c.drawPath(star..close(), fill);
      for (final o in const [Offset(84, 30), Offset(16, 70), Offset(70, 74)]) {
        c.drawCircle(o, 9, fill);
      }
    case 'vampire':
      c.drawPath(
        Path()
          ..moveTo(50, 8)
          ..cubicTo(64, 34, 80, 48, 80, 66)
          ..cubicTo(80, 84, 66, 94, 50, 94)
          ..cubicTo(34, 94, 20, 84, 20, 66)
          ..cubicTo(20, 48, 36, 34, 50, 8)
          ..close(),
        fill,
      );
      c.drawCircle(const Offset(38, 66), 7, Paint()..color = const Color(0x88FFFFFF));
    case 'heart':
      c.drawPath(
        Path()
          ..moveTo(50, 30)
          ..cubicTo(50, 12, 14, 8, 12, 36)
          ..cubicTo(12, 58, 40, 74, 50, 90)
          ..cubicTo(60, 74, 88, 58, 88, 36)
          ..cubicTo(86, 8, 50, 12, 50, 30)
          ..close(),
        fill,
      );
    case 'shield':
      c.drawPath(
        Path()
          ..moveTo(50, 6)
          ..cubicTo(70, 14, 86, 14, 86, 14)
          ..cubicTo(86, 56, 74, 80, 50, 96)
          ..cubicTo(26, 80, 14, 56, 14, 14)
          ..cubicTo(14, 14, 30, 14, 50, 6)
          ..close(),
        fill,
      );
      c.drawLine(
        const Offset(50, 22),
        const Offset(50, 80),
        Paint()
          ..color = const Color(0x66000000)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    case 'focus':
      c.drawPath(
        Path()
          ..moveTo(6, 50)
          ..quadraticBezierTo(50, 4, 94, 50)
          ..quadraticBezierTo(50, 96, 6, 50)
          ..close(),
        line..strokeWidth = 7,
      );
      c.drawCircle(const Offset(50, 50), 15, fill);
      c.drawCircle(const Offset(45, 45), 5, Paint()..color = const Color(0xAA000000));
    default:
      c.drawCircle(const Offset(50, 50), 30, fill);
  }
  c.restore();
}
