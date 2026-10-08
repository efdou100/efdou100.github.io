// 메아리 화살 — 결정론적 시뮬레이션.
// echo-arrow/sim.js(레벨 생성기·솔버)와 계산 순서를 맞춰 두었다. 한쪽을 고치면 다른 쪽도 고칠 것.
import 'dart:math' as math;

import 'level.dart';

const double kDt = 1 / 240;
const double kSpeed = 560;
const int kMaxBounce = 12;
const double kLife = 6;
const double kTargetR = 15;
const double kSwitchR = 13;
const double kPortalR = 15;
const double kPrismR = 12;
const int kMaxArrows = 30;
const double kRelayR = 14; // 되쏘기 고리 반지름
const double kRelayHold = 0.5; // 붙잡고 있는 시간
const double kLanternR = 12;
const double kBlastR = 74; // 등불 폭발 반경
const double kChain = 0.18; // 옆 등불로 번지는 시간
const double kD2R = math.pi / 180;

class Field {
  static const double x0 = 12, y0 = 84, x1 = 348, y1 = 624;
  static const double w = 360, h = 640;
}

/// 벽 종류: w 나무(튕김), m 이끼(정지), g 문(닫히면 정지)
class Seg {
  Seg(this.x1, this.y1, this.x2, this.y2, this.k, {this.ice, this.edge = false, this.crys, this.soft = false}) {
    ex = x2 - x1;
    ey = y2 - y1;
    final len = math.sqrt(ex * ex + ey * ey);
    nx = -ey / len;
    ny = ex / len;
  }
  final double x1, y1, x2, y2;
  final String k;
  final int? ice;
  final bool edge;
  final int? crys; // 유리 마개 번호
  final bool soft; // 깨지는 면
  late final double ex, ey, nx, ny;
}

class Compiled {
  Compiled(this.segs, this.gates, this.iceCount);
  final List<Seg> segs;
  final List<Seg> gates;
  final int iceCount;
}

final Expando<Compiled> _compiled = Expando();

Compiled compileLevel(LevelData l) {
  final cached = _compiled[l];
  if (cached != null) return cached;
  final segs = <Seg>[];
  void side(String name, double a0, double a1, Seg Function(double a, double b, String k) mk) {
    final iv = l.edges[name] ?? [EdgeSpan(a0, a1, 'w')];
    for (final s in iv) {
      segs.add(mk(s.a, s.b, s.k));
    }
  }

  side('top', Field.x0, Field.x1, (a, b, k) => Seg(a, Field.y0, b, Field.y0, k, edge: true));
  side('bottom', Field.x0, Field.x1, (a, b, k) => Seg(a, Field.y1, b, Field.y1, k, edge: true));
  side('left', Field.y0, Field.y1, (a, b, k) => Seg(Field.x0, a, Field.x0, b, k, edge: true));
  side('right', Field.y0, Field.y1, (a, b, k) => Seg(Field.x1, a, Field.x1, b, k, edge: true));
  for (final w in l.walls) {
    segs.add(Seg(w.x1, w.y1, w.x2, w.y2, w.k));
  }
  var ice = 0;
  for (final b in l.blocks) {
    final id = b.k == 'i' ? ice++ : null;
    final k = b.k == 'i' ? 'w' : b.k;
    final x = b.x, y = b.y, w = b.w, h = b.h;
    segs.add(Seg(x, y, x + w, y, k, ice: id));
    segs.add(Seg(x + w, y, x + w, y + h, k, ice: id));
    segs.add(Seg(x + w, y + h, x, y + h, k, ice: id));
    segs.add(Seg(x, y + h, x, y, k, ice: id));
  }
  for (var id = 0; id < l.crystals.length; id++) {
    final k = l.crystals[id];
    final x = k.x, y = k.y, w = k.w, h = k.h;
    segs.add(Seg(x, y, x + w, y, 'c', crys: id, soft: k.soft == 't'));
    segs.add(Seg(x + w, y, x + w, y + h, 'c', crys: id, soft: k.soft == 'r'));
    segs.add(Seg(x + w, y + h, x, y + h, 'c', crys: id, soft: k.soft == 'b'));
    segs.add(Seg(x, y + h, x, y, 'c', crys: id, soft: k.soft == 'l'));
  }
  final gates = [for (final g in l.gates) Seg(g.x1, g.y1, g.x2, g.y2, 'g')];
  return _compiled[l] = Compiled(segs, gates, ice);
}

/// 째깍 거울은 정수 step 으로 계산해 JS/Dart 가 똑같이 끊어지게 한다
double mirrorAngle(MirrorDef m, int s, int st) => (s + (m.spin > 0 ? st ~/ (m.spin / kDt).round() : 0)) * 45 * kD2R;

Seg? mirrorSeg(MirrorDef m, int s, [int st = 0]) {
  if (m.relay) return null;
  final a = mirrorAngle(m, s, st), hx = math.cos(a) * m.len / 2, hy = math.sin(a) * m.len / 2;
  return Seg(m.x - hx, m.y - hy, m.x + hx, m.y + hy, 'w');
}

double _hitSeg(Seg s, double px, double py, double dx, double dy) {
  final den = dx * s.ey - dy * s.ex;
  if (den.abs() < 1e-12) return -1;
  final ax = s.x1 - px, ay = s.y1 - py;
  final t = (ax * s.ey - ay * s.ex) / den, u = (ax * dy - ay * dx) / den;
  return t >= 0 && t <= 1 && u >= -1e-6 && u <= 1 + 1e-6 ? t : -1;
}

double _hitCircle(double cx, double cy, double r, double px, double py, double dx, double dy) {
  final fx = px - cx, fy = py - cy, a = dx * dx + dy * dy, b = 2 * (fx * dx + fy * dy), c = fx * fx + fy * fy - r * r;
  if (b >= 0) return -1;
  final disc = b * b - 4 * a * c;
  if (disc < 0) return -1;
  final t = (-b - math.sqrt(disc)) / (2 * a);
  return t >= 0 && t <= 1 ? t : -1;
}

class _Hit {
  _Hit(this.t, this.k, {this.nx = 0, this.ny = 0, this.ice, this.mirror = false, this.bumper = false, this.portal = -1, this.end = '', this.crys, this.soft = false});
  double t;
  final String k;
  final double nx, ny;
  final int? ice;
  final int? crys;
  final bool soft;
  final bool mirror, bumper;
  final int portal;
  final String end;
}

class Shot {
  Shot({required this.ang, required this.step, required this.idx, this.kind = 'n', this.echo = false});
  final double ang; // 라디안
  final int step;
  final int idx;
  final String kind; // n, split, pierce
  final bool echo;
  bool launched = false;
  Shot copy({bool? echo}) => Shot(ang: ang, step: step, idx: idx, kind: kind, echo: echo ?? this.echo);
}

class Arrow {
  Arrow({required this.x, required this.y, required this.vx, required this.vy, required this.idx, required this.kind, this.b = 0, this.age = 0, List<int>? prisms, this.child = false})
    : prisms = prisms ?? [];
  double x, y, vx, vy;
  final int idx;
  String kind;
  int b;
  double age;
  bool alive = true;
  int hits = 0;
  double pcd = 0;
  final List<int> prisms;
  final bool child;
  bool didSplit = false;
  String? stuck;
  double? ang;
  // 렌더용 궤적 (sim 은 건드리지 않음)
  final List<double> trail = [];
}

enum Ev { launch, bounce, stick, ice, split, portal, prism, sw, hit, shield, oops, fizzle, spawn, win, crack, relayCatch, relay, boom }

class SimEvent {
  SimEvent(this.type, {this.a, this.x = 0, this.y = 0, this.x2 = 0, this.y2 = 0, this.b = 0, this.i = -1, this.k = '', this.multi = 0, this.mirror = false, this.bumper = false, this.boom = false});
  final Ev type;
  final Arrow? a;
  final double x, y, x2, y2;
  final int b, i, multi;
  final String k;
  final bool mirror, bumper;
  final bool boom; // 등불 폭발로 일어난 일
}

/// 되쏘기 고리에 붙잡힌 화살
class _Held {
  _Held(this.i, this.at, this.idx, this.kind, this.b, this.age, this.prisms);
  final int i, at, idx, b;
  final String kind;
  final double age;
  final List<int> prisms;
}

class Run {
  Run(this.level, List<Shot> shots, List<int>? mirrors) : c = compileLevel(level) {
    this.shots = [for (final s in shots) s.copy()];
    this.mirrors = List.of(mirrors ?? level.defaultMirrors);
    mseg = [for (var i = 0; i < level.mirrors.length; i++) mirrorSeg(level.mirrors[i], this.mirrors[i])];
    hit = List.filled(level.targets.length, false);
    gateOpen = List.filled(c.gates.length, -1);
    ice = List.filled(c.iceCount, false);
    crys = List.filled(level.crystals.length, false);
    lit = List.filled(level.lanterns.length, false);
  }
  final LevelData level;
  final Compiled c;
  late final List<Shot> shots;
  late final List<int> mirrors;
  late final List<Seg?> mseg; // 되쏘기 고리 자리는 null
  late final List<bool> hit;
  late final List<double> gateOpen;
  late final List<bool> ice;
  late final List<bool> crys; // 깨진 유리 마개
  late final List<bool> lit; // 터진(불 붙은) 등불
  final List<_Held> _held = [];
  List<({int i, int at})> _booms = [];
  final List<Arrow> arrows = [];
  final List<Arrow> _spawned = [];
  int step = 0;
  bool won = false;
  bool failed = false;

  double get time => step * kDt;

  bool get done => (failed && arrows.every((a) => !a.alive)) || (shots.every((s) => s.launched) && arrows.every((a) => !a.alive) && _held.isEmpty && _booms.isEmpty);

  /// 고리에 붙잡혀 있는 화살 (그리기용): 고리 번호 → 놓아줄 step
  Iterable<(int, int)> get held => _held.map((h) => (h.i, h.at));

  _Hit? _nearest(double time, double px, double py, double dx, double dy, bool pierce, bool extra) {
    var bt = 2.0;
    _Hit? h;
    for (final s in c.segs) {
      if (s.k == 'm' && pierce) continue;
      if (s.ice != null && ice[s.ice!]) continue;
      if (s.crys != null && crys[s.crys!]) continue;
      final t = _hitSeg(s, px, py, dx, dy);
      if (t >= 0 && t < bt) {
        bt = t;
        h = _Hit(t, s.k, nx: s.nx, ny: s.ny, ice: s.ice, crys: s.crys, soft: s.soft);
      }
    }
    for (final s in mseg) {
      if (s == null) continue;
      final t = _hitSeg(s, px, py, dx, dy);
      if (t >= 0 && t < bt) {
        bt = t;
        h = _Hit(t, 'w', nx: s.nx, ny: s.ny, mirror: true);
      }
    }
    for (var i = 0; i < c.gates.length; i++) {
      if (time < gateOpen[i]) continue;
      final g = c.gates[i];
      final t = _hitSeg(g, px, py, dx, dy);
      if (t >= 0 && t < bt) {
        bt = t;
        h = _Hit(t, 'g', nx: g.nx, ny: g.ny);
      }
    }
    for (final u in level.bumpers) {
      final t = _hitCircle(u.x, u.y, u.r, px, py, dx, dy);
      if (t >= 0 && t < bt) {
        bt = t;
        final hx = px + dx * t - u.x, hy = py + dy * t - u.y, l = math.sqrt(hx * hx + hy * hy);
        h = _Hit(t, 'w', nx: hx / l, ny: hy / l, bumper: true);
      }
    }
    if (extra) {
      for (var i = 0; i < level.portals.length; i++) {
        final p = level.portals[i];
        for (final e in [('a', p.ax, p.ay), ('b', p.bx, p.by)]) {
          final t = _hitCircle(e.$2, e.$3, kPortalR, px, py, dx, dy);
          if (t >= 0 && t < bt) {
            bt = t;
            h = _Hit(t, 'p', portal: i, end: e.$1);
          }
        }
      }
      for (final x in level.prisms) {
        final t = _hitCircle(x.x, x.y, kPrismR, px, py, dx, dy);
        if (t >= 0 && t < bt) {
          bt = t;
          h = _Hit(t, 'x');
        }
      }
      for (var i = 0; i < level.mirrors.length; i++) {
        final m = level.mirrors[i];
        if (!m.relay) continue;
        final t = _hitCircle(m.x, m.y, kRelayR, px, py, dx, dy);
        if (t >= 0 && t < bt) {
          bt = t;
          h = _Hit(t, 'r', portal: i);
        }
      }
      for (var i = 0; i < level.lanterns.length; i++) {
        if (lit[i]) continue;
        final n = level.lanterns[i];
        final t = _hitCircle(n.x, n.y, kLanternR, px, py, dx, dy);
        if (t >= 0 && t < bt) {
          bt = t;
          h = _Hit(t, 'l', portal: i);
        }
      }
    }
    return h;
  }

  void _spawn(Arrow from, double x, double y, double ang, {List<int>? prisms, bool didSplit = false}) {
    if (arrows.length + _spawned.length >= kMaxArrows) return;
    final a = Arrow(
      x: x,
      y: y,
      vx: math.cos(ang) * kSpeed,
      vy: math.sin(ang) * kSpeed,
      idx: from.idx,
      kind: from.kind == 'split' ? 'n' : from.kind,
      b: from.b,
      age: from.age,
      prisms: prisms ?? List.of(from.prisms),
      child: true,
    )..didSplit = didSplit;
    _spawned.add(a);
  }

  void _move(Arrow a, double time, List<SimEvent>? ev) {
    var dx = a.vx * kDt, dy = a.vy * kDt;
    for (var it = 0; it < 6; it++) {
      final h = _nearest(time, a.x, a.y, dx, dy, a.kind == 'pierce', false);
      if (h == null) {
        a.x += dx;
        a.y += dy;
        return;
      }
      a.x += dx * h.t;
      a.y += dy * h.t;
      if (h.k == 'c' && h.soft) {
        crys[h.crys!] = true;
        a.alive = false;
        a.stuck = 'c';
        a.ang = math.atan2(a.vy, a.vx);
        ev?.add(SimEvent(Ev.crack, a: a, i: h.crys!, x: a.x, y: a.y));
        return;
      }
      if (h.k == 'w' || h.k == 'c') {
        var nx = h.nx, ny = h.ny;
        if (nx * dx + ny * dy > 0) {
          nx = -nx;
          ny = -ny;
        }
        final rem = 1 - h.t, vd = a.vx * nx + a.vy * ny;
        a.vx -= 2 * vd * nx;
        a.vy -= 2 * vd * ny;
        a.x += nx * 0.05;
        a.y += ny * 0.05;
        dx = a.vx * kDt * rem;
        dy = a.vy * kDt * rem;
        a.b++;
        if (h.ice != null) {
          ice[h.ice!] = true;
          ev?.add(SimEvent(Ev.ice, i: h.ice!, x: a.x, y: a.y));
        }
        ev?.add(SimEvent(Ev.bounce, a: a, x: a.x, y: a.y, b: a.b, mirror: h.mirror, bumper: h.bumper));
        if (a.kind == 'split' && !a.didSplit) {
          a.didSplit = true;
          a.kind = 'n';
          final ang = math.atan2(a.vy, a.vx);
          for (final d in const [-28, 28]) {
            _spawn(a, a.x, a.y, ang + d * kD2R, didSplit: true);
          }
          ev?.add(SimEvent(Ev.split, a: a, x: a.x, y: a.y));
        }
        if (a.b > kMaxBounce) {
          a.alive = false;
          ev?.add(SimEvent(Ev.fizzle, a: a, x: a.x, y: a.y));
          return;
        }
      } else {
        a.alive = false;
        a.stuck = h.k;
        a.ang = math.atan2(a.vy, a.vx);
        ev?.add(SimEvent(Ev.stick, a: a, x: a.x, y: a.y, k: h.k));
        return;
      }
    }
  }

  /// 등불 폭발: 반경 안 정령을 깨우고(방패 무시, 아기 정령은 실패), 유리 마개를 깨고, 다른 등불에 불을 옮긴다
  void _boom(int i, double time, List<SimEvent>? ev) {
    final l = level, n = l.lanterns[i];
    ev?.add(SimEvent(Ev.boom, i: i, x: n.x, y: n.y));
    for (var j = 0; j < l.targets.length; j++) {
      if (hit[j]) continue;
      final (tx, ty) = l.targets[j].pos(time);
      if ((tx - n.x) * (tx - n.x) + (ty - n.y) * (ty - n.y) >= kBlastR * kBlastR) continue;
      hit[j] = true;
      if (l.targets[j].avoid) {
        failed = true;
        ev?.add(SimEvent(Ev.oops, i: j, x: tx, y: ty, boom: true));
      } else {
        ev?.add(SimEvent(Ev.hit, i: j, x: tx, y: ty, b: 0, multi: 1, boom: true));
      }
    }
    for (var j = 0; j < l.crystals.length; j++) {
      if (crys[j]) continue;
      final k = l.crystals[j];
      final cx = k.x + k.w / 2, cy = k.y + k.h / 2;
      if ((cx - n.x) * (cx - n.x) + (cy - n.y) * (cy - n.y) < kBlastR * kBlastR) {
        crys[j] = true;
        ev?.add(SimEvent(Ev.crack, i: j, x: cx, y: cy));
      }
    }
    for (var j = 0; j < l.lanterns.length; j++) {
      if (lit[j]) continue;
      final o = l.lanterns[j];
      if ((o.x - n.x) * (o.x - n.x) + (o.y - n.y) * (o.y - n.y) < kBlastR * kBlastR) {
        lit[j] = true;
        _booms.add((i: j, at: step + (kChain / kDt).round()));
      }
    }
  }

  void tick([List<SimEvent>? ev]) {
    final l = level, time = step * kDt;
    for (var i = 0; i < l.mirrors.length; i++) {
      if (l.mirrors[i].spin > 0) mseg[i] = mirrorSeg(l.mirrors[i], mirrors[i], step);
    }
    if (_booms.isNotEmpty) {
      final due = _booms.where((b) => b.at <= step).toList();
      _booms = _booms.where((b) => b.at > step).toList();
      for (final b in due) {
        _boom(b.i, time, ev);
      }
    }
    for (final s in shots) {
      if (!s.launched && s.step <= step) {
        s.launched = true;
        final a = Arrow(x: l.bowX, y: l.bowY, vx: math.cos(s.ang) * kSpeed, vy: math.sin(s.ang) * kSpeed, idx: s.idx, kind: s.kind);
        arrows.add(a);
        ev?.add(SimEvent(Ev.launch, a: a, k: s.echo ? 'echo' : ''));
      }
    }
    if (_held.isNotEmpty) {
      final due = _held.where((h) => h.at <= step).toList();
      _held.removeWhere((h) => h.at <= step);
      for (final h in due) {
        if (arrows.length >= kMaxArrows) continue;
        final m = l.mirrors[h.i], ang = mirrors[h.i] * 45 * kD2R;
        final a = Arrow(
          x: m.x + math.cos(ang) * (kRelayR + 4),
          y: m.y + math.sin(ang) * (kRelayR + 4),
          vx: math.cos(ang) * kSpeed,
          vy: math.sin(ang) * kSpeed,
          idx: h.idx,
          kind: h.kind,
          b: h.b,
          age: h.age,
          prisms: h.prisms,
          child: true,
        );
        arrows.add(a);
        ev?.add(SimEvent(Ev.relay, a: a, i: h.i, x: m.x, y: m.y));
      }
    }
    for (final a in arrows) {
      if (!a.alive) continue;
      _move(a, time, ev);
      if (!a.alive) continue;
      if (a.pcd > 0) a.pcd -= kDt;
      // 포털
      for (var i = 0; i < l.portals.length && a.pcd <= 0; i++) {
        final p = l.portals[i];
        for (final pair in [(p.ax, p.ay, p.bx, p.by), (p.bx, p.by, p.ax, p.ay)]) {
          final fx = a.x - pair.$1, fy = a.y - pair.$2;
          if (fx * fx + fy * fy < kPortalR * kPortalR) {
            final sp = math.sqrt(a.vx * a.vx + a.vy * a.vy);
            a.x = pair.$3 + (a.vx / sp) * (kPortalR + 2);
            a.y = pair.$4 + (a.vy / sp) * (kPortalR + 2);
            a.pcd = 0.15;
            ev?.add(SimEvent(Ev.portal, a: a, x: pair.$1, y: pair.$2, x2: pair.$3, y2: pair.$4));
            break;
          }
        }
      }
      // 프리즘
      for (var i = 0; i < l.prisms.length; i++) {
        final x = l.prisms[i];
        if (a.prisms.contains(i)) continue;
        final fx = a.x - x.x, fy = a.y - x.y;
        if (fx * fx + fy * fy < kPrismR * kPrismR) {
          a.alive = false;
          a.stuck = 'x';
          final ang = math.atan2(a.vy, a.vx);
          for (final d in const [-40, 0, 40]) {
            final na = ang + d * kD2R;
            _spawn(a, x.x + math.cos(na) * (kPrismR + 3), x.y + math.sin(na) * (kPrismR + 3), na, prisms: [...a.prisms, i]);
          }
          ev?.add(SimEvent(Ev.prism, a: a, x: x.x, y: x.y, i: i));
          break;
        }
      }
      if (!a.alive) continue;
      // 되쏘기 고리
      for (var i = 0; i < l.mirrors.length; i++) {
        final m = l.mirrors[i];
        if (!m.relay) continue;
        final fx = a.x - m.x, fy = a.y - m.y;
        if (fx * fx + fy * fy < kRelayR * kRelayR) {
          a.alive = false;
          a.stuck = 'r';
          _held.add(_Held(i, step + (kRelayHold / kDt).round(), a.idx, a.kind, a.b, a.age, List.of(a.prisms)));
          ev?.add(SimEvent(Ev.relayCatch, a: a, i: i, x: m.x, y: m.y));
          break;
        }
      }
      if (!a.alive) continue;
      // 스위치
      for (var i = 0; i < l.switches.length; i++) {
        final sw = l.switches[i];
        final fx = a.x - sw.x, fy = a.y - sw.y;
        if (fx * fx + fy * fy < (kSwitchR + 2) * (kSwitchR + 2)) {
          a.alive = false;
          a.stuck = 's';
          for (final g in sw.gates) {
            gateOpen[g] = time + l.gates[g].dur;
          }
          ev?.add(SimEvent(Ev.sw, a: a, i: i, x: sw.x, y: sw.y));
          break;
        }
      }
      if (!a.alive) continue;
      // 등불
      for (var i = 0; i < l.lanterns.length; i++) {
        if (lit[i]) continue;
        final n = l.lanterns[i];
        final fx = a.x - n.x, fy = a.y - n.y;
        if (fx * fx + fy * fy < (kLanternR + 2) * (kLanternR + 2)) {
          a.alive = false;
          a.stuck = 'l';
          a.ang = math.atan2(a.vy, a.vx);
          lit[i] = true;
          _boom(i, time, ev);
          break;
        }
      }
      if (!a.alive) continue;
      // 정령
      for (var i = 0; i < l.targets.length; i++) {
        final tg = l.targets[i];
        if (hit[i]) continue;
        final (tx, ty) = tg.pos(time);
        final ddx = a.x - tx, ddy = a.y - ty;
        if (ddx * ddx + ddy * ddy < (kTargetR + 2) * (kTargetR + 2)) {
          if (tg.avoid) {
            hit[i] = true;
            failed = true;
            a.alive = false;
            a.stuck = 'o';
            a.ang = math.atan2(a.vy, a.vx);
            ev?.add(SimEvent(Ev.oops, a: a, i: i, x: tx, y: ty));
            break;
          }
          if (tg.shield != null) {
            final phi = math.atan2(ddy, ddx);
            final diff = (((phi - tg.shield! * kD2R).remainder(2 * math.pi) + 3 * math.pi).remainder(2 * math.pi) - math.pi).abs();
            if (diff < 75 * kD2R) {
              final l2 = math.sqrt(ddx * ddx + ddy * ddy);
              final ln = l2 == 0 ? 1.0 : l2;
              final nx = ddx / ln, ny = ddy / ln, vd = a.vx * nx + a.vy * ny;
              if (vd < 0) {
                a.vx -= 2 * vd * nx;
                a.vy -= 2 * vd * ny;
                a.b++;
                a.x = tx + nx * (kTargetR + 3);
                a.y = ty + ny * (kTargetR + 3);
                ev?.add(SimEvent(Ev.shield, a: a, i: i, x: a.x, y: a.y, b: a.b));
              }
              continue;
            }
          }
          hit[i] = true;
          a.hits++;
          ev?.add(SimEvent(Ev.hit, a: a, i: i, x: tx, y: ty, b: a.b, multi: a.hits));
        }
      }
      a.age += kDt;
      if (a.age > kLife) {
        a.alive = false;
        ev?.add(SimEvent(Ev.fizzle, a: a, x: a.x, y: a.y));
      }
    }
    if (_spawned.isNotEmpty) {
      for (final a in _spawned) {
        arrows.add(a);
        ev?.add(SimEvent(Ev.spawn, a: a));
      }
      _spawned.clear();
    }
    step++;
    if (!won && !failed) {
      var all = true;
      for (var i = 0; i < l.targets.length; i++) {
        if (!l.targets[i].avoid && !hit[i]) {
          all = false;
          break;
        }
      }
      if (all) {
        won = true;
        ev?.add(SimEvent(Ev.win));
      }
    }
  }

  /// 조준선. 포털을 따라가며 경로를 여러 조각으로 돌려준다.
  RayResult ray(double ang, int maxB, double maxLen, {bool pierce = false}) {
    final l = level, time = step * kDt;
    var x = l.bowX, y = l.bowY, vx = math.cos(ang), vy = math.sin(ang);
    final paths = <List<(double, double)>>[
      [(x, y)],
    ];
    var pts = paths.first;
    var b = 0, jumps = 0;
    var end = 'open';
    while (b <= maxB && jumps < 4) {
      const reach = 900.0;
      final h = _nearest(time, x, y, vx * reach, vy * reach, pierce, true);
      if (h == null) {
        pts.add((x + vx * reach, y + vy * reach));
        break;
      }
      final d = reach * h.t;
      if (b == maxB && maxLen > 0 && d > maxLen && h.k != 'p') {
        pts.add((x + vx * maxLen, y + vy * maxLen));
        end = 'cut';
        break;
      }
      x += vx * d;
      y += vy * d;
      pts.add((x, y));
      if (h.k == 'p') {
        final p = l.portals[h.portal];
        final to = h.end == 'a' ? (p.bx, p.by) : (p.ax, p.ay);
        x = to.$1 + vx * (kPortalR + 2);
        y = to.$2 + vy * (kPortalR + 2);
        pts = [(x, y)];
        paths.add(pts);
        jumps++;
        continue;
      }
      if (h.k == 'r') {
        final m = l.mirrors[h.portal], a2 = mirrors[h.portal] * 45 * kD2R;
        vx = math.cos(a2);
        vy = math.sin(a2);
        x = m.x + vx * (kRelayR + 4);
        y = m.y + vy * (kRelayR + 4);
        pts = [(x, y)];
        paths.add(pts);
        jumps++;
        continue;
      }
      if (h.k == 'x') {
        end = 'x';
        break;
      }
      if (h.k == 'c' && h.soft) {
        end = 'c';
        break;
      }
      if (h.k != 'w' && h.k != 'c') {
        end = h.k;
        break;
      }
      var nx = h.nx, ny = h.ny;
      if (nx * vx + ny * vy > 0) {
        nx = -nx;
        ny = -ny;
      }
      final vd = vx * nx + vy * ny;
      vx -= 2 * vd * nx;
      vy -= 2 * vd * ny;
      x += nx * 0.05;
      y += ny * 0.05;
      b++;
    }
    return RayResult(paths, end);
  }
}

class RayResult {
  RayResult(this.paths, this.end);
  final List<List<(double, double)>> paths;
  final String end;
}

/// 솔버·테스트용: 끝까지 돌려서 결과 반환
Run simulate(LevelData l, List<Shot> shots, List<int>? mirrors, {int maxSteps = 2600}) {
  final run = Run(l, shots, mirrors);
  while (run.step < maxSteps) {
    run.tick();
    if (run.won || run.done) break;
  }
  return run;
}
