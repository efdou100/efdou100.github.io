import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import '../app/theme.dart';
import '../game/controller.dart';
import '../game/level.dart';
import '../game/painter.dart';
import '../game/sim.dart';
import '../services/services.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';
import 'sheets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.index, this.boosters = const {}});
  final int index;
  final Set<String> boosters;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameController g;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  String? _toast;
  bool _toastGold = false;
  Timer? _toastTimer;
  bool _fired = false;
  int? _pointer;

  LevelData get level => LevelRepo.instance[widget.index];

  @override
  void initState() {
    super.initState();
    _setup();
    _ticker = createTicker((d) {
      final dt = ((d - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
      _last = d;
      g.update(dt);
    })..start();
    Analytics.log('level_start', {'id': level.id, 'boosters': widget.boosters.join(',')});
    if (level.hint != null) WidgetsBinding.instance.addPostFrameCallback((_) => _showToast(level.hint!, gold: true, sticky: true));
  }

  void _setup() {
    g = GameController(level, boosters: widget.boosters)
      ..onWin = _onWin
      ..onOutOfArrows = _onOut
      ..onToast = (m, {gold = false}) => _showToast(m, gold: gold);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _toastTimer?.cancel();
    g.dispose();
    super.dispose();
  }

  void _showToast(String m, {bool gold = false, bool sticky = false}) {
    if (!mounted) return;
    setState(() {
      _toast = m;
      _toastGold = gold;
    });
    _toastTimer?.cancel();
    if (!sticky) _toastTimer = Timer(const Duration(milliseconds: 2400), () => mounted ? setState(() => _toast = null) : null);
  }

  // ---------- 입력 ----------
  (double, double) _toLogical(Offset p, Size size) {
    final r = GamePainter.fit(size);
    return ((p.dx - r.left) / r.width * Field.w, (p.dy - r.top) / r.height * Field.h);
  }

  void _down(PointerDownEvent e, Size size) {
    if (_pointer != null) return;
    final (x, y) = _toLogical(e.localPosition, size);
    if (y < Field.y0 - 4) return;
    if (g.pointerDown(x, y)) {
      _pointer = e.pointer;
      if (_toast != null && (level.hint == null || _fired)) setState(() => _toast = null);
    }
  }

  void _move(PointerMoveEvent e, Size size) {
    if (e.pointer != _pointer) return;
    final (x, y) = _toLogical(e.localPosition, size);
    g.pointerMove(x, y);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final wasHold = g.mode == Mode.hold;
    g.pointerUp();
    if (wasHold && g.mode == Mode.fly && !_fired) {
      setState(() {
        _fired = true;
        _toast = null;
      });
    }
  }

  // ---------- 결과 ----------
  Future<void> _onWin(WinResult r) async {
    final p = Profile.instance;
    final prev = p.stars[level.id] ?? 0;
    final gainedStars = math.max(0, r.stars - prev);
    final coins = Economy.clearCoins(level, r.stars) + (gainedStars > 0 ? 20 : 0);
    if (r.stars > prev) p.stars[level.id] = r.stars;
    p.coins += coins;
    p.passStars += gainedStars;
    if (p.cleared >= Economy.unlockShop) p.piggy = math.min(Economy.piggyMax, p.piggy + Economy.piggyPerClear);
    p.streak = r.firstTry ? p.streak + 1 : 0;
    p.best = math.max(p.best, p.streak);
    p.clearsSinceAd++;
    if (p.cleared == Economy.unlockShop && p.starterUntil == 0) p.starterUntil = DateTime.now().millisecondsSinceEpoch + const Duration(hours: 48).inMilliseconds;
    p.save();
    Analytics.log('level_win', {'id': level.id, 'stars': r.stars, 'used': r.used, 'continues': g.continues, 'tricks': r.tricks});
    if (!mounted) return;
    final action = await showSheet<String>(context, ClearSheet(level: level, result: r, coins: coins, streak: p.streak, isLast: widget.index >= LevelRepo.instance.count - 1), dismissible: false);
    if (!mounted) return;
    switch (action) {
      case 'replay':
        g.startReplay();
        g.onWin = null;
        await _waitReplay();
        if (mounted) _onWinAgain(r, coins);
      case 'retry':
        _replaceWith(widget.index);
      default:
        await _next();
    }
  }

  Future<void> _waitReplay() async {
    while (mounted && g.mode == Mode.replay) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _onWinAgain(WinResult r, int coins) async {
    final action = await showSheet<String>(context, ClearSheet(level: level, result: r, coins: coins, streak: Profile.instance.streak, isLast: widget.index >= LevelRepo.instance.count - 1, replayed: true), dismissible: false);
    if (!mounted) return;
    if (action == 'replay') {
      g.startReplay();
      await _waitReplay();
      if (mounted) _onWinAgain(r, coins);
    } else if (action == 'retry') {
      _replaceWith(widget.index);
    } else {
      await _next();
    }
  }

  Future<void> _next() async {
    if (Economy.interstitialDue()) await AdService.instance.interstitial('level_end');
    if (!mounted) return;
    final p = Profile.instance;
    final next = widget.index + 1;
    // 온보딩: 처음 3판은 홈을 거치지 않고 바로 다음 판
    if (p.cleared < Economy.unlockMap && next < LevelRepo.instance.count) {
      _replaceWith(next);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeScreen(autoStart: true)), (_) => false);
  }

  void _replaceWith(int index, {Set<String> boosters = const {}}) {
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(pageBuilder: (_, _, _) => GameScreen(index: index, boosters: boosters), transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c)));
  }

  Future<void> _onOut() async {
    Analytics.log('level_out_of_arrows', {'id': level.id, 'continues': g.continues});
    final action = await showSheet<String>(context, ContinueSheet(controller: g), dismissible: false);
    if (!mounted) return;
    switch (action) {
      case 'coins':
        g.addArrows(Economy.continueArrows);
      case 'ad':
        g.addArrows(1);
      default:
        _giveUp(retry: action == 'retry');
    }
  }

  void _giveUp({required bool retry}) {
    final p = Profile.instance;
    p.loseHeart();
    p.streak = 0;
    p.save();
    Analytics.log('level_fail', {'id': level.id});
    if (retry && p.canPlay) {
      _replaceWith(widget.index);
    } else {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeScreen()), (_) => false);
    }
  }

  Future<void> _pause() async {
    final action = await showSheet<String>(context, PauseSheet(level: level, shotsUsed: g.shots.isNotEmpty));
    if (!mounted) return;
    if (action == 'restart') {
      g.restartLevel();
    } else if (action == 'home') {
      if (g.shots.isNotEmpty) {
        Profile.instance.loseHeart();
        Profile.instance.streak = 0;
        Profile.instance.save();
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeScreen()), (_) => false);
    }
  }

  Future<void> _hint() async {
    final p = Profile.instance;
    if (g.hintOn) return;
    if (p.hints > 0) {
      p.hints--;
      p.save();
      g.showHint();
      return;
    }
    final r = await showSheet<String>(context, const HintSheet());
    if (r == 'coins' && p.spend(Economy.hintPrice) || r == 'ad') g.showHint();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.nightDeep,
        body: Padding(
          padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
          child: LayoutBuilder(builder: (context, box) {
            final size = box.biggest;
            final r = GamePainter.fit(size);
            final s = r.width / Field.w;
            Offset at(double x, double y) => Offset(r.left + x * s, r.top + y * s);
            return Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (e) => _down(e, size),
                    onPointerMove: (e) => _move(e, size),
                    onPointerUp: _up,
                    onPointerCancel: (e) {
                      if (e.pointer == _pointer) {
                        _pointer = null;
                        g.pointerCancel();
                      }
                    },
                    child: RepaintBoundary(child: CustomPaint(painter: GamePainter(g), size: size)),
                  ),
                ),
                // 위쪽 HUD
                Positioned(
                  left: r.left + 8 * s,
                  right: size.width - r.right + 8 * s,
                  top: r.top + 6 * s,
                  height: 76 * s,
                  child: _Hud(g: g, level: level, scale: s, onMenu: _pause, onRestart: g.restartLevel),
                ),
                // 아래쪽: 스킬 칩, 힌트
                Positioned(
                  left: at(Field.x0 + 8, 0).dx,
                  right: size.width - at(Field.x1 - 8, 0).dx,
                  top: at(0, Field.y1 - 46).dy,
                  child: AnimatedBuilder(
                    animation: g,
                    builder: (_, _) => Row(
                      children: [
                        for (final e in g.skillLeft.entries) ...[_SkillChip(kind: e.key, left: e.value, on: g.kind == e.key, onTap: () => g.toggleSkill(e.key), scale: s), SizedBox(width: 6 * s)],
                        const Spacer(),
                        if (Economy.unlocked(Economy.unlockHint) && level.solution != null && g.mode == Mode.aim && !g.hintOn) _HintChip(scale: s, count: Profile.instance.hints, onTap: _hint),
                      ],
                    ),
                  ),
                ),
                if (_toast != null)
                  Positioned(
                    left: r.left + 24 * s,
                    right: size.width - r.right + 24 * s,
                    top: at(0, Field.y1 - 150).dy,
                    child: IgnorePointer(child: AnimatedOpacity(opacity: 1, duration: const Duration(milliseconds: 200), child: Toast(text: _toast!, gold: _toastGold))),
                  ),
                if (widget.index == 0 && !_fired) Positioned.fill(child: IgnorePointer(child: _TutorialHand(rect: r))),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.g, required this.level, required this.scale, required this.onMenu, required this.onRestart});
  final GameController g;
  final LevelData level;
  final double scale;
  final VoidCallback onMenu, onRestart;

  @override
  Widget build(BuildContext context) {
    final tier = switch (level.tier) { Tier.hard => ('어려움', Palette.danger), Tier.superhard => ('아주 어려움', Palette.violet), Tier.boss => ('보스', Palette.moon), _ => null };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoundBtn(icon: Icons.pause_rounded, onTap: onMenu, label: '일시정지'),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${LevelRepo.worldNames[level.world]} · ${level.id}', style: ko(11 * scale + 1, color: level.isEcho ? Palette.echo : Palette.inkSoft)),
                  if (tier != null) ...[const SizedBox(width: 6), TierBadge(text: tier.$1, color: tier.$2)],
                ],
              ),
              Text(level.name, style: ko(20 * scale + 2), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              AnimatedBuilder(animation: g, builder: (_, _) => _Arrows(g: g)),
            ],
          ),
        ),
        RoundBtn(icon: Icons.refresh_rounded, onTap: onRestart, label: '처음부터'),
      ],
    );
  }
}

class _Arrows extends StatelessWidget {
  const _Arrows({required this.g});
  final GameController g;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '남은 화살 ${g.remaining}발, 기준 ${g.level.par}발',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < g.total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -math.pi / 2,
                  child: Icon(Icons.arrow_right_alt_rounded, size: 18, color: (i < g.shots.length ? Palette.shot[1 + i % 5] : Palette.moon).withValues(alpha: i < g.used ? 0.3 : 1)),
                ),
                if (i == g.level.par - 1) const Icon(Icons.star_rounded, size: 9, color: Palette.moon) else const SizedBox(height: 9),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.kind, required this.left, required this.on, required this.onTap, required this.scale});
  final String kind;
  final int left;
  final bool on;
  final VoidCallback onTap;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final col = kind == 'split' ? Palette.moon : Palette.moss;
    final name = kind == 'split' ? '분열' : '관통';
    return Opacity(
      opacity: left > 0 ? 1 : 0.35,
      child: Pressable(
        onTap: left > 0 ? onTap : null,
        semantic: '$name 화살 $left개',
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: on ? col : const Color(0xE6141A46),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: col, width: on ? 2.5 : 1.5),
            boxShadow: on ? [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 14)] : null,
          ),
          alignment: Alignment.center,
          child: Text('$name ×$left', style: ko(15, color: on ? const Color(0xFF1B1440) : col)),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.scale, required this.count, required this.onTap});
  final double scale;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semantic: '힌트',
    child: Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xE6141A46), borderRadius: BorderRadius.circular(22), border: Border.all(color: Palette.inkSoft.withValues(alpha: 0.5))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded, size: 18, color: Palette.moon),
          const SizedBox(width: 6),
          Text(count > 0 ? '힌트 ×$count' : '힌트', style: ko(15)),
        ],
      ),
    ),
  );
}

/// 첫 판: 손가락이 눌러서 아래로 당기는 시범
class _TutorialHand extends StatefulWidget {
  const _TutorialHand({required this.rect});
  final Rect rect;
  @override
  State<_TutorialHand> createState() => _TutorialHandState();
}

class _TutorialHandState extends State<_TutorialHand> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rect, s = r.width / Field.w;
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) {
        final t = c.value;
        final pullT = Curves.easeInOut.transform(((t - 0.15) / 0.55).clamp(0.0, 1.0));
        final x = r.left + 180 * s, y = r.top + (300 + pullT * 110) * s;
        final pressed = t > 0.12 && t < 0.78;
        return Stack(
          children: [
            if (pressed)
              Positioned(
                left: x - 1,
                top: r.top + 300 * s,
                child: Container(width: 2, height: pullT * 110 * s, color: Palette.moon.withValues(alpha: 0.5)),
              ),
            Positioned(
              left: x - 22,
              top: y - 8,
              child: Opacity(
                opacity: t > 0.9 ? 0 : 1,
                child: Column(
                  children: [
                    AnimatedScale(scale: pressed ? 0.88 : 1, duration: const Duration(milliseconds: 120), child: const Icon(Icons.touch_app_rounded, size: 48, color: Colors.white)),
                    Text(pressed ? '당기고…' : (t > 0.78 ? '놓기!' : '누르고'), style: ko(15, shadows: const [Shadow(color: Colors.black, blurRadius: 6)])),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
