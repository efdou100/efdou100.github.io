import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import 'level.dart';
import 'sim.dart';

enum Mode { aim, hold, fly, finish, over, replay }

class Particle {
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size, {this.g = 0, this.confetti = false, this.rot = 0});
  double x, y, vx, vy, t = 0;
  final double life, size, g, rot;
  final int color;
  final bool confetti;
}

class RingFx {
  RingFx(this.x, this.y, this.color, this.r1, this.life, this.w);
  final double x, y, r1, life, w;
  final int color;
  double t = 0;
}

class FloatText {
  FloatText(this.x, this.y, this.text, this.color, this.size, this.life);
  final double x, y, size, life;
  final String text;
  final int color;
  double t = 0;
}

class WinResult {
  WinResult({required this.stars, required this.used, required this.maxBounce, required this.tricks, required this.firstTry, required this.shots, required this.mirrors});
  final int stars, used, maxBounce, tricks;
  final bool firstTry;
  final List<Shot> shots;
  final List<int> mirrors;
}

/// 한 판의 진행(조준 → 비행 → 메아리 → 클리어/실패)과 연출 상태.
class GameController extends ChangeNotifier {
  GameController(this.level, {Set<String> boosters = const {}}) {
    this.boosters.addAll(boosters);
    mirrors = level.defaultMirrors;
    skillLeft = Map.of(level.skills);
    if (boosters.contains('split')) skillLeft['split'] = (skillLeft['split'] ?? 0) + 1;
    if (boosters.contains('extra')) bonus = 1;
    _startTurn(first: true);
  }

  final LevelData level;
  final Set<String> boosters = {};
  final math.Random _rnd = math.Random(7);

  late Run run;
  final List<Shot> shots = []; // 지나간 화살 (메아리)
  Shot? cur;
  int bonus = 0;
  int continues = 0; // 이어하기 횟수
  Mode mode = Mode.aim;
  late List<int> mirrors;
  late Map<String, int> skillLeft;
  String kind = 'n';
  List<({int idx, List<double> pts})> echoPreview = [];
  bool hintOn = false;
  bool restarted = false;

  // 조준
  double aimAng = -math.pi / 2, pull = 0;
  double dsX = 0, dsY = 0;
  int mirrorTap = -1;
  (int, double)? mirrorSpin;

  // 시간·연출
  double acc = 0, endT = 0, finT = 0, slowT = 0, hitstop = 0, flash = 0, shake = 0, holdVis = 0, clock = 0;
  double camZ = 1, camX = 180, camY = 320, camTz = 1, camTx = 180, camTy = 320;
  (double, double) lastHit = (180, 320);
  bool trailsFull = false;
  int replayIdx = 0;
  List<double> gateVis = [];
  List<bool> gateWas = [];
  int maxB = 0, tricks = 0;
  WinResult? result;
  final Map<int, double> wakeAt = {}; // 정령이 깬 시각(clock) → 깨어나는 애니메이션
  double fireAt = -9; // 마지막 발사 시각 → 궁수 반동
  double winAt = -9;

  final List<Particle> parts = [];
  final List<RingFx> rings = [];
  final List<FloatText> texts = [];

  // 화면 쪽 콜백
  void Function(WinResult r)? onWin;
  void Function()? onOutOfArrows;
  void Function(String msg, {bool gold})? onToast;

  int get total => level.shots + bonus;
  int get used => shots.length + (cur == null ? 0 : 1);
  int get remaining => total - used;
  int get curIdx => mode == Mode.replay ? replayIdx : (cur?.idx ?? shots.length);
  int get guide => boosters.contains('aim') ? 3 : level.guide;

  // ---------------- 흐름 ----------------
  void _startTurn({bool first = false, bool quiet = false}) {
    run = Run(level, [for (final s in shots) s.copy(echo: true)], mirrors);
    echoPreview = _buildEchoPreview();
    mode = Mode.aim;
    cur = null;
    acc = endT = finT = slowT = hitstop = 0;
    camTz = 1;
    camTx = 180;
    camTy = 320;
    maxB = 0;
    tricks = 0;
    gateVis = List.filled(run.c.gates.length, 0);
    gateWas = List.filled(run.c.gates.length, false);
    trailsFull = false;
    wakeAt.clear();
    if (quiet) return;
    if (!first && shots.isNotEmpty) onToast?.call(tr('t_echo_wait', {'n': shots.length}));
  }

  List<({int idx, List<double> pts})> _buildEchoPreview() {
    if (shots.isEmpty) return [];
    final r = Run(level, shots, mirrors);
    final map = <Arrow, List<double>>{};
    for (var i = 0; i < 1500 && !r.done; i++) {
      r.tick();
      if (i % 3 != 0) continue;
      for (final a in r.arrows) {
        if (!a.alive) continue;
        (map[a] ??= []).addAll([a.x, a.y]);
      }
    }
    return [for (final e in map.entries) (idx: e.key.idx, pts: e.value)];
  }

  void restartLevel() {
    shots.clear();
    bonus = boosters.contains('extra') ? 1 : 0;
    continues = 0;
    mirrors = level.defaultMirrors;
    skillLeft = Map.of(level.skills);
    if (boosters.contains('split')) skillLeft['split'] = (skillLeft['split'] ?? 0) + 1;
    kind = 'n';
    restarted = true;
    parts.clear();
    texts.clear();
    rings.clear();
    _startTurn(quiet: true);
    notifyListeners();
  }

  /// 이어하기: 화살 추가, 메아리는 유지
  void addArrows(int n) {
    bonus += n;
    continues++;
    _startTurn(quiet: true);
    onToast?.call(tr('t_plus', {'n': n}), gold: true);
    notifyListeners();
  }

  void _endTurn() {
    shots.add(cur!);
    cur = null;
    if (total - shots.length > 0) {
      _startTurn();
    } else {
      mode = Mode.over;
      Sfx.instance.play('fail');
      Sfx.instance.haptic(strong: true);
      onOutOfArrows?.call();
    }
  }

  void _fire() {
    final shot = Shot(ang: aimAng, step: run.step, idx: shots.length, kind: kind);
    if (kind != 'n') {
      skillLeft[kind] = (skillLeft[kind] ?? 1) - 1;
      kind = 'n';
    }
    cur = shot;
    run.shots.add(shot.copy());
    mode = Mode.fly;
    fireAt = clock;
  }

  void _win() {
    final u = shots.length + 1;
    final stars = u <= level.par ? 3 : (u == level.par + 1 ? 2 : 1);
    result = WinResult(
      stars: stars,
      used: u,
      maxBounce: maxB,
      tricks: tricks,
      firstTry: shots.isEmpty && !restarted && continues == 0,
      shots: [...shots, cur!],
      mirrors: List.of(mirrors),
    );
    mode = Mode.finish;
    finT = 0;
  }

  void startReplay() {
    final r = result;
    if (r == null) return;
    run = Run(level, [for (final s in r.shots) s.copy(echo: false)], r.mirrors);
    replayIdx = r.shots.length - 1;
    mode = Mode.replay;
    acc = finT = slowT = 0;
    trailsFull = true;
    wakeAt.clear();
    gateVis = List.filled(run.c.gates.length, 0);
    gateWas = List.filled(run.c.gates.length, false);
    camTz = 1;
    camTx = 180;
    camTy = 320;
  }

  // ---------------- 입력 (논리 좌표 360×640) ----------------
  bool pointerDown(double x, double y) {
    if (mode == Mode.replay) {
      finT = 99;
      return false;
    }
    if (mode != Mode.aim) return false;
    mirrorTap = -1;
    for (var i = 0; i < level.mirrors.length; i++) {
      final m = level.mirrors[i];
      if (m.rot && math.sqrt((x - m.x) * (x - m.x) + (y - m.y) * (y - m.y)) < 30) mirrorTap = i;
    }
    mode = Mode.hold;
    dsX = x;
    dsY = y;
    pull = 0;
    return true;
  }

  void pointerMove(double x, double y) {
    if (mode != Mode.hold) return;
    final dx = dsX - x, dy = dsY - y;
    pull = math.sqrt(dx * dx + dy * dy);
    if (pull > 6) aimAng = math.atan2(dy, dx);
  }

  void pointerUp() {
    if (mode != Mode.hold) return;
    if (pull >= 22) {
      _fire();
    } else if (mirrorTap >= 0) {
      final i = mirrorTap;
      mirrors[i] = (mirrors[i] + 1) % 4;
      mirrorSpin = (i, 0);
      Sfx.instance.play('rotate');
      Sfx.instance.haptic();
      _startTurn(quiet: true);
      if (shots.isNotEmpty) onToast?.call(tr('t_mirror'));
    } else {
      _startTurn(quiet: true);
      onToast?.call(tr('t_pull'));
    }
  }

  void pointerCancel() {
    if (mode == Mode.hold) _startTurn(quiet: true);
  }

  void toggleSkill(String k) {
    if (mode != Mode.aim || (skillLeft[k] ?? 0) <= 0) return;
    kind = kind == k ? 'n' : k;
    Sfx.instance.play('click');
    onToast?.call(kind == 'n' ? tr('t_basic') : (k == 'split' ? tr('t_split') : tr('t_pierce')), gold: true);
    notifyListeners();
  }

  /// 힌트: 정답 거울 배치로 맞추고, 첫 화살 방향을 유령 화살로 보여 준다
  void showHint() {
    final s = level.solution;
    if (s == null) return;
    hintOn = true;
    if (shots.isEmpty) {
      mirrors = List.of(s.mirrors);
      _startTurn(quiet: true);
    }
    notifyListeners();
  }

  // ---------------- 진행 ----------------
  void update(double rdt) {
    clock += rdt;
    var ts = switch (mode) { Mode.hold => 0.32, Mode.fly || Mode.finish || Mode.over => 1.0, Mode.replay => 0.65, _ => 0.0 };
    holdVis += ((mode == Mode.hold ? 1 : 0) - holdVis) * 0.15;
    if (slowT > 0) {
      slowT -= rdt;
      ts *= 0.2;
    }
    if (hitstop > 0) {
      hitstop -= rdt;
      ts = 0;
    }
    if (run.won && finT > 1.3) ts = 0;
    acc += rdt * ts;
    var n = 0;
    while (acc >= kDt && n < 60) {
      acc -= kDt;
      n++;
      final ev = <SimEvent>[];
      run.tick(ev);
      _onEvents(ev);
      for (final a in run.arrows) {
        if (!a.alive) continue;
        a.trail.addAll([a.x, a.y]);
        if (!trailsFull && a.trail.length > 44) a.trail.removeRange(0, 2);
      }
    }
    _updateGates();
    if (mode == Mode.fly && run.done && !run.won) {
      endT += rdt;
      if (endT > 0.5) _endTurn();
    }
    if (mode == Mode.finish) {
      finT += rdt;
      if (finT > 1.7 && result != null && onWin != null) {
        final cb = onWin;
        onWin = null;
        cb!(result!);
      }
    }
    if (mode == Mode.replay) {
      if (run.won) finT += rdt;
      if (finT > 1.8 || (run.done && !run.won)) {
        mode = Mode.finish;
        finT = 2;
        trailsFull = false;
      }
    }
    // 카메라·흔들림
    camZ += (camTz - camZ) * 0.08;
    camX += (camTx - camX) * 0.08;
    camY += (camTy - camY) * 0.08;
    if (finT > 1.3 || mode == Mode.over) {
      camTz = 1;
      camTx = 180;
      camTy = 320;
    }
    shake *= 0.86;
    if (Profile.instance.reduceMotion) shake = 0;
    if (flash > 0) flash -= rdt * 2.2;
    final ms = mirrorSpin;
    if (ms != null) mirrorSpin = ms.$2 >= 1 ? null : (ms.$1, ms.$2 + rdt * 7);
    _updateFx(rdt);
    notifyListeners();
  }

  void _updateGates() {
    final t = run.time;
    for (var i = 0; i < run.c.gates.length; i++) {
      final open = t < run.gateOpen[i];
      if (open != gateWas[i]) {
        if (mode != Mode.aim) Sfx.instance.play(open ? 'gate_open' : 'gate_close');
        gateWas[i] = open;
        final g = run.c.gates[i];
        if (open) _burst((g.x1 + g.x2) / 2, (g.y1 + g.y2) / 2, 0xFFB38CFF, 14, 120, 2.4);
      }
      gateVis[i] += ((open ? 1 : 0) - gateVis[i]) * 0.25;
    }
  }

  void _updateFx(double rdt) {
    for (var i = parts.length - 1; i >= 0; i--) {
      final p = parts[i];
      p.t += rdt;
      if (p.t > p.life) {
        parts.removeAt(i);
        continue;
      }
      p.vx *= 0.96;
      p.vy = p.vy * 0.96 + p.g * rdt;
      p.x += p.vx * rdt;
      p.y += p.vy * rdt;
    }
    for (var i = rings.length - 1; i >= 0; i--) {
      rings[i].t += rdt;
      if (rings[i].t > rings[i].life) rings.removeAt(i);
    }
    for (var i = texts.length - 1; i >= 0; i--) {
      texts[i].t += rdt;
      if (texts[i].t > texts[i].life) texts.removeAt(i);
    }
  }

  int _col(Arrow a) => (a.idx == curIdx ? Palette.shot[0] : Palette.shot[1 + a.idx % 5]).toARGB32();

  void _burst(double x, double y, int col, int n, double sp, double size) {
    for (var i = 0; i < n; i++) {
      final a = _rnd.nextDouble() * math.pi * 2, v = sp * (0.35 + _rnd.nextDouble() * 0.75);
      parts.add(Particle(x, y, math.cos(a) * v, math.sin(a) * v, 0.45 + _rnd.nextDouble() * 0.4, col, size * (0.6 + _rnd.nextDouble() * 0.8)));
    }
  }

  void _ring(double x, double y, int col, [double r1 = 34, double life = 0.4, double w = 3]) => rings.add(RingFx(x, y, col, r1, life, w));
  void _text(double x, double y, String s, int col, [double size = 18, double life = 1]) => texts.add(FloatText(x, y, s, col, size, life));

  void _onEvents(List<SimEvent> ev) {
    final sfx = Sfx.instance;
    for (final e in ev) {
      final a = e.a;
      final col = a == null ? 0xFFFFFFFF : _col(a);
      final mine = a != null && a.idx == curIdx;
      switch (e.type) {
        case Ev.launch:
          if (mine) {
            sfx.play('twang');
            sfx.haptic();
            shake = math.max(shake, 3);
          } else {
            sfx.play('echo', volume: 0.5);
            _ring(a!.x, a.y, col, 26, 0.5, 2);
          }
        case Ev.bounce:
          sfx.bounce(e.b - 1);
          _burst(e.x, e.y, col, 8, 140, 2.2);
          _ring(e.x, e.y, col, 18, 0.25, 2);
          if (mine) {
            maxB = math.max(maxB, e.b);
            if (e.b >= 2) _text(e.x, e.y - 8, '×${e.b}', col, 13.0 + math.min(e.b, 8), 0.6);
            shake = math.max(shake, 1.5);
          }
        case Ev.stick:
          sfx.play(e.k == 'g' ? 'gate_stick' : 'stick', volume: 0.6);
          _burst(e.x, e.y, e.k == 'g' ? 0xFFB38CFF : 0xFF6FD39B, 10, 110, 2.4);
        case Ev.sw:
          sfx.play('switch');
          _ring(e.x, e.y, 0xFF7EF0FF, 46, 0.6, 4);
          _burst(e.x, e.y, 0xFF7EF0FF, 16, 180, 2.6);
          shake = math.max(shake, 3);
        case Ev.hit:
          sfx.hit(e.multi - 1);
          sfx.haptic(strong: true);
          _burst(e.x, e.y, 0xFFFFE08A, 26, 240, 3.2);
          _burst(e.x, e.y, 0xFFFFFFFF, 10, 120, 2);
          _ring(e.x, e.y, 0xFFFFD36B, 52, 0.55, 5);
          hitstop = math.max(hitstop, 0.07);
          shake = math.max(shake, 6);
          flash = math.max(flash, 0.25);
          String? label;
          if (e.multi == 2) {
            label = tr('f_double');
          } else if (e.multi == 3) {
            label = tr('f_triple');
          } else if (e.multi > 3) {
            label = tr('f_combo', {'n': e.multi});
          }
          if (e.b >= 2) {
            label = label == null ? tr('f_trick') : tr('f_trick_x', {'x': label});
            if (mode != Mode.replay) tricks++;
          }
          if (!mine && label == null) label = tr('f_echo');
          if (label != null) _text(e.x, e.y - 26, label, e.b >= 2 ? 0xFFFFD36B : 0xFFFFFFFF, 22, 1.1);
          lastHit = (e.x, e.y);
          wakeAt[e.i] = clock;
        case Ev.win:
          winAt = clock;
          sfx.play('win');
          sfx.haptic(strong: true);
          slowT = 1.1;
          hitstop = 0.12;
          flash = 0.7;
          shake = 10;
          camTz = Profile.instance.reduceMotion ? 1 : 1.28;
          camTx = lastHit.$1;
          camTy = lastHit.$2;
          for (var i = 0; i < 70; i++) {
            final an = _rnd.nextDouble() * math.pi * 2, v = 120 + _rnd.nextDouble() * 320;
            parts.add(Particle(lastHit.$1, lastHit.$2, math.cos(an) * v, math.sin(an) * v - 120, 1 + _rnd.nextDouble() * 0.8, Palette.shot[i % 6].toARGB32(), 3 + _rnd.nextDouble() * 3, g: 380, confetti: true, rot: _rnd.nextDouble() * 6));
          }
          if (mode == Mode.fly || mode == Mode.hold) {
            _win();
          } else if (mode == Mode.replay) {
            finT = 0;
          }
        case Ev.fizzle:
          sfx.play('fizzle', volume: 0.5);
          _burst(e.x, e.y, 0xFF9AA6D6, 8, 60, 2);
        case Ev.spawn:
          break;
        case Ev.oops:
          wakeAt[e.i] = clock;
          sfx.play('oops');
          sfx.haptic(strong: true);
          shake = 8;
          flash = 0.2;
          _burst(e.x, e.y, 0xFFFF9FC8, 20, 200, 3);
          _ring(e.x, e.y, 0xFFFF7A9A, 48, 0.5, 4);
          _text(e.x, e.y - 26, mine ? tr('f_oops_me') : tr('f_oops_echo'), 0xFFFF9FC8, 17, 1.6);
          if (!mine) onToast?.call(tr('t_baby_echo'));
        case Ev.ice:
          sfx.play('ice');
          shake = math.max(shake, 4);
          final ib = level.blocks.where((b) => b.k == 'i').elementAt(e.i);
          for (var k = 0; k < 22; k++) {
            parts.add(Particle(ib.x + _rnd.nextDouble() * ib.w, ib.y + _rnd.nextDouble() * ib.h, (_rnd.nextDouble() - 0.5) * 260, (_rnd.nextDouble() - 0.8) * 220, 0.7 + _rnd.nextDouble() * 0.5,
                _rnd.nextBool() ? 0xFFBFF4FF : 0xFF7FD8FF, 2 + _rnd.nextDouble() * 3, g: 520, confetti: true, rot: _rnd.nextDouble() * 6));
          }
          _text(e.x, e.y - 14, tr('f_ice'), 0xFFBFF4FF, 18, 0.7);
        case Ev.portal:
          sfx.play('portal', volume: 0.6);
          _ring(e.x, e.y, 0xFFFF9F5A, 34, 0.45, 3);
          _ring(e.x2, e.y2, 0xFF5AB8FF, 34, 0.45, 3);
          _burst(e.x2, e.y2, 0xFF9FD4FF, 10, 140, 2.2);
          a?.trail.addAll([double.nan, double.nan]);
        case Ev.prism:
          sfx.play('prism');
          shake = math.max(shake, 4);
          for (final c in const [0xFFFF7A8A, 0xFFFFD36B, 0xFF8DFFB5, 0xFF7EF0FF, 0xFFB9A4FF]) {
            _burst(e.x, e.y, c, 5, 200, 2.4);
          }
          _ring(e.x, e.y, 0xFFFFFFFF, 40, 0.5, 3);
          _text(e.x, e.y - 22, tr('f_prism'), 0xFFFFFFFF, 18, 0.8);
        case Ev.split:
          sfx.play('prism', volume: 0.6);
          _ring(e.x, e.y, 0xFFFFD36B, 30, 0.4, 3);
          _text(e.x, e.y - 16, tr('f_split'), 0xFFFFD36B, 18, 0.8);
        case Ev.shield:
          sfx.play('shield');
          _burst(e.x, e.y, 0xFFDFE8FF, 12, 160, 2.2);
          _text(e.x, e.y - 14, tr('f_shield'), 0xFFDFE8FF, 16, 0.6);
          shake = math.max(shake, 3);
      }
    }
  }
}
