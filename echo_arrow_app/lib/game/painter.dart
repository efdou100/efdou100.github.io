import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/art.dart';
import '../app/profile.dart';
import '../app/theme.dart';
import 'controller.dart';
import 'level.dart';
import 'sim.dart';

/// 월드별 색과 분위기
class WorldTheme {
  const WorldTheme(this.sky, this.fieldTop, this.fieldBottom, this.silhouette, this.accent, this.glow);
  final List<Color> sky;
  final Color fieldTop, fieldBottom, silhouette, accent, glow;

  static const themes = [
    WorldTheme([Color(0xFF151B4A), Color(0xFF0F2347), Color(0xFF0B2B33)], Color(0x8C283478), Color(0x8C144646), Color(0xFF0C2632), Color(0xFF6FD39B), Color(0xFFFFE9A0)),
    WorldTheme([Color(0xFF1A2150), Color(0xFF26305E), Color(0xFF1B2A44)], Color(0x8C3A4684), Color(0x8C2A3A5A), Color(0xFF1A2440), Color(0xFFDDEBFF), Color(0xFFCFE6FF)),
    WorldTheme([Color(0xFF1B1240), Color(0xFF2A1752), Color(0xFF102F3E)], Color(0x8C3A2470), Color(0x8C134650), Color(0xFF150C2E), Color(0xFFB38CFF), Color(0xFF7EF0FF)),
    WorldTheme([Color(0xFF0C1A3A), Color(0xFF12304A), Color(0xFF162040)], Color(0x8C1E4466), Color(0x8C2A2462), Color(0xFF0A1830), Color(0xFF7EF0FF), Color(0xFF8DFFB5)),
    WorldTheme([Color(0xFF070A24), Color(0xFF141040), Color(0xFF1E1236)], Color(0x8C1C1A5A), Color(0x8C2E1A4A), Color(0xFF07081C), Color(0xFFFFD36B), Color(0xFFFFE9B0)),
  ];
  static WorldTheme of(int world) => themes[(world - 1).clamp(0, themes.length - 1)];
}

/// 게임 화면 그리기. 논리 좌표 360×640, 바깥은 화면에 맞춰 늘린다.
/// 이미지(assets/images/...)가 있으면 이미지로, 없으면 코드 그림으로 그린다.
class GamePainter extends CustomPainter {
  GamePainter(this.g) : super(repaint: g);
  final GameController g;

  static final Map<int, ui.Picture> _static = {};
  static final Map<String, TextPainter> _tp = {};
  static final Art _art = Art.instance;

  WorldTheme get theme => WorldTheme.of(g.level.world);

  static Rect fit(Size size) {
    final s = math.min(size.width / Field.w, size.height / Field.h);
    final w = Field.w * s, h = Field.h * s;
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = fit(size);
    final s = r.width / Field.w;
    _background(canvas, size);
    canvas.save();
    canvas.translate(r.left, r.top);
    canvas.scale(s);
    final sx = (_rand() - 0.5) * g.shake, sy = (_rand() - 0.5) * g.shake;
    canvas.save();
    canvas.translate(180 + sx, 320 + sy);
    canvas.scale(g.camZ);
    canvas.translate(-g.camX, -g.camY);
    canvas.drawPicture(_static[g.level.id] ??= _buildStatic(g.level));
    _ambient(canvas);
    final t = g.run.time;
    _gates(canvas, t);
    _devices(canvas);
    _switches(canvas, t);
    _targets(canvas, t);
    _echoPreview(canvas);
    _hint(canvas);
    _arrows(canvas);
    _archer(canvas);
    _guide(canvas);
    _fx(canvas);
    canvas.restore();
    if (g.holdVis > 0.01) {
      canvas.drawRect(
        const Rect.fromLTWH(-600, -800, Field.w + 1200, Field.h + 1600),
        Paint()..shader = ui.Gradient.radial(const Offset(180, 320), 440, [const Color(0x000A1E3C), Color.fromRGBO(40, 140, 180, 0.42 * g.holdVis)], [0.42, 1]),
      );
    }
    if (g.flash > 0) canvas.drawRect(const Rect.fromLTWH(-600, -800, Field.w + 1200, Field.h + 1600), Paint()..color = Color.fromRGBO(255, 248, 220, math.min(0.8, g.flash)));
    if ((g.mode == Mode.hold || g.mode == Mode.fly) && g.shots.isNotEmpty) {
      _label(canvas, 'ECHO ${t.toStringAsFixed(2)}s', Field.x0 + 10, Field.y0 + 8, Palette.echo, 11, align: TextAlign.left, num: true);
    }
    if (g.mode == Mode.replay) {
      canvas.drawCircle(const Offset(Field.x0 + 16, Field.y0 + 16), 4.5, Paint()..color = Color.fromRGBO(255, 90, 110, 0.6 + 0.4 * math.sin(g.clock * 6)));
      _label(canvas, 'REPLAY', Field.x0 + 26, Field.y0 + 9, Colors.white, 11, align: TextAlign.left, num: true);
      _label(canvas, 'ECHO ARROW', Field.x1 - 10, Field.y1 - 22, Colors.white60, 11, align: TextAlign.right, num: true);
    }
    canvas.restore();
  }

  int _seed = 1;
  double _rand() {
    _seed = (_seed * 16807) % 2147483647;
    return _seed / 2147483647;
  }

  // ---------------- 배경 ----------------
  void _background(Canvas c, Size size) {
    final full = Offset.zero & size;
    final bg = _art.image('bg/world${g.level.world}_game');
    if (bg != null) {
      c.drawArtCover(bg, full);
      return;
    }
    c.drawRect(full, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: theme.sky).createShader(full));
  }

  ui.Picture _buildStatic(LevelData l) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rnd = math.Random(99 + l.id * 13);
    final th = theme;
    final hasBg = _art.has('bg/world${l.world}_game');
    final field = RRect.fromRectAndRadius(const Rect.fromLTRB(Field.x0, Field.y0, Field.x1, Field.y1), const Radius.circular(12));
    if (!hasBg) {
      c.drawRRect(field, Paint()..shader = ui.Gradient.linear(const Offset(0, Field.y0), const Offset(0, Field.y1), [th.fieldTop, th.fieldBottom]));
      c.save();
      c.clipRRect(field);
      _scenery(c, l.world, rnd, th);
      c.restore();
    } else {
      c.drawRRect(field, Paint()..color = const Color(0x40080B22));
    }
    c.drawRRect(field, Paint()..shader = ui.Gradient.radial(const Offset(180, 340), 330, [const Color(0x00000000), const Color(0x59000010)], [0.6, 1]));
    for (final t in l.targets) {
      if (t.per == 0) continue;
      _dashed(c, Offset(t.x - t.mx, t.y - t.my), Offset(t.x + t.mx, t.y + t.my), Paint()..color = const Color(0x40C8E6FF)..strokeWidth = 2, 3, 7);
    }
    for (final b in l.blocks) {
      if (b.k != 'i') _block(c, b, rnd);
    }
    final comp = compileLevel(l);
    for (final s in comp.segs) {
      if (s.edge) _wall(c, s.x1, s.y1, s.x2, s.y2, s.k, true, rnd);
    }
    for (final w in l.walls) {
      _wall(c, w.x1, w.y1, w.x2, w.y2, w.k, false, rnd);
    }
    // 궁수가 서는 언덕
    final hill = Path()
      ..moveTo(l.bowX - 70, Field.y1)
      ..quadraticBezierTo(l.bowX, l.bowY + 4, l.bowX + 70, Field.y1)
      ..close();
    c.drawPath(hill, Paint()..color = th.silhouette.withValues(alpha: 0.9));
    c.drawPath(Path()..moveTo(l.bowX - 50, l.bowY + 22)..quadraticBezierTo(l.bowX, l.bowY + 8, l.bowX + 50, l.bowY + 22), Paint()..color = th.accent.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 2);
    return rec.endRecording();
  }

  /// 월드별 풍경 (이미지가 없을 때)
  void _scenery(Canvas c, int world, math.Random rnd, WorldTheme th) {
    for (var i = 0; i < 80; i++) {
      c.drawCircle(Offset(Field.x0 + rnd.nextDouble() * 336, Field.y0 + rnd.nextDouble() * 420), rnd.nextDouble() * 1.2 + 0.2, Paint()..color = Color.fromRGBO(220, 230, 255, 0.15 + rnd.nextDouble() * 0.5));
    }
    switch (world) {
      case 1:
        _moon(c, const Offset(290, 150), 34, th.glow);
        _treeLine(c, rnd, [const Color(0x591E3C5A), const Color(0x73143246), const Color(0x990C2632)]);
        _sideTrees(c, rnd, const Color(0xCC0A1E28));
      case 2:
        _moon(c, const Offset(80, 140), 26, th.glow);
        for (var i = 0; i < 9; i++) {
          final x = rnd.nextBool() ? Field.x0 + rnd.nextDouble() * 50 : Field.x1 - rnd.nextDouble() * 50;
          final h = 160 + rnd.nextDouble() * 220;
          c.drawRect(Rect.fromLTWH(x, Field.y1 - h, 6 + rnd.nextDouble() * 5, h), Paint()..color = const Color(0x66DDE6FF));
          for (var k = 0; k < 6; k++) {
            c.drawRect(Rect.fromLTWH(x, Field.y1 - h + rnd.nextDouble() * h, 7, 2), Paint()..color = const Color(0x55101830));
          }
        }
        for (var i = 0; i < 12; i++) {
          final o = Offset(Field.x0 + 20 + rnd.nextDouble() * 296, Field.y0 + 40 + rnd.nextDouble() * 460);
          c.drawPath(Path()..moveTo(o.dx, o.dy - 6)..lineTo(o.dx + 4, o.dy)..lineTo(o.dx, o.dy + 7)..lineTo(o.dx - 3, o.dy)..close(), Paint()..color = const Color(0x40DDEBFF));
        }
        _treeLine(c, rnd, [const Color(0x40566A9A), const Color(0x59384A78), const Color(0x80202C50)]);
      case 3:
        final cave = Path()..moveTo(Field.x0, Field.y0);
        for (var x = Field.x0; x <= Field.x1; x += 18) {
          cave.lineTo(x + 9, Field.y0 + 14 + rnd.nextDouble() * 34);
          cave.lineTo(x + 18, Field.y0);
        }
        c.drawPath(cave, Paint()..color = const Color(0xCC120A28));
        for (var i = 0; i < 14; i++) {
          final left = i.isEven;
          final x = left ? Field.x0 + rnd.nextDouble() * 40 : Field.x1 - rnd.nextDouble() * 40;
          final y = Field.y1 - rnd.nextDouble() * 260;
          _crystal(c, Offset(x, y), 10 + rnd.nextDouble() * 18, rnd.nextBool() ? const Color(0xFFB38CFF) : const Color(0xFF7EF0FF), (left ? 0.3 : -0.3) + (rnd.nextDouble() - 0.5) * 0.5);
        }
        _treeLine(c, rnd, [const Color(0x402A1A5A), const Color(0x66201444), const Color(0x99140C30)]);
      case 4:
        for (var layer = 0; layer < 3; layer++) {
          final p = Path()..moveTo(Field.x0, Field.y1);
          for (var x = Field.x0; x <= Field.x1 + 40; x += 40) {
            p.lineTo(x, (Field.y1 - 150 + layer * 45) + (rnd.nextDouble() - 0.5) * 70);
          }
          p
            ..lineTo(Field.x1, Field.y1)
            ..close();
          c.drawPath(p, Paint()..color = [const Color(0x4D1E3A5A), const Color(0x73142A46), const Color(0xA60A1830)][layer]);
        }
        for (var i = 0; i < 6; i++) {
          final o = Offset(Field.x0 + 18 + rnd.nextDouble() * 300, Field.y0 + 60 + rnd.nextDouble() * 380);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 10, height: 14), const Radius.circular(3)), Paint()..color = const Color(0x332A4A6A));
          c.drawLine(o.translate(-2, -3), o.translate(2, 3), Paint()..color = const Color(0x557EF0FF)..strokeWidth = 1);
        }
      default:
        c.drawPath(
          Path()
            ..moveTo(Field.x0, Field.y0 + 380)
            ..quadraticBezierTo(180, 160, Field.x1, Field.y0 + 60)
            ..lineTo(Field.x1, Field.y0 + 140)
            ..quadraticBezierTo(180, 260, Field.x0, Field.y0 + 460)
            ..close(),
          Paint()..color = const Color(0x22B9A4FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );
        for (var i = 0; i < 160; i++) {
          final t = rnd.nextDouble();
          final o = Offset(Field.x0 + t * 336, Field.y0 + 380 - t * 300 + (rnd.nextDouble() - 0.5) * 90);
          c.drawCircle(o, rnd.nextDouble() * 1.1 + 0.2, Paint()..color = Color.fromRGBO(255, 240, 210, 0.2 + rnd.nextDouble() * 0.6));
        }
        for (final isl in const [Offset(50, 520), Offset(310, 470)]) {
          c.drawPath(Path()..moveTo(isl.dx - 34, isl.dy)..lineTo(isl.dx + 34, isl.dy)..lineTo(isl.dx + 8, isl.dy + 40)..lineTo(isl.dx - 10, isl.dy + 30)..close(), Paint()..color = const Color(0xCC0C0A24));
          c.drawRect(Rect.fromLTWH(isl.dx - 34, isl.dy - 3, 68, 4), Paint()..color = const Color(0x66FFD36B));
        }
    }
  }

  void _moon(Canvas c, Offset o, double r, Color glow) {
    c.drawCircle(o, r * 3, Paint()..shader = ui.Gradient.radial(o, r * 3, [glow.withValues(alpha: 0.22), glow.withValues(alpha: 0)]));
    c.drawCircle(o, r, Paint()..shader = ui.Gradient.radial(o.translate(-r * 0.3, -r * 0.3), r * 1.3, [const Color(0xFFFFF6D8), const Color(0xFFF2D9A0)]));
    c.drawCircle(o.translate(r * 0.3, r * 0.1), r * 0.18, Paint()..color = const Color(0x22A07840));
    c.drawCircle(o.translate(-r * 0.35, r * 0.35), r * 0.12, Paint()..color = const Color(0x22A07840));
  }

  void _treeLine(Canvas c, math.Random rnd, List<Color> layers) {
    for (var layer = 0; layer < 3; layer++) {
      final baseY = Field.y1 - 40 + layer * 18;
      final p = Path()..moveTo(Field.x0, Field.y1);
      for (var px = Field.x0; px <= Field.x1 + 30; px += 28 + layer * 6) {
        final h = 50 + rnd.nextDouble() * 70 - layer * 14;
        p
          ..lineTo(px, baseY - h * 0.4)
          ..lineTo(px + 10, baseY - h)
          ..lineTo(px + 22, baseY - h * 0.4);
      }
      p
        ..lineTo(Field.x1, Field.y1)
        ..close();
      c.drawPath(p, Paint()..color = layers[layer]);
    }
  }

  void _sideTrees(Canvas c, math.Random rnd, Color col) {
    for (final left in const [true, false]) {
      final x = left ? Field.x0 - 6 : Field.x1 + 6;
      c.drawPath(Path()..moveTo(x, Field.y1)..quadraticBezierTo(x + (left ? 16 : -16), 380, x + (left ? 4 : -4), Field.y0 + 40), Paint()..color = col..strokeWidth = 18..style = PaintingStyle.stroke);
      for (var i = 0; i < 6; i++) {
        final y = Field.y0 + 50 + i * 55 + rnd.nextDouble() * 20;
        c.drawCircle(Offset(x + (left ? 18 : -18) + (rnd.nextDouble() - 0.5) * 16, y), 22 + rnd.nextDouble() * 12, Paint()..color = col);
      }
    }
  }

  void _crystal(Canvas c, Offset o, double h, Color col, double tilt) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(tilt);
    final p = Path()..moveTo(0, -h)..lineTo(h * 0.28, -h * 0.55)..lineTo(h * 0.22, 0)..lineTo(-h * 0.22, 0)..lineTo(-h * 0.28, -h * 0.55)..close();
    c.drawPath(p, Paint()..color = col.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawPath(p, Paint()..shader = ui.Gradient.linear(Offset(0, -h), Offset.zero, [col.withValues(alpha: 0.95), col.withValues(alpha: 0.35)]));
    c.drawLine(Offset(0, -h), Offset(0, -h * 0.1), Paint()..color = const Color(0x66FFFFFF)..strokeWidth = 1);
    c.restore();
  }

  /// 움직이는 분위기 요소 (상태 없이 시간으로 계산)
  void _ambient(Canvas c) {
    if (Profile.instance.reduceMotion) return;
    final t = g.clock;
    final w = g.level.world;
    if (w == 4) {
      for (var k = 0; k < 2; k++) {
        final p = Path()..moveTo(Field.x0, Field.y0 + 90 + k * 40);
        for (var x = Field.x0; x <= Field.x1; x += 12) {
          p.lineTo(x, Field.y0 + 90 + k * 40 + math.sin(x / 40 + t * 0.6 + k) * 18);
        }
        c.drawPath(p, Paint()..color = (k == 0 ? const Color(0x338DFFB5) : const Color(0x26B38CFF))..strokeWidth = 26..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      }
    }
    if (w == 5) {
      final ph = (t * 0.25) % 1;
      if (ph < 0.25) {
        final k = ph / 0.25;
        final a = Offset(Field.x1 - 20 - k * 220, Field.y0 + 30 + k * 120);
        c.drawLine(a, a.translate(40, -22), Paint()..shader = ui.Gradient.linear(a, a.translate(40, -22), [const Color(0xCCFFF4D0), const Color(0x00FFF4D0)])..strokeWidth = 2);
      }
    }
    final col = theme.glow;
    for (var i = 0; i < 14; i++) {
      final fx = Field.x0 + 20 + ((i * 97.3) % 296) + math.sin(t * 0.5 + i * 1.7) * 14;
      final fy = Field.y0 + 60 + ((i * 151.7) % 480) + math.cos(t * 0.4 + i) * 12 - (w == 2 ? (t * 6 + i * 30) % 60 : 0);
      final a = (0.25 + 0.35 * math.sin(t * 2 + i * 2.3)).clamp(0.0, 1.0);
      c.drawCircle(Offset(fx, fy), 3.5, Paint()..color = col.withValues(alpha: a * 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      c.drawCircle(Offset(fx, fy), 1.2, Paint()..color = col.withValues(alpha: a));
    }
  }

  void _wall(Canvas c, double x1, double y1, double x2, double y2, String k, bool edge, math.Random rnd) {
    final a = Offset(x1, y1), b = Offset(x2, y2);
    final tile = _art.image(k == 'w' ? 'tile/wood' : 'tile/moss');
    if (tile != null) {
      c.drawArtStrip(tile, a, b, k == 'w' ? (edge ? 13 : 12) : 15);
      return;
    }
    if (k == 'w') {
      c.drawLine(a, b, Paint()..color = const Color(0x66000000)..strokeWidth = edge ? 13 : 12..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      c.drawLine(a, b, Paint()..color = const Color(0xFF4A2C1A)..strokeWidth = edge ? 11 : 10..strokeCap = StrokeCap.round);
      c.drawLine(a, b, Paint()..color = const Color(0xFF8A5A3B)..strokeWidth = edge ? 7 : 6.5..strokeCap = StrokeCap.round);
      final nx = -(y2 - y1), ny = x2 - x1, l = math.max(1.0, math.sqrt(nx * nx + ny * ny));
      final off = Offset(-nx / l * 1.5, -ny / l * 1.5);
      c.drawLine(a + off, b + off, Paint()..color = const Color(0xBFE8AA6E)..strokeWidth = 1.6..strokeCap = StrokeCap.round);
      final len = (b - a).distance;
      for (var d = 18.0; d < len - 8; d += 26 + rnd.nextDouble() * 20) {
        c.drawCircle(Offset.lerp(a, b, d / len)!, 1.4, Paint()..color = const Color(0x994A2C1A));
      }
    } else {
      c.drawLine(a, b, Paint()..color = const Color(0x996FD39B)..strokeWidth = 14..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      c.drawLine(a, b, Paint()..color = const Color(0xFF1D5139)..strokeWidth = 12..strokeCap = StrokeCap.round);
      final len = (b - a).distance, n = math.max(2, len ~/ 6);
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        c.drawCircle(Offset(x1 + (x2 - x1) * t + (rnd.nextDouble() - 0.5) * 6, y1 + (y2 - y1) * t + (rnd.nextDouble() - 0.5) * 6), 2 + rnd.nextDouble() * 2.6,
            Paint()..color = (rnd.nextBool() ? const Color(0xFF3FA36B) : const Color(0xFF6FD39B)).withValues(alpha: 0.8));
      }
      for (var i = 0; i < n ~/ 3; i++) {
        final t = rnd.nextDouble();
        c.drawCircle(Offset(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t), 1, Paint()..color = const Color(0xCCE6FFF0));
      }
    }
  }

  void _block(Canvas c, BlockDef b, math.Random rnd) {
    final rect = Rect.fromLTWH(b.x, b.y, b.w, b.h);
    final img = _art.image(b.k == 'w' ? 'tile/wood_block' : 'tile/moss_block');
    c.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(0, 4)), const Radius.circular(8)), Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    if (img != null) {
      c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), rect, Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    if (b.k == 'w') {
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      c.drawRRect(rr, Paint()..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [const Color(0xFFA36B45), const Color(0xFF5E3A24)]));
      c.drawRRect(rr, Paint()..color = const Color(0xFF3D2414)..style = PaintingStyle.stroke..strokeWidth = 2);
      c.drawLine(rect.topLeft.translate(5, 2), rect.topRight.translate(-5, 2), Paint()..color = const Color(0x66FFD7A8)..strokeWidth = 1.2);
      for (var i = 1; i < 3; i++) {
        c.drawLine(Offset(b.x + 6, b.y + b.h * i / 3), Offset(b.x + b.w - 6, b.y + b.h * i / 3 + (rnd.nextDouble() - 0.5) * 3), Paint()..color = const Color(0x40FFC88C)..strokeWidth = 1);
      }
    } else {
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      c.drawRRect(rr.inflate(2), Paint()..color = const Color(0x736FD39B)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawRRect(rr, Paint()..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [const Color(0xFF2F7A52), const Color(0xFF174130)]));
      for (var i = 0; i < b.w / 5; i++) {
        c.drawCircle(Offset(b.x + 3 + rnd.nextDouble() * (b.w - 6), b.y + rnd.nextDouble() * 5), 2 + rnd.nextDouble() * 2.5, Paint()..color = (rnd.nextBool() ? const Color(0xFF6FD39B) : const Color(0xFF3FA36B)).withValues(alpha: 0.85));
      }
      for (var i = 0; i < b.w * b.h / 260; i++) {
        c.drawCircle(Offset(b.x + rnd.nextDouble() * b.w, b.y + rnd.nextDouble() * b.h), 0.9, Paint()..color = const Color(0x55CCFFE0));
      }
    }
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p, double on, double off, {double phase = 0}) {
    final len = (b - a).distance;
    if (len < 1) return;
    final d = (b - a) / len;
    var s = -(phase % (on + off));
    while (s < len) {
      final s0 = math.max(0.0, s), s1 = math.min(len, s + on);
      if (s1 > s0) c.drawLine(a + d * s0, a + d * s1, p);
      s += on + off;
    }
  }

  // ---------------- 동적 요소 ----------------
  void _gates(Canvas c, double t) {
    final run = g.run;
    final img = _art.image('device/gate');
    for (var i = 0; i < run.c.gates.length; i++) {
      final gt = run.c.gates[i];
      final open = t < run.gateOpen[i];
      final v = g.gateVis[i];
      final m = Offset((gt.x1 + gt.x2) / 2, (gt.y1 + gt.y2) / 2);
      final a = Offset(gt.x1, gt.y1), b = Offset(gt.x2, gt.y2);
      for (final o in [a, b]) {
        c.drawCircle(o, 7, Paint()..color = const Color(0xFF3A2470));
        c.drawCircle(o, 5, Paint()..color = Palette.violet);
      }
      if (v < 0.98) {
        final half = 1 - v;
        final pa = Offset.lerp(a, m, half)!, pb = Offset.lerp(b, m, half)!;
        if (img != null) {
          c.drawArtStrip(img, a, pa, 10);
          c.drawArtStrip(img, b, pb, 10);
        } else {
          final glow = Paint()..color = const Color(0xFF7D55E0).withValues(alpha: 0.95 * half + 0.05)..strokeWidth = 9..strokeCap = StrokeCap.round;
          c.drawLine(a, pa, Paint()..color = const Color(0x99B38CFF)..strokeWidth = 16..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
          c.drawLine(b, pb, Paint()..color = const Color(0x99B38CFF)..strokeWidth = 16..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
          c.drawLine(a, pa, glow);
          c.drawLine(b, pb, glow);
          final dash = Paint()..color = const Color(0xFFE6D8FF)..strokeWidth = 2;
          _dashed(c, a, pa, dash, 5, 6, phase: g.clock * 20);
          _dashed(c, b, pb, dash, 5, 6, phase: g.clock * 20);
        }
      }
      if (open) {
        final frac = ((run.gateOpen[i] - t) / g.level.gates[i].dur).clamp(0.0, 1.0);
        _dashed(c, a, b, Paint()..color = const Color(0x59B38CFF)..strokeWidth = 2, 3, 5);
        final ring = Rect.fromCircle(center: m + const Offset(0, 16), radius: 8);
        c.drawCircle(ring.center, 10, Paint()..color = const Color(0xCC1A1240));
        c.drawArc(ring, -math.pi / 2, math.pi * 2 * frac, false, Paint()..color = const Color(0xFFE6D8FF)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
      }
    }
  }

  void _devices(Canvas c) {
    final l = g.level, run = g.run;
    final bumperImg = _art.image('device/bumper');
    for (final u in l.bumpers) {
      final o = Offset(u.x, u.y);
      c.drawOval(Rect.fromCenter(center: o.translate(0, u.r * 0.9), width: u.r * 1.8, height: u.r * 0.5), Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      if (bumperImg != null) {
        c.drawArt(bumperImg, o, Size.square(u.r * 2.3));
        continue;
      }
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(u.x - u.r * 0.35, u.y, u.r * 0.7, u.r * 0.9), const Radius.circular(4)), Paint()..color = const Color(0xFFE8D9C8));
      c.drawCircle(o, u.r + 3, Paint()..color = const Color(0x80FF7896)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawCircle(o, u.r, Paint()..shader = ui.Gradient.radial(o + Offset(-u.r * 0.3, -u.r * 0.4), u.r * 1.2, [const Color(0xFFFF9FB4), const Color(0xFFC2365A)]));
      for (final d in const [(-0.4, -0.35, 0.2), (0.35, -0.2, 0.16), (0.0, 0.35, 0.14), (-0.2, 0.15, 0.1)]) {
        c.drawCircle(o + Offset(d.$1 * u.r, d.$2 * u.r), d.$3 * u.r, Paint()..color = const Color(0xE6FFF0F0));
      }
      c.drawArc(Rect.fromCircle(center: o, radius: u.r - 3), -2.6, 1.2, false, Paint()..color = const Color(0x99FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    }
    final iceImg = _art.image('tile/ice');
    var iceIdx = 0;
    for (final b in l.blocks) {
      if (b.k != 'i') continue;
      final i = iceIdx++;
      if (run.ice[i]) continue;
      final rect = Rect.fromLTWH(b.x, b.y, b.w, b.h), rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      c.drawRRect(rr.inflate(2), Paint()..color = const Color(0x809FE8FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      if (iceImg != null) {
        c.drawImageRect(iceImg, Rect.fromLTWH(0, 0, iceImg.width.toDouble(), iceImg.height.toDouble()), rect, Paint()..filterQuality = FilterQuality.medium);
        continue;
      }
      c.drawRRect(rr, Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [const Color(0xE6D2F8FF), const Color(0xBF6EC8FF)]));
      final line = Paint()..color = const Color(0xCCFFFFFF)..strokeWidth = 1..style = PaintingStyle.stroke;
      c.drawRRect(rr, line);
      c.drawLine(Offset(b.x + b.w * 0.2, b.y + 2), Offset(b.x + b.w * 0.35, b.y + b.h - 2), line);
      c.drawLine(Offset(b.x + b.w * 0.6, b.y + 2), Offset(b.x + b.w * 0.52, b.y + b.h * 0.6), line);
      final sh = ((g.clock * 0.4) % 1.6) - 0.3;
      if (sh > 0 && sh < 1) c.drawRect(Rect.fromLTWH(b.x + sh * b.w, b.y + 1, 4, b.h - 2), Paint()..color = const Color(0x99FFFFFF));
    }
    for (final p in l.portals) {
      for (final e in [(p.ax, p.ay, const Color(0xFFFF9F5A), 1.0, 'device/portal_a'), (p.bx, p.by, const Color(0xFF5AB8FF), -1.0, 'device/portal_b')]) {
        final o = Offset(e.$1, e.$2);
        c.drawCircle(o, kPortalR + 8, Paint()..color = e.$3.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        final img = _art.image(e.$5);
        if (img != null) {
          c.drawArt(img, o, const Size.square((kPortalR + 6) * 2), rotation: g.clock * 1.5 * e.$4);
          continue;
        }
        c.drawCircle(o, kPortalR + 3, Paint()..shader = ui.Gradient.radial(o, kPortalR + 3, [const Color(0xF20A0A1E), const Color(0xCC0A0A1E), e.$3], [0, 0.7, 1]));
        for (var k = 0; k < 3; k++) {
          c.drawArc(Rect.fromCircle(center: o, radius: kPortalR - 2 - k * 4), k + g.clock * 3 * e.$4, 2.2, false, Paint()..color = e.$3..style = PaintingStyle.stroke..strokeWidth = 2);
        }
      }
    }
    final prismImg = _art.image('device/prism');
    for (final x in l.prisms) {
      final bob = math.sin(g.clock * 1.6) * 2;
      if (prismImg != null) {
        c.drawCircle(Offset(x.x, x.y + bob), kPrismR + 8, Paint()..color = const Color(0x55FFFFFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
        c.drawArt(prismImg, Offset(x.x, x.y + bob), const Size.square((kPrismR + 6) * 2), rotation: math.sin(g.clock) * 0.15);
        continue;
      }
      c.save();
      c.translate(x.x, x.y + bob);
      c.rotate(math.sin(g.clock) * 0.15);
      const r = kPrismR + 3;
      final path = Path()..moveTo(0, -r)..lineTo(r * 0.8, 0)..lineTo(0, r)..lineTo(-r * 0.8, 0)..close();
      c.drawPath(path, Paint()..color = const Color(0x99FFFFFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      c.drawPath(path, Paint()..shader = ui.Gradient.linear(const Offset(-r, -r), const Offset(r, r), const [Color(0xFFFF7A8A), Color(0xFFFFD36B), Color(0xFF8DFFB5), Color(0xFF7EF0FF), Color(0xFFB9A4FF)], const [0, 0.25, 0.5, 0.75, 1]));
      c.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
      c.restore();
    }
    final mirrorImg = _art.image('device/mirror');
    for (var i = 0; i < l.mirrors.length; i++) {
      final m = l.mirrors[i], sg = run.mseg[i];
      var ang = math.atan2(sg.y2 - sg.y1, sg.x2 - sg.x1);
      final spin = g.mirrorSpin;
      if (spin != null && spin.$1 == i) ang -= (1 - Curves.easeOutBack.transform(math.min(1.0, spin.$2))) * math.pi / 4;
      c.save();
      c.translate(m.x, m.y);
      if (m.rot) {
        final ring = Paint()..color = const Color(0x59C8DCFF)..style = PaintingStyle.stroke..strokeWidth = 1.5;
        final rr = m.len / 2 + 6;
        for (var k = 0; k < 16; k++) {
          c.drawArc(Rect.fromCircle(center: Offset.zero, radius: rr), k * math.pi / 8 + g.clock * 0.3, math.pi / 16, false, ring);
        }
        if (g.mode == Mode.aim) {
          final pulse = 0.5 + 0.5 * math.sin(g.clock * 3);
          c.drawCircle(Offset.zero, rr + 2, Paint()..color = Palette.moon.withValues(alpha: 0.14 * pulse)..style = PaintingStyle.stroke..strokeWidth = 4);
          _label(c, 'TAP', 0, m.len / 2 + 10, const Color(0xBFC8DCFF), 9, num: true);
        }
      }
      c.rotate(ang);
      final rect = Rect.fromCenter(center: Offset.zero, width: m.len, height: 7);
      c.drawRRect(RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(6)), Paint()..color = const Color(0x80DFF3FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      if (mirrorImg != null) {
        c.drawImageRect(mirrorImg, Rect.fromLTWH(0, 0, mirrorImg.width.toDouble(), mirrorImg.height.toDouble()), rect.inflate(2), Paint()..filterQuality = FilterQuality.medium);
      } else {
        c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3.5)), Paint()..shader = ui.Gradient.linear(const Offset(0, -4), const Offset(0, 4), [Colors.white, const Color(0xFFA9C4E8), const Color(0xFF5D7AA8)], [0, 0.5, 1]));
      }
      c.drawCircle(Offset.zero, 4, Paint()..color = m.rot ? Palette.moon : const Color(0xFF6B7BB0));
      final sh = ((g.clock * 0.6) % 1.4) - 0.2;
      if (sh > 0 && sh < 1) c.drawRect(Rect.fromLTWH(-m.len / 2 + sh * m.len - 3, -3, 6, 6), Paint()..color = const Color(0xCCFFFFFF));
      c.restore();
    }
  }

  void _switches(Canvas c, double t) {
    for (final sw in g.level.switches) {
      final lit = sw.gates.any((gi) => t < g.run.gateOpen[gi]);
      final o = Offset(sw.x, sw.y);
      c.drawCircle(o, kSwitchR + (lit ? 10 : 4), Paint()..color = Palette.echo.withValues(alpha: lit ? 0.6 : 0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      final img = _art.image(lit ? 'device/switch_on' : 'device/switch_off');
      if (img != null) {
        c.drawArt(img, o, const Size.square((kSwitchR + 6) * 2));
        continue;
      }
      c.drawCircle(o, kSwitchR + 2, Paint()..color = const Color(0xFF0A1830));
      c.drawCircle(o, kSwitchR, Paint()..color = lit ? const Color(0xE67EF0FF) : const Color(0xE6142846));
      final ring = Paint()..color = Palette.echo..style = PaintingStyle.stroke..strokeWidth = 2;
      for (var k = 0; k < 8; k++) {
        c.drawArc(Rect.fromCircle(center: o, radius: kSwitchR + 5), k * math.pi / 4 + g.clock * (lit ? 3 : 0.8), math.pi / 8, false, ring);
      }
      c.drawPath(Path()..moveTo(sw.x, sw.y - 6)..lineTo(sw.x + 5.5, sw.y + 4)..lineTo(sw.x - 5.5, sw.y + 4)..close(), Paint()..color = lit ? const Color(0xFF073040) : Palette.echo);
    }
  }

  // ---------------- 정령 ----------------
  void _targets(Canvas c, double t) {
    final l = g.level;
    for (var i = 0; i < l.targets.length; i++) {
      final tg = l.targets[i];
      var (x, y) = tg.pos(t);
      final hit = g.run.hit[i], av = tg.avoid;
      final woke = g.wakeAt[i];
      final wk = woke == null ? 1.0 : ((g.clock - woke) / 0.6).clamp(0.0, 1.0);
      final breathe = hit ? 1.0 : 1 + math.sin(g.clock * 2.2 + i) * 0.04;
      var bob = hit ? math.sin(g.clock * 3 + i) * 1.5 : math.sin(g.clock * 1.6 + i) * 2.5;
      // 클리어 후 정령들이 하늘로 날아오름
      var fly = 0.0;
      if (g.winAt > 0 && hit && !av && g.mode != Mode.replay) {
        final k = ((g.clock - g.winAt - 0.35) / 1.4).clamp(0.0, 1.0);
        fly = Curves.easeInCubic.transform(k);
        y -= fly * 260;
        x += math.sin(k * 6 + i) * 10 * k;
        bob = 0;
      }
      final pop = hit ? (wk < 0.35 ? 1 + Curves.easeOut.transform(wk / 0.35) * 0.4 : 1.4 - Curves.elasticOut.transform((wk - 0.35) / 0.65) * 0.32) : 1.0;
      final r = kTargetR * (av ? 0.85 : 1) * breathe * pop;
      final o = Offset(x, y + bob);
      final alpha = (1 - fly * 0.9).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;
      if (fly == 0) c.drawOval(Rect.fromCenter(center: Offset(x, y + kTargetR + 8), width: r * 1.6, height: 5), Paint()..color = Color.fromRGBO(0, 0, 0, 0.25 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      final glowCol = av ? Palette.blossom : (hit ? Palette.moon : const Color(0xFF8FD6FF));
      c.drawCircle(o, r + (hit ? 12 : 6), Paint()..color = glowCol.withValues(alpha: 0.5 * alpha)..maskFilter = MaskFilter.blur(BlurStyle.normal, hit ? 12 : 7));
      if (hit && wk < 1) c.drawCircle(o, r + 6 + wk * 26, Paint()..color = glowCol.withValues(alpha: (1 - wk) * 0.8)..style = PaintingStyle.stroke..strokeWidth = 3 * (1 - wk) + 0.5);
      if (fly > 0) {
        c.drawLine(o, o.translate(0, 30 * fly + 10), Paint()..shader = ui.Gradient.linear(o, o.translate(0, 40), [glowCol.withValues(alpha: 0.6 * alpha), glowCol.withValues(alpha: 0)])..strokeWidth = r * 1.2..strokeCap = StrokeCap.round);
      }
      final img = _art.image(av ? (hit ? 'spirit/baby_cry' : 'spirit/baby_sleep') : (hit ? 'spirit/awake' : 'spirit/sleep'));
      if (img != null) {
        c.drawArt(img, o, Size.square(r * 2.6), opacity: alpha);
      } else {
        _spiritVector(c, o, r, i, hit, av, alpha);
      }
      if (tg.shield != null && !hit) {
        final sImg = _art.image('spirit/shield');
        if (sImg != null) {
          c.drawArt(sImg, o + Offset.fromDirection(tg.shield! * kD2R, r * 0.9), Size(r * 1.4, r * 2.4), rotation: tg.shield! * kD2R);
        } else {
          c.save();
          c.translate(o.dx, o.dy);
          c.rotate(tg.shield! * kD2R);
          c.drawArc(Rect.fromCircle(center: Offset.zero, radius: r + 6), -1.2, 2.4, false, Paint()..color = const Color(0x80C9D6FF)..strokeWidth = 9..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          c.drawArc(Rect.fromCircle(center: Offset.zero, radius: r + 6), -1.2, 2.4, false, Paint()..shader = ui.Gradient.linear(Offset(r, -r), Offset(r, r), [const Color(0xFFFFFFFF), const Color(0xFF9FB2E8)])..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
          c.restore();
        }
      }
      if (!hit && !av) {
        final zt = (g.clock * 0.6 + i * 0.3) % 1;
        _label(c, 'z', x + 10 + zt * 8, y - 22 - zt * 16, const Color(0xFFCFE6FF).withValues(alpha: 1 - zt), 9 + zt * 6, num: true);
      }
    }
  }

  void _spiritVector(Canvas c, Offset o, double r, int i, bool hit, bool av, double alpha) {
    c.save();
    c.translate(o.dx, o.dy);
    final cols = av ? [const Color(0xFFFFF0F6), hit ? const Color(0xFFFF3D6E) : const Color(0xFFFF8FB8)] : hit ? [const Color(0xFFFFFBE6), const Color(0xFFFFBF3F)] : [const Color(0xFFF2FDFF), const Color(0xFF6FB7FF)];
    final ear = Paint()..color = (av ? const Color(0xFFFFB3CF) : (hit ? const Color(0xFFFFCF5A) : const Color(0xFF9FDCFF))).withValues(alpha: alpha);
    final earWiggle = hit ? math.sin(g.clock * 10 + i) * 0.15 : math.sin(g.clock * 1.3 + i) * 0.06;
    final s = r / kTargetR;
    for (final sgn in const [-1.0, 1.0]) {
      c.save();
      c.translate(7 * sgn * s, -r + 1);
      c.rotate((0.5 + earWiggle) * sgn);
      c.drawOval(const Rect.fromLTWH(-3, -7, 6, 13), ear);
      c.drawOval(const Rect.fromLTWH(-1.2, -5, 2.4, 8), Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 * alpha));
      c.restore();
    }
    c.drawCircle(Offset.zero, r, Paint()..shader = ui.Gradient.radial(const Offset(-4, -5), r * 1.3, [cols[0].withValues(alpha: alpha), cols[1].withValues(alpha: alpha)]));
    c.drawCircle(Offset(-r * 0.35, -r * 0.4), r * 0.22, Paint()..color = Color.fromRGBO(255, 255, 255, 0.55 * alpha));
    if (av && !hit) {
      c.drawCircle(Offset(0, -r - 7), 4.5, Paint()..color = Colors.white.withValues(alpha: alpha));
      final no = Paint()..color = const Color(0xFFFF5A86).withValues(alpha: alpha)..strokeWidth = 1.6..style = PaintingStyle.stroke;
      c.drawCircle(Offset(0, -r - 7), 4.5, no);
      c.drawLine(Offset(-3, -r - 10), Offset(3, -r - 4), no);
    }
    final face = Paint()..color = const Color(0xFF1B2456).withValues(alpha: alpha)..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    if (hit && av) {
      for (final ex in const [-5.0, 5.0]) {
        c.drawLine(Offset((ex - 2) * s, -3 * s), Offset((ex + 2) * s, 1 * s), face);
        c.drawLine(Offset((ex + 2) * s, -3 * s), Offset((ex - 2) * s, 1 * s), face);
      }
      c.drawArc(Rect.fromCircle(center: Offset(0, 6 * s), radius: 3 * s), math.pi, math.pi, false, face);
      final tear = (g.clock * 2) % 1;
      c.drawCircle(Offset(-6 * s, (2 + tear * 8) * s), 1.6, Paint()..color = const Color(0xFF9FDCFF).withValues(alpha: alpha * (1 - tear)));
    } else if (hit) {
      for (final ex in const [-4.5, 4.5]) {
        c.drawPath(Path()..moveTo((ex - 2.5) * s, 0)..lineTo(ex * s, -3 * s)..lineTo((ex + 2.5) * s, 0), face);
      }
      c.drawArc(Rect.fromCircle(center: Offset(0, 3 * s), radius: 3.2 * s), 0, math.pi, false, face);
      c.drawCircle(Offset(-8 * s, 4 * s), 2.4 * s, Paint()..color = Color.fromRGBO(255, 140, 120, 0.5 * alpha));
      c.drawCircle(Offset(8 * s, 4 * s), 2.4 * s, Paint()..color = Color.fromRGBO(255, 140, 120, 0.5 * alpha));
    } else {
      final peek = ((g.clock + i * 1.37) % 5.0) < 0.18;
      for (final ex in const [-4.5, 4.5]) {
        if (peek) {
          c.drawCircle(Offset(ex * s, -1 * s), 1.4 * s, Paint()..color = const Color(0xFF1B2456).withValues(alpha: alpha));
        } else {
          c.drawArc(Rect.fromCircle(center: Offset(ex * s, -1 * s), radius: 2.4 * s), 0.1, math.pi - 0.2, false, face);
        }
      }
      c.drawCircle(Offset(-8 * s, 4 * s), 2.4 * s, Paint()..color = Color.fromRGBO(255, 140, 170, 0.45 * alpha));
      c.drawCircle(Offset(8 * s, 4 * s), 2.4 * s, Paint()..color = Color.fromRGBO(255, 140, 170, 0.45 * alpha));
    }
    c.restore();
  }

  // ---------------- 화살 ----------------
  Color _shotColor(int idx) {
    if (idx == g.curIdx) {
      return switch (Profile.instance.trail) { 'ember' => const Color(0xFFFF8A4C), 'aurora' => const Color(0xFF9DFFCB), _ => Palette.shot[0] };
    }
    return Palette.shot[1 + idx % 5];
  }

  void _arrowShape(Canvas c, double x, double y, double ang, Color col, double alpha, bool glow) {
    final img = _art.image('char/arrow');
    if (img != null) {
      if (glow) c.drawCircle(Offset(x, y), 9, Paint()..color = col.withValues(alpha: 0.5 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawArt(img, Offset(x - math.cos(ang) * 10, y - math.sin(ang) * 10), const Size(28, 7), rotation: ang, opacity: alpha);
      return;
    }
    c.save();
    c.translate(x, y);
    c.rotate(ang);
    if (glow) {
      c.drawLine(const Offset(-20, 0), Offset.zero, Paint()..color = col.withValues(alpha: 0.6 * alpha)..strokeWidth = 8..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawCircle(const Offset(2, 0), 5, Paint()..color = Colors.white.withValues(alpha: 0.5 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    c.drawLine(const Offset(-20, 0), Offset.zero, Paint()..color = col.withValues(alpha: alpha)..strokeWidth = 2.4..strokeCap = StrokeCap.round);
    c.drawLine(const Offset(-18, 0), const Offset(-2, 0), Paint()..color = Colors.white.withValues(alpha: 0.6 * alpha)..strokeWidth = 0.8);
    c.drawPath(Path()..moveTo(5, 0)..lineTo(-5, -4.8)..lineTo(-3, 0)..lineTo(-5, 4.8)..close(), Paint()..color = col.withValues(alpha: alpha));
    c.drawPath(Path()..moveTo(-17, 0)..lineTo(-24, -4.5)..lineTo(-20, 0)..lineTo(-24, 4.5)..close(), Paint()..color = col.withValues(alpha: alpha * 0.85));
    c.restore();
  }

  void _arrows(Canvas c) {
    for (final a in g.run.arrows) {
      final tr = a.trail;
      if (tr.length < 4) continue;
      final col = _shotColor(a.idx);
      if (g.trailsFull) {
        final path = Path()..moveTo(tr[0], tr[1]);
        var jump = false;
        for (var i = 2; i < tr.length; i += 2) {
          if (tr[i].isNaN) {
            jump = true;
            continue;
          }
          if (jump) {
            path.moveTo(tr[i], tr[i + 1]);
            jump = false;
          } else {
            path.lineTo(tr[i], tr[i + 1]);
          }
        }
        c.drawPath(path, Paint()..color = col.withValues(alpha: 0.35)..strokeWidth = 6..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        c.drawPath(path, Paint()..color = col.withValues(alpha: 0.7)..strokeWidth = 2.2..style = PaintingStyle.stroke..blendMode = BlendMode.plus);
      } else {
        final n = tr.length ~/ 2;
        for (var i = 1; i < n; i++) {
          if (tr[i * 2].isNaN || tr[i * 2 - 2].isNaN) continue;
          final k = i / n;
          final p0 = Offset(tr[i * 2 - 2], tr[i * 2 - 1]), p1 = Offset(tr[i * 2], tr[i * 2 + 1]);
          c.drawLine(p0, p1, Paint()..color = col.withValues(alpha: k * (a.alive ? 0.35 : 0.15))..strokeWidth = 4 + k * 6..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          c.drawLine(p0, p1, Paint()..color = col.withValues(alpha: k * (a.alive ? 0.85 : 0.35))..strokeWidth = 1 + k * 3..strokeCap = StrokeCap.round..blendMode = BlendMode.plus);
        }
      }
    }
    for (final a in g.run.arrows) {
      final col = _shotColor(a.idx), mine = a.idx == g.curIdx;
      if (a.alive) {
        _arrowShape(c, a.x, a.y, math.atan2(a.vy, a.vx), col, mine ? 1 : 0.8, true);
      } else if (a.ang != null) {
        _arrowShape(c, a.x, a.y, a.ang!, col, mine ? 0.85 : 0.45, false);
      }
    }
  }

  // ---------------- 궁수 ----------------
  void _archer(Canvas c) {
    final l = g.level;
    final hold = g.mode == Mode.hold;
    final pull = hold ? g.pull.clamp(0.0, 70.0) : 0.0;
    final ang = g.aimAng;
    final since = g.clock - g.fireAt;
    final recoil = since < 0.25 ? math.sin(since / 0.25 * math.pi) * 5 : 0.0;
    final bob = math.sin(g.clock * 2.4) * 1.2;
    final cheer = g.winAt > 0 && g.mode != Mode.replay ? math.max(0.0, math.sin((g.clock - g.winAt) * 9)) * 6 : 0.0;
    final base = Offset(l.bowX - math.cos(ang) * recoil, l.bowY - math.sin(ang) * recoil + bob - cheer);
    c.drawOval(Rect.fromCenter(center: Offset(l.bowX, l.bowY + 22), width: 46, height: 10), Paint()..color = const Color(0x55000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    c.drawOval(Rect.fromCenter(center: Offset(l.bowX, l.bowY + 22), width: 54, height: 12), Paint()..color = Palette.moon.withValues(alpha: hold ? 0.25 : 0.12));
    final bodyImg = _art.image(hold ? 'char/archer_draw' : (g.winAt > 0 ? 'char/archer_cheer' : 'char/archer_idle')) ?? _art.image('char/archer_idle');
    if (bodyImg != null) {
      c.drawArt(bodyImg, base.translate(0, -4), const Size(58, 58));
    } else {
      c.save();
      c.translate(base.dx, base.dy);
      c.drawPath(Path()..moveTo(-13, 0)..quadraticBezierTo(-16, 20, -10, 22)..lineTo(10, 22)..quadraticBezierTo(16, 20, 13, 0)..close(), Paint()..color = const Color(0xFF26306E));
      c.drawPath(Path()..moveTo(-8, 18)..lineTo(-3, 22)..lineTo(2, 18)..lineTo(7, 22)..lineTo(10, 22)..lineTo(-10, 22)..close(), Paint()..color = const Color(0xFF1D2558));
      c.drawCircle(const Offset(0, -4), 13, Paint()..shader = ui.Gradient.radial(const Offset(-4, -9), 16, [const Color(0xFF5263C0), const Color(0xFF34419A)]));
      for (final sgn in const [-1.0, 1.0]) {
        c.drawPath(Path()..moveTo(sgn * 4, -15)..lineTo(sgn * 9, -24)..lineTo(sgn * 12, -11)..close(), Paint()..color = const Color(0xFF3B4AA0));
      }
      c.drawOval(const Rect.fromLTWH(-8, -11, 16, 14), Paint()..color = const Color(0xFFFFE9CF));
      final lx = math.cos(ang) * 1.6, ly = math.sin(ang) * 1.2;
      final blink = ((g.clock + 0.7) % 3.6) < 0.12;
      final eye = Paint()..color = const Color(0xFF1B1440);
      if (blink) {
        c.drawLine(Offset(-4 + lx, -4 + ly), Offset(-1 + lx, -4 + ly), eye..strokeWidth = 1.4);
        c.drawLine(Offset(2 + lx, -4 + ly), Offset(5 + lx, -4 + ly), eye);
      } else {
        c.drawCircle(Offset(-2.5 + lx, -4 + ly), 1.8, eye);
        c.drawCircle(Offset(3.5 + lx, -4 + ly), 1.8, eye);
        c.drawCircle(Offset(-2 + lx, -4.6 + ly), 0.6, Paint()..color = Colors.white);
        c.drawCircle(Offset(4 + lx, -4.6 + ly), 0.6, Paint()..color = Colors.white);
      }
      c.drawCircle(const Offset(-6, -1), 1.8, Paint()..color = const Color(0x66FF8CAA));
      c.drawCircle(const Offset(6, -1), 1.8, Paint()..color = const Color(0x66FF8CAA));
      c.drawCircle(const Offset(0, 4), 2.6, Paint()..color = Palette.moon);
      c.drawCircle(const Offset(1.2, 3.4), 2.1, Paint()..color = const Color(0xFF26306E));
      c.restore();
    }
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(ang);
    final bowImg = _art.image('char/bow');
    final bend = pull / 70;
    final rad = 20 - bend * 3;
    if (bowImg != null) {
      c.drawArt(bowImg, const Offset(2, 0), Size(30 - bend * 4, 44 + bend * 2));
    } else {
      final bow = Paint()..color = Palette.moon..strokeWidth = 3.4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      if (hold) c.drawArc(Rect.fromCircle(center: const Offset(-4, 0), radius: rad), -1.15 - bend * 0.2, 2.3 + bend * 0.4, false, Paint()..color = const Color(0x99FFD36B)..strokeWidth = 8..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawArc(Rect.fromCircle(center: const Offset(-4, 0), radius: rad), -1.15 - bend * 0.2, 2.3 + bend * 0.4, false, bow);
      c.drawCircle(Offset(-4 + math.cos(-1.15 - bend * 0.2) * rad, math.sin(-1.15 - bend * 0.2) * rad), 2, Paint()..color = const Color(0xFFFFF3CF));
      c.drawCircle(Offset(-4 + math.cos(1.15 + bend * 0.2) * rad, math.sin(1.15 + bend * 0.2) * rad), 2, Paint()..color = const Color(0xFFFFF3CF));
    }
    final tipX = -4 + math.cos(1.15 + bend * 0.2) * rad, tipY = math.sin(1.15 + bend * 0.2) * rad, sx = tipX - pull * 0.42;
    final twang = since < 0.2 ? math.sin(since * 80) * (1 - since / 0.2) * 3 : 0.0;
    c.drawPath(Path()..moveTo(tipX, -tipY)..lineTo(sx + twang, 0)..lineTo(tipX, tipY), Paint()..color = const Color(0xCCFFFFFF)..strokeWidth = 1.1..style = PaintingStyle.stroke);
    if (g.mode == Mode.aim || hold) {
      _arrowShape(c, sx + 22, 0, 0, g.kind == 'pierce' ? Palette.moss : Palette.moon, 1, hold || g.kind != 'n');
    }
    c.restore();
  }

  // ---------------- 조준선·미리보기·힌트 ----------------
  void _guide(Canvas c) {
    if (g.mode != Mode.hold || g.pull < 22) return;
    final r = g.run.ray(g.aimAng, g.guide, 70, pierce: g.kind == 'pierce');
    final gcol = g.kind == 'pierce' ? Palette.moss : Palette.moon;
    const gap = 10.0;
    final flow = (g.clock * 30) % gap;
    for (var pi = 0; pi < r.paths.length; pi++) {
      final pts = r.paths[pi];
      var d = 0.0;
      for (var i = 1; i < pts.length; i++) {
        final a = Offset(pts[i - 1].$1, pts[i - 1].$2), b = Offset(pts[i].$1, pts[i].$2), len = (b - a).distance;
        final last = pi == r.paths.length - 1 && i == pts.length - 1, first = pi == 0 && i == 1;
        for (var s = (gap - ((d - flow) % gap)) % gap; s < len; s += gap) {
          final t = s / len, fade = last ? 1 - s / len : 1.0;
          c.drawCircle(Offset.lerp(a, b, t)!, first ? 2.4 : 1.9, Paint()..color = (first ? const Color(0xFFFFF4CF) : gcol).withValues(alpha: 0.9 * fade * (first ? 1 : 0.75)));
        }
        d += len;
        if (i < pts.length - 1) {
          c.drawCircle(b, 6, Paint()..color = gcol.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          c.drawCircle(b, 5, Paint()..color = gcol.withValues(alpha: 0.9)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }
      }
    }
    final lp = r.paths.last.last;
    if (r.end == 'm' || r.end == 'g') {
      final x = Paint()..color = const Color(0xE6FF7A8A)..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      c.drawLine(Offset(lp.$1 - 5, lp.$2 - 5), Offset(lp.$1 + 5, lp.$2 + 5), x);
      c.drawLine(Offset(lp.$1 + 5, lp.$2 - 5), Offset(lp.$1 - 5, lp.$2 + 5), x);
    }
  }

  void _echoPreview(Canvas c) {
    if (g.mode != Mode.aim || g.echoPreview.isEmpty) return;
    for (final e in g.echoPreview) {
      final pts = e.pts;
      if (pts.length < 4) continue;
      final p = Paint()..color = Palette.shot[1 + e.idx % 5].withValues(alpha: 0.45)..strokeWidth = 2..strokeCap = StrokeCap.round;
      for (var i = 2; i < pts.length; i += 2) {
        final a = Offset(pts[i - 2], pts[i - 1]), b = Offset(pts[i], pts[i + 1]);
        if ((b - a).distance > 40) continue;
        if (((i ~/ 2) + (g.clock * 8).floor()) % 3 == 0) continue;
        c.drawLine(a, b, p);
      }
    }
    for (var i = 0; i < g.shots.length; i++) {
      final s = g.shots[i];
      final o = Offset(g.level.bowX + math.cos(s.ang) * 42, g.level.bowY + math.sin(s.ang) * 42);
      c.drawCircle(o, 8, Paint()..color = const Color(0xCC0C102E));
      c.drawCircle(o, 8, Paint()..color = Palette.shot[1 + i % 5]..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _label(c, '${i + 1}', o.dx, o.dy - 7, Palette.shot[1 + i % 5], 11, num: true);
    }
  }

  void _hint(Canvas c) {
    final s = g.level.solution;
    if (!g.hintOn || s == null || g.mode != Mode.aim) return;
    final idx = g.shots.length.clamp(0, s.shots.length - 1);
    final r = g.run.ray(s.shots[idx].angDeg * kD2R, 1, 60);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.25 * math.sin(g.clock * 4))..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (final path in r.paths) {
      for (var i = 1; i < path.length; i++) {
        _dashed(c, Offset(path[i - 1].$1, path[i - 1].$2), Offset(path[i].$1, path[i].$2), p, 8, 8, phase: -g.clock * 30);
      }
    }
    if (s.shots[idx].step > 30) _label(c, '${(s.shots[idx].step * kDt).toStringAsFixed(1)}s', g.level.bowX, g.level.bowY - 50, Colors.white70, 11, num: true);
  }

  void _fx(Canvas c) {
    for (final p in g.parts) {
      final k = 1 - p.t / p.life;
      final paint = Paint()..color = Color(p.color).withValues(alpha: k.clamp(0.0, 1.0));
      if (p.confetti) {
        c.save();
        c.translate(p.x, p.y);
        c.rotate(p.rot + p.t * 8);
        c.drawRect(Rect.fromLTWH(-p.size, -p.size / 2, p.size * 2, p.size), paint);
        c.restore();
      } else {
        c.drawCircle(Offset(p.x, p.y), p.size * k + 0.3, paint);
        if (p.size > 2.5) c.drawCircle(Offset(p.x, p.y), p.size * k * 2.2, Paint()..color = Color(p.color).withValues(alpha: 0.25 * k)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }
    for (final r in g.rings) {
      final k = r.t / r.life;
      c.drawCircle(Offset(r.x, r.y), r.r1 * (0.3 + Curves.easeOut.transform(k) * 0.9), Paint()..color = Color(r.color).withValues(alpha: 1 - k)..style = PaintingStyle.stroke..strokeWidth = r.w * (1 - k) + 0.5);
    }
    for (final t in g.texts) {
      final k = t.t / t.life;
      final pop = k < 0.15 ? 0.6 + k / 0.15 * 0.6 : 1.2 - math.min(0.2, k - 0.15);
      final alpha = k > 0.7 ? (1 - k) / 0.3 : 1.0;
      c.save();
      c.translate(t.x, t.y - Curves.easeOut.transform(k) * 26);
      c.scale(pop);
      _label(c, t.text, 0, -t.size / 2, Color(t.color).withValues(alpha: alpha), t.size, outline: true);
      c.restore();
    }
  }

  void _label(Canvas c, String s, double x, double y, Color col, double size, {TextAlign align = TextAlign.center, bool num = false, bool outline = false}) {
    final key = '$s|$size|${col.toARGB32()}|$num|$outline';
    final tp = _tp[key] ??= (TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: num ? Fonts.num : Fonts.ko,
          fontSize: size,
          color: col,
          fontWeight: num ? FontWeight.w600 : FontWeight.normal,
          shadows: outline ? [Shadow(color: const Color(0xFF0A0C28).withValues(alpha: 0.85 * col.a), blurRadius: 3), Shadow(color: const Color(0xFF0A0C28).withValues(alpha: 0.85 * col.a), offset: const Offset(0, 1.5), blurRadius: 1)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout());
    if (_tp.length > 400) _tp.clear();
    final dx = switch (align) { TextAlign.left => 0.0, TextAlign.right => -tp.width, _ => -tp.width / 2 };
    tp.paint(c, Offset(x + dx, y));
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}
