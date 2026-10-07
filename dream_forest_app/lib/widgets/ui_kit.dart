import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/render/skill_icons.dart';
import '../game/skills.dart';

/// 메뉴 화면 공통 배경: 보랏빛 하늘, 달, 겹겹의 숲, 반딧불, 떠다니는 빛가루.
class ForestBackdrop extends StatefulWidget {
  final Widget child;
  final double dim;
  const ForestBackdrop({super.key, required this.child, this.dim = 0});
  @override
  State<ForestBackdrop> createState() => _ForestBackdropState();
}

class _ForestBackdropState extends State<ForestBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(painter: _BackdropPainter(_c.value * 60, widget.dim)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final double t, dim;
  _BackdropPainter(this.t, this.dim);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    p.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0, s.height),
      const [Color(0xFF1B1538), Color(0xFF2B3B5E), Color(0xFF173238), Color(0xFF0B171B)],
      const [0, 0.42, 0.75, 1],
    );
    c.drawRect(Offset.zero & s, p);
    p.shader = null;
    // 별
    for (var i = 0; i < 70; i++) {
      final x = (i * 211.7) % s.width, y = (i * 97.3) % (s.height * 0.55);
      final a = 0.2 + 0.3 * (0.5 + 0.5 * math.sin(t * (0.6 + i % 4 * 0.3) + i));
      c.drawCircle(Offset(x, y), i % 9 == 0 ? 1.6 : 0.9, p..color = Color.fromRGBO(255, 246, 220, a));
    }
    // 달 + 후광
    final moon = Offset(s.width * 0.8, s.height * 0.2);
    c.drawCircle(
      moon,
      150,
      Paint()
        ..color = const Color(0x2EFFE6BE)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
    );
    c.drawCircle(
      moon,
      64,
      Paint()
        ..color = const Color(0x50FFF0C8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    c.drawCircle(moon, 44, p..shader = ui.Gradient.radial(moon.translate(-10, -10), 60, const [Color(0xFFFFFAEA), Color(0xFFF1DFB4)]));
    p.shader = null;
    // 산·숲 실루엣 (시차 스크롤)
    void hills(double base, double amp, double freq, double speed, Color col) {
      final path = Path()..moveTo(0, s.height);
      for (var x = 0.0; x <= s.width + 20; x += 18) {
        final xx = x + t * speed;
        path.lineTo(x, base + math.sin(xx / freq) * amp + math.sin(xx / (freq * 0.37) + 2) * amp * 0.4);
      }
      path
        ..lineTo(s.width, s.height)
        ..close();
      c.drawPath(path, p..color = col);
    }

    hills(s.height * 0.62, 26, 160, 4, const Color(0xFF243B57));
    final k = (s.height / 700).clamp(0.45, 1.4);
    _trees(c, s, s.height * 0.72, 0.9 * k, 9, const Color(0xFF1A3340), 7);
    hills(s.height * 0.8, 18, 120, 10, const Color(0xFF142A30));
    _trees(c, s, s.height * 0.9, 1.25 * k, 16, const Color(0xFF0E2025), 13);
    // 빛줄기
    final ray = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 3; i++) {
      final x = s.width * (0.15 + i * 0.32);
      final a = 0.04 + 0.025 * math.sin(t * 0.5 + i * 2);
      ray.shader = ui.Gradient.linear(Offset(x, 0), Offset(x - 200, s.height), [Color.fromRGBO(255, 230, 180, a), const Color(0x00FFE6B4)]);
      c.drawPath(
        Path()
          ..moveTo(x - 30, 0)
          ..lineTo(x + 50, 0)
          ..lineTo(x - 160, s.height)
          ..lineTo(x - 320, s.height)
          ..close(),
        ray,
      );
    }
    // 반딧불
    for (var i = 0; i < 46; i++) {
      final bx = (i * 137.5) % s.width, by = s.height * 0.3 + (i * 61.7) % (s.height * 0.65);
      final x = bx + math.sin(t * 0.4 + i) * 30, y = by + math.cos(t * 0.5 + i * 1.3) * 20;
      final a = 0.3 + 0.4 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.7));
      c.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = Color.fromRGBO(236, 255, 170, a * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      c.drawCircle(Offset(x, y), 2, p..color = Color.fromRGBO(250, 255, 210, a));
    }
    if (dim > 0) c.drawRect(Offset.zero & s, p..color = Color.fromRGBO(6, 12, 14, dim));
  }

  void _trees(Canvas c, Size s, double base, double scale, int n, Color col, int seed) {
    final p = Paint()..color = col;
    final r = math.Random(seed);
    for (var i = 0; i < n; i++) {
      final x = r.nextDouble() * s.width, h = (120 + r.nextDouble() * 140) * scale, tw = (10 + r.nextDouble() * 10) * scale;
      c.drawRect(Rect.fromLTWH(x - tw / 2, base - h, tw, h + 40), p);
      for (var k = 0; k < 5; k++) {
        c.drawCircle(Offset(x + (r.nextDouble() - 0.5) * 90 * scale, base - h + (r.nextDouble() - 0.4) * 50 * scale), (34 + r.nextDouble() * 34) * scale, p);
      }
    }
    c.drawRect(Rect.fromLTWH(0, base, s.width, s.height - base), p);
    // 빛나는 버섯
    for (var i = 0; i < n; i++) {
      final x = r.nextDouble() * s.width, ms = (4 + r.nextDouble() * 6) * scale;
      final hue = i.isEven ? const Color(0xFFF2A55E) : const Color(0xFFE07AA8);
      c.drawCircle(
        Offset(x, base - ms),
        ms * 3.4,
        Paint()
          ..color = hue.withValues(alpha: 0.32)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ms * 2),
      );
      c.drawArc(Rect.fromCenter(center: Offset(x, base - ms * 0.3), width: ms * 2, height: ms * 1.4), math.pi, math.pi, true, Paint()..color = hue);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.t != t || old.dim != dim;
}

/// 눌렀을 때 쏙 들어가는 빛나는 버튼.
class GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color> colors;
  final IconData? icon;
  final double fontSize;
  final EdgeInsets padding;
  final Color textColor;
  const GlowButton({
    super.key,
    required this.label,
    this.onTap,
    this.colors = const [Color(0xFFFFD98A), Color(0xFFF5A84C)],
    this.icon,
    this.fontSize = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
    this.textColor = const Color(0xFF3A2008),
  });

  static const secondary = [Color(0xFF3E6B66), Color(0xFF244448)];
  static const violet = [Color(0xFFC8A6FF), Color(0xFF8A5FE0)];

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              Sfx.instance.play('select');
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.93 : 1,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [BoxShadow(color: widget.colors.last.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: 1, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: widget.colors),
                      border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 2), const SizedBox(width: 8)],
                        Text(widget.label, style: display(widget.fontSize, color: widget.textColor)),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _shine,
                        builder: (_, _) => CustomPaint(painter: _ShinePainter(_shine.value)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShinePainter extends CustomPainter {
  final double v;
  _ShinePainter(this.v);
  @override
  void paint(Canvas c, Size s) {
    final x = -s.width * 0.5 + v * s.width * 2.4;
    c.drawPath(
      Path()
        ..moveTo(x, 0)
        ..lineTo(x + 26, 0)
        ..lineTo(x + 6, s.height)
        ..lineTo(x - 20, s.height)
        ..close(),
      Paint()..color = const Color(0x40FFFFFF),
    );
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height * 0.45), Paint()..color = const Color(0x1AFFFFFF));
  }

  @override
  bool shouldRepaint(_ShinePainter o) => o.v != v;
}

/// 흐릿한 유리 패널 + 빛나는 테두리.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color glow;
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 22, this.glow = const Color(0x33F5B85C)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: glow, blurRadius: 30, spreadRadius: -4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xCC1E383E), Color(0xE00C1A1F)]),
              border: Border.all(color: const Color(0x557FD6B0), width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 금빛 그라데이션 제목 글씨.
class ShinyTitle extends StatelessWidget {
  final String text;
  final double size;
  final List<Color> colors;
  const ShinyTitle(this.text, {super.key, this.size = 40, this.colors = const [Color(0xFFFFF4D2), Color(0xFFF5B85C), Color(0xFFE86FA6)]});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: display(
            size,
            color: const Color(0x00000000),
            shadows: [Shadow(color: colors[1].withValues(alpha: 0.6), blurRadius: 24)],
          ),
        ),
        ShaderMask(
          shaderCallback: (r) =>
              LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors, stops: const [0, 0.55, 1]).createShader(r),
          child: Text(
            text,
            style: display(
              size,
              color: Colors.white,
              shadows: const [Shadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 6)],
            ),
          ),
        ),
      ],
    );
  }
}

class SkillIcon extends StatelessWidget {
  final String id;
  final double size;
  final Color color;
  const SkillIcon(this.id, {super.key, this.size = 40, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _IconPainter(id, color));
}

class _IconPainter extends CustomPainter {
  final String id;
  final Color color;
  _IconPainter(this.id, this.color);
  @override
  void paint(Canvas c, Size s) => paintSkillIcon(c, id, Offset.zero & s, color: color);
  @override
  bool shouldRepaint(_IconPainter o) => o.id != id || o.color != color;
}

/// 레벨업 스킬 카드: 희귀도 색으로 빛나는 테두리, 영웅 등급은 반짝이며 흘러요.
class SkillCard extends StatefulWidget {
  final SkillDef skill;
  final int currentStack;
  final VoidCallback onTap;
  final int index;
  const SkillCard({super.key, required this.skill, required this.currentStack, required this.onTap, required this.index});
  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  bool _down = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 90 * widget.index), () {
      if (mounted) _in.forward();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.skill;
    final col = rarityColor(s.rarity);
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _loop]),
      builder: (_, child) {
        final k = Curves.easeOutBack.transform(_in.value.clamp(0, 1));
        return Opacity(
          opacity: _in.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - k) * 80),
            child: Transform.scale(scale: (0.7 + 0.3 * k) * (_down ? 0.95 : 1), child: child),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _loop,
          builder: (_, _) => CustomPaint(
            painter: _CardFramePainter(col, _loop.value, s.rarity == Rarity.epic),
            child: Container(
              width: 186,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: col.withValues(alpha: 0.6)),
                    ),
                    child: Text(rarityLabel(s.rarity), style: display(12, color: col)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [col.withValues(alpha: 0.55), col.withValues(alpha: 0.08)]),
                      boxShadow: [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 24)],
                      border: Border.all(color: col.withValues(alpha: 0.8), width: 2),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SkillIcon(s.id, size: 44),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.name,
                    style: display(21, color: Palette.ink),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.desc,
                    style: const TextStyle(fontSize: 13, color: Palette.mute, height: 1.35),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (s.maxStack > 1 && s.maxStack < 99)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < s.maxStack; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 14,
                            height: 5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i < widget.currentStack
                                  ? col
                                  : i == widget.currentStack
                                  ? Palette.gold
                                  : const Color(0x33FFFFFF),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFramePainter extends CustomPainter {
  final Color col;
  final double t;
  final bool shimmer;
  _CardFramePainter(this.col, this.t, this.shimmer);
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(22));
    c.drawRRect(
      r.inflate(4),
      Paint()
        ..color = col.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    c.drawRRect(r, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), const [Color(0xF2213E44), Color(0xF20D1A1F)]));
    c.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = ui.Gradient.sweep(
          s.center(Offset.zero),
          [col, col.withValues(alpha: 0.2), col, col.withValues(alpha: 0.2), col],
          const [0, 0.25, 0.5, 0.75, 1],
          TileMode.repeated,
          t * math.pi * 2,
          t * math.pi * 2 + math.pi * 2,
        ),
    );
    if (shimmer) {
      final x = -s.width + t * s.width * 3;
      c.save();
      c.clipRRect(r);
      c.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + 50, 0)
          ..lineTo(x - 30, s.height)
          ..lineTo(x - 80, s.height)
          ..close(),
        Paint()..color = col.withValues(alpha: 0.12),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_CardFramePainter o) => true;
}

/// 별 3개. 하나씩 튀어나오며 반짝여요.
class StarRow extends StatefulWidget {
  final List<bool> stars;
  final double size;
  final bool animate;
  const StarRow({super.key, required this.stars, this.size = 44, this.animate = false});
  @override
  State<StarRow> createState() => _StarRowState();
}

class _StarRowState extends State<StarRow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.forward();
      for (var i = 0; i < 3; i++) {
        if (widget.stars[i]) Future.delayed(Duration(milliseconds: 300 + i * 380), () => Sfx.instance.play('coin', minGapMs: 0));
      }
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
              child: Transform.translate(
                offset: Offset(0, i == 1 ? -widget.size * 0.18 : 0),
                child: CustomPaint(
                  size: Size.square(widget.size * (i == 1 ? 1.2 : 1)),
                  painter: _StarPainter(widget.stars[i], ((_c.value * 1500 - 200 - i * 380) / 420).clamp(0.0, 1.0)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final bool on;
  final double k;
  _StarPainter(this.on, this.k);
  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    Path star(double r) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final rr = i.isEven ? r : r * 0.45;
        final a = -math.pi / 2 + i * math.pi / 5;
        final pt = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      return path..close();
    }

    final r = s.width / 2;
    c.drawPath(star(r), Paint()..color = const Color(0x55061012));
    c.drawPath(
      star(r),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x553A5056),
    );
    if (!on || k <= 0) return;
    final pop = Curves.elasticOut.transform(k);
    c.save();
    c.translate(center.dx, center.dy);
    c.scale(pop);
    c.translate(-center.dx, -center.dy);
    c.drawPath(
      star(r * 1.1),
      Paint()
        ..color = const Color(0x88FFD45E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    c.drawPath(
      star(r),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, center.dy - r),
          Offset(0, center.dy + r),
          const [Color(0xFFFFF4C2), Color(0xFFFFC23D), Color(0xFFE88A1E)],
          const [0, 0.5, 1],
        ),
    );
    c.drawPath(star(r * 0.45), Paint()..color = const Color(0x55FFFFFF));
    c.restore();
    if (k < 1) {
      final burst = Paint()..color = Color.fromRGBO(255, 230, 150, 1 - k);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        c.drawCircle(center + Offset(math.cos(a), math.sin(a)) * r * (0.8 + k * 1.2), 2.5 * (1 - k) + 1, burst);
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter o) => o.k != k || o.on != on;
}

/// 코인 표시
class CoinBadge extends StatelessWidget {
  final int coins;
  const CoinBadge(this.coins, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: const Color(0xAA0C1A1F),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x55FFD45E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0xFFFFF0B0), Color(0xFFE0A93A)]),
              boxShadow: [BoxShadow(color: Color(0x88FFD45E), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 8),
          Text('$coins', style: display(18, color: Palette.gold)),
        ],
      ),
    );
  }
}

/// 둥근 아이콘 버튼 (일시정지 등)
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const RoundIconButton(this.icon, {super.key, required this.onTap, this.size = 46});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Sfx.instance.play('select');
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xAA0C1A1F),
          border: Border.all(color: const Color(0x557FD6B0)),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
        ),
        child: Icon(icon, color: Palette.ink, size: size * 0.5),
      ),
    );
  }
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 450),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, a, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween(begin: 1.04, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
);
