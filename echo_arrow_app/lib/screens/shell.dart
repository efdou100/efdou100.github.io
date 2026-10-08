import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/art.dart';
import '../app/economy.dart';
import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/level.dart';
import '../game/painter.dart' show WorldTheme;
import '../widgets/icons.dart';
import '../widgets/ui.dart';
import 'collection_screen.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'meta_sheets.dart';
import 'pass_screen.dart';
import 'shop_screen.dart';

/// 메인 화면 틀: 상단 재화 바(고정) + 탭 페이지(좌우 스와이프) + 하단 탭바.
/// 상위 퍼즐 게임들의 공통 구조: 홈이 가운데, 상점은 왼쪽, 진행/수집은 오른쪽.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.autoStart = false, this.justCleared = false, this.initialTab = 1});
  final bool autoStart, justCleared;
  final int initialTab;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late int tab = widget.initialTab;
  late final PageController _pages = PageController(initialPage: widget.initialTab);
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  final _mapKey = GlobalKey<HomeMapPageState>();
  Timer? _clock;
  String? _toast;
  Timer? _toastTimer;
  bool _jumping = false; // 탭을 눌러 이동 중이면 중간 페이지의 잠금 검사는 건너뜀

  Profile get p => Profile.instance;
  int get current => math.min(p.nextLevelIndex, LevelRepo.instance.count - 1);

  static const tabs = [GI.bag, GI.play, GI.medal, GI.chest];
  List<String> get tabLabels => [tr('shop'), tr('home'), tr('pass'), tr('collection')];
  List<int> get tabUnlock => [Economy.unlockShop, 0, Economy.unlockPass, Economy.unlockCollection];

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

  @override
  void dispose() {
    p.removeListener(_refresh);
    _clock?.cancel();
    _toastTimer?.cancel();
    _pulse.dispose();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _afterFirstFrame() async {
    if (widget.justCleared) await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
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
      const gift = Reward(boosters: {'aim': 1, 'extra': 1, 'split': 1});
      gift.grant();
      await showSheet<void>(context, GiftSheet(title: tr('booster_unlock_t'), body: tr('booster_unlock_b'), reward: gift));
    }
    if (!mounted) return;
    for (final (i, key) in [(0, 'tab_shop'), (2, 'tab_pass'), (3, 'tab_collection')]) {
      if (p.cleared >= tabUnlock[i] && tabUnlock[i] > 0 && !p.seen.contains(key)) {
        p.seen.add(key);
        p.save();
        _showToast(tr('tab_unlocked', {'x': tabLabels[i]}));
      }
    }
    if (widget.autoStart && p.nextLevelIndex < LevelRepo.instance.count) _openLevel(current);
  }

  void _showToast(String m) {
    setState(() => _toast = m);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2200), () => mounted ? setState(() => _toast = null) : null);
  }

  void goTab(int i) {
    if (p.cleared < tabUnlock[i]) {
      Sfx.instance.play('click');
      _showToast(tr('unlock_at', {'n': tabUnlock[i]}));
      return;
    }
    if (i == tab && i == 1) {
      _mapKey.currentState?.jumpToCurrent(animate: true);
      return;
    }
    Sfx.instance.play('pop');
    _jumping = true;
    setState(() => tab = i);
    _pages.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic).whenComplete(() => _jumping = false);
  }

  Future<void> _openLevel(int index) async {
    if (index > p.nextLevelIndex) return;
    final boosters = await showSheet<Set<String>>(context, LevelStartSheet(index: index));
    if (boosters == null || !mounted) return;
    if (!p.canPlay) {
      await showSheet<void>(context, const HeartsSheet());
      return;
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (_, _, _) => GameScreen(index: index, boosters: boosters),
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 1.08, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c)),
    ));
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
    const topBarH = 64.0, tabBarH = 84.0;
    final bottomInset = pad.bottom + tabBarH;
    return Scaffold(
      backgroundColor: Palette.nightDeep,
      body: Stack(
        children: [
          Positioned.fill(child: Art.instance.has('bg/home_sky') ? const ArtImage('bg/home_sky', fit: BoxFit.cover, fallback: NightSky()) : const NightSky()),
          Positioned.fill(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) {
                if (_jumping) return;
                if (p.cleared < tabUnlock[i]) {
                  _pages.animateToPage(tab, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  _showToast(tr('unlock_at', {'n': tabUnlock[i]}));
                  return;
                }
                setState(() => tab = i);
              },
              children: [
                ShopPage(topInset: pad.top + topBarH, bottomInset: bottomInset),
                Stack(
                  children: [
                    HomeMapPage(key: _mapKey, onOpenLevel: _openLevel, justCleared: widget.justCleared, topInset: pad.top + topBarH, bottomInset: bottomInset + 96),
                    Positioned(left: 0, right: 0, top: 0, child: IgnorePointer(child: Container(height: pad.top + 130, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xF0080B22), Color(0x00080B22)]))))),
                    Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: Container(height: bottomInset + 140, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xF0080B22), Color(0x00080B22)]))))),
                    Positioned(left: Space.m, top: pad.top + topBarH + 4, child: _EventDock(onDaily: _daily, onRefresh: _refresh)),
                    Positioned(right: Space.l, top: pad.top + topBarH + 4, child: _WorldChip(world: LevelRepo.instance[current].world)),
                    Positioned(left: 0, right: 0, bottom: bottomInset + 10, child: Center(child: _PlayButton(level: current + 1, disabled: p.nextLevelIndex >= LevelRepo.instance.count, pulse: _pulse, onTap: () => _openLevel(current)))),
                  ],
                ),
                PassPage(topInset: pad.top + topBarH, bottomInset: bottomInset),
                CollectionPage(topInset: pad.top + topBarH, bottomInset: bottomInset),
              ],
            ),
          ),
          // 상단 재화 바
          Positioned(
            left: Space.l,
            right: Space.l,
            top: pad.top + Space.s,
            child: Row(
              children: [
                HeartsPill(onTap: Economy.unlocked(Economy.unlockHearts) ? () => showSheet<void>(context, const HeartsSheet()) : null),
                const SizedBox(width: Space.s),
                Pill(icon: const CoinIcon(), text: '${p.coins}', onTap: Economy.unlocked(Economy.unlockShop) ? () => goTab(0) : null, label: tr('coins')),
                const Spacer(),
                IconCircle(icon: GI.gear, label: tr('settings'), onTap: () => showSheet<void>(context, const SettingsSheet()).then((_) => _refresh())),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(tab: tab, pageController: _pages, onTap: goTab, labels: tabLabels, unlock: tabUnlock, badges: [p.starterActive, false, _passReady, false])),
          if (_toast != null) Positioned(left: Space.xl, right: Space.xl, bottom: bottomInset + 130, child: IgnorePointer(child: Center(child: Toast(text: _toast!, gold: true)))),
        ],
      ),
    );
  }

  bool get _passReady {
    if (!Economy.unlocked(Economy.unlockPass)) return false;
    final reached = (p.passStars ~/ Economy.passStep).clamp(0, Economy.passTiers);
    for (var i = 0; i < reached; i++) {
      if (!p.passClaimed.contains(i)) return true;
    }
    return false;
  }
}

/// 원형 아이콘 버튼 (48dp)
class IconCircle extends StatelessWidget {
  const IconCircle({super.key, required this.icon, required this.label, required this.onTap, this.badge = false, this.size = 48});
  final GI icon;
  final String label;
  final VoidCallback? onTap;
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xE62A3478), Color(0xE6161D52)]),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x55A0B4FF)),
              boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 6)],
            ),
            alignment: Alignment.center,
            child: GameIcon(icon, size: size * 0.56),
          ),
          if (badge) Positioned(right: 1, top: 1, child: Container(width: 13, height: 13, decoration: BoxDecoration(color: Palette.danger, shape: BoxShape.circle, border: Border.all(color: Palette.night, width: 2)))),
        ],
      ),
    ),
  );
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.pageController, required this.onTap, required this.labels, required this.unlock, required this.badges});
  final int tab;
  final PageController pageController;
  final void Function(int) onTap;
  final List<String> labels;
  final List<int> unlock;
  final List<bool> badges;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final cleared = Profile.instance.cleared;
    return Container(
      height: 84 + pad.bottom,
      padding: EdgeInsets.only(bottom: pad.bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF26307A), Color(0xFF141A4A)]),
        border: Border(top: BorderSide(color: Color(0x66A0B4FF), width: 1.5)),
        boxShadow: [BoxShadow(color: Color(0xAA000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth / _MainShellState.tabs.length;
        return AnimatedBuilder(
          animation: pageController,
          builder: (_, _) {
            final page = pageController.hasClients && pageController.position.haveDimensions ? (pageController.page ?? tab.toDouble()) : tab.toDouble();
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 선택 표시 (페이지 스와이프를 따라 미끄러짐)
                Positioned(
                  left: page * w + 6,
                  width: w - 12,
                  top: 6,
                  bottom: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4256B8), Color(0xFF2A3478)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x88CFD8FF)),
                      boxShadow: const [BoxShadow(color: Color(0x667EF0FF), blurRadius: 12)],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _MainShellState.tabs.length; i++)
                      Expanded(
                        child: _TabItem(
                          icon: _MainShellState.tabs[i],
                          label: labels[i],
                          selected: (page - i).abs() < 0.5,
                          locked: cleared < unlock[i],
                          badge: badges[i],
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.selected, required this.locked, required this.badge, required this.onTap});
  final GI icon;
  final String label;
  final bool selected, locked, badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSlide(
              offset: Offset(0, selected ? -0.18 : 0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Stack(clipBehavior: Clip.none, children: [
                Opacity(opacity: locked ? 0.4 : 1, child: icon == GI.play ? const _HomeIcon() : GameIcon(icon, size: selected ? 38 : 32)),
                if (locked) const Positioned(right: -6, bottom: -4, child: GameIcon(GI.lock, size: 18)),
                if (badge && !locked) Positioned(right: -4, top: -2, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Palette.danger, shape: BoxShape.circle, border: Border.all(color: Palette.night, width: 2)))),
              ]),
            ),
            AnimatedOpacity(opacity: selected ? 1 : 0.7, duration: const Duration(milliseconds: 200), child: Text(label, style: ko(selected ? 13 : 12, color: selected ? Palette.ink : Palette.inkSoft))),
          ],
        ),
      ),
    ),
  );
}

class _HomeIcon extends StatelessWidget {
  const _HomeIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(36, 36), painter: _HomePainter());
}

class _HomePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 24);
    final roof = Path()..moveTo(2, 11)..lineTo(12, 3)..lineTo(22, 11)..close();
    c.drawPath(roof, Paint()..shader = ui.Gradient.linear(const Offset(12, 3), const Offset(12, 11), const [Color(0xFFFF9FC8), Color(0xFFD9467A)]));
    c.drawRect(const Rect.fromLTWH(5, 10, 14, 11), Paint()..shader = ui.Gradient.linear(const Offset(0, 10), const Offset(0, 21), const [Color(0xFFFFE9CF), Color(0xFFE0C29A)]));
    c.drawRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(10, 14, 4, 7), topLeft: const Radius.circular(2), topRight: const Radius.circular(2)), Paint()..color = const Color(0xFF7A4E2E));
    c.drawCircle(const Offset(17, 7), 1.6, Paint()..color = const Color(0xFFFFD36B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WorldChip extends StatelessWidget {
  const _WorldChip({required this.world});
  final int world;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final levels = LevelRepo.instance.levels.where((l) => l.world == world).toList();
    final got = levels.fold<int>(0, (a, l) => a + (p.stars[l.id] ?? 0));
    final th = WorldTheme.of(world);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(color: const Color(0xCC141A4A), borderRadius: BorderRadius.circular(16), border: Border.all(color: th.accent.withValues(alpha: 0.45))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(worldName(world), style: ko(TypeScale.body, color: th.accent)),
          const SizedBox(height: 4),
          SizedBox(width: 96, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: got / (levels.length * 3), minHeight: 6, backgroundColor: const Color(0x33FFFFFF), color: Palette.moon))),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [const GameIcon(GI.star, size: 12), const SizedBox(width: 3), Text('$got / ${levels.length * 3}', style: numStyle(TypeScale.caption, color: Palette.inkSoft))]),
        ],
      ),
    );
  }
}

class _EventDock extends StatelessWidget {
  const _EventDock({required this.onDaily, required this.onRefresh});
  final VoidCallback onDaily, onRefresh;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final items = <Widget>[
      if (Economy.unlocked(Economy.unlockCheckin)) _DockItem(icon: GI.calendar, label: tr('checkin'), badge: p.checkinAvailable, onTap: () => showSheet<void>(context, const CheckinSheet()).then((_) => onRefresh())),
      if (Economy.unlocked(Economy.unlockDaily)) _DockItem(icon: GI.sunrise, label: tr('daily'), badge: p.dailyAvailable, onTap: onDaily),
      if (Economy.unlocked(Economy.unlockStreak)) _DockItem(icon: GI.flame, label: tr('streak_n', {'n': p.streak}), badge: false, onTap: () => showSheet<void>(context, const StreakSheet())),
      if (p.starterActive) _DockItem(icon: GI.gift, label: fmtDur(Duration(milliseconds: p.starterUntil - DateTime.now().millisecondsSinceEpoch)), badge: true, onTap: () => showSheet<void>(context, const StarterOfferSheet()).then((_) => onRefresh())),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: items);
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.icon, required this.label, required this.badge, required this.onTap});
  final GI icon;
  final String label;
  final bool badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: SizedBox(
      width: 66,
      child: Column(
        children: [
          IconCircle(icon: icon, label: label, onTap: onTap, badge: badge, size: 52),
          const SizedBox(height: 2),
          Text(label, style: ko(11, shadows: const [Shadow(color: Colors.black, blurRadius: 4), Shadow(color: Colors.black, blurRadius: 2)]), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.level, required this.disabled, required this.pulse, required this.onTap});
  final int level;
  final bool disabled;
  final Animation<double> pulse;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: disabled ? null : onTap,
    semantic: disabled ? tr('all_cleared') : tr('level_start', {'n': level}),
    sound: 'pop',
    child: AnimatedBuilder(
      animation: pulse,
      builder: (_, child) {
        final b = math.sin(pulse.value * math.pi * 2);
        return Transform.scale(scale: 1 + b * 0.025, child: child);
      },
      child: Container(
        height: 68,
        constraints: const BoxConstraints(minWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB4F58A), Color(0xFF4CC24A)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE6FFD8), width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0xFF2B8A33), offset: Offset(0, 6)), BoxShadow(color: Color(0x8040C040), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(disabled ? tr('all_cleared') : tr('level_n', {'n': level}), style: ko(26, color: Colors.white, shadows: const [Shadow(color: Color(0xFF1E6B26), offset: Offset(0, 2.5)), Shadow(color: Color(0xFF1E6B26), blurRadius: 2)])),
          ],
        ),
      ),
    ),
  );
}
