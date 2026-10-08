import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/profile.dart';
import '../app/theme.dart';
import 'controller.dart';
import 'level.dart';
import 'sim.dart';

/// 게임 화면 그리기. 논리 좌표 360×640, 바깥은 화면에 맞춰 늘린다.
class GamePainter extends CustomPainter {
  GamePainter(this.g) : super(repaint: g);
  final GameController g;

  static final Map<int, ui.Picture> _static = {};
  static final Map<String, TextPainter> _tp = {};

  static Rect fit(Size size) {
    final s = math.min(size.width / Field.w, size.height / Field.h);
    final w = Field.w * s, h = Field.h * s;
    return Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = fit(size);
    final s = r.width / Field.w;
    // 화면 전체 바탕
    canvas.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF151B4A), Color(0xFF0F2347), Color(0xFF0B2B33)]).createShader(Offset.zero & size));
    canvas.save();
    canvas.translate(r.left, r.top);
    canvas.scale(s);
    final sx = (_rand() - 0.5) * g.shake, sy = (_rand() - 0.5) * g.shake;
    canvas.save();
    canvas.translate(180 + sx, 320 + sy);
    canvas.scale(g.camZ);
    canvas.translate(-g.camX, -g.camY);
    canvas.drawPicture(_static[g.level.id] ??= _buildStatic(g.level));
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
    // 시간 느려짐 비네트
    if (g.holdVis > 0.01) {
      canvas.drawRect(
        const Rect.fromLTWH(-400, -600, Field.w + 800, Field.h + 1200),
        Paint()..shader = ui.Gradient.radial(const Offset(180, 320), 420, [const Color(0x000A1E3C), Color.fromRGBO(40, 140, 180, 0.45 * g.holdVis)], [0.38, 1]),
      );
    }
    if (g.flash > 0) canvas.drawRect(const Rect.fromLTWH(-400, -600, Field.w + 800, Field.h + 1200), Paint()..color = Color.fromRGBO(255, 248, 220, math.min(0.8, g.flash)));
    // 메아리 시계 / 다시보기 표시
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

  // ---------------- 정적 레이어 ----------------
  ui.Picture _buildStatic(LevelData l) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rnd = math.Random(99 + l.id * 13);
    // 필드
    final field = RRect.fromRectAndRadius(const Rect.fromLTRB(Field.x0, Field.y0, Field.x1, Field.y1), const Radius.circular(10));
    c.drawRRect(field, Paint()..shader = ui.Gradient.linear(const Offset(0, Field.y0), const Offset(0, Field.y1), [const Color(0x8C283478), const Color(0x8C144646)]));
    c.save();
    c.clipRRect(field);
    for (var i = 0; i < 70; i++) {
      c.drawCircle(Offset(Field.x0 + rnd.nextDouble() * 336, Field.y0 + rnd.nextDouble() * 400), rnd.nextDouble() * 1.2 + 0.2, Paint()..color = Color.fromRGBO(207, 224, 255, 0.15 + rnd.nextDouble() * 0.5));
    }
    const layers = [Color(0x591E3C5A), Color(0x73143246), Color(0x990C2632)];
    for (var layer = 0; layer < 3; layer++) {
      final base = Field.y1 - 40 + layer * 18;
      final p = Path()..moveTo(Field.x0, Field.y1);
      for (var px = Field.x0; px <= Field.x1 + 30; px += 28 + layer * 6) {
        final h = 50 + rnd.nextDouble() * 70 - layer * 14;
        p
          ..lineTo(px, base - h * 0.4)
          ..lineTo(px + 10, base - h)
          ..lineTo(px + 22, base - h * 0.4);
      }
      p
        ..lineTo(Field.x1, Field.y1)
        ..close();
      c.drawPath(p, Paint()..color = layers[layer]);
    }
    c.drawCircle(const Offset(180, 300), 260, Paint()..shader = ui.Gradient.radial(const Offset(180, 300), 260, [const Color(0x147EF0FF), const Color(0x007EF0FF)]));
    c.restore();
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
    return rec.endRecording();
  }

  void _wall(Canvas c, double x1, double y1, double x2, double y2, String k, bool edge, math.Random rnd) {
    final a = Offset(x1, y1), b = Offset(x2, y2);
    if (k == 'w') {
      c.drawLine(a, b, Paint()..color = const Color(0xFF4A2C1A)..strokeWidth = edge ? 11 : 10..strokeCap = StrokeCap.round);
      c.drawLine(a, b, Paint()..color = const Color(0xFF8A5A3B)..strokeWidth = edge ? 7 : 6.5..strokeCap = StrokeCap.round);
      final nx = -(y2 - y1), ny = x2 - x1, l = math.max(1.0, math.sqrt(nx * nx + ny * ny));
      final off = Offset(-nx / l * 1.5, -ny / l * 1.5);
      c.drawLine(a + off, b + off, Paint()..color = const Color(0xBFE8AA6E)..strokeWidth = 1.6..strokeCap = StrokeCap.round);
    } else {
      c.drawLine(a, b, Paint()..color = const Color(0x996FD39B)..strokeWidth = 14..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      c.drawLine(a, b, Paint()..color = const Color(0xFF1D5139)..strokeWidth = 12..strokeCap = StrokeCap.round);
      final len = (b - a).distance, n = math.max(2, len ~/ 6);
      for (var i = 0; i <= n; i++) {
        final t = i / n;
        c.drawCircle(Offset(x1 + (x2 - x1) * t + (rnd.nextDouble() - 0.5) * 6, y1 + (y2 - y1) * t + (rnd.nextDouble() - 0.5) * 6), 2 + rnd.nextDouble() * 2.6,
            Paint()..color = (rnd.nextBool() ? const Color(0xFF3FA36B) : const Color(0xFF6FD39B)).withValues(alpha: 0.8));
      }
    }
  }

  void _block(Canvas c, BlockDef b, math.Random rnd) {
    final rect = Rect.fromLTWH(b.x, b.y, b.w, b.h);
    if (b.k == 'w') {
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      c.drawRRect(rr, Paint()..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [const Color(0xFF9A6440), const Color(0xFF5E3A24)]));
      c.drawRRect(rr, Paint()..color = const Color(0xFF3D2414)..style = PaintingStyle.stroke..strokeWidth = 2);
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
    for (var i = 0; i < run.c.gates.length; i++) {
      final gt = run.c.gates[i];
      final open = t < run.gateOpen[i];
      final v = g.gateVis[i];
      final m = Offset((gt.x1 + gt.x2) / 2, (gt.y1 + gt.y2) / 2);
      final a = Offset(gt.x1, gt.y1), b = Offset(gt.x2, gt.y2);
      c.drawCircle(a, 5, Paint()..color = Palette.violet);
      c.drawCircle(b, 5, Paint()..color = Palette.violet);
      if (v < 0.98) {
        final half = 1 - v;
        final pa = Offset.lerp(a, m, half)!, pb = Offset.lerp(b, m, half)!;
        final glow = Paint()..color = const Color(0xFF7D55E0).withValues(alpha: 0.95 * half + 0.05)..strokeWidth = 9..strokeCap = StrokeCap.round;
        c.drawLine(a, pa, Paint()..color = const Color(0x99B38CFF)..strokeWidth = 14..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        c.drawLine(b, pb, Paint()..color = const Color(0x99B38CFF)..strokeWidth = 14..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        c.drawLine(a, pa, glow);
        c.drawLine(b, pb, glow);
        final dash = Paint()..color = const Color(0xFFE6D8FF)..strokeWidth = 2;
        _dashed(c, a, pa, dash, 5, 6, phase: g.clock * 20);
        _dashed(c, b, pb, dash, 5, 6, phase: g.clock * 20);
      }
      if (open) {
        final frac = ((run.gateOpen[i] - t) / g.level.gates[i].dur).clamp(0.0, 1.0);
        _dashed(c, a, b, Paint()..color = const Color(0x59B38CFF)..strokeWidth = 2, 3, 5);
        c.drawArc(Rect.fromCircle(center: m + const Offset(0, 14), radius: 7), -math.pi / 2, math.pi * 2 * frac, false, Paint()..color = const Color(0xFFE6D8FF)..style = PaintingStyle.stroke..strokeWidth = 3);
      }
    }
  }

  void _devices(Canvas c) {
    final l = g.level, run = g.run;
    for (final u in l.bumpers) {
      final o = Offset(u.x, u.y);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(u.x - u.r * 0.35, u.y, u.r * 0.7, u.r * 0.9), const Radius.circular(4)), Paint()..color = const Color(0xFFE8D9C8));
      c.drawCircle(o, u.r + 3, Paint()..color = const Color(0x80FF7896)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawCircle(o, u.r, Paint()..shader = ui.Gradient.radial(o + Offset(-u.r * 0.3, -u.r * 0.4), u.r * 1.2, [const Color(0xFFFF9FB4), const Color(0xFFC2365A)]));
      for (final d in const [(-0.4, -0.35, 0.2), (0.35, -0.2, 0.16), (0.0, 0.35, 0.14), (-0.2, 0.15, 0.1)]) {
        c.drawCircle(o + Offset(d.$1 * u.r, d.$2 * u.r), d.$3 * u.r, Paint()..color = const Color(0xE6FFF0F0));
      }
    }
    var iceIdx = 0;
    for (final b in l.blocks) {
      if (b.k != 'i') continue;
      final i = iceIdx++;
      if (run.ice[i]) continue;
      final rect = Rect.fromLTWH(b.x, b.y, b.w, b.h), rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      c.drawRRect(rr.inflate(2), Paint()..color = const Color(0x809FE8FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawRRect(rr, Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [const Color(0xE6D2F8FF), const Color(0xBF6EC8FF)]));
      final line = Paint()..color = const Color(0xCCFFFFFF)..strokeWidth = 1..style = PaintingStyle.stroke;
      c.drawRRect(rr, line);
      c.drawLine(Offset(b.x + b.w * 0.2, b.y + 2), Offset(b.x + b.w * 0.35, b.y + b.h - 2), line);
      c.drawLine(Offset(b.x + b.w * 0.6, b.y + 2), Offset(b.x + b.w * 0.52, b.y + b.h * 0.6), line);
    }
    for (final p in l.portals) {
      for (final e in [(p.ax, p.ay, const Color(0xFFFF9F5A), 1.0), (p.bx, p.by, const Color(0xFF5AB8FF), -1.0)]) {
        final o = Offset(e.$1, e.$2);
        c.drawCircle(o, kPortalR + 6, Paint()..color = e.$3.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        c.drawCircle(o, kPortalR + 3, Paint()..shader = ui.Gradient.radial(o, kPortalR + 3, [const Color(0xF20A0A1E), const Color(0xCC0A0A1E), e.$3], [0, 0.7, 1]));
        for (var k = 0; k < 3; k++) {
          final start = k + g.clock * 3 * e.$4;
          c.drawArc(Rect.fromCircle(center: o, radius: kPortalR - 2 - k * 4), start, 2.2, false, Paint()..color = e.$3..style = PaintingStyle.stroke..strokeWidth = 2);
        }
      }
    }
    for (final x in l.prisms) {
      c.save();
      c.translate(x.x, x.y);
      c.rotate(math.sin(g.clock) * 0.15);
      const r = kPrismR + 3;
      final path = Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.8, 0)
        ..lineTo(0, r)
        ..lineTo(-r * 0.8, 0)
        ..close();
      c.drawPath(path, Paint()..color = const Color(0x99FFFFFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      c.drawPath(path, Paint()..shader = ui.Gradient.linear(const Offset(-r, -r), const Offset(r, r), const [Color(0xFFFF7A8A), Color(0xFFFFD36B), Color(0xFF8DFFB5), Color(0xFF7EF0FF), Color(0xFFB9A4FF)], const [0, 0.25, 0.5, 0.75, 1]));
      c.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
      c.restore();
    }
    for (var i = 0; i < l.mirrors.length; i++) {
      final m = l.mirrors[i], sg = run.mseg[i];
      var ang = math.atan2(sg.y2 - sg.y1, sg.x2 - sg.x1);
      final spin = g.mirrorSpin;
      if (spin != null && spin.$1 == i) ang -= (1 - math.min(1.0, spin.$2)) * math.pi / 4;
      c.save();
      c.translate(m.x, m.y);
      if (m.rot) {
        final ring = Paint()..color = const Color(0x59C8DCFF)..style = PaintingStyle.stroke..strokeWidth = 1.5;
        final rr = m.len / 2 + 6;
        for (var k = 0; k < 16; k++) {
          final a0 = k * math.pi / 8 + g.clock * 0.3;
          c.drawArc(Rect.fromCircle(center: Offset.zero, radius: rr), a0, math.pi / 16, false, ring);
        }
        if (g.mode == Mode.aim) _label(c, 'TAP', 0, m.len / 2 + 10, const Color(0xBFC8DCFF), 9, num: true);
      }
      c.rotate(ang);
      final rect = Rect.fromCenter(center: Offset.zero, width: m.len, height: 7);
      c.drawRRect(RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(6)), Paint()..color = const Color(0x80DFF3FF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3.5)), Paint()..shader = ui.Gradient.linear(const Offset(0, -4), const Offset(0, 4), [Colors.white, const Color(0xFFA9C4E8), const Color(0xFF5D7AA8)], [0, 0.5, 1]));
      c.drawCircle(Offset.zero, 4, Paint()..color = m.rot ? Palette.moon : const Color(0xFF6B7BB0));
      final sh = ((g.clock * 0.6) % 1.4) - 0.2;
      if (sh > 0 && sh < 1) c.drawRect(Rect.fromLTWH(-m.len / 2 + sh * m.len - 3, -3, 6, 6), Paint()..color = const Color(0xCCFFFFFF));
      c.restore();
    }
  }

  void _switches(Canvas c, double t) {
    final l = g.level;
    for (final sw in l.switches) {
      final lit = sw.gates.any((gi) => t < g.run.gateOpen[gi]);
      final o = Offset(sw.x, sw.y);
      c.drawCircle(o, kSwitchR + (lit ? 8 : 3), Paint()..color = Palette.echo.withValues(alpha: lit ? 0.6 : 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      c.drawCircle(o, kSwitchR, Paint()..color = lit ? const Color(0xE67EF0FF) : const Color(0xE6142846));
      final ring = Paint()..color = Palette.echo..style = PaintingStyle.stroke..strokeWidth = 2;
      for (var k = 0; k < 8; k++) {
        c.drawArc(Rect.fromCircle(center: o, radius: kSwitchR + 5), k * math.pi / 4 + g.clock * (lit ? 3 : 0.8), math.pi / 8, false, ring);
      }
      final tri = Path()
        ..moveTo(sw.x, sw.y - 6)
        ..lineTo(sw.x + 5.5, sw.y + 4)
        ..lineTo(sw.x - 5.5, sw.y + 4)
        ..close();
      c.drawPath(tri, Paint()..color = lit ? const Color(0xFF073040) : Palette.echo);
    }
  }

  void _targets(Canvas c, double t) {
    final l = g.level;
    for (var i = 0; i < l.targets.length; i++) {
      final tg = l.targets[i];
      final (x, y) = tg.pos(t);
      final hit = g.run.hit[i], av = tg.avoid;
      final bob = hit ? 0.0 : math.sin(g.clock * 2 + i) * 2.5;
      c.save();
      c.translate(x, y + bob);
      final r = kTargetR * (hit ? 1.08 : 1) * (av ? 0.85 : 1);
      final glowCol = av ? Palette.blossom : (hit ? Palette.moon : const Color(0xFF8FD6FF));
      c.drawCircle(Offset.zero, r + (hit ? 10 : 5), Paint()..color = glowCol.withValues(alpha: 0.55)..maskFilter = MaskFilter.blur(BlurStyle.normal, hit ? 12 : 7));
      final cols = av ? [const Color(0xFFFFF0F6), hit ? const Color(0xFFFF3D6E) : const Color(0xFFFF8FB8)] : hit ? [const Color(0xFFFFFBE6), const Color(0xFFFFBF3F)] : [const Color(0xFFF2FDFF), const Color(0xFF6FB7FF)];
      c.drawCircle(Offset.zero, r, Paint()..shader = ui.Gradient.radial(const Offset(-4, -5), r * 1.3, cols));
      final ear = Paint()..color = av ? const Color(0xFFFFB3CF) : (hit ? const Color(0xFFFFCF5A) : const Color(0xFF9FDCFF));
      for (final sgn in const [-1.0, 1.0]) {
        c.save();
        c.translate(7 * sgn, -r + 1);
        c.rotate(0.5 * sgn);
        c.drawOval(const Rect.fromLTWH(-3, -6, 6, 12), ear);
        c.restore();
      }
      if (av && !hit) {
        c.drawCircle(Offset(0, -r - 6), 4, Paint()..color = Colors.white);
        final no = Paint()..color = const Color(0xFFFF5A86)..strokeWidth = 1.5..style = PaintingStyle.stroke;
        c.drawCircle(Offset(0, -r - 6), 4, no);
        c.drawLine(Offset(-2.5, -r - 8.5), Offset(2.5, -r - 3.5), no);
      }
      if (tg.shield != null && !hit) {
        c.save();
        c.rotate(tg.shield! * kD2R);
        c.drawArc(Rect.fromCircle(center: Offset.zero, radius: r + 6), -1.2, 2.4, false, Paint()..color = const Color(0xFFC9D6FF)..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
        c.drawArc(Rect.fromCircle(center: Offset.zero, radius: r + 6), -1.0, 2.0, false, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);
        c.restore();
      }
      final face = Paint()..color = const Color(0xFF1B2456)..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      if (hit && av) {
        for (final ex in const [-5.0, 5.0]) {
          c.drawLine(Offset(ex - 2, -3), Offset(ex + 2, 1), face);
          c.drawLine(Offset(ex + 2, -3), Offset(ex - 2, 1), face);
        }
        c.drawArc(Rect.fromCircle(center: const Offset(0, 6), radius: 3), math.pi, math.pi, false, face);
      } else if (hit) {
        for (final ex in const [-4.5, 4.5]) {
          c.drawPath(Path()..moveTo(ex - 2.5, 0)..lineTo(ex, -3)..lineTo(ex + 2.5, 0), face);
        }
        c.drawArc(Rect.fromCircle(center: const Offset(0, 3), radius: 3.2), 0, math.pi, false, face);
      } else {
        for (final ex in const [-4.5, 4.5]) {
          c.drawArc(Rect.fromCircle(center: Offset(ex, -1), radius: 2.4), 0.1, math.pi - 0.2, false, face);
        }
        c.drawCircle(const Offset(-8, 4), 2.4, Paint()..color = const Color(0x73FF8CAA));
        c.drawCircle(const Offset(8, 4), 2.4, Paint()..color = const Color(0x73FF8CAA));
      }
      c.restore();
      if (!hit && !av) {
        final zt = (g.clock * 0.6 + i * 0.3) % 1;
        _label(c, 'z', x + 10 + zt * 8, y - 22 - zt * 16, const Color(0xFFCFE6FF).withValues(alpha: 1 - zt), 9 + zt * 6, num: true);
      }
    }
  }

  Color _shotColor(int idx) {
    if (idx == g.curIdx) {
      return switch (Profile.instance.trail) { 'ember' => const Color(0xFFFF8A4C), 'aurora' => const Color(0xFF9DFFCB), _ => Palette.shot[0] };
    }
    return Palette.shot[1 + idx % 5];
  }

  void _arrowShape(Canvas c, double x, double y, double ang, Color col, double alpha, bool glow) {
    c.save();
    c.translate(x, y);
    c.rotate(ang);
    final p = Paint()..color = col.withValues(alpha: alpha);
    if (glow) c.drawLine(const Offset(-20, 0), Offset.zero, Paint()..color = col.withValues(alpha: 0.6 * alpha)..strokeWidth = 7..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawLine(const Offset(-20, 0), Offset.zero, p..strokeWidth = 2.4..strokeCap = StrokeCap.round);
    c.drawPath(Path()..moveTo(4, 0)..lineTo(-5, -4.5)..lineTo(-3, 0)..lineTo(-5, 4.5)..close(), Paint()..color = col.withValues(alpha: alpha));
    c.drawPath(Path()..moveTo(-17, 0)..lineTo(-23, -4)..lineTo(-20, 0)..lineTo(-23, 4)..close(), Paint()..color = col.withValues(alpha: alpha));
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
        c.drawPath(path, Paint()..color = col.withValues(alpha: 0.5)..strokeWidth = 2.5..style = PaintingStyle.stroke..blendMode = BlendMode.plus);
      } else {
        final n = tr.length ~/ 2;
        for (var i = 1; i < n; i++) {
          if (tr[i * 2].isNaN || tr[i * 2 - 2].isNaN) continue;
          final k = i / n;
          c.drawLine(Offset(tr[i * 2 - 2], tr[i * 2 - 1]), Offset(tr[i * 2], tr[i * 2 + 1]),
              Paint()..color = col.withValues(alpha: k * (a.alive ? 0.75 : 0.35))..strokeWidth = 1 + k * 4..strokeCap = StrokeCap.round..blendMode = BlendMode.plus);
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

  void _archer(Canvas c) {
    final l = g.level;
    final pull = g.mode == Mode.hold ? g.pull.clamp(0.0, 70.0) : 0.0;
    final ang = g.aimAng;
    c.save();
    c.translate(l.bowX, l.bowY);
    c.drawOval(const Rect.fromLTWH(-26, 16, 52, 12), Paint()..color = const Color(0x26FFD36B));
    c.drawOval(const Rect.fromLTWH(-13, -2, 26, 24), Paint()..color = const Color(0xFF26306E));
    c.drawCircle(const Offset(0, -4), 12, Paint()..color = const Color(0xFF3B4AA0));
    c.drawPath(Path()..moveTo(-9, -12)..lineTo(-4, -24)..lineTo(1, -13)..close(), Paint()..color = const Color(0xFF3B4AA0));
    c.drawOval(const Rect.fromLTWH(-7, -10, 16, 14), Paint()..color = const Color(0xFFFFE9CF));
    final lx = math.cos(ang) * 2, ly = math.sin(ang) * 1.5;
    c.drawCircle(Offset(-2 + lx, -3 + ly), 1.6, Paint()..color = const Color(0xFF1B1440));
    c.drawCircle(Offset(4 + lx, -3 + ly), 1.6, Paint()..color = const Color(0xFF1B1440));
    c.rotate(ang);
    final bow = Paint()..color = Palette.moon..strokeWidth = 3.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    if (g.mode == Mode.hold) c.drawArc(Rect.fromCircle(center: const Offset(-4, 0), radius: 20), -1.15, 2.3, false, Paint()..color = const Color(0x99FFD36B)..strokeWidth = 7..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawArc(Rect.fromCircle(center: const Offset(-4, 0), radius: 20), -1.15, 2.3, false, bow);
    final tipX = -4 + math.cos(1.15) * 20, tipY = math.sin(1.15) * 20, sx = tipX - pull * 0.4;
    c.drawPath(Path()..moveTo(tipX, -tipY)..lineTo(sx, 0)..lineTo(tipX, tipY), Paint()..color = const Color(0xCCFFFFFF)..strokeWidth = 1.1..style = PaintingStyle.stroke);
    if (g.mode == Mode.aim || g.mode == Mode.hold) {
      final kc = g.kind == 'split' ? Palette.moon : (g.kind == 'pierce' ? Palette.moss : Palette.moon);
      _arrowShape(c, sx + 22, 0, 0, kc, 1, g.mode == Mode.hold || g.kind != 'n');
    }
    c.restore();
  }

  void _guide(Canvas c) {
    if (g.mode != Mode.hold || g.pull < 22) return;
    final r = g.run.ray(g.aimAng, g.guide, 70, pierce: g.kind == 'pierce');
    final gcol = g.kind == 'pierce' ? Palette.moss : Palette.moon;
    const gap = 10.0;
    for (var pi = 0; pi < r.paths.length; pi++) {
      final pts = r.paths[pi];
      var d = 0.0;
      for (var i = 1; i < pts.length; i++) {
        final a = Offset(pts[i - 1].$1, pts[i - 1].$2), b = Offset(pts[i].$1, pts[i].$2), len = (b - a).distance;
        final last = pi == r.paths.length - 1 && i == pts.length - 1, first = pi == 0 && i == 1;
        for (var s = (gap - (d % gap)) % gap; s < len; s += gap) {
          final t = s / len, fade = last ? 1 - s / len : 1.0;
          c.drawCircle(Offset.lerp(a, b, t)!, first ? 2.2 : 1.8, Paint()..color = (first ? const Color(0xFFFFF4CF) : gcol).withValues(alpha: 0.85 * fade * (first ? 1 : 0.75)));
        }
        d += len;
        if (i < pts.length - 1) c.drawCircle(b, 5, Paint()..color = gcol.withValues(alpha: 0.9)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
    final lp = r.paths.last.last;
    if (r.end == 'm' || r.end == 'g') {
      final x = Paint()..color = const Color(0xE6FF7A8A)..strokeWidth = 2.2;
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
      _label(c, '${i + 1}', g.level.bowX + math.cos(s.ang) * 40, g.level.bowY + math.sin(s.ang) * 40 - 6, Palette.shot[1 + i % 5], 11, num: true);
    }
  }

  void _hint(Canvas c) {
    final s = g.level.solution;
    if (!g.hintOn || s == null || g.mode != Mode.aim) return;
    final idx = g.shots.length.clamp(0, s.shots.length - 1);
    final ang = s.shots[idx].angDeg * kD2R;
    final r = g.run.ray(ang, 1, 60);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.35 + 0.25 * math.sin(g.clock * 4))..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (final path in r.paths) {
      for (var i = 1; i < path.length; i++) {
        _dashed(c, Offset(path[i - 1].$1, path[i - 1].$2), Offset(path[i].$1, path[i].$2), p, 8, 8, phase: -g.clock * 30);
      }
    }
    if (s.shots[idx].step > 30) _label(c, '${(s.shots[idx].step * kDt).toStringAsFixed(1)}초 뒤 발사', g.level.bowX, g.level.bowY - 50, Colors.white70, 11);
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
      }
    }
    for (final r in g.rings) {
      final k = r.t / r.life;
      c.drawCircle(Offset(r.x, r.y), r.r1 * (0.3 + k * 0.9), Paint()..color = Color(r.color).withValues(alpha: 1 - k)..style = PaintingStyle.stroke..strokeWidth = r.w * (1 - k) + 0.5);
    }
    for (final t in g.texts) {
      final k = t.t / t.life;
      final pop = k < 0.15 ? 0.6 + k / 0.15 * 0.6 : 1.2 - math.min(0.2, k - 0.15);
      final alpha = k > 0.7 ? (1 - k) / 0.3 : 1.0;
      c.save();
      c.translate(t.x, t.y - k * 26);
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
