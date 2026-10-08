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
const double kD2R = math.pi / 180;

class Field {
  static const double x0 = 12, y0 = 84, x1 = 348, y1 = 624;
  static const double w = 360, h = 640;
}

/// 벽 종류: w 나무(튕김), m 이끼(정지), g 문(닫히면 정지)
class Seg {
  Seg(this.x1, this.y1, this.x2, this.y2, this.k, {this.ice, this.edge = false}) {
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
  final gates = [for (final g in l.gates) Seg(g.x1, g.y1, g.x2, g.y2, 'g')];
  return _compiled[l] = Compiled(segs, gates, ice);
}

Seg mirrorSeg(MirrorDef m, int s) {
  final a = s * 45 * kD2R, hx = math.cos(a) * m.len / 2, hy = math.sin(a) * m.len / 2;
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
  _Hit(this.t, this.k, {this.nx = 0, this.ny = 0, this.ice, this.mirror = false, this.bumper = false, this.portal = -1, this.end = ''});
  double t;
  final String k;
  final double nx, ny;
  final int? ice;
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

enum Ev { launch, bounce, stick, ice, split, portal, prism, sw, hit, shield, oops, fizzle, spawn, win }

class SimEvent {
  SimEvent(this.type, {this.a, this.x = 0, this.y = 0, this.x2 = 0, this.y2 = 0, this.b = 0, this.i = -1, this.k = '', this.multi = 0, this.mirror = false, this.bumper = false});
  final Ev type;
  final Arrow? a;
  final double x, y, x2, y2;
  final int b, i, multi;
  final String k;
  final bool mirror, bumper;
}

class Run {
  Run(this.level, List<Shot> shots, List<int>? mirrors) : c = compileLevel(level) {
    this.shots = [for (final s in shots) s.copy()];
    this.mirrors = List.of(mirrors ?? level.defaultMirrors);
    mseg = [for (var i = 0; i < level.mirrors.length; i++) mirrorSeg(level.mirrors[i], this.mirrors[i])];
    hit = List.filled(level.targets.length, false);
    gateOpen = List.filled(c.gates.length, -1);
    ice = List.filled(c.iceCount, false);
  }
  final LevelData level;
  final Compiled c;
  late final List<Shot> shots;
  late final List<int> mirrors;
  late final List<Seg> mseg;
  late final List<bool> hit;
  late final List<double> gateOpen;
  late final List<bool> ice;
  final List<Arrow> arrows = [];
  final List<Arrow> _spawned = [];
  int step = 0;
  bool won = false;
  bool failed = false;

  double get time => step * kDt;

  bool get done => (failed && arrows.every((a) => !a.alive)) || (shots.every((s) => s.launched) && arrows.every((a) => !a.alive));

  _Hit? _nearest(double time, double px, double py, double dx, double dy, bool pierce, bool extra) {
    var bt = 2.0;
    _Hit? h;
    for (final s in c.segs) {
      if (s.k == 'm' && pierce) continue;
      if (s.ice != null && ice[s.ice!]) continue;
      final t = _hitSeg(s, px, py, dx, dy);
      if (t >= 0 && t < bt) {
        bt = t;
        h = _Hit(t, s.k, nx: s.nx, ny: s.ny, ice: s.ice);
      }
    }
    for (final s in mseg) {
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
      if (h.k == 'w') {
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

  void tick([List<SimEvent>? ev]) {
    final l = level, time = step * kDt;
    for (final s in shots) {
      if (!s.launched && s.step <= step) {
        s.launched = true;
        final a = Arrow(x: l.bowX, y: l.bowY, vx: math.cos(s.ang) * kSpeed, vy: math.sin(s.ang) * kSpeed, idx: s.idx, kind: s.kind);
        arrows.add(a);
        ev?.add(SimEvent(Ev.launch, a: a, k: s.echo ? 'echo' : ''));
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
      if (h.k == 'x') {
        end = 'x';
        break;
      }
      if (h.k != 'w') {
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
