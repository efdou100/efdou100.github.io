import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';

/// 누르면 살짝 눌리는 반응 + 효과음
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.semantic, this.sound = 'click'});
  final Widget child;
  final VoidCallback? onTap;
  final String? semantic;
  final String? sound;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => down = true) : null,
        onTapCancel: () => setState(() => down = false),
        onTapUp: enabled ? (_) => setState(() => down = false) : null,
        onTap: enabled
            ? () {
                if (widget.sound != null) Sfx.instance.play(widget.sound!);
                Sfx.instance.haptic();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(scale: down ? 0.95 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
      ),
    );
  }
}

enum BtnStyle { moon, echo, dusk, ghost }

/// 주요 버튼. 높이 52 이상(터치 48dp 기준 충족), 바닥 그림자로 입체감.
class Btn extends StatelessWidget {
  const Btn(this.label, {super.key, this.onTap, this.style = BtnStyle.moon, this.icon, this.trailing, this.height = 56, this.expand = true, this.sound = 'click'});
  final String label;
  final VoidCallback? onTap;
  final BtnStyle style;
  final Widget? icon;
  final Widget? trailing;
  final double height;
  final bool expand;
  final String? sound;

  @override
  Widget build(BuildContext context) {
    final (top, bottom, edge, fg) = switch (style) {
      BtnStyle.moon => (const Color(0xFFFFE39A), const Color(0xFFFFC14D), const Color(0xFFC8892A), const Color(0xFF2A1B05)),
      BtnStyle.echo => (const Color(0xFFA6F6FF), const Color(0xFF57D9F0), const Color(0xFF2A9BB0), const Color(0xFF052A33)),
      BtnStyle.dusk => (const Color(0xFF2E3A80), const Color(0xFF232C66), const Color(0xFF131848), Palette.ink),
      BtnStyle.ghost => (Colors.transparent, Colors.transparent, Colors.transparent, Palette.inkSoft),
    };
    final disabled = onTap == null;
    final body = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: Space.l),
      decoration: style == BtnStyle.ghost
          ? null
          : BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 4)), if (style == BtnStyle.moon) BoxShadow(color: bottom.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: Space.s)],
          Flexible(child: Text(label, style: ko(TypeScale.label, color: fg), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (trailing != null) ...[const SizedBox(width: Space.s), trailing!],
        ],
      ),
    );
    return Opacity(opacity: disabled ? 0.45 : 1, child: Pressable(onTap: onTap, semantic: label, sound: sound, child: body));
  }
}

/// 둥근 아이콘 버튼 (48×48)
class RoundBtn extends StatelessWidget {
  const RoundBtn({super.key, required this.icon, required this.onTap, required this.label, this.badge = false, this.size = 48});
  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final bool badge;
  final double size;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semantic: label,
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(color: const Color(0xD91E2660), shape: BoxShape.circle, border: Border.all(color: Palette.line)),
            alignment: Alignment.center,
            child: Icon(icon, color: Palette.ink, size: size * 0.48),
          ),
          if (badge) Positioned(right: 2, top: 2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Palette.danger, shape: BoxShape.circle, border: Border.all(color: Palette.night, width: 2)))),
        ],
      ),
    ),
  );
}

/// 코인 아이콘: 금화 위 초승달
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 22});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _CoinPainter());
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2, o = Offset(r, r);
    c.drawCircle(o, r, Paint()..shader = ui.Gradient.radial(o - Offset(r * 0.3, r * 0.3), r * 1.4, [const Color(0xFFFFF0B8), const Color(0xFFF2A93B)]));
    c.drawCircle(o, r * 0.78, Paint()..color = const Color(0x55A05A10)..style = PaintingStyle.stroke..strokeWidth = r * 0.12);
    final moon = Path()
      ..addOval(Rect.fromCircle(center: o, radius: r * 0.45))
      ..addOval(Rect.fromCircle(center: o + Offset(r * 0.22, -r * 0.12), radius: r * 0.38));
    moon.fillType = PathFillType.evenOdd;
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: r * 0.45)));
    c.drawPath(moon, Paint()..color = const Color(0xFFB8721E));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 하트 아이콘
class HeartIcon extends StatelessWidget {
  const HeartIcon({super.key, this.size = 22, this.infinite = false});
  final double size;
  final bool infinite;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _HeartPainter(infinite));
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.infinite);
  final bool infinite;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final p = Path()
      ..moveTo(w / 2, h * 0.88)
      ..cubicTo(-w * 0.1, h * 0.45, w * 0.18, -h * 0.05, w / 2, h * 0.28)
      ..cubicTo(w * 0.82, -h * 0.05, w * 1.1, h * 0.45, w / 2, h * 0.88)
      ..close();
    c.drawPath(p, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), infinite ? [const Color(0xFFB9F7FF), const Color(0xFF3BC4E0)] : [const Color(0xFFFF9FB4), const Color(0xFFE23B62)]));
    c.drawCircle(Offset(w * 0.32, h * 0.32), w * 0.08, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) => old.infinite != infinite;
}

/// 재화 표시 알약
class Pill extends StatelessWidget {
  const Pill({super.key, required this.icon, required this.text, this.sub, this.onTap, this.label = ''});
  final Widget icon;
  final String text;
  final String? sub;
  final VoidCallback? onTap;
  final String label;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semantic: label,
    child: Container(
      height: 40,
      padding: const EdgeInsets.only(left: 6, right: 10),
      decoration: BoxDecoration(color: const Color(0xD9161D52), borderRadius: BorderRadius.circular(20), border: Border.all(color: Palette.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(text, style: numStyle(TypeScale.label)),
          if (sub != null) ...[const SizedBox(width: 6), Text(sub!, style: numStyle(TypeScale.caption, color: Palette.inkSoft))],
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Container(width: 18, height: 18, decoration: const BoxDecoration(color: Palette.moss, shape: BoxShape.circle), child: const Icon(Icons.add, size: 14, color: Color(0xFF0B2B1C))),
          ],
        ],
      ),
    ),
  );
}

class HeartsPill extends StatelessWidget {
  const HeartsPill({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final inf = p.infinite;
    String? sub;
    if (inf) {
      final left = Duration(milliseconds: p.infiniteUntil - DateTime.now().millisecondsSinceEpoch);
      sub = fmtDur(left);
    } else if (p.hearts < Profile.maxHearts) {
      sub = fmtDur(p.nextHeartIn);
    } else {
      sub = '가득';
    }
    return Pill(icon: HeartIcon(infinite: inf), text: inf ? '∞' : '${p.hearts}', sub: sub, onTap: onTap, label: '하트');
  }
}

String fmtDur(Duration d) {
  if (d.inHours >= 1) return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// 아래에서 올라오는 시트 공통 틀
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.child, this.title});
  final Widget child;
  final String? title;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF222C70), Color(0xFF151B4C)]),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      border: Border(top: BorderSide(color: Color(0x40A0B4FF))),
    ),
    padding: EdgeInsets.fromLTRB(Space.xl, Space.m, Space.xl, Space.xl + MediaQuery.of(context).padding.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Palette.line, borderRadius: BorderRadius.circular(2)))),
        if (title != null) ...[const SizedBox(height: Space.l), Text(title!, style: ko(TypeScale.title), textAlign: TextAlign.center)],
        const SizedBox(height: Space.l),
        child,
      ],
    ),
  );
}

Future<T?> showSheet<T>(BuildContext context, Widget child, {bool dismissible = true}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  isDismissible: dismissible,
  enableDrag: dismissible,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0xB3050818),
  builder: (_) => child,
);

/// 별 세 개 (획득한 만큼 차례로 튀어나옴)
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 44, this.animate = true});
  final int stars;
  final double size;
  final bool animate;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.08),
          child: i < stars && animate
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 450 + i * 180),
                  curve: Interval(i * 0.25, 1, curve: Curves.elasticOut),
                  onEnd: () {},
                  builder: (_, v, _) => Transform.scale(scale: v, child: Transform.rotate(angle: (1 - v) * -0.6, child: _star(true))),
                )
              : _star(i < stars),
        ),
    ],
  );

  Widget _star(bool on) => Icon(Icons.star_rounded, size: size, color: on ? Palette.moon : const Color(0xFF343C74), shadows: on ? const [Shadow(color: Color(0xB3FFD36B), blurRadius: 14)] : null);
}

/// 숫자가 올라가며 세어지는 텍스트
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.to, this.from = 0, this.style, this.prefix = ''});
  final int from, to;
  final TextStyle? style;
  final String prefix;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: from.toDouble(), end: to.toDouble()),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text('$prefix${v.round()}', style: style ?? numStyle(TypeScale.title)),
  );
}

/// 밤하늘 배경 (홈·상점 공통)
class NightSky extends StatelessWidget {
  const NightSky({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SkyPainter(), child: child);
}

class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    c.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D1238), Color(0xFF141C52), Color(0xFF0E2A3A)]).createShader(rect));
    final rnd = math.Random(3);
    for (var i = 0; i < 120; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.8), rnd.nextDouble() * 1.3 + 0.2, Paint()..color = Color.fromRGBO(220, 230, 255, 0.2 + rnd.nextDouble() * 0.6));
    }
    final moon = Offset(s.width * 0.82, s.height * 0.1);
    c.drawCircle(moon, 70, Paint()..shader = ui.Gradient.radial(moon, 70, [const Color(0x40FFE9B0), const Color(0x00FFE9B0)]));
    c.drawCircle(moon, 22, Paint()..color = const Color(0xFFFFF1C7));
    c.drawCircle(moon + const Offset(9, -5), 19, Paint()..color = const Color(0xFF111848));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 짧은 안내 띠
class Toast extends StatelessWidget {
  const Toast({super.key, required this.text, this.gold = false});
  final String text;
  final bool gold;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
    decoration: BoxDecoration(color: const Color(0xE60C102E), borderRadius: BorderRadius.circular(14), border: Border.all(color: gold ? const Color(0x80FFD36B) : const Color(0x597EF0FF))),
    child: Text(text, style: ko(TypeScale.body, height: 1.4), textAlign: TextAlign.center),
  );
}

/// 등급 배지 (어려움/아주 어려움/보스)
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.7))),
    child: Text(text, style: ko(TypeScale.caption, color: color)),
  );
}
