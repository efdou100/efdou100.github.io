import 'dart:math' as math;

import '../constants.dart';
import '../physics.dart';
import 'room_template.dart';

class Cell {
  static const empty = 0, solid = 1, oneWay = 2, crumble = 3, spike = 4, spring = 5, thorn = 6, bridge = 7, crystal = 8;
}

class Spawn {
  final String kind;

  /// 바닥 가운데 기준 월드 좌표
  final double x, y;
  const Spawn(this.kind, this.x, this.y);
}

class Spot {
  final double x, y;
  bool taken = false;
  Spot(this.x, this.y);
}

class MovingPlatform extends Platform {
  final double ax, ay, bx, by;
  final bool vertical;
  final double period;
  double t;
  MovingPlatform({required this.ax, required this.ay, required this.bx, required this.by, required double w, required this.vertical})
    : period = math.max(1.6, math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay)) / 95),
      t = 0,
      super(ax, ay, w, 16);

  void update(double dt) {
    t += dt;
    // 양 끝에서 살짝 머무는 핑퐁. 타이밍을 읽기 쉽게 해요.
    final cycle = (t / period) % 2.0;
    final raw = cycle < 1 ? cycle : 2 - cycle;
    final e = _ease(raw);
    final nx = ax + (bx - ax) * e, ny = ay + (by - ay) * e;
    dx = nx - x;
    dy = ny - y;
    x = nx;
    y = ny;
  }

  static double _ease(double v) {
    final c = (v.clamp(0.0, 1.0) * 1.25 - 0.125).clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }
}

class CrumbleState {
  double shake = -1; // >=0 이면 흔들리는 중(남은 시간)
  double down = 0; // >0 이면 무너져 있음(다시 생길 때까지 남은 시간)
}

enum RoomEventKind { crumbleFall, crumbleBack, bridgeOn, bridgeOff, bridgeWarn }

class RoomEvent {
  final RoomEventKind kind;
  final int cx, cy;
  const RoomEvent(this.kind, this.cx, this.cy);
}

class Room implements Geometry {
  final RoomTemplate tpl;
  final bool mirrored;
  late final int w, h;
  late final List<List<int>> cells;
  double startX = 0, startY = 0;
  double portalX = 0, portalY = 0;
  static const double portalW = 40, portalH = 80;
  final List<Spawn> spawns = [];
  final List<MovingPlatform> movers = [];
  final List<Spot> coins = [];
  final List<Spot> shards = [];
  final List<Spot> chests = [];
  final List<RoomHint> hints = [];
  final Map<int, double> thornPhase = {};
  final Map<int, CrumbleState> crumbles = {};
  final Map<int, double> springAnim = {};
  final List<RoomEvent> events = [];
  double bridgeTimer = 0;
  double time = 0;
  bool _testMode = false;

  static const double thornCycle = 3.2, thornOn = 1.3, bridgeTime = 7.5;

  Room(this.tpl, {this.mirrored = false}) {
    final rows = mirrored ? tpl.rows.map((r) => r.split('').reversed.join()).toList() : tpl.rows;
    h = rows.length;
    w = rows.first.length;
    cells = List.generate(h, (_) => List.filled(w, Cell.empty));
    final chars = rows.map((r) => r.split('')).toList();
    var thornPatch = 0;
    for (var cy = 0; cy < h; cy++) {
      for (var cx = 0; cx < w; cx++) {
        final c = chars[cy][cx];
        final bx = (cx + 0.5) * kTile, by = (cy + 1) * kTile;
        switch (c) {
          case '#':
            cells[cy][cx] = Cell.solid;
          case '=':
            cells[cy][cx] = Cell.oneWay;
          case 'C':
            cells[cy][cx] = Cell.crumble;
            crumbles[cy * w + cx] = CrumbleState();
          case '^':
            cells[cy][cx] = Cell.spike;
          case 'J':
            cells[cy][cx] = Cell.spring;
          case 'T':
            cells[cy][cx] = Cell.thorn;
            if (cx == 0 || chars[cy][cx - 1] != 'T') thornPatch++;
            thornPhase[cy * w + cx] = thornPatch * 0.85;
          case 'h':
            cells[cy][cx] = Cell.bridge;
          case 'S':
            cells[cy][cx] = Cell.crystal;
          case '@':
            startX = bx - Phys.playerW / 2;
            startY = by - Phys.playerH;
          case 'P':
            portalX = bx - portalW / 2;
            portalY = by - portalH;
          case 'o':
            coins.add(Spot(bx, by - kTile / 2));
          case '*':
            shards.add(Spot(bx, by - kTile / 2));
          case 'R':
            chests.add(Spot(bx, by));
          case 'M':
            if (cx == 0 || chars[cy][cx - 1] != 'M') _parseMover(chars, cx, cy, false);
          case 'V':
            if (cx == 0 || chars[cy][cx - 1] != 'V') _parseMover(chars, cx, cy, true);
          case 's' || 'x' || 'm' || 'b' || 'w' || 'K' || 'L':
            spawns.add(Spawn(c, bx, by));
        }
      }
    }
    for (final hint in tpl.hints) {
      hints.add(RoomHint(mirrored ? w - 1 - hint.x : hint.x, hint.text));
    }
  }

  void _parseMover(List<List<String>> chars, int cx, int cy, bool vertical) {
    final mark = vertical ? 'V' : 'M';
    var n = 0;
    while (cx + n < w && chars[cy][cx + n] == mark) {
      n++;
    }
    final pw = n * kTile;
    if (!vertical) {
      var left = 0, right = 0;
      while (cx - left - 1 >= 0 && chars[cy][cx - left - 1] == '-') {
        left++;
      }
      while (cx + n + right < w && chars[cy][cx + n + right] == '-') {
        right++;
      }
      final y = cy * kTile;
      movers.add(MovingPlatform(ax: cx * kTile, ay: y, bx: (cx + (right > 0 ? right : -left)) * kTile, by: y, w: pw, vertical: false));
    } else {
      var up = 0, down = 0;
      for (var col = cx; col < cx + n; col++) {
        var u = 0, d = 0;
        while (cy - u - 1 >= 0 && chars[cy - u - 1][col] == '|') {
          u++;
        }
        while (cy + d + 1 < h && chars[cy + d + 1][col] == '|') {
          d++;
        }
        up = math.max(up, u);
        down = math.max(down, d);
      }
      final x = cx * kTile;
      movers.add(MovingPlatform(ax: x, ay: cy * kTile, bx: x, by: (cy + (up > 0 ? -up : down)) * kTile, w: pw, vertical: true));
    }
  }

  /// 도달 가능성 검사용: 움직이는 발판의 이동 경로를 고정 발판으로, 수정 다리는 켜진 상태로 바꿔요.
  Room asStaticForTest() {
    _testMode = true;
    for (final m in movers) {
      final x0 = cellOf(math.min(m.ax, m.bx)), x1 = cellOf(math.max(m.ax, m.bx) + m.w - 1);
      final y0 = cellOf(math.min(m.ay, m.by)), y1 = cellOf(math.max(m.ay, m.by));
      for (var cy = y0; cy <= y1; cy++) {
        for (var cx = x0; cx <= x1; cx++) {
          if (cells[cy][cx] == Cell.empty) cells[cy][cx] = Cell.oneWay;
        }
      }
    }
    movers.clear();
    return this;
  }

  // ───────── Geometry ─────────
  @override
  int kindAt(int cx, int cy) {
    if (cx < 0 || cx >= w) return 2;
    if (cy < 0 || cy >= h) return 0;
    switch (cells[cy][cx]) {
      case Cell.solid:
      case Cell.spring:
        return 2;
      case Cell.oneWay:
        return 1;
      case Cell.crumble:
        return (crumbles[cy * w + cx]?.down ?? 0) > 0 ? 0 : 1;
      case Cell.bridge:
        return (_testMode || bridgeTimer > 0) ? 1 : 0;
      default:
        return 0;
    }
  }

  int cellAt(int cx, int cy) => (cx < 0 || cx >= w || cy < 0 || cy >= h) ? Cell.empty : cells[cy][cx];

  @override
  bool springAt(int cx, int cy) => cellAt(cx, cy) == Cell.spring;

  @override
  Iterable<Platform> get platforms => movers;

  @override
  void onStand(int cx, int cy) {
    final c = crumbles[cy * w + cx];
    if (c != null && c.shake < 0 && c.down <= 0 && !_testMode) c.shake = 0.42;
  }

  bool thornActive(int cx, int cy) {
    final ph = thornPhase[cy * w + cx];
    if (ph == null) return false;
    return ((time + ph) % thornCycle) < thornOn;
  }

  /// 0이면 평소, 1에 가까울수록 곧 튀어나옴(경고 연출용).
  double thornWarn(int cx, int cy) {
    final ph = thornPhase[cy * w + cx];
    if (ph == null) return 0;
    final t = (time + ph) % thornCycle;
    if (t < thornOn) return 1;
    final until = thornCycle - t;
    return until < 0.5 ? 1 - until / 0.5 : 0;
  }

  void triggerBridge() {
    if (bridgeTimer <= 0) events.add(const RoomEvent(RoomEventKind.bridgeOn, 0, 0));
    bridgeTimer = bridgeTime;
  }

  void update(double dt) {
    time += dt;
    for (final m in movers) {
      m.update(dt);
    }
    crumbles.forEach((key, c) {
      if (c.shake >= 0) {
        c.shake -= dt;
        if (c.shake < 0) {
          c.shake = -1;
          c.down = 3.2;
          events.add(RoomEvent(RoomEventKind.crumbleFall, key % w, key ~/ w));
        }
      } else if (c.down > 0) {
        c.down -= dt;
        if (c.down <= 0) events.add(RoomEvent(RoomEventKind.crumbleBack, key % w, key ~/ w));
      }
    });
    springAnim.updateAll((k, v) => math.max(0, v - dt));
    if (bridgeTimer > 0) {
      final before = bridgeTimer;
      bridgeTimer -= dt;
      if (before > 2 && bridgeTimer <= 2) events.add(const RoomEvent(RoomEventKind.bridgeWarn, 0, 0));
      if (bridgeTimer <= 0) events.add(const RoomEvent(RoomEventKind.bridgeOff, 0, 0));
    }
  }

  double get pixelW => w * kTile;
  double get pixelH => h * kTile;
}
