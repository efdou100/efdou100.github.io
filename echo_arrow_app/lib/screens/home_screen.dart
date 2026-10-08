import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import '../app/theme.dart';
import '../game/level.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';
import 'meta_sheets.dart';
import 'pass_screen.dart';
import 'shop_screen.dart';

/// 홈: 아래에서 위로 올라가는 숲길 지도
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.autoStart = false});
  final bool autoStart;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  Timer? _clock;
  static const nodeGap = 96.0;

  Profile get p => Profile.instance;
  int get current => math.min(p.nextLevelIndex, LevelRepo.instance.count - 1);

  @override
  void initState() {
    super.initState();
    p.addListener(_refresh);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      p.tickHearts();
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  void _refresh() => mounted ? setState(() {}) : null;

  Future<void> _afterFirstFrame() async {
    _jumpToCurrent();
    // 온보딩 팝업 순서: 출석 → 스타터 팩 → (자동 시작)
    if (p.checkinAvailable && !p.seen.contains('checkin_${Profile.today()}')) {
      p.seen.add('checkin_${Profile.today()}');
      p.save();
      await showSheet<void>(context, const CheckinSheet());
    }
    if (!mounted) return;
    if (p.starterActive && !p.seen.contains('starter_popup')) {
      p.seen.add('starter_popup');
      p.save();
      await showSheet<void>(context, const StarterOfferSheet());
    }
    if (!mounted) return;
    if (p.cleared >= Economy.unlockBoosters && !p.seen.contains('booster_gift')) {
      p.seen.add('booster_gift');
      const Reward(boosters: {'aim': 1, 'extra': 1, 'split': 1}).grant();
      await showSheet<void>(context, const GiftSheet(title: '부스터가 열렸어요', body: '판을 시작하기 전에 고를 수 있어요. 선물로 하나씩 드릴게요.', reward: Reward(boosters: {'aim': 1, 'extra': 1, 'split': 1})));
    }
    if (!mounted) return;
    if (widget.autoStart && p.nextLevelIndex < LevelRepo.instance.count) _openStart(current);
  }

  void _jumpToCurrent() {
    if (!_scroll.hasClients) return;
    final pad = MediaQuery.of(context).padding.bottom + 160;
    final worlds = current ~/ LevelRepo.levelsPerWorld + 1;
    final pos = pad + current * nodeGap + worlds * 56 + nodeGap / 2;
    final target = (pos - _scroll.position.viewportDimension / 2).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    p.removeListener(_refresh);
    _clock?.cancel();
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openStart(int index) async {
    if (index > p.nextLevelIndex) return;
    final boosters = await showSheet<Set<String>>(context, LevelStartSheet(index: index));
    if (boosters == null || !mounted) return;
    if (!p.canPlay) {
      await showSheet<void>(context, const HeartsSheet());
      return;
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(pageBuilder: (_, _, _) => GameScreen(index: index, boosters: boosters), transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c)));
  }

  Future<void> _daily() async {
    final cleared = p.cleared;
    if (cleared == 0) return;
    final seed = DateTime.now().difference(DateTime(2026)).inDays;
    final idx = (seed * 7919) % cleared;
    final ok = await showSheet<bool>(context, DailySheet(level: LevelRepo.instance[idx]));
    if (ok == true && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => GameScreen(index: idx, boosters: const {})));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final count = LevelRepo.instance.count;
    return Scaffold(
      body: NightSky(
        child: Stack(
          children: [
            // 지도
            Positioned.fill(
              child: ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: EdgeInsets.only(top: pad.top + 120, bottom: pad.bottom + 160),
                itemCount: count,
                itemBuilder: (_, i) => _MapNode(index: i, current: current, pulse: _pulse, onTap: () => _openStart(i), height: nodeGap),
              ),
            ),
            // 위쪽 상태바
            Positioned(
              left: Space.l,
              right: Space.l,
              top: pad.top + Space.s,
              child: Row(
                children: [
                  HeartsPill(onTap: Economy.unlocked(Economy.unlockHearts) ? () => showSheet<void>(context, const HeartsSheet()) : null),
                  const SizedBox(width: Space.s),
                  Pill(icon: const CoinIcon(), text: '${p.coins}', onTap: Economy.unlocked(Economy.unlockShop) ? () => _push(const ShopScreen()) : null, label: '코인'),
                  const Spacer(),
                  RoundBtn(icon: Icons.settings_rounded, label: '설정', onTap: () => showSheet<void>(context, const SettingsSheet())),
                ],
              ),
            ),
            // 왼쪽 이벤트
            Positioned(
              left: Space.l,
              top: pad.top + 64,
              child: Column(
                children: [
                  if (Economy.unlocked(Economy.unlockCheckin)) _SideEvent(icon: Icons.calendar_month_rounded, label: '출석', badge: p.checkinAvailable, onTap: () => showSheet<void>(context, const CheckinSheet())),
                  if (Economy.unlocked(Economy.unlockDaily)) _SideEvent(icon: Icons.wb_twilight_rounded, label: '오늘의 한 발', badge: p.dailyAvailable, onTap: _daily),
                  if (Economy.unlocked(Economy.unlockStreak)) _SideEvent(icon: Icons.local_fire_department_rounded, label: '연승 ${p.streak}', badge: false, onTap: () => showSheet<void>(context, const StreakSheet())),
                  if (p.starterActive) _SideEvent(icon: Icons.card_giftcard_rounded, label: fmtDur(Duration(milliseconds: p.starterUntil - DateTime.now().millisecondsSinceEpoch)), badge: true, onTap: () => showSheet<void>(context, const StarterOfferSheet())),
                ],
              ),
            ),
            // 아래: 시작 버튼 + 탭
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, pad.bottom + Space.m),
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x000B1030), Color(0xF20B1030)])),
                child: Row(
                  children: [
                    _Tab(icon: Icons.storefront_rounded, label: '상점', locked: !Economy.unlocked(Economy.unlockShop), onTap: () => _push(const ShopScreen())),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: p.nextLevelIndex >= count
                          ? Btn('모든 단계를 깼어요', onTap: null)
                          : Btn('${current + 1}단계 시작', icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2A1B05)), onTap: () => _openStart(current), sound: 'pop'),
                    ),
                    const SizedBox(width: Space.m),
                    _Tab(icon: Icons.military_tech_rounded, label: '패스', locked: !Economy.unlocked(Economy.unlockPass), onTap: () => _push(const PassScreen())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w)).then((_) => _refresh());
}

class _SideEvent extends StatelessWidget {
  const _SideEvent({required this.icon, required this.label, required this.badge, required this.onTap});
  final IconData icon;
  final String label;
  final bool badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.m),
    child: Column(
      children: [
        RoundBtn(icon: icon, label: label, onTap: onTap, badge: badge, size: 52),
        const SizedBox(height: 2),
        Text(label, style: ko(TypeScale.caption, shadows: const [Shadow(color: Colors.black, blurRadius: 4)])),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.locked, required this.onTap});
  final IconData icon;
  final String label;
  final bool locked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: locked ? 0.4 : 1,
    child: Pressable(
      onTap: locked ? null : onTap,
      semantic: label,
      child: SizedBox(
        width: 64,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(locked ? Icons.lock_rounded : icon, color: Palette.ink, size: 26),
            Text(label, style: ko(TypeScale.caption)),
          ],
        ),
      ),
    ),
  );
}

/// 지도 위 한 칸: 구불구불한 길 + 번호 원 + 별
class _MapNode extends StatelessWidget {
  const _MapNode({required this.index, required this.current, required this.pulse, required this.onTap, required this.height});
  final int index, current;
  final Animation<double> pulse;
  final VoidCallback onTap;
  final double height;

  static double xOf(int i, double w) => w / 2 + math.sin(i * 0.9) * (w * 0.26);

  @override
  Widget build(BuildContext context) {
    final l = LevelRepo.instance[index];
    final p = Profile.instance;
    final stars = p.stars[l.id] ?? 0;
    final locked = index > current;
    final isCur = index == current;
    final worldStart = index % LevelRepo.levelsPerWorld == 0;
    return SizedBox(
      height: height + (worldStart ? 56 : 0),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final x = xOf(index, w), nx = xOf(index + 1, w);
        final tierCol = switch (l.tier) { Tier.hard => Palette.danger, Tier.superhard => Palette.violet, Tier.boss => Palette.moon, _ => null };
        final size = l.tier == Tier.boss ? 66.0 : 56.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _PathPainter(x, nx, height, done: index < current))),
            if (worldStart)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 44,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xCC141A4A), borderRadius: BorderRadius.circular(14), border: Border.all(color: Palette.line)),
                    child: Text('월드 ${l.world} · ${LevelRepo.worldNames[l.world]}', style: ko(TypeScale.label, color: Palette.moon)),
                  ),
                ),
              ),
            Positioned(
              left: x - size / 2,
              top: (height - size) / 2 - 6,
              child: Pressable(
                onTap: locked ? null : onTap,
                semantic: '${l.id}단계 ${l.name}${stars > 0 ? ', 별 $stars개' : ''}${locked ? ', 잠김' : ''}',
                sound: 'pop',
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, child) => Transform.scale(scale: isCur ? 1 + pulse.value * 0.08 : 1, child: child),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: locked
                          ? const LinearGradient(colors: [Color(0xFF1C2350), Color(0xFF141A40)])
                          : isCur
                          ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE39A), Color(0xFFFFB84A)])
                          : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: l.isEcho ? const [Color(0xFF2F8EA6), Color(0xFF1C566C)] : const [Color(0xFF3A4AA0), Color(0xFF26306E)]),
                      border: Border.all(color: tierCol ?? (isCur ? const Color(0xFFFFF3CF) : Palette.line), width: tierCol != null ? 3 : 2),
                      boxShadow: [if (isCur) const BoxShadow(color: Color(0x99FFD36B), blurRadius: 22), const BoxShadow(color: Color(0x66000000), offset: Offset(0, 4), blurRadius: 4)],
                    ),
                    alignment: Alignment.center,
                    child: locked ? Icon(Icons.lock_rounded, color: Palette.inkSoft.withValues(alpha: 0.6), size: 20) : Text('${l.id}', style: numStyle(20, color: isCur ? const Color(0xFF2A1B05) : Palette.ink)),
                  ),
                ),
              ),
            ),
            if (stars > 0)
              Positioned(
                left: x - 30,
                top: (height + size) / 2 - 12,
                width: 60,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var s = 0; s < 3; s++) Icon(Icons.star_rounded, size: 16, color: s < stars ? Palette.moon : const Color(0xFF39407A))]),
              ),
            if (isCur)
              Positioned(
                left: x + size / 2 + 6,
                top: (height - 44) / 2 - 6,
                child: const _Avatar(),
              ),
          ],
        );
      }),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.x, this.nx, this.h, {required this.done});
  final double x, nx, h;
  final bool done;
  @override
  void paint(Canvas c, Size s) {
    // reverse 리스트: 다음 칸은 위쪽
    final a = Offset(x, h / 2 - 6 + (s.height - h)), b = Offset(nx, -h / 2 - 6 + (s.height - h));
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, a.dy - h * 0.5, b.dx, b.dy + h * 0.5, b.dx, b.dy);
    c.drawPath(path, Paint()..color = const Color(0x33000000)..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final metrics = path.computeMetrics().first;
    final dash = Paint()..color = done ? const Color(0xCCFFD36B) : const Color(0x55A7B2DE)..strokeWidth = 5..strokeCap = StrokeCap.round;
    for (var d = 0.0; d < metrics.length; d += 14) {
      final t = metrics.getTangentForOffset(d)!.position;
      c.drawCircle(t, 2.6, dash);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.done != done || old.x != x;
}

class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(40, 44), painter: _AvatarPainter());
}

class _AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.translate(20, 26);
    c.drawOval(const Rect.fromLTWH(-13, -2, 26, 24), Paint()..color = const Color(0xFF26306E));
    c.drawCircle(const Offset(0, -4), 12, Paint()..color = const Color(0xFF3B4AA0));
    c.drawPath(Path()..moveTo(-9, -12)..lineTo(-4, -24)..lineTo(1, -13)..close(), Paint()..color = const Color(0xFF3B4AA0));
    c.drawOval(const Rect.fromLTWH(-7, -10, 16, 14), Paint()..color = const Color(0xFFFFE9CF));
    c.drawCircle(const Offset(-2, -3), 1.6, Paint()..color = const Color(0xFF1B1440));
    c.drawCircle(const Offset(4, -3), 1.6, Paint()..color = const Color(0xFF1B1440));
    c.drawArc(const Rect.fromLTWH(-24, -20, 40, 40), -1.15 - math.pi / 2, 2.3, false, Paint()..color = Palette.moon..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

