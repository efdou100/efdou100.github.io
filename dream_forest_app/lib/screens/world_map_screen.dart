import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/save_data.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/stages.dart';
import '../widgets/ui_kit.dart';
import 'camp_screen.dart';
import 'game_screen.dart';

/// 잠든 숲 지도: 구불구불한 빛의 길 위에 스테이지 10개 + 끝없는 숲.
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});
  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  final ScrollController _scroll = ScrollController();
  int selected = 0; // 0..9, 10 = 끝없는 숲
  static const double nodeGap = 150, pad = 120;

  @override
  void initState() {
    super.initState();
    selected = math.min(SaveData.instance.unlockedStage, 10) - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        final w = MediaQuery.of(context).size.width;
        _scroll.jumpTo((pad + selected * nodeGap - w / 2).clamp(0, _scroll.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Offset nodePos(int i, double h) => Offset(pad + i * nodeGap, h * 0.46 + math.sin(i * 1.15) * h * 0.13);

  void _start() {
    final save = SaveData.instance;
    StageDef stage;
    var depth = 0;
    if (selected == 10) {
      depth = save.endlessBest + 1;
      stage = endlessStage(depth, DateTime.now().millisecondsSinceEpoch);
    } else {
      stage = kStages[selected];
    }
    Navigator.of(context).push(fadeRoute(GameScreen(stage: stage, endlessDepth: depth))).then((_) {
      if (!mounted) return;
      setState(() => selected = math.min(save.unlockedStage, 10) - 1 + (selected == 10 ? 1 : 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    Sfx.instance.music('map');
    return Scaffold(
      body: ForestBackdrop(
        dim: 0.25,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, cons) {
              final h = cons.maxHeight - 150;
              final total = pad * 2 + nodeGap * 10;
              return Stack(
                children: [
                  Positioned.fill(
                    bottom: 150,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: total,
                        height: h,
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, _) => Stack(
                            children: [
                              Positioned.fill(child: CustomPaint(painter: _PathPainter(this, h, save.unlockedStage, _pulse.value))),
                              for (var i = 0; i <= 10; i++) _node(i, h, save),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        RoundIconButton(Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 14),
                        const ShinyTitle('잠든 숲', size: 30),
                        const Spacer(),
                        Text('★ ${save.totalStars}/30', style: display(18, color: Palette.gold)),
                        const SizedBox(width: 12),
                        CoinBadge(save.coins),
                        const SizedBox(width: 10),
                        GlowButton(
                          label: '캠프',
                          fontSize: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          colors: GlowButton.secondary,
                          textColor: Palette.ink,
                          icon: Icons.local_fire_department_rounded,
                          onTap: () => Navigator.of(context).push(fadeRoute(const CampScreen())).then((_) => setState(() {})),
                        ),
                      ],
                    ),
                  ),
                  Positioned(left: 16, right: 16, bottom: 10, child: _infoPanel(save)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _unlocked(int i, SaveData s) => i == 10 ? s.endlessUnlocked : i + 1 <= s.unlockedStage;

  Widget _node(int i, double h, SaveData save) {
    final pos = nodePos(i, h);
    final unlocked = _unlocked(i, save);
    final isSel = i == selected;
    final isBoss = i < 10 && kStages[i].isBoss;
    final stars = i < 10 ? (save.stars[i + 1] ?? 0) : 0;
    final size = isBoss || i == 10 ? 74.0 : 62.0;
    final pulse = 0.5 + 0.5 * math.sin(_pulse.value * math.pi * 2);
    final List<Color> colors = !unlocked
        ? const [Color(0xFF3A4A4E), Color(0xFF1E2A2D)]
        : i == 10
        ? const [Color(0xFFE6D2FF), Color(0xFF8A5FE0)]
        : isBoss
        ? const [Color(0xFFFFB3D2), Color(0xFFD0508A)]
        : const [Color(0xFFFFE9B0), Color(0xFFE8A13E)];
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: GestureDetector(
        onTap: unlocked ? () => setState(() => selected = i) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSel ? 1.15 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: colors),
                  border: Border.all(color: isSel ? Colors.white : const Color(0x66FFFFFF), width: isSel ? 3 : 1.5),
                  boxShadow: unlocked
                      ? [
                          BoxShadow(
                            color: colors.last.withValues(alpha: isSel ? 0.5 + 0.3 * pulse : 0.35),
                            blurRadius: isSel ? 28 : 14,
                            spreadRadius: isSel ? 4 : 0,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: !unlocked
                    ? const Icon(Icons.lock_rounded, color: Color(0xFF8A9A9E), size: 26)
                    : i == 10
                    ? const Icon(Icons.all_inclusive_rounded, color: Color(0xFF2A1450), size: 34)
                    : isBoss
                    ? Icon(Icons.whatshot_rounded, color: const Color(0xFF4A0F2A), size: size * 0.48)
                    : Text('${i + 1}', style: display(28, color: const Color(0xFF3A2008))),
              ),
            ),
            const SizedBox(height: 6),
            if (i < 10) StarRow(stars: [stars >= 1, stars >= 2, stars >= 3], size: 15),
          ],
        ),
      ),
    );
  }

  Widget _infoPanel(SaveData save) {
    final endless = selected == 10;
    final stage = endless ? null : kStages[selected];
    final stars = endless ? 0 : (save.stars[selected + 1] ?? 0);
    final found = endless ? 0 : (save.shardsFound[selected + 1]?.length ?? 0);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(endless ? '끝없는 숲' : 'STAGE ${selected + 1}', style: display(14, color: Palette.mute)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        endless ? '최고 깊이 ${save.endlessBest}' : stage!.name,
                        style: display(24, color: Palette.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(endless ? '방 조합이 매번 바뀌어요. 어디까지 갈 수 있을까요?' : stage!.subtitle, style: const TextStyle(color: Palette.mute, fontSize: 13)),
                if (!endless) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _goal('클리어', stars >= 1),
                      _goal('체력 절반 이상 남기기', stars >= 2),
                      _goal('꿈 조각 $found/${stage!.shardCount}', found >= stage.shardCount && stage.shardCount > 0),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GlowButton(label: '출발', icon: Icons.play_arrow_rounded, fontSize: 24, onTap: _unlocked(selected, save) ? _start : null),
        ],
      ),
    );
  }

  Widget _goal(String text, bool done) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(done ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: done ? Palette.gold : Palette.mute),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 13, color: done ? Palette.ink : Palette.mute)),
    ],
  );
}

class _PathPainter extends CustomPainter {
  final _WorldMapScreenState s;
  final double h, pulse;
  final int unlocked;
  _PathPainter(this.s, this.h, this.unlocked, this.pulse);

  @override
  void paint(Canvas c, Size size) {
    final pts = [for (var i = 0; i <= 10; i++) s.nodePos(i, h)];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      path.cubicTo(a.dx + 60, a.dy, b.dx - 60, b.dy, b.dx, b.dy);
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = const Color(0x44061012)
        ..strokeCap = StrokeCap.round,
    );
    // 열린 구간은 빛나는 점선
    final metric = path.computeMetrics().first;
    final openLen = metric.length * (math.min(unlocked, 11) - 1) / 10;
    for (var d = 0.0; d < metric.length; d += 16) {
      final tan = metric.getTangentForOffset(d);
      if (tan == null) continue;
      final open = d <= openLen;
      final glow = open ? 0.6 + 0.4 * math.sin(pulse * math.pi * 2 - d / 60) : 0.25;
      c.drawCircle(tan.position, open ? 3.5 : 2.5, Paint()..color = open ? Color.fromRGBO(255, 214, 140, glow) : const Color(0x447F9A9E));
    }
    // 길가 장식: 버섯과 풀
    final r = math.Random(5);
    for (var i = 0; i < 40; i++) {
      final x = r.nextDouble() * size.width, y = h * 0.2 + r.nextDouble() * h * 0.7;
      final col = i.isEven ? const Color(0xFFF2A55E) : const Color(0xFFE07AA8);
      c.drawCircle(
        Offset(x, y),
        12,
        Paint()
          ..color = col.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      c.drawArc(Rect.fromCenter(center: Offset(x, y), width: 10, height: 7), math.pi, math.pi, true, Paint()..color = col.withValues(alpha: 0.7));
    }
    c.drawRect(Offset.zero & size, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), const [Color(0x00000000), Color(0x00000000)]));
  }

  @override
  bool shouldRepaint(_PathPainter o) => true;
}
