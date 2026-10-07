import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../app/art.dart';
import '../constants.dart';

/// 잠든 숲 배경: 하늘 → 먼 산 → 중간 숲 → 가까운 숲(빛나는 버섯) + 빛줄기, 반딧불.
/// 숲 레이어는 처음에 한 번 이미지로 구워두고 시차 스크롤만 해요.
class Background {
  static const double layerW = 2048;
  late final ui.Image far, mid, near;
  final List<Firefly> flies;
  final Paint _p = Paint();

  /// 교체 이미지: bg/ch{n}_sky, bg/ch{n}_far, bg/ch{n}_mid, bg/ch{n}_near (좌우가 이어지는 가로 그림)
  final int chapter;
  Background({this.chapter = 1}) : flies = List.generate(40, (i) => Firefly(i)) {
    far = _bake(11, _drawFar);
    mid = _bake(23, _drawMid);
    near = _bake(57, _drawNear);
  }

  ui.Image _bake(int seed, void Function(Canvas, math.Random) draw) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    draw(c, math.Random(seed));
    return rec.endRecording().toImageSync(layerW.toInt(), kViewH.toInt());
  }

  static void _repeat(double x, void Function(double x) f) {
    f(x);
    if (x < 260) f(x + layerW);
    if (x > layerW - 260) f(x - layerW);
  }

  void _drawFar(Canvas c, math.Random r) {
    final p = Paint()..color = const Color(0xFF2A4566);
    final path = Path()..moveTo(0, kViewH);
    for (var x = 0.0; x <= layerW; x += 32) {
      final y = 300 + math.sin(x / 210) * 40 + math.sin(x / 77 + 1.3) * 18;
      path.lineTo(x, y);
    }
    path
      ..lineTo(layerW, kViewH)
      ..close();
    c.drawPath(path, p);
    p.color = const Color(0xFF223B55);
    for (var i = 0; i < 46; i++) {
      final x = r.nextDouble() * layerW, h = 120 + r.nextDouble() * 120;
      _repeat(x, (xx) {
        final tri = Path()
          ..moveTo(xx, kViewH - h - 60)
          ..lineTo(xx - 26, kViewH)
          ..lineTo(xx + 26, kViewH)
          ..close();
        c.drawPath(tri, p);
      });
    }
  }

  void _drawMid(Canvas c, math.Random r) {
    final p = Paint()..color = const Color(0xFF1B3B46);
    for (var i = 0; i < 22; i++) {
      final x = r.nextDouble() * layerW, h = 260 + r.nextDouble() * 160, tw = 14 + r.nextDouble() * 14;
      final blobs = List.generate(6, (_) => [(r.nextDouble() - 0.5) * 120, (r.nextDouble() - 0.4) * 70, 46 + r.nextDouble() * 46]);
      _repeat(x, (xx) {
        c.drawRect(Rect.fromLTWH(xx - tw / 2, kViewH - h, tw, h), p);
        for (final b in blobs) {
          c.drawCircle(Offset(xx + b[0], kViewH - h + b[1]), b[2], p);
        }
      });
    }
    c.drawRect(const Rect.fromLTWH(0, kViewH - 70, layerW, 70), p);
  }

  void _drawNear(Canvas c, math.Random r) {
    final trunk = Paint()..color = const Color(0xFF132D33);
    for (var i = 0; i < 9; i++) {
      final x = r.nextDouble() * layerW, tw = 34 + r.nextDouble() * 26;
      final vines = List.generate(3, (_) => [(r.nextDouble() - 0.5) * 160, 60 + r.nextDouble() * 160]);
      _repeat(x, (xx) {
        final path = Path()
          ..moveTo(xx - tw / 2, kViewH)
          ..quadraticBezierTo(xx - tw * 0.3, kViewH * 0.5, xx - tw * 0.45, -10)
          ..lineTo(xx + tw * 0.45, -10)
          ..quadraticBezierTo(xx + tw * 0.3, kViewH * 0.5, xx + tw / 2 + 18, kViewH)
          ..close();
        c.drawPath(path, trunk);
        c.drawCircle(Offset(xx, -30), 140, trunk);
        final vp = Paint()
          ..color = const Color(0xFF173A30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        for (final v in vines) {
          final vx = xx + v[0];
          c.drawPath(
            Path()
              ..moveTo(vx, 0)
              ..quadraticBezierTo(vx + 14, v[1] / 2, vx - 4, v[1]),
            vp,
          );
          c.drawCircle(Offset(vx - 4, v[1]), 4, Paint()..color = const Color(0xFF2D6B52));
        }
      });
    }
    c.drawRect(const Rect.fromLTWH(0, kViewH - 46, layerW, 46), trunk);
    // 빛나는 버섯 군락
    for (var i = 0; i < 26; i++) {
      final x = r.nextDouble() * layerW, s = 5 + r.nextDouble() * 9;
      final hue = r.nextBool() ? const Color(0xFFF2A55E) : const Color(0xFFE07AA8);
      _repeat(x, (xx) {
        const y = kViewH - 46;
        c.drawCircle(
          Offset(xx, y - s),
          s * 3.2,
          Paint()
            ..color = hue.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        c.drawRect(Rect.fromLTWH(xx - s * 0.22, y - s, s * 0.44, s), Paint()..color = const Color(0xFFD9C8A6));
        c.drawArc(Rect.fromCenter(center: Offset(xx, y - s), width: s * 2, height: s * 1.3), math.pi, math.pi, true, Paint()..color = hue);
      });
    }
  }

  void render(Canvas c, double viewW, double camX, double camY, double roomH, double time) {
    final art = Art.instance;
    final skyArt = art.image('bg/ch${chapter}_sky');
    final lift = math.max(0.0, (roomH - kViewH) - camY);
    if (skyArt != null) {
      drawArt(c, skyArt, Rect.fromLTWH(0, 0, viewW, kViewH));
      _layersArt(c, viewW, camX, lift, time);
      return;
    }
    // 하늘
    final sky = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(0, kViewH),
      const [Color(0xFF1B1636), Color(0xFF243A52), Color(0xFF14292E)],
      const [0, 0.55, 1],
    );
    c.drawRect(Rect.fromLTWH(0, 0, viewW, kViewH), _p..shader = sky);
    _p.shader = null;
    // 별
    for (var i = 0; i < 40; i++) {
      final x = (i * 197.3) % viewW, y = (i * 83.7) % 200 + 10;
      final a = 0.25 + 0.25 * math.sin(time * (0.8 + i % 5 * 0.3) + i);
      c.drawCircle(Offset(x, y), i % 7 == 0 ? 1.6 : 1.0, _p..color = Color.fromRGBO(255, 248, 225, a));
    }
    // 달
    final mx = viewW * 0.78 - camX * 0.02, my = 92.0;
    c.drawCircle(
      Offset(mx, my),
      110,
      Paint()
        ..color = const Color(0x30FFE8B8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
    c.drawCircle(
      Offset(mx, my),
      48,
      Paint()
        ..color = const Color(0x55FFF0C8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    c.drawCircle(Offset(mx, my), 34, _p..color = const Color(0xFFF6ECD0));
    c.drawCircle(Offset(mx - 10, my - 6), 7, _p..color = const Color(0x40C8BC9A));
    c.drawCircle(Offset(mx + 11, my + 10), 5, _p..color = const Color(0x40C8BC9A));
    if (art.has('bg/ch${chapter}_far')) {
      _layersArt(c, viewW, camX, lift, time);
      return;
    }
    for (final (img, f, dy) in [(far, 0.12, -150.0), (mid, 0.3, -110.0), (near, 0.55, -80.0)]) {
      final off = -((camX * f) % layerW);
      final y = dy + lift * f * 0.6;
      for (var x = off; x < viewW; x += layerW) {
        c.drawImage(img, Offset(x, y), _p);
      }
      if (identical(img, far)) _fog(c, viewW, time, y + 280, const Color(0x1A9FC2C8));
      if (identical(img, mid)) _rays(c, viewW, time);
    }
    for (final f in flies) {
      final x = ((f.x - camX * 0.7) % viewW + viewW) % viewW;
      final y = f.y + math.sin(time * f.sp + f.ph) * 16;
      final a = 0.35 + 0.35 * math.sin(time * 2.2 * f.sp + f.ph);
      c.drawCircle(Offset(x, y), 7, _p..color = Color.fromRGBO(240, 255, 170, a * 0.18));
      c.drawCircle(Offset(x, y), 1.6, _p..color = Color.fromRGBO(250, 255, 205, a));
    }
  }

  /// 교체 이미지로 그린 숲 레이어 (높이를 화면에 맞추고 가로로 반복)
  void _layersArt(Canvas c, double viewW, double camX, double lift, double time) {
    final art = Art.instance;
    for (final (name, f) in [('far', 0.12), ('mid', 0.3), ('near', 0.55)]) {
      final img = art.image('bg/ch${chapter}_$name');
      if (img == null) continue;
      final h = kViewH, w = h * img.width / img.height;
      final off = -((camX * f) % w);
      for (var x = off; x < viewW; x += w) {
        drawArt(c, img, Rect.fromLTWH(x, lift * f * 0.6, w, h));
      }
      if (name == 'mid') _rays(c, viewW, time);
    }
    _flies(c, viewW, camX, time);
  }

  void _flies(Canvas c, double viewW, double camX, double time) {
    for (final f in flies) {
      final x = ((f.x - camX * 0.7) % viewW + viewW) % viewW;
      final y = f.y + math.sin(time * f.sp + f.ph) * 16;
      final a = 0.35 + 0.35 * math.sin(time * 2.2 * f.sp + f.ph);
      c.drawCircle(Offset(x, y), 7, _p..color = Color.fromRGBO(240, 255, 170, a * 0.18));
      c.drawCircle(Offset(x, y), 1.6, _p..color = Color.fromRGBO(250, 255, 205, a));
    }
  }

  void _fog(Canvas c, double viewW, double time, double y, Color color) {
    final shift = math.sin(time * 0.2) * 40;
    c.drawRect(
      Rect.fromLTWH(-60 + shift, y - 40, viewW + 120, 90),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, y - 40), Offset(0, y + 50), [color.withValues(alpha: 0), color, color.withValues(alpha: 0)], const [0, 0.5, 1]),
    );
  }

  void _rays(Canvas c, double viewW, double time) {
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 3; i++) {
      final x = viewW * (0.2 + i * 0.3);
      final a = 0.035 + 0.02 * math.sin(time * 0.6 + i * 2);
      p.shader = ui.Gradient.linear(Offset(x, 0), Offset(x - 160, kViewH), [Color.fromRGBO(255, 236, 190, a), const Color(0x00FFECBE)]);
      c.drawPath(
        Path()
          ..moveTo(x - 30, 0)
          ..lineTo(x + 40, 0)
          ..lineTo(x - 120, kViewH)
          ..lineTo(x - 260, kViewH)
          ..close(),
        p,
      );
    }
  }
}

class Firefly {
  final double x, y, ph, sp;
  Firefly(int i) : x = (i * 137.5) % 1400, y = 60 + (i * 53.3) % (kViewH - 140), ph = i * 1.7, sp = 0.5 + (i % 5) * 0.2;
}
