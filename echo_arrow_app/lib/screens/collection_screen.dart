import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/art.dart';
import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/theme.dart';
import '../game/level.dart';
import '../widgets/icons.dart';
import '../widgets/ui.dart';

/// 도감 탭: 만난 정령과 장치를 모아 보는 곳 (수집 욕구 + 규칙 복습)
class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, this.topInset = 0, this.bottomInset = 0});
  final double topInset, bottomInset;

  static final spirits = <_Entry>[
    _Entry('spirit_sleep', 'spirit/sleep', (l) => true),
    _Entry('spirit_moving', 'spirit/sleep', (l) => l.targets.any((t) => t.per > 0)),
    _Entry('spirit_shield', 'spirit/shield', (l) => l.targets.any((t) => t.shield != null)),
    _Entry('spirit_baby', 'spirit/baby_sleep', (l) => l.targets.any((t) => t.avoid)),
  ];
  static final devices = <_Entry>[
    _Entry('dev_wood', 'tile/wood_block', (l) => true),
    _Entry('dev_moss', 'tile/moss_block', (l) => l.blocks.any((b) => b.k == 'm') || l.walls.any((w) => w.k == 'm') || l.edges.values.any((e) => e.any((s) => s.k == 'm'))),
    _Entry('dev_bumper', 'device/bumper', (l) => l.bumpers.isNotEmpty),
    _Entry('dev_mirror', 'device/mirror', (l) => l.mirrors.isNotEmpty),
    _Entry('dev_ice', 'tile/ice', (l) => l.blocks.any((b) => b.k == 'i')),
    _Entry('dev_portal', 'device/portal_a', (l) => l.portals.isNotEmpty),
    _Entry('dev_prism', 'device/prism', (l) => l.prisms.isNotEmpty),
    _Entry('dev_gate', 'device/switch_on', (l) => l.gates.isNotEmpty),
    _Entry('dev_echo', 'char/arrow', (l) => l.par > 1),
  ];

  @override
  Widget build(BuildContext context) {
    final reached = Profile.instance.nextLevelIndex;
    int firstAt(_Entry e) {
      final i = LevelRepo.instance.levels.indexWhere(e.test);
      return i < 0 ? 9999 : i;
    }

    Widget grid(List<_Entry> list) => GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.s,
      crossAxisSpacing: Space.s,
      childAspectRatio: 0.82,
      children: [for (final e in list) _Card(entry: e, at: firstAt(e), found: firstAt(e) <= reached)],
    );

    final spiritsFound = spirits.where((e) => firstAt(e) <= reached).length;
    final devicesFound = devices.where((e) => firstAt(e) <= reached).length;
    return ListView(
      padding: EdgeInsets.fromLTRB(Space.l, topInset + Space.m, Space.l, bottomInset + Space.xl),
      children: [
        Center(child: RibbonTitle(text: tr('collection'), color: Palette.violet)),
        const SizedBox(height: Space.l),
        _Header(tr('col_spirits'), tr('col_found', {'a': spiritsFound, 'b': spirits.length})),
        grid(spirits),
        const SizedBox(height: Space.l),
        _Header(tr('col_devices'), tr('col_found', {'a': devicesFound, 'b': devices.length})),
        grid(devices),
      ],
    );
  }
}

class _Entry {
  const _Entry(this.key, this.art, this.test);
  final String key, art;
  final bool Function(LevelData) test;
}

class _Header extends StatelessWidget {
  const _Header(this.title, this.sub);
  final String title, sub;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.s, left: 4),
    child: Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: Palette.violet, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: Space.s),
      Text(title, style: ko(TypeScale.label)),
      const Spacer(),
      Text(sub, style: numStyle(TypeScale.caption, color: Palette.inkSoft)),
    ]),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.entry, required this.at, required this.found});
  final _Entry entry;
  final int at;
  final bool found;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.m),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: found ? const [Color(0xFF2E3A84), Color(0xFF1A2058)] : const [Color(0xFF1C2252), Color(0xFF12163C)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: found ? const Color(0x77B38CFF) : Palette.line),
    ),
    child: Column(
      children: [
        Expanded(
          child: found
              ? ArtImage(entry.art, fallback: CustomPaint(painter: _MiniPainter(entry.key), size: Size.infinite))
              : const Center(child: GameIcon(GI.lock, size: 36)),
        ),
        const SizedBox(height: Space.s),
        Text(found ? tr(entry.key) : '???', style: ko(TypeScale.label), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(found ? tr('${entry.key}_d') : tr('met_at', {'n': at + 1}), style: ko(TypeScale.caption, color: Palette.inkSoft, height: 1.3), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

/// 이미지가 없을 때의 작은 미리보기 그림
class _MiniPainter extends CustomPainter {
  _MiniPainter(this.key);
  final String key;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final r = math.min(s.width, s.height) * 0.3;
    void spirit(Color a, Color b, {bool shield = false, bool baby = false}) {
      c.drawCircle(o, r * 1.4, Paint()..color = b.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      for (final sgn in const [-1.0, 1.0]) {
        c.save();
        c.translate(o.dx + sgn * r * 0.45, o.dy - r * 0.9);
        c.rotate(0.5 * sgn);
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.4, height: r * 0.85), Paint()..color = b);
        c.restore();
      }
      c.drawCircle(o, r * (baby ? 0.85 : 1), Paint()..shader = ui.Gradient.radial(o.translate(-r * 0.3, -r * 0.35), r * 1.3, [a, b]));
      final face = Paint()..color = const Color(0xFF1B2456)..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      for (final ex in const [-0.3, 0.3]) {
        c.drawArc(Rect.fromCircle(center: o.translate(ex * r, -r * 0.05), radius: r * 0.16), 0.1, math.pi - 0.2, false, face);
      }
      if (shield) c.drawArc(Rect.fromCircle(center: o, radius: r * 1.35), -1.1, 2.2, false, Paint()..color = const Color(0xFFDDE6FF)..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }

    switch (key) {
      case 'spirit_sleep':
      case 'spirit_moving':
        spirit(const Color(0xFFF2FDFF), const Color(0xFF6FB7FF));
        if (key == 'spirit_moving') {
          for (final d in const [-1.0, 1.0]) {
            c.drawLine(o.translate(d * r * 1.6, 0), o.translate(d * r * 2.1, 0), Paint()..color = Palette.inkSoft..strokeWidth = 2..strokeCap = StrokeCap.round);
          }
        }
      case 'spirit_shield':
        spirit(const Color(0xFFF2FDFF), const Color(0xFF6FB7FF), shield: true);
      case 'spirit_baby':
        spirit(const Color(0xFFFFF0F6), const Color(0xFFFF8FB8), baby: true);
      case 'dev_wood':
        c.drawLine(o.translate(-r * 1.6, 0), o.translate(r * 1.6, 0), Paint()..color = const Color(0xFF8A5A3B)..strokeWidth = 14..strokeCap = StrokeCap.round);
      case 'dev_moss':
        c.drawLine(o.translate(-r * 1.6, 0), o.translate(r * 1.6, 0), Paint()..color = const Color(0xFF2F7A52)..strokeWidth = 16..strokeCap = StrokeCap.round);
        for (var i = 0; i < 10; i++) {
          c.drawCircle(o.translate(-r * 1.5 + i * r * 0.33, -6 + (i % 3) * 4.0), 4, Paint()..color = Palette.moss);
        }
      case 'dev_bumper':
        c.drawCircle(o, r, Paint()..shader = ui.Gradient.radial(o.translate(-r * 0.3, -r * 0.4), r * 1.2, const [Color(0xFFFF9FB4), Color(0xFFC2365A)]));
        c.drawCircle(o.translate(-r * 0.4, -r * 0.3), r * 0.2, Paint()..color = Colors.white);
      case 'dev_mirror':
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(-0.7);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r * 3, height: 9), const Radius.circular(4)), Paint()..shader = ui.Gradient.linear(const Offset(0, -5), const Offset(0, 5), const [Colors.white, Color(0xFF5D7AA8)]));
        c.restore();
      case 'dev_ice':
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: r * 3, height: r * 0.8), const Radius.circular(4)), Paint()..color = const Color(0xCCBFEFFF));
      case 'dev_portal':
        for (final e in [(-0.8, const Color(0xFFFF9F5A)), (0.8, const Color(0xFF5AB8FF))]) {
          c.drawCircle(o.translate(e.$1 * r * 1.2, 0), r * 0.7, Paint()..color = e.$2..style = PaintingStyle.stroke..strokeWidth = 5);
        }
      case 'dev_prism':
        final p = Path()..moveTo(o.dx, o.dy - r)..lineTo(o.dx + r * 0.8, o.dy)..lineTo(o.dx, o.dy + r)..lineTo(o.dx - r * 0.8, o.dy)..close();
        c.drawPath(p, Paint()..shader = ui.Gradient.linear(o.translate(-r, -r), o.translate(r, r), const [Color(0xFFFF7A8A), Color(0xFFFFD36B), Color(0xFF7EF0FF)], const [0, 0.5, 1]));
      case 'dev_gate':
        c.drawCircle(o.translate(-r * 0.9, r * 0.5), r * 0.45, Paint()..color = Palette.echo);
        c.drawLine(o.translate(-r * 0.2, -r * 0.5), o.translate(r * 1.6, -r * 0.5), Paint()..color = Palette.violet..strokeWidth = 8..strokeCap = StrokeCap.round);
      default:
        for (var k = 0; k < 3; k++) {
          final y = o.dy - r + k * r;
          c.drawLine(Offset(o.dx - r * 1.4, y), Offset(o.dx + r * 1.2, y), Paint()..color = Palette.shot[k].withValues(alpha: 1 - k * 0.25)..strokeWidth = 3..strokeCap = StrokeCap.round);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => old.key != key;
}

