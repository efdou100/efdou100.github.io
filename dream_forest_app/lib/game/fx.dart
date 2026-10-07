import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../app/theme.dart';

enum PShape { circle, square, spark, leaf, star }

class Particle {
  double x, y, vx, vy, life, max, size, gravity, drag, rot, vr;
  Color color;
  PShape shape;
  bool glow;
  Particle(this.x, this.y, this.vx, this.vy,
      {required this.life,
      required this.size,
      required this.color,
      this.gravity = 0,
      this.drag = 0,
      this.shape = PShape.circle,
      this.rot = 0,
      this.vr = 0,
      this.glow = false})
      : max = life;
}

class FloatText {
  double x, y, vy, vx, life;
  final double max;
  final TextPainter painter;
  final double pop;
  FloatText(this.x, this.y, this.vx, this.vy, this.life, this.painter, this.pop) : max = life;
}

class Ring {
  double x, y, r, maxR, life, width;
  final double max;
  final Color color;
  Ring(this.x, this.y, this.r, this.maxR, this.life, this.color, this.width) : max = life;
}

/// 파티클·떠오르는 숫자·충격파 고리. 손맛 연출의 대부분이 여기서 나와요.
class Fx {
  final List<Particle> particles = [];
  final List<FloatText> texts = [];
  final List<Ring> rings = [];
  final math.Random rng = math.Random();
  final Paint _p = Paint();
  final Paint _glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  double rand(double a, double b) => a + rng.nextDouble() * (b - a);

  void add(Particle p) {
    if (particles.length > 900) particles.removeRange(0, 100);
    particles.add(p);
  }

  void burst(double x, double y, Color color,
      {int n = 12, double speed = 220, double size = 4, double life = 0.5, double gravity = 600, PShape shape = PShape.circle, bool glow = false}) {
    for (var i = 0; i < n; i++) {
      final a = rng.nextDouble() * math.pi * 2, v = speed * rand(0.3, 1);
      add(Particle(x, y, math.cos(a) * v, math.sin(a) * v,
          life: life * rand(0.6, 1.2), size: size * rand(0.6, 1.3), color: color, gravity: gravity, drag: 2.2, shape: shape,
          rot: rng.nextDouble() * 6, vr: rand(-10, 10), glow: glow));
    }
  }

  /// 방향이 있는 불꽃. 화살이 맞은 반대쪽으로 튀어요.
  void sparks(double x, double y, double angle, Color color, {int n = 8, double spread = 0.9, double speed = 420}) {
    for (var i = 0; i < n; i++) {
      final a = angle + rand(-spread, spread), v = speed * rand(0.4, 1);
      add(Particle(x, y, math.cos(a) * v, math.sin(a) * v,
          life: rand(0.12, 0.26), size: rand(2, 3.5), color: color, drag: 6, shape: PShape.spark, glow: true));
    }
  }

  void dust(double x, double y, {int n = 6, double dir = 0, double power = 1}) {
    for (var i = 0; i < n; i++) {
      add(Particle(x + rand(-8, 8), y - 2, (dir * 80 + rand(-90, 90)) * power, -rand(20, 90) * power,
          life: rand(0.3, 0.55), size: rand(4, 8) * power, color: const Color(0xFFCFE3C9), drag: 4, gravity: -30));
    }
  }

  void leaves(double x, double y, {int n = 6}) {
    for (var i = 0; i < n; i++) {
      add(Particle(x, y, rand(-140, 140), rand(-260, -60),
          life: rand(0.7, 1.2), size: rand(4, 7), color: i.isEven ? Palette.moss : Palette.grass, gravity: 380, drag: 2.5,
          shape: PShape.leaf, rot: rand(0, 6), vr: rand(-8, 8)));
    }
  }

  void ring(double x, double y, Color color, {double from = 6, double to = 60, double life = 0.35, double width = 4}) {
    rings.add(Ring(x, y, from, to, life, color, width));
  }

  void text(double x, double y, String s,
      {Color color = Palette.ink, double size = 18, bool crit = false, double life = 0.75}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: kDisplayFont,
          fontSize: size,
          color: color,
          shadows: const [Shadow(color: Color(0xE60A1012), blurRadius: 0, offset: Offset(0, 2)), Shadow(color: Color(0xCC0A1012), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (texts.length > 80) texts.removeAt(0);
    texts.add(FloatText(x + rand(-10, 10), y, rand(-30, 30), crit ? -230 : -170, life, tp, crit ? 1.9 : 1.45));
  }

  void update(double dt) {
    for (final p in particles) {
      p.life -= dt;
      p.vy += p.gravity * dt;
      if (p.drag > 0) {
        final k = math.exp(-p.drag * dt);
        p.vx *= k;
        p.vy *= k;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
    }
    particles.removeWhere((p) => p.life <= 0);
    for (final t in texts) {
      t.life -= dt;
      t.vy += 420 * dt;
      t.x += t.vx * dt;
      t.y += t.vy * dt;
    }
    texts.removeWhere((t) => t.life <= 0);
    for (final r in rings) {
      r.life -= dt;
    }
    rings.removeWhere((r) => r.life <= 0);
  }

  void render(Canvas c) {
    for (final r in rings) {
      final k = 1 - r.life / r.max;
      final ease = 1 - math.pow(1 - k, 3).toDouble();
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.width * (1 - k) + 0.5
        ..color = r.color.withValues(alpha: (1 - k) * 0.9);
      c.drawCircle(Offset(r.x, r.y), r.r + (r.maxR - r.r) * ease, _p);
    }
    _p.style = PaintingStyle.fill;
    for (final p in particles) {
      final a = (p.life / p.max).clamp(0.0, 1.0);
      final s = p.size * (0.4 + 0.6 * a);
      _p.color = p.color.withValues(alpha: a);
      if (p.glow) {
        _glow.color = p.color.withValues(alpha: a * 0.6);
        c.drawCircle(Offset(p.x, p.y), s * 1.8, _glow);
      }
      switch (p.shape) {
        case PShape.circle:
          c.drawCircle(Offset(p.x, p.y), s, _p);
        case PShape.square:
          c.save();
          c.translate(p.x, p.y);
          c.rotate(p.rot);
          c.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s * 1.6), _p);
          c.restore();
        case PShape.spark:
          final len = math.sqrt(p.vx * p.vx + p.vy * p.vy) * 0.035 + 2;
          final ang = math.atan2(p.vy, p.vx);
          _p
            ..strokeWidth = s
            ..strokeCap = StrokeCap.round;
          c.drawLine(Offset(p.x, p.y), Offset(p.x - math.cos(ang) * len, p.y - math.sin(ang) * len), _p);
        case PShape.leaf:
          c.save();
          c.translate(p.x, p.y);
          c.rotate(p.rot);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 2.2, height: s), _p);
          c.restore();
        case PShape.star:
          c.save();
          c.translate(p.x, p.y);
          c.rotate(p.rot);
          final path = Path();
          for (var i = 0; i < 8; i++) {
            final rr = i.isEven ? s * 1.6 : s * 0.55;
            final aa = i * math.pi / 4;
            i == 0 ? path.moveTo(math.cos(aa) * rr, math.sin(aa) * rr) : path.lineTo(math.cos(aa) * rr, math.sin(aa) * rr);
          }
          path.close();
          c.drawPath(path, _p);
          c.restore();
      }
    }
    for (final t in texts) {
      final k = 1 - t.life / t.max;
      // 튀어나왔다가 제자리로 돌아오는 팝 + 끝에서 사라짐
      final pop = k < 0.12 ? 1 + (t.pop - 1) * (k / 0.12) : 1 + (t.pop - 1) * math.max(0, 1 - (k - 0.12) / 0.18);
      final alpha = t.life < 0.2 ? t.life / 0.2 : 1.0;
      c.save();
      c.translate(t.x, t.y);
      c.scale(pop);
      if (alpha < 1) c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
      t.painter.paint(c, Offset(-t.painter.width / 2, -t.painter.height / 2));
      if (alpha < 1) c.restore();
      c.restore();
    }
  }

  void clear() {
    particles.clear();
    texts.clear();
    rings.clear();
  }
}
