import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/art.dart';
import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/theme.dart';
import '../game/level.dart';
import '../game/painter.dart' show WorldTheme;
import '../widgets/icons.dart';
import '../widgets/ui.dart';

/// 홈 탭: 아래에서 위로 이어지는 월드 지도
class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key, required this.onOpenLevel, this.justCleared = false, this.topInset = 0, this.bottomInset = 0});
  final void Function(int index) onOpenLevel;
  final bool justCleared;
  final double topInset, bottomInset;
  @override
  State<HomeMapPage> createState() => HomeMapPageState();
}

class HomeMapPageState extends State<HomeMapPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _unlock = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  static const nodeGap = 108.0;
  static const headerH = 96.0;

  Profile get p => Profile.instance;
  int get current => math.min(p.nextLevelIndex, LevelRepo.instance.count - 1);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.justCleared) {
      _unlock.forward();
    } else {
      _unlock.value = 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToCurrent());
  }

  double _offsetOf(int index) {
    final worlds = index ~/ LevelRepo.levelsPerWorld + 1;
    return index * nodeGap + worlds * headerH + nodeGap / 2;
  }

  void jumpToCurrent({bool animate = false}) {
    if (!_scroll.hasClients) return;
    final target = (widget.bottomInset + _offsetOf(current) - _scroll.position.viewportDimension * 0.42).clamp(0.0, _scroll.position.maxScrollExtent);
    animate ? _scroll.animateTo(target, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic) : _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _unlock.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: EdgeInsets.only(top: widget.topInset + 40, bottom: widget.bottomInset),
      itemCount: LevelRepo.instance.count,
      itemBuilder: (_, i) => _MapRow(index: i, current: current, pulse: _pulse, unlock: _unlock, onTap: () => widget.onOpenLevel(i), gap: nodeGap, headerH: headerH),
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({required this.index, required this.current, required this.pulse, required this.unlock, required this.onTap, required this.gap, required this.headerH});
  final int index, current;
  final Animation<double> pulse, unlock;
  final VoidCallback onTap;
  final double gap, headerH;

  static double xOf(int i, double w) => w / 2 + math.sin(i * 0.85 + 0.6) * (w * 0.24);

  @override
  Widget build(BuildContext context) {
    final l = LevelRepo.instance[index];
    final worldStart = index % LevelRepo.levelsPerWorld == 0;
    return SizedBox(
      height: gap + (worldStart ? headerH : 0),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final x = xOf(index, w), nx = xOf(index + 1, w);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _SceneryPainter(index: index, world: l.world, gap: gap))),
            if (index < LevelRepo.instance.count - 1)
              Positioned(
                left: 0,
                right: 0,
                top: -gap,
                height: gap * 2,
                child: AnimatedBuilder(
                  animation: unlock,
                  builder: (_, _) => CustomPaint(painter: _PathPainter(x, nx, gap, world: l.world, fill: index == current - 1 ? Curves.easeInOut.transform((unlock.value / 0.55).clamp(0.0, 1.0)) : (index < current - 1 ? 1 : 0))),
                ),
              ),
            if (worldStart) Positioned(left: 0, right: 0, top: gap, height: headerH, child: _WorldBanner(world: l.world, locked: index > current)),
            _MapNode(level: l, index: index, current: current, x: x, y: gap / 2, pulse: pulse, unlock: unlock, onTap: onTap),
          ],
        );
      }),
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({required this.level, required this.index, required this.current, required this.x, required this.y, required this.pulse, required this.unlock, required this.onTap});
  final LevelData level;
  final int index, current;
  final double x, y;
  final Animation<double> pulse, unlock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final stars = p.stars[level.id] ?? 0;
    final locked = index > current;
    final isCur = index == current;
    final boss = level.tier == Tier.boss;
    final size = locked ? 46.0 : (boss ? 76.0 : (isCur ? 68.0 : 58.0));
    final artId = locked ? 'map/node_locked' : (isCur ? 'map/node_current' : (boss ? 'map/node_boss' : (level.tier == Tier.hard || level.tier == Tier.superhard ? 'map/node_hard' : 'map/node_open')));
    Widget node = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: ArtImage(artId, fit: BoxFit.contain, fallback: CustomPaint(painter: _MedallionPainter(level: level, locked: locked, current: isCur)))),
          if (locked)
            const GameIcon(GI.lock, size: 20)
          else
            Text('${level.id}', style: numStyle(isCur ? 25 : 20, color: isCur ? const Color(0xFF3A2208) : Palette.ink).copyWith(shadows: isCur ? null : const [Shadow(color: Color(0x99000000), offset: Offset(0, 1.5), blurRadius: 2)])),
        ],
      ),
    );
    if (isCur) {
      node = AnimatedBuilder(
        animation: Listenable.merge([pulse, unlock]),
        builder: (_, child) {
          final u = Curves.elasticOut.transform(((unlock.value - 0.5) / 0.5).clamp(0.0, 1.0));
          final breathe = 1 + math.sin(pulse.value * math.pi * 2) * 0.04;
          return Transform.scale(scale: (unlock.value < 1 ? 0.3 + u * 0.7 : 1) * breathe, child: child);
        },
        child: node,
      );
    }
    return Positioned(
      left: x - 64,
      top: y - 64,
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isCur) Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: Listenable.merge([pulse, unlock]), builder: (_, _) => CustomPaint(painter: _RingsPainter(pulse.value, unlock.value))))),
          Pressable(
            onTap: locked ? null : onTap,
            semantic: '${tr('level_n', {'n': level.id})} ${levelName(level.name)}${stars > 0 ? ' ★$stars' : ''}',
            sound: 'pop',
            child: node,
          ),
          if (!locked && stars > 0) Positioned(top: 64 - size / 2 - 17, child: IgnorePointer(child: _StarArc(stars: stars))),
          if (boss && !locked) Positioned(top: 64 - size / 2 - (stars > 0 ? 36 : 22), child: const IgnorePointer(child: GameIcon(GI.crown, size: 26))),
          if (isCur)
            Positioned(
              left: 64 + size / 2 - 6,
              top: 18,
              child: IgnorePointer(
                child: AnimatedBuilder(animation: pulse, builder: (_, child) => Transform.translate(offset: Offset(0, -math.sin(pulse.value * math.pi * 2).abs() * 6), child: child), child: const _Avatar()),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarArc extends StatelessWidget {
  const _StarArc({required this.stars});
  final int stars;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62,
    height: 20,
    child: Stack(children: [for (var s = 0; s < 3; s++) Positioned(left: 4 + s * 18.0, top: s == 1 ? 0 : 5, child: GameIcon(GI.star, size: s == 1 ? 18 : 16, color: s < stars ? null : const Color(0xFF39407A)))]),
  );
}

class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.level, required this.locked, required this.current});
  final LevelData level;
  final bool locked, current;

  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2, o = Offset(r, r);
    final th = WorldTheme.of(level.world);
    c.drawOval(Rect.fromCenter(center: o.translate(0, r * 0.82), width: r * 1.8, height: r * 0.5), Paint()..color = const Color(0x66000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    if (locked) {
      c.drawCircle(o, r, Paint()..shader = ui.Gradient.radial(o.translate(-r * 0.3, -r * 0.4), r * 1.5, [const Color(0xFF39406E), const Color(0xFF1A1F44)]));
      c.drawCircle(o, r - 1, Paint()..color = const Color(0x33A7B2DE)..style = PaintingStyle.stroke..strokeWidth = 2);
      return;
    }
    final tierCol = switch (level.tier) { Tier.hard => Palette.danger, Tier.superhard => Palette.violet, Tier.boss => Palette.moon, _ => null };
    if (tierCol != null) c.drawCircle(o, r + 4, Paint()..color = tierCol.withValues(alpha: 0.55)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    c.drawCircle(o, r, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), current ? const [Color(0xFFFFF3CF), Color(0xFFC8892A)] : [tierCol ?? const Color(0xFFCFD8FF), const Color(0xFF2A3266)]));
    final inner = r * 0.84;
    final cols = current ? const [Color(0xFFFFE39A), Color(0xFFFFB84A)] : level.isEcho ? const [Color(0xFF3FA7C0), Color(0xFF1C566C)] : [Color.lerp(th.accent, const Color(0xFF3A4AA0), 0.7)!, const Color(0xFF22296A)];
    c.drawCircle(o, inner, Paint()..shader = ui.Gradient.radial(o.translate(-inner * 0.3, -inner * 0.45), inner * 1.4, cols));
    c.drawArc(Rect.fromCircle(center: o, radius: inner * 0.82), -2.7, 2.2, false, Paint()..color = Colors.white.withValues(alpha: current ? 0.6 : 0.28)..style = PaintingStyle.stroke..strokeWidth = inner * 0.16..strokeCap = StrokeCap.round);
    c.drawArc(Rect.fromCircle(center: o, radius: inner * 0.9), 0.5, 2.1, false, Paint()..color = th.accent.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter old) => old.locked != locked || old.current != current || old.level.id != level.id;
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t, this.unlock);
  final double t, unlock;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    for (var k = 0; k < 2; k++) {
      final ph = (t + k * 0.5) % 1;
      c.drawCircle(o, 36 + ph * 26, Paint()..color = Palette.moon.withValues(alpha: (1 - ph) * 0.45)..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1 - ph) + 0.5);
    }
    c.drawCircle(o, 44, Paint()..color = Palette.moon.withValues(alpha: 0.16)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    if (unlock < 1 && unlock > 0.5) {
      final k = (unlock - 0.5) / 0.5;
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6 + k;
        c.drawLine(o + Offset.fromDirection(a, 30), o + Offset.fromDirection(a, 30 + 50 * k), Paint()..color = Palette.moon.withValues(alpha: (1 - k) * 0.8)..strokeWidth = 3..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => true;
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.x, this.nx, this.gap, {required this.world, required this.fill});
  final double x, nx, gap, fill;
  final int world;
  @override
  void paint(Canvas c, Size s) {
    final a = Offset(x, gap * 1.5), b = Offset(nx, gap * 0.5);
    final path = Path()..moveTo(a.dx, a.dy)..cubicTo(a.dx, a.dy - gap * 0.55, b.dx, b.dy + gap * 0.55, b.dx, b.dy);
    final th = WorldTheme.of(world);
    c.drawPath(path, Paint()..color = const Color(0x40000000)..strokeWidth = 26..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawPath(path, Paint()..color = th.silhouette.withValues(alpha: 0.85)..strokeWidth = 18..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final m = path.computeMetrics().first;
    final len = m.length;
    for (var d = 8.0; d < len - 8; d += 15) {
      final pos = m.getTangentForOffset(d)!.position;
      final lit = d / len <= fill;
      c.drawCircle(pos, lit ? 3.2 : 2.4, Paint()..color = lit ? Palette.moon : const Color(0x66A7B2DE));
      if (lit) c.drawCircle(pos, 6, Paint()..color = const Color(0x40FFD36B)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.fill != fill || old.x != x;
}

/// 길 양옆 풍경 (월드별). 이미지(bg/world{n}_map)가 있으면 그 이미지를 이어 붙인다.
class _SceneryPainter extends CustomPainter {
  _SceneryPainter({required this.index, required this.world, required this.gap});
  final int index, world;
  final double gap;

  @override
  void paint(Canvas c, Size s) {
    final th = WorldTheme.of(world);
    final img = Art.instance.image('bg/world${world}_map');
    final local = index % LevelRepo.levelsPerWorld;
    if (img != null) {
      final scale = s.width / img.width;
      final ih = img.height * scale;
      final fromTop = (LevelRepo.levelsPerWorld - 1 - local) * gap;
      final srcY = (fromTop % ih) / scale;
      final visible = math.min(s.height, (img.height - srcY) * scale);
      c.drawImageRect(img, Rect.fromLTWH(0, srcY, img.width.toDouble(), visible / scale), Rect.fromLTWH(0, 0, s.width, visible), Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    c.drawRect(Offset.zero & s, Paint()..color = th.fieldBottom.withValues(alpha: 0.32));
    final rnd = math.Random(index * 31 + world * 7);
    final w = s.width;
    for (final left in const [true, false]) {
      final n = 1 + rnd.nextInt(2);
      for (var k = 0; k < n; k++) {
        final x = left ? 8 + rnd.nextDouble() * 60 : w - 8 - rnd.nextDouble() * 60;
        final y = rnd.nextDouble() * gap;
        switch (world) {
          case 1:
            _tree(c, Offset(x, y + 40), 26 + rnd.nextDouble() * 18);
            if (rnd.nextDouble() < 0.5) _mushroom(c, Offset(x + (left ? 32 : -32), y + 62), 6 + rnd.nextDouble() * 4);
          case 2:
            c.drawRect(Rect.fromLTWH(x, y - 20, 7, 110), Paint()..color = const Color(0x80DDE6FF));
            for (var i = 0; i < 4; i++) {
              c.drawRect(Rect.fromLTWH(x, y - 10 + rnd.nextDouble() * 90, 7, 2), Paint()..color = const Color(0x66101830));
            }
            _shard(c, Offset(x + (left ? 34 : -34), y + 20), 6 + rnd.nextDouble() * 6);
          case 3:
            for (var i = 0; i < 3; i++) {
              _crystal(c, Offset(x + (i - 1) * 9.0, y + 70), 18 + rnd.nextDouble() * 22, i.isEven ? Palette.violet : Palette.echo, (i - 1) * 0.35);
            }
          case 4:
            c.drawCircle(Offset(x, y + 50), 22, Paint()..color = Palette.echo.withValues(alpha: 0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + 50), width: 22, height: 34), const Radius.circular(6)), Paint()..color = const Color(0xFF1C2E4E));
            c.drawLine(Offset(x - 4, y + 42), Offset(x + 4, y + 58), Paint()..color = Palette.echo.withValues(alpha: 0.7)..strokeWidth = 2);
          default:
            final o = Offset(x, y + 50);
            c.drawPath(Path()..moveTo(o.dx - 26, o.dy)..lineTo(o.dx + 26, o.dy)..lineTo(o.dx + 6, o.dy + 30)..lineTo(o.dx - 8, o.dy + 22)..close(), Paint()..color = const Color(0xFF14123A));
            c.drawRect(Rect.fromLTWH(o.dx - 26, o.dy - 3, 52, 4), Paint()..color = Palette.moon.withValues(alpha: 0.45));
        }
      }
    }
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * s.height), 1.2, Paint()..color = th.glow.withValues(alpha: 0.5));
    }
  }

  void _tree(Canvas c, Offset o, double r) {
    c.drawRect(Rect.fromCenter(center: o.translate(0, r * 0.9), width: r * 0.28, height: r), Paint()..color = const Color(0xFF2A1E2E));
    for (final d in [Offset(0, -r * 0.2), Offset(-r * 0.55, r * 0.15), Offset(r * 0.55, r * 0.15)]) {
      c.drawCircle(o + d, r * 0.62, Paint()..color = const Color(0xFF123A3A));
    }
    c.drawCircle(o.translate(-r * 0.2, -r * 0.45), r * 0.3, Paint()..color = const Color(0x33FFE9A0));
  }

  void _mushroom(Canvas c, Offset o, double r) {
    c.drawRect(Rect.fromCenter(center: o.translate(0, r * 0.7), width: r * 0.6, height: r * 1.2), Paint()..color = const Color(0xFFE8D9C8));
    c.drawCircle(o, r * 1.6, Paint()..color = const Color(0x55FF7896)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawArc(Rect.fromCircle(center: o, radius: r), math.pi, math.pi, true, Paint()..color = const Color(0xFFE04A74));
    c.drawCircle(o.translate(-r * 0.3, -r * 0.4), r * 0.18, Paint()..color = Colors.white);
  }

  void _shard(Canvas c, Offset o, double r) {
    c.drawPath(Path()..moveTo(o.dx, o.dy - r)..lineTo(o.dx + r * 0.6, o.dy)..lineTo(o.dx, o.dy + r * 1.2)..lineTo(o.dx - r * 0.5, o.dy)..close(), Paint()..color = const Color(0x99DDEBFF));
    c.drawCircle(o, r * 1.6, Paint()..color = const Color(0x22DDEBFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }

  void _crystal(Canvas c, Offset o, double h, Color col, double tilt) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(tilt);
    final p = Path()..moveTo(0, -h)..lineTo(h * 0.28, -h * 0.55)..lineTo(h * 0.22, 0)..lineTo(-h * 0.22, 0)..lineTo(-h * 0.28, -h * 0.55)..close();
    c.drawPath(p, Paint()..color = col.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawPath(p, Paint()..shader = ui.Gradient.linear(Offset(0, -h), Offset.zero, [col, col.withValues(alpha: 0.3)]));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _SceneryPainter old) => old.index != index;
}

class _WorldBanner extends StatelessWidget {
  const _WorldBanner({required this.world, required this.locked});
  final int world;
  final bool locked;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final levels = LevelRepo.instance.levels.where((l) => l.world == world);
    final got = levels.fold<int>(0, (a, l) => a + (p.stars[l.id] ?? 0));
    final th = WorldTheme.of(world);
    return Center(
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RibbonTitle(text: worldName(world), color: th.accent),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xB3101640), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${tr('world_n', {'n': world})} · ', style: numStyle(TypeScale.caption, color: th.accent)),
                if (locked) const GameIcon(GI.lock, size: 14) else const GameIcon(GI.star, size: 14),
                const SizedBox(width: 4),
                Text(tr('world_stars', {'a': got, 'b': levels.length * 3}), style: numStyle(TypeScale.caption, color: Palette.inkSoft)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) => ArtImage('char/archer_idle', size: const Size(54, 54), fallback: CustomPaint(size: const Size(44, 48), painter: AvatarPainter()));
}

/// 궁수 루미 (이미지 없을 때)
class AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 44);
    c.translate(22, 28);
    c.drawOval(const Rect.fromLTWH(-14, 16, 28, 7), Paint()..color = const Color(0x55000000));
    c.drawPath(Path()..moveTo(-12, 0)..quadraticBezierTo(-15, 18, -9, 20)..lineTo(9, 20)..quadraticBezierTo(15, 18, 12, 0)..close(), Paint()..color = const Color(0xFF26306E));
    c.drawCircle(const Offset(0, -4), 12, Paint()..shader = ui.Gradient.radial(const Offset(-4, -9), 15, [const Color(0xFF5263C0), const Color(0xFF34419A)]));
    for (final sgn in const [-1.0, 1.0]) {
      c.drawPath(Path()..moveTo(sgn * 4, -14)..lineTo(sgn * 9, -23)..lineTo(sgn * 11, -10)..close(), Paint()..color = const Color(0xFF3B4AA0));
    }
    c.drawOval(const Rect.fromLTWH(-7.5, -10.5, 15, 13), Paint()..color = const Color(0xFFFFE9CF));
    c.drawCircle(const Offset(-2.5, -4), 1.7, Paint()..color = const Color(0xFF1B1440));
    c.drawCircle(const Offset(3, -4), 1.7, Paint()..color = const Color(0xFF1B1440));
    c.drawCircle(const Offset(-2, -4.6), 0.55, Paint()..color = Colors.white);
    c.drawCircle(const Offset(3.5, -4.6), 0.55, Paint()..color = Colors.white);
    c.drawCircle(const Offset(-5.5, -1), 1.6, Paint()..color = const Color(0x66FF8CAA));
    c.drawCircle(const Offset(5.5, -1), 1.6, Paint()..color = const Color(0x66FF8CAA));
    c.drawCircle(const Offset(0, 4), 2.4, Paint()..color = Palette.moon);
    c.drawCircle(const Offset(1.1, 3.4), 1.9, Paint()..color = const Color(0xFF26306E));
    c.drawArc(const Rect.fromLTWH(4, -16, 24, 32), -1.2, 2.4, false, Paint()..color = Palette.moon..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    c.drawLine(Offset(16 + math.cos(-1.2) * 12, math.sin(-1.2) * 16), Offset(16 + math.cos(1.2) * 12, math.sin(1.2) * 16), Paint()..color = Colors.white70..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
