import 'package:dream_forest/game/constants.dart';
import 'package:dream_forest/game/motor.dart';
import 'package:dream_forest/game/physics.dart';
import 'package:dream_forest/game/rooms/room.dart';
import 'package:dream_forest/game/rooms/room_template.dart';
import 'package:dream_forest/game/rooms/room_templates.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 이동 코드(PlayerMotor)로 여러 입력 조합을 시뮬레이션해서
/// 시작 지점에서 포털과 모든 꿈 조각에 닿을 수 있는지 확인해요.
class ExploreResult {
  bool portal = false;
  final Set<int> shards = {};
}

typedef _Plan = ({int runFrames, int dir, bool jump, int holdFrames, bool drop});

const double dt = 1 / 60;

List<_Plan> _plans() {
  final plans = <_Plan>[];
  for (final dir in [-1, 0, 1]) {
    for (final hold in [0, 4, 8, 14, 20, 30, 999]) {
      plans.add((runFrames: 0, dir: dir, jump: true, holdFrames: hold, drop: false));
    }
  }
  for (final dir in [-1, 1]) {
    for (final run in [4, 8, 16]) {
      plans.add((runFrames: run, dir: dir, jump: true, holdFrames: 999, drop: false));
    }
    for (final run in [3, 6]) {
      plans.add((runFrames: run, dir: dir, jump: false, holdFrames: 0, drop: false));
    }
  }
  plans.add((runFrames: 0, dir: 0, jump: false, holdFrames: 0, drop: true));
  return plans;
}

bool _hazard(Room room, Body b) {
  final l = cellOf(b.x + 2), r = cellOf(b.x + b.w - 2), t = cellOf(b.y + 2), bo = cellOf(b.y + b.h - 2);
  for (var cy = t; cy <= bo; cy++) {
    for (var cx = l; cx <= r; cx++) {
      final c = room.cellAt(cx, cy);
      if (c == Cell.spike) return true;
    }
  }
  return false;
}

void _touch(Room room, Body b, ExploreResult res) {
  if (b.x < room.portalX + Room.portalW && b.x + b.w > room.portalX && b.y < room.portalY + Room.portalH && b.y + b.h > room.portalY) {
    res.portal = true;
  }
  for (var i = 0; i < room.shards.length; i++) {
    final s = room.shards[i];
    if ((b.cx - s.x).abs() < 26 && (b.cy - s.y).abs() < 30) res.shards.add(i);
  }
}

ExploreResult explore(Room room) {
  final res = ExploreResult();
  final seen = <int>{};
  final queue = <(double, double)>[];
  int key(double x, double y) => ((y / 4).round() << 16) ^ (x / 6).round();

  // 시작 지점에서 먼저 떨어뜨려 바닥에 세워요.
  final m0 = PlayerMotor(room.startX, room.startY);
  final idle = MotorInput();
  for (var i = 0; i < 60; i++) {
    m0.step(room, idle, dt);
  }
  queue.add((m0.body.x, m0.body.y));
  seen.add(key(m0.body.x, m0.body.y));
  final plans = _plans();
  var guard = 0;
  while (queue.isNotEmpty && guard < 4000) {
    guard++;
    final (sx, sy) = queue.removeAt(0);
    for (final p in plans) {
      final m = PlayerMotor(sx, sy);
      m.body.onGround = true;
      final inp = MotorInput();
      var ok = true;
      var frame = 0;
      var landedAgain = false;
      for (; frame < 360; frame++) {
        inp.jump = false;
        inp.drop = false;
        if (frame < p.runFrames) {
          inp.dir = p.dir;
        } else {
          final f = frame - p.runFrames;
          if (f == 0 && p.jump) inp.jump = true;
          if (f == 0 && p.drop) inp.drop = true;
          inp.dir = (p.jump && f < p.holdFrames) ? p.dir : 0;
          if (!p.jump && p.runFrames > 0 && f > 0) inp.dir = 0;
        }
        m.step(room, inp, dt);
        _touch(room, m.body, res);
        if (_hazard(room, m.body) || m.body.y > room.pixelH + 40) {
          ok = false;
          break;
        }
        if (frame > p.runFrames + 2 && m.body.onGround && m.body.vx.abs() < 1) {
          landedAgain = true;
          break;
        }
      }
      if (!ok || !landedAgain) continue;
      final k = key(m.body.x, m.body.y);
      if (seen.add(k)) queue.add((m.body.x, m.body.y));
    }
  }
  return res;
}

void main() {
  for (final tpl in kRoomTemplates) {
    for (final mirrored in [false, true]) {
      test('${tpl.id}${mirrored ? ' (거울)' : ''}: 포털과 꿈 조각에 닿을 수 있다', () {
        final room = Room(tpl, mirrored: mirrored).asStaticForTest();
        expect(room.startX, isNot(0));
        final res = explore(room);
        expect(res.portal, isTrue, reason: '${tpl.id} 포털에 닿지 못함');
        expect(res.shards.length, room.shards.length, reason: '${tpl.id} 꿈 조각 ${room.shards.length}개 중 ${res.shards.length}개만 닿음');
      });
    }
  }

  test('검사기가 막힌 방을 실제로 잡아낸다', () {
    const blocked = RoomTemplate(
      id: 'blocked',
      type: RoomType.platform,
      tier: 1,
      waves: 0,
      hints: [],
      rows: [
        '##########',
        '#........#',
        '#........#',
        '#........#',
        '#....#...#',
        '#....#...#',
        '#....#...#',
        '#....#...#',
        '#....#...#',
        '#.@..#.P.#',
        '##########',
      ],
    );
    expect(explore(Room(blocked).asStaticForTest()).portal, isFalse);
  });

  test('점프 높이는 3칸은 넘고 4칸은 못 넘는다', () {
    final g = Room(kRoomTemplates.first);
    final m = PlayerMotor(g.startX, g.startY);
    final inp = MotorInput();
    for (var i = 0; i < 30; i++) {
      m.step(g, inp, dt);
    }
    final floor = m.body.bottom;
    inp.jump = true;
    var best = floor;
    for (var i = 0; i < 60; i++) {
      m.step(g, inp, dt);
      inp.jump = false;
      if (m.body.bottom < best) best = m.body.bottom;
    }
    final rise = floor - best;
    expect(rise, greaterThan(3 * kTile));
    expect(rise, lessThan(4 * kTile));
  });
}
