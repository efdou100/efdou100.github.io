import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/art.dart';

/// 게임 전용 아이콘. assets/images/ui/icon_<이름>.png (또는 ui/<이름>.png) 가 있으면 이미지로 바뀐다.
enum GI { calendar, sunrise, flame, gift, bag, medal, gear, pause, restart, bulb, lock, play, star, quiver, replay, share, back, plus, check, ad, crown, chest, aim, extra, split, heart, coin, close, globe }

class GameIcon extends StatelessWidget {
  const GameIcon(this.icon, {super.key, this.size = 28, this.color});
  final GI icon;
  final double size;
  final Color? color;

  static const _artIds = {
    GI.calendar: 'ui/icon_checkin',
    GI.sunrise: 'ui/icon_daily',
    GI.flame: 'ui/icon_streak',
    GI.gift: 'ui/icon_gift',
    GI.bag: 'ui/icon_shop',
    GI.medal: 'ui/icon_pass',
    GI.gear: 'ui/icon_settings',
    GI.bulb: 'ui/hint',
    GI.star: 'ui/star',
    GI.chest: 'ui/chest',
    GI.aim: 'ui/booster_aim',
    GI.extra: 'ui/booster_extra',
    GI.split: 'ui/booster_split',
    GI.heart: 'ui/heart',
    GI.coin: 'ui/coin',
  };

  @override
  Widget build(BuildContext context) {
    final id = _artIds[icon];
    final painted = CustomPaint(size: Size.square(size), painter: _IconPainter(icon, color));
    if (id != null && Art.instance.has(id)) return ArtImage(id, size: Size.square(size), fallback: painted);
    return painted;
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.tint);
  final GI icon;
  final Color? tint;

  static const gold = [Color(0xFFFFF0B8), Color(0xFFF2A93B)];
  static const ink = Color(0xFF2A1B05);

  Paint _grad(Rect r, List<Color> c) => Paint()..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, c);
  Paint _stroke(Color c, double w) => Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    c.scale(w / 24);
    final white = tint ?? const Color(0xFFEEF2FF);
    switch (icon) {
      case GI.calendar:
        final r = RRect.fromRectAndRadius(const Rect.fromLTWH(3, 5, 18, 16), const Radius.circular(3.5));
        c.drawRRect(r, _grad(r.outerRect, const [Color(0xFFFFFFFF), Color(0xFFD9E0FF)]));
        c.drawRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(3, 5, 18, 5), topLeft: const Radius.circular(3.5), topRight: const Radius.circular(3.5)), Paint()..color = const Color(0xFFFF6F86));
        for (final x in const [8.0, 16.0]) {
          c.drawLine(Offset(x, 3), Offset(x, 7), _stroke(const Color(0xFF8A93C8), 2));
        }
        _star(c, const Offset(12, 15.5), 3.6, gold);
      case GI.sunrise:
        c.drawCircle(const Offset(12, 15), 6, Paint()..shader = ui.Gradient.radial(const Offset(12, 13), 7, const [Color(0xFFFFF0B8), Color(0xFFFF9F5A)]));
        for (var k = 0; k < 5; k++) {
          final a = math.pi + k * math.pi / 4;
          c.drawLine(Offset(12 + math.cos(a) * 8, 15 + math.sin(a) * 8), Offset(12 + math.cos(a) * 10.5, 15 + math.sin(a) * 10.5), _stroke(const Color(0xFFFFD36B), 1.8));
        }
        c.drawRect(const Rect.fromLTWH(2, 15, 20, 7), Paint()..color = const Color(0xFF1B2462));
        c.drawLine(const Offset(3, 15), const Offset(21, 15), _stroke(const Color(0xFF7EF0FF), 1.6));
      case GI.flame:
        final p = Path()..moveTo(12, 2)..cubicTo(18, 8, 20, 12, 18, 17)..cubicTo(16.5, 21, 7.5, 21, 6, 17)..cubicTo(4.5, 13, 7, 10, 9, 8)..cubicTo(9, 11, 10.5, 12, 11.5, 12)..cubicTo(10.5, 8, 11, 5, 12, 2)..close();
        c.drawPath(p, Paint()..shader = ui.Gradient.linear(const Offset(12, 2), const Offset(12, 21), const [Color(0xFFB9F7FF), Color(0xFF2A9BB0)]));
        c.drawPath(Path()..moveTo(12, 11)..cubicTo(15, 14, 15, 18, 12, 19)..cubicTo(9, 18, 9.5, 15, 12, 11)..close(), Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85));
      case GI.gift:
        final box = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 10, 16, 11), const Radius.circular(2));
        c.drawRRect(box, _grad(box.outerRect, const [Color(0xFFFF9FC8), Color(0xFFD9467A)]));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 7, 18, 4.5), const Radius.circular(1.5)), Paint()..color = const Color(0xFFFF7AA8));
        c.drawRect(const Rect.fromLTWH(10.5, 7, 3, 14), Paint()..color = const Color(0xFFFFD36B));
        c.drawOval(const Rect.fromLTWH(6, 3, 6, 4.5), _stroke(const Color(0xFFFFD36B), 1.8));
        c.drawOval(const Rect.fromLTWH(12, 3, 6, 4.5), _stroke(const Color(0xFFFFD36B), 1.8));
      case GI.bag:
        final body = Path()..moveTo(4, 9)..lineTo(20, 9)..lineTo(18.5, 21)..lineTo(5.5, 21)..close();
        c.drawPath(body, _grad(const Rect.fromLTWH(4, 9, 16, 12), const [Color(0xFFB98A5E), Color(0xFF7A4E2E)]));
        c.drawPath(Path()..moveTo(8, 10)..cubicTo(8, 3, 16, 3, 16, 10), _stroke(const Color(0xFF7A4E2E), 2));
        c.drawCircle(const Offset(12, 15), 3.6, _grad(const Rect.fromLTWH(8, 11, 8, 8), gold));
      case GI.medal:
        c.drawPath(Path()..moveTo(7, 2)..lineTo(11, 2)..lineTo(13, 9)..lineTo(9, 9)..close(), Paint()..color = const Color(0xFF7EF0FF));
        c.drawPath(Path()..moveTo(17, 2)..lineTo(13, 2)..lineTo(11, 9)..lineTo(15, 9)..close(), Paint()..color = const Color(0xFFB38CFF));
        c.drawCircle(const Offset(12, 15), 6.5, _grad(const Rect.fromLTWH(5, 8, 14, 14), gold));
        _star(c, const Offset(12, 15), 3.5, const [Color(0xFFFFFFFF), Color(0xFFFFE39A)]);
      case GI.gear:
        final p = Paint()..color = white;
        for (var k = 0; k < 8; k++) {
          c.save();
          c.translate(12, 12);
          c.rotate(k * math.pi / 4);
          c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -10, 4, 5), const Radius.circular(1)), p);
          c.restore();
        }
        c.drawCircle(const Offset(12, 12), 7, p);
        c.drawCircle(const Offset(12, 12), 3, Paint()..color = const Color(0xFF1B2462));
      case GI.pause:
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6.5, 5, 4, 14), const Radius.circular(1.5)), Paint()..color = white);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(13.5, 5, 4, 14), const Radius.circular(1.5)), Paint()..color = white);
      case GI.restart:
      case GI.replay:
        c.drawArc(const Rect.fromLTWH(5, 5, 14, 14), -0.4, 5.0, false, _stroke(white, 2.6));
        c.drawPath(Path()..moveTo(20.5, 3.5)..lineTo(20, 10)..lineTo(14, 8.5)..close(), Paint()..color = white);
      case GI.bulb:
        c.drawCircle(const Offset(12, 10), 7, Paint()..color = const Color(0x55FFD36B)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
        c.drawCircle(const Offset(12, 10), 6, _grad(const Rect.fromLTWH(6, 4, 12, 12), const [Color(0xFFFFF6D0), Color(0xFFFFC14D)]));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 15.5, 6, 5), const Radius.circular(1.5)), Paint()..color = const Color(0xFFA7B2DE));
        c.drawLine(const Offset(9.5, 18), const Offset(14.5, 18), _stroke(const Color(0xFF6B76AA), 1));
      case GI.lock:
        c.drawPath(Path()..moveTo(8, 11)..lineTo(8, 8)..cubicTo(8, 3.5, 16, 3.5, 16, 8)..lineTo(16, 11), _stroke(const Color(0xFFA7B2DE), 2.4));
        final b = RRect.fromRectAndRadius(const Rect.fromLTWH(5.5, 10.5, 13, 10), const Radius.circular(2.5));
        c.drawRRect(b, _grad(b.outerRect, const [Color(0xFFCBD3F5), Color(0xFF7D88BE)]));
        c.drawCircle(const Offset(12, 15), 1.6, Paint()..color = const Color(0xFF2A3266));
      case GI.play:
        c.drawPath(Path()..moveTo(8, 5)..lineTo(19, 12)..lineTo(8, 19)..close(), Paint()..color = tint ?? ink);
      case GI.star:
        _star(c, const Offset(12, 12.5), 10, gold);
      case GI.quiver:
        c.drawLine(const Offset(12, 21), const Offset(12, 5), _stroke(tint ?? const Color(0xFFFFD36B), 2));
        c.drawPath(Path()..moveTo(12, 2)..lineTo(16, 7.5)..lineTo(8, 7.5)..close(), Paint()..color = tint ?? const Color(0xFFFFD36B));
        c.drawPath(Path()..moveTo(12, 17)..lineTo(15.5, 21)..lineTo(12, 19.5)..lineTo(8.5, 21)..close(), Paint()..color = (tint ?? const Color(0xFFFFD36B)).withValues(alpha: 0.8));
      case GI.share:
        c.drawPath(Path()..moveTo(7, 10)..lineTo(5, 10)..lineTo(5, 20)..lineTo(19, 20)..lineTo(19, 10)..lineTo(17, 10), _stroke(white, 2.2));
        c.drawLine(const Offset(12, 14), const Offset(12, 3.5), _stroke(white, 2.2));
        c.drawPath(Path()..moveTo(8, 7)..lineTo(12, 3)..lineTo(16, 7), _stroke(white, 2.2));
      case GI.back:
        c.drawPath(Path()..moveTo(14.5, 5)..lineTo(7.5, 12)..lineTo(14.5, 19), _stroke(white, 3));
      case GI.plus:
        c.drawLine(const Offset(12, 6), const Offset(12, 18), _stroke(tint ?? white, 3));
        c.drawLine(const Offset(6, 12), const Offset(18, 12), _stroke(tint ?? white, 3));
      case GI.check:
        c.drawPath(Path()..moveTo(5, 12.5)..lineTo(10, 17.5)..lineTo(19.5, 7), _stroke(tint ?? const Color(0xFF6FD39B), 3.2));
      case GI.close:
        c.drawLine(const Offset(7, 7), const Offset(17, 17), _stroke(white, 2.8));
        c.drawLine(const Offset(17, 7), const Offset(7, 17), _stroke(white, 2.8));
      case GI.ad:
        final r = RRect.fromRectAndRadius(const Rect.fromLTWH(3, 5, 18, 14), const Radius.circular(4));
        c.drawRRect(r, Paint()..color = tint ?? const Color(0xFF052A33));
        c.drawPath(Path()..moveTo(10, 8.5)..lineTo(15.5, 12)..lineTo(10, 15.5)..close(), Paint()..color = const Color(0xFFA6F6FF));
      case GI.crown:
        final p = Path()..moveTo(3, 18)..lineTo(4, 7)..lineTo(9, 12)..lineTo(12, 5)..lineTo(15, 12)..lineTo(20, 7)..lineTo(21, 18)..close();
        c.drawPath(p, _grad(const Rect.fromLTWH(3, 5, 18, 13), gold));
        c.drawRect(const Rect.fromLTWH(3, 17, 18, 3), Paint()..color = const Color(0xFFE09A2E));
        for (final x in const [4.0, 12.0, 20.0]) {
          c.drawCircle(Offset(x, x == 12 ? 5 : 7), 1.6, Paint()..color = const Color(0xFFFF9FC8));
        }
      case GI.chest:
        final lid = RRect.fromRectAndCorners(const Rect.fromLTWH(3, 6, 18, 6), topLeft: const Radius.circular(6), topRight: const Radius.circular(6));
        c.drawRRect(lid, _grad(lid.outerRect, const [Color(0xFFB98A5E), Color(0xFF8A5A3B)]));
        c.drawRect(const Rect.fromLTWH(3, 12, 18, 9), _grad(const Rect.fromLTWH(3, 12, 18, 9), const [Color(0xFF9A6440), Color(0xFF5E3A24)]));
        c.drawRect(const Rect.fromLTWH(3, 11, 18, 2), Paint()..color = const Color(0xFFFFD36B));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 10, 4, 5), const Radius.circular(1)), Paint()..color = const Color(0xFFFFE39A));
      case GI.aim:
        for (var k = 0; k < 5; k++) {
          c.drawCircle(Offset(4 + k * 3.0, 19 - k * 3.5), 1.4, Paint()..color = const Color(0xFFFFD36B));
        }
        c.drawCircle(const Offset(17, 5), 2.6, _stroke(const Color(0xFFFFD36B), 1.6));
        for (var k = 0; k < 3; k++) {
          c.drawCircle(Offset(18 + k * 1.0, 8 + k * 4.0), 1.2, Paint()..color = const Color(0xFFFFE9A0).withValues(alpha: 0.7));
        }
      case GI.extra:
        c.drawLine(const Offset(5, 19), const Offset(16, 8), _stroke(const Color(0xFFFFD36B), 2.2));
        c.drawPath(Path()..moveTo(18, 6)..lineTo(17, 11)..lineTo(13, 7)..close(), Paint()..color = const Color(0xFFFFD36B));
        c.drawCircle(const Offset(17.5, 17.5), 4.5, Paint()..color = const Color(0xFF6FD39B));
        c.drawLine(const Offset(17.5, 15), const Offset(17.5, 20), _stroke(const Color(0xFF0B2B1C), 1.8));
        c.drawLine(const Offset(15, 17.5), const Offset(20, 17.5), _stroke(const Color(0xFF0B2B1C), 1.8));
      case GI.split:
        c.drawLine(const Offset(4, 20), const Offset(11, 12), _stroke(const Color(0xFFFFD36B), 2.2));
        for (final e in const [(-0.9, 4.0), (-0.25, 4.0), (0.4, 4.0)]) {
          final a = e.$1 - math.pi / 4;
          final end = Offset(11 + math.cos(a) * 10, 12 + math.sin(a) * 10);
          c.drawLine(const Offset(11, 12), end, _stroke(const Color(0xFFFFE9A0), 1.8));
          c.drawCircle(end, 1.8, Paint()..color = const Color(0xFFFFD36B));
        }
      case GI.heart:
        final p = Path()..moveTo(12, 21)..cubicTo(-1, 12, 5, 1, 12, 7)..cubicTo(19, 1, 25, 12, 12, 21)..close();
        c.drawPath(p, _grad(const Rect.fromLTWH(0, 2, 24, 20), const [Color(0xFFFF9FB4), Color(0xFFE23B62)]));
      case GI.coin:
        c.drawCircle(const Offset(12, 12), 10, _grad(const Rect.fromLTWH(2, 2, 20, 20), gold));
      case GI.globe:
        c.drawCircle(const Offset(12, 12), 8.5, _stroke(white, 2));
        c.drawOval(const Rect.fromLTWH(8, 3.5, 8, 17), _stroke(white, 1.6));
        c.drawLine(const Offset(3.5, 12), const Offset(20.5, 12), _stroke(white, 1.6));
    }
  }

  void _star(Canvas c, Offset o, double r, List<Color> cols) {
    final p = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? r : r * 0.48;
      final a = -math.pi / 2 + k * math.pi / 5;
      final pt = Offset(o.dx + math.cos(a) * rr, o.dy + math.sin(a) * rr);
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    c.drawPath(p, Paint()..shader = ui.Gradient.linear(o.translate(-r, -r), o.translate(r, r), cols));
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.icon != icon || old.tint != tint;
}
