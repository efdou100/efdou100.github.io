// 레벨 데이터 (assets/levels/levels.json)
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

double _d(dynamic v) => (v as num).toDouble();

class EdgeSpan {
  const EdgeSpan(this.a, this.b, this.k);
  final double a, b;
  final String k;
}

class WallDef {
  const WallDef(this.x1, this.y1, this.x2, this.y2, this.k);
  final double x1, y1, x2, y2;
  final String k;
}

class BlockDef {
  const BlockDef(this.x, this.y, this.w, this.h, this.k);
  final double x, y, w, h;
  final String k; // w 나무, m 이끼, i 얼음
}

class MirrorDef {
  const MirrorDef(this.x, this.y, this.s, this.rot, this.len, {this.relay = false, this.spin = 0});
  final double x, y;
  final int s;
  final bool rot;
  final double len;
  final bool relay; // 되쏘기 고리: 화살을 붙잡았다가 s*45° 방향으로 다시 쏨 (탭하면 8방향)
  final double spin; // 도는 거울: spin 초마다 반 바퀴 (0 = 고정)
  int get states => relay ? 8 : 4;
}

/// 유리 마개: soft 면(l/r/t/b)으로 맞을 때만 깨진다 (화살은 멈춤). 나머지 면은 나무처럼 튕긴다.
class CrystalDef {
  const CrystalDef(this.x, this.y, this.w, this.h, this.soft);
  final double x, y, w, h;
  final String soft;
}

class BumperDef {
  const BumperDef(this.x, this.y, this.r);
  final double x, y, r;
}

class PortalDef {
  const PortalDef(this.ax, this.ay, this.bx, this.by);
  final double ax, ay, bx, by;
}

class PointDef {
  const PointDef(this.x, this.y);
  final double x, y;
}

class SwitchDef {
  const SwitchDef(this.x, this.y, this.gates);
  final double x, y;
  final List<int> gates;
}

class GateDef {
  const GateDef(this.x1, this.y1, this.x2, this.y2, this.dur);
  final double x1, y1, x2, y2, dur;
}

class TargetDef {
  const TargetDef({required this.x, required this.y, this.mx = 0, this.my = 0, this.per = 0, this.shield, this.avoid = false});
  final double x, y, mx, my, per;
  final double? shield; // 방패가 향한 방향(°)
  final bool avoid; // 아기 정령: 맞히면 실패
  (double, double) pos(double time) {
    if (per == 0) return (x, y);
    final k = math.sin((2 * math.pi * time) / per);
    return (x + mx * k, y + my * k);
  }
}

class SolutionShot {
  const SolutionShot(this.angDeg, this.step, this.kind);
  final double angDeg;
  final int step;
  final String kind;
}

class Solution {
  const Solution(this.mirrors, this.shots);
  final List<int> mirrors;
  final List<SolutionShot> shots;
}

enum Tier { normal, hard, superhard, boss }

class LevelData {
  LevelData({
    required this.id,
    required this.world,
    required this.name,
    required this.shots,
    required this.par,
    required this.guide,
    required this.bowX,
    required this.bowY,
    this.edges = const {},
    this.walls = const [],
    this.blocks = const [],
    this.mirrors = const [],
    this.bumpers = const [],
    this.portals = const [],
    this.prisms = const [],
    this.switches = const [],
    this.gates = const [],
    this.crystals = const [],
    this.lanterns = const [],
    required this.targets,
    this.skills = const {},
    this.hint,
    this.intro,
    this.tier = Tier.normal,
    this.solution,
    this.width = 0,
    this.ways = 0,
  });

  final int id, world, shots, par, guide;
  final String name;
  final double bowX, bowY;
  final Map<String, List<EdgeSpan>> edges;
  final List<WallDef> walls;
  final List<BlockDef> blocks;
  final List<MirrorDef> mirrors;
  final List<BumperDef> bumpers;
  final List<PortalDef> portals;
  final List<PointDef> prisms;
  final List<SwitchDef> switches;
  final List<GateDef> gates;
  final List<CrystalDef> crystals;
  final List<PointDef> lanterns;
  final List<TargetDef> targets;
  final Map<String, int> skills;
  final String? hint;
  final String? intro; // 이 판에서 처음 소개하는 요소 (새 장치 팝업)
  final Tier tier;
  final Solution? solution;
  final double width; // 솔버가 잰 성공 각도 폭(°)
  final int ways; // 풀이 갈래 수

  List<int> get defaultMirrors => [for (final m in mirrors) m.s];
  bool get isEcho => par > 1 || gates.isNotEmpty;
  int get coinReward => switch (tier) { Tier.hard => 2, Tier.superhard => 3, Tier.boss => 3, _ => 1 } * 10;

  factory LevelData.fromJson(Map<String, dynamic> j) {
    final bow = j['bow'] as List;
    final edges = <String, List<EdgeSpan>>{};
    (j['edges'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      edges[k] = [for (final s in v as List) EdgeSpan(_d(s[0]), _d(s[1]), s[2] as String)];
    });
    final sol = j['solution'] as Map<String, dynamic>?;
    return LevelData(
      id: j['id'] as int,
      world: j['w'] as int,
      name: j['name'] as String,
      shots: j['shots'] as int,
      par: j['par'] as int,
      guide: (j['guide'] as int?) ?? 1,
      bowX: _d(bow[0]),
      bowY: _d(bow[1]),
      edges: edges,
      walls: [for (final w in j['walls'] as List? ?? []) WallDef(_d(w[0]), _d(w[1]), _d(w[2]), _d(w[3]), (w.length > 4 ? w[4] : 'w') as String)],
      blocks: [for (final b in j['blocks'] as List? ?? []) BlockDef(_d(b[0]), _d(b[1]), _d(b[2]), _d(b[3]), (b.length > 4 ? b[4] : 'w') as String)],
      mirrors: [
        for (final m in j['mirrors'] as List? ?? [])
          MirrorDef(_d(m['x']), _d(m['y']), m['s'] as int, m['rot'] as bool? ?? true, _d(m['len'] ?? 58), relay: m['relay'] as bool? ?? false, spin: _d(m['spin'] ?? 0)),
      ],
      bumpers: [for (final u in j['bumpers'] as List? ?? []) BumperDef(_d(u['x']), _d(u['y']), _d(u['r'] ?? 22))],
      portals: [for (final p in j['portals'] as List? ?? []) PortalDef(_d(p['a'][0]), _d(p['a'][1]), _d(p['b'][0]), _d(p['b'][1]))],
      prisms: [for (final x in j['prisms'] as List? ?? []) PointDef(_d(x['x']), _d(x['y']))],
      switches: [for (final s in j['switches'] as List? ?? []) SwitchDef(_d(s['x']), _d(s['y']), [for (final g in s['g'] as List) g as int])],
      gates: [for (final g in j['gates'] as List? ?? []) GateDef(_d(g['x1']), _d(g['y1']), _d(g['x2']), _d(g['y2']), _d(g['dur']))],
      crystals: [for (final k in j['crystals'] as List? ?? []) CrystalDef(_d(k['x']), _d(k['y']), _d(k['w']), _d(k['h']), k['soft'] as String)],
      lanterns: [for (final n in j['lanterns'] as List? ?? []) PointDef(_d(n['x']), _d(n['y']))],
      targets: [
        for (final t in j['targets'] as List)
          TargetDef(
            x: _d(t['x']),
            y: _d(t['y']),
            mx: _d(t['mx'] ?? 0),
            my: _d(t['my'] ?? 0),
            per: _d(t['per'] ?? 0),
            shield: t['shield'] == null ? null : _d(t['shield']),
            avoid: t['avoid'] as bool? ?? false,
          ),
      ],
      skills: {for (final e in (j['skills'] as Map<String, dynamic>? ?? {}).entries) e.key: e.value as int},
      hint: j['hint'] as String?,
      intro: j['intro'] as String?,
      tier: Tier.values.firstWhere((t) => t.name == (j['tier'] ?? 'normal'), orElse: () => Tier.normal),
      solution: sol == null
          ? null
          : Solution(
              [for (final m in sol['mirrors'] as List) m as int],
              [for (final s in sol['shots'] as List) SolutionShot(_d(s['ang']), s['step'] as int, s['kind'] as String? ?? 'n')],
            ),
      width: _d(j['width'] ?? 0),
      ways: (j['ways'] as int?) ?? 0,
    );
  }
}

class LevelRepo {
  LevelRepo._();
  static final LevelRepo instance = LevelRepo._();
  List<LevelData> levels = [];

  static const worldNames = ['', '달빛 숲', '은빛 거울', '수정 동굴', '메아리 계곡', '별의 끝'];
  static const levelsPerWorld = 20;

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/levels/levels.json');
    levels = parse(raw);
  }

  static List<LevelData> parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return [for (final l in j['levels'] as List) LevelData.fromJson(l as Map<String, dynamic>)];
  }

  int get count => levels.length;
  LevelData operator [](int i) => levels[i];
}
