import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/economy.dart';
import '../app/l10n.dart';
import '../app/missions.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/controller.dart';
import '../game/level.dart';
import '../game/painter.dart';
import '../game/sim.dart';
import '../services/services.dart';
import '../widgets/icons.dart';
import '../widgets/ui.dart';
import 'collection_screen.dart' show NewDeviceSheet;
import 'sheets.dart';
import 'shell.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.index, this.boosters = const {}});
  final int index;
  final Set<String> boosters;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController g;
  late final Ticker _ticker;
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..forward();
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
    g = GameController(level, boosters: widget.boosters)
      ..onWin = _onWin
      ..onOutOfArrows = _onOut
      ..onToast = (m, {gold = false}) => _showToast(m, gold: gold);
    _ticker = createTicker((d) {
      final dt = ((d - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
      _last = d;
      g.update(dt);
    })..start();
    Sfx.instance.music('bgm_game');
    Analytics.log('level_start', {'id': level.id, 'boosters': widget.boosters.join(',')});
    Future<void>.delayed(const Duration(milliseconds: 1400), _introduce);
  }

  /// 새 요소를 처음 만나는 판이면 소개 팝업부터, 그다음 판 안내 문구
  Future<void> _introduce() async {
    if (!mounted) return;
    final key = level.intro, p = Profile.instance;
    if (key != null && !p.seen.contains('intro_$key')) {
      p.seen.add('intro_$key');
      p.save();
      Analytics.log('device_intro', {'key': key});
      await showSheet<void>(context, NewDeviceSheet(intro: key));
      if (!mounted) return;
    }
    if (level.hint != null) _showToast(levelHint(level.hint!), gold: true, sticky: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _intro.dispose();
    _toastTimer?.cancel();
    g.dispose();
    super.dispose();
  }

  void _showToast(String m, {bool gold = false, bool sticky = false}) {
    if (!mounted || (sticky && _fired)) return;
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
    if (g.pointerDown(x, y)) _pointer = e.pointer;
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
    final newMedal = r.tricks > 0 && !p.trickMedals.contains(level.id) && p.cleared >= Economy.unlockTrickMedal;
    if (newMedal) p.trickMedals.add(level.id);
    final coins = Economy.clearCoins(level, r.stars) + (gainedStars > 0 ? 20 : 0) + (newMedal ? Economy.trickMedalCoins : 0);
    final firstClear = prev == 0;
    if (r.stars > prev) p.stars[level.id] = r.stars;
    p.coins += coins;
    p.passStars += gainedStars;
    if (p.cleared >= Economy.unlockShop) p.piggy = math.min(Economy.piggyMax, p.piggy + Economy.piggyPerClear);
    p.streak = r.firstTry ? p.streak + 1 : 0;
    p.best = math.max(p.best, p.streak);
    p.clearsSinceAd++;
    if (p.cleared == Economy.unlockShop && p.starterUntil == 0) p.starterUntil = DateTime.now().millisecondsSinceEpoch + const Duration(hours: 48).inMilliseconds;
    p.save();
    final missionsDone = Missions.recordWin(r, level);
    Analytics.log('level_win', {'id': level.id, 'stars': r.stars, 'used': r.used, 'continues': g.continues, 'tricks': r.tricks});
    var replayed = false;
    while (true) {
      if (!mounted) return;
      final action = await showFullscreen<String>(context, WinScreen(level: level, result: r, coins: coins, streak: p.streak, isLast: widget.index >= LevelRepo.instance.count - 1, replayed: replayed, missions: replayed ? const [] : missionsDone, newMedal: newMedal && !replayed));
      if (!mounted) return;
      if (action == 'replay') {
        replayed = true;
        g.startReplay();
        while (mounted && g.mode == Mode.replay) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        continue;
      }
      if (action == 'retry') {
        _replaceWith(widget.index);
      } else {
        await _next(firstClear);
      }
      return;
    }
  }

  Future<void> _next(bool firstClear) async {
    if (Economy.interstitialDue()) await AdService.instance.interstitial('level_end');
    if (!mounted) return;
    final p = Profile.instance;
    final next = widget.index + 1;
    // 온보딩: 처음 3판은 홈을 거치지 않고 바로 다음 판
    if (p.cleared < Economy.unlockMap && next < LevelRepo.instance.count) {
      _replaceWith(next);
      return;
    }
    _toShell(autoStart: true, justCleared: firstClear);
  }

  void _toShell({bool autoStart = false, bool justCleared = false}) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => MainShell(autoStart: autoStart, justCleared: justCleared),
        transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
      ),
      (_) => false,
    );
  }

  void _replaceWith(int index, {Set<String> boosters = const {}}) {
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(transitionDuration: const Duration(milliseconds: 380), pageBuilder: (_, _, _) => GameScreen(index: index, boosters: boosters), transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c)));
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
      _toShell();
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
      _toShell();
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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _pause();
        },
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
                  Positioned(left: r.left + 8 * s, right: size.width - r.right + 8 * s, top: r.top + 6 * s, height: 78 * s, child: _Hud(g: g, level: level, scale: s, onMenu: _pause, onRestart: g.restartLevel)),
                  Positioned(
                    left: at(Field.x0 + 8, 0).dx,
                    right: size.width - at(Field.x1 - 8, 0).dx,
                    top: at(0, Field.y1 - 48).dy,
                    child: AnimatedBuilder(
                      animation: g,
                      builder: (_, _) => Row(
                        children: [
                          for (final e in g.skillLeft.entries) ...[_SkillChip(kind: e.key, left: e.value, on: g.kind == e.key, onTap: () => g.toggleSkill(e.key)), SizedBox(width: 6 * s)],
                          const Spacer(),
                          if (Economy.unlocked(Economy.unlockHint) && level.solution != null && g.mode == Mode.aim && !g.hintOn) _HintChip(count: Profile.instance.hints, onTap: _hint),
                        ],
                      ),
                    ),
                  ),
                  if (_toast != null)
                    Positioned(left: r.left + 24 * s, right: size.width - r.right + 24 * s, top: at(0, Field.y1 - 156).dy, child: IgnorePointer(child: Toast(text: _toast!, gold: _toastGold))),
                  if (widget.index == 0 && !_fired) Positioned.fill(child: IgnorePointer(child: _TutorialHand(rect: r))),
                  // 판 소개 카드
                  Positioned.fill(child: IgnorePointer(child: _IntroCard(anim: _intro, level: level))),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.anim, required this.level});
  final Animation<double> anim;
  final LevelData level;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    builder: (_, _) {
      final t = anim.value;
      if (t >= 1) return const SizedBox.shrink();
      final inK = Curves.easeOutBack.transform((t / 0.25).clamp(0.0, 1.0));
      final outK = Curves.easeInCubic.transform(((t - 0.72) / 0.28).clamp(0.0, 1.0));
      final th = WorldTheme.of(level.world);
      return Opacity(
        opacity: (1 - outK).clamp(0.0, 1.0),
        child: Container(
          color: Color.fromRGBO(5, 8, 24, 0.45 * (1 - outK)),
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset((1 - inK) * -120 + outK * 140, 0),
            child: Transform.scale(
              scale: 0.8 + inK * 0.2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RibbonTitle(text: tr('level_n', {'n': level.id}), color: level.tier == Tier.normal ? th.accent : (level.tier == Tier.hard ? Palette.danger : level.tier == Tier.superhard ? Palette.violet : Palette.moon)),
                  const SizedBox(height: Space.s),
                  Text(levelName(level.name), style: ko(TypeScale.display, shadows: const [Shadow(color: Colors.black, blurRadius: 8)])),
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < level.par; i++) const Padding(padding: EdgeInsets.symmetric(horizontal: 1), child: GameIcon(GI.quiver, size: 20)),
                    const SizedBox(width: 6),
                    Text(tr('par_hint', {'n': level.par}), style: ko(TypeScale.body, color: Palette.inkSoft, shadows: const [Shadow(color: Colors.black, blurRadius: 6)])),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Hud extends StatelessWidget {
  const _Hud({required this.g, required this.level, required this.scale, required this.onMenu, required this.onRestart});
  final GameController g;
  final LevelData level;
  final double scale;
  final VoidCallback onMenu, onRestart;

  @override
  Widget build(BuildContext context) {
    final tier = switch (level.tier) { Tier.hard => (tr('tier_hard'), Palette.danger), Tier.superhard => (tr('tier_superhard'), Palette.violet), Tier.boss => (tr('tier_boss'), Palette.moon), _ => null };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HudBtn(icon: GI.pause, label: tr('resume'), onTap: onMenu),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${worldName(level.world)} · ${level.id}', style: ko(11 * scale + 1, color: level.isEcho ? Palette.echo : Palette.inkSoft)),
                  if (tier != null) ...[const SizedBox(width: 6), TierBadge(text: tier.$1, color: tier.$2)],
                ],
              ),
              Text(levelName(level.name), style: ko(20 * scale + 2, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              AnimatedBuilder(animation: g, builder: (_, _) => _Arrows(g: g)),
            ],
          ),
        ),
        _HudBtn(icon: GI.restart, label: tr('restart'), onTap: onRestart),
      ],
    );
  }
}

class _HudBtn extends StatelessWidget {
  const _HudBtn({required this.icon, required this.label, required this.onTap});
  final GI icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semantic: label,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xE62A3478), Color(0xE6161D52)]),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x55A0B4FF)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 6)],
      ),
      alignment: Alignment.center,
      child: GameIcon(icon, size: 26),
    ),
  );
}

class _Arrows extends StatelessWidget {
  const _Arrows({required this.g});
  final GameController g;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${g.remaining} / ${g.total}',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xB30C102E), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < g.total; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: i < g.used ? 0.28 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: GameIcon(GI.quiver, size: 18, color: i < g.shots.length ? Palette.shot[1 + i % 5] : Palette.moon),
                  ),
                  if (i == g.level.par - 1) const GameIcon(GI.star, size: 9) else const SizedBox(height: 9),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.kind, required this.left, required this.on, required this.onTap});
  final String kind;
  final int left;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final col = kind == 'split' ? Palette.moon : Palette.moss;
    final name = kind == 'split' ? tr('sk_split') : tr('sk_pierce');
    return Opacity(
      opacity: left > 0 ? 1 : 0.35,
      child: Pressable(
        onTap: left > 0 ? onTap : null,
        semantic: '$name ×$left',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 46, minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: on ? col : const Color(0xE6141A46),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: col, width: on ? 2.5 : 1.5),
            boxShadow: on ? [BoxShadow(color: col.withValues(alpha: 0.55), blurRadius: 16)] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            GameIcon(kind == 'split' ? GI.split : GI.extra, size: 22),
            const SizedBox(width: 6),
            Text('$name ×$left', style: ko(15, color: on ? const Color(0xFF1B1440) : col)),
          ]),
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semantic: tr('hint'),
    child: Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xE6141A46), borderRadius: BorderRadius.circular(23), border: Border.all(color: const Color(0x99FFD36B))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const GameIcon(GI.bulb, size: 24),
        const SizedBox(width: 6),
        Text(count > 0 ? tr('hint_n', {'n': count}) : tr('hint'), style: ko(15)),
      ]),
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
            if (pressed) Positioned(left: x - 1, top: r.top + 300 * s, child: Container(width: 2, height: pullT * 110 * s, color: Palette.moon.withValues(alpha: 0.5))),
            Positioned(
              left: x - 30,
              top: y - 8,
              child: Opacity(
                opacity: t > 0.9 ? 0 : 1,
                child: Column(
                  children: [
                    AnimatedScale(scale: pressed ? 0.88 : 1, duration: const Duration(milliseconds: 120), child: const Icon(Icons.touch_app_rounded, size: 52, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
                    Text(pressed ? tr('tut_pull') : (t > 0.78 ? tr('tut_release') : tr('tut_press')), style: ko(16, shadows: const [Shadow(color: Colors.black, blurRadius: 6)])),
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
