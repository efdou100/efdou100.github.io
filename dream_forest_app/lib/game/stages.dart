import 'dart:math' as math;

import 'rooms/room_template.dart';
import 'rooms/room_templates.dart';

class StageRoom {
  final RoomTemplate tpl;
  final bool mirrored;
  const StageRoom(this.tpl, this.mirrored);
}

class StageDef {
  final int number; // 0 이면 끝없는 숲
  final String name;
  final String subtitle;
  final List<StageRoom> rooms;
  final double power;
  const StageDef({required this.number, required this.name, required this.subtitle, required this.rooms, required this.power});

  bool get isBoss => rooms.any((r) => r.tpl.type == RoomType.boss);
  bool get isEndless => number == 0;
  int get shardCount => rooms.fold(0, (a, r) => a + r.tpl.rows.join().split('*').length - 1);
}

RoomTemplate _t(String id) => kRoomTemplates.firstWhere((t) => t.id == id);

StageDef _stage(int n, String name, String sub, List<String> ids) => StageDef(
      number: n,
      name: name,
      subtitle: sub,
      power: 1 + 0.16 * (n - 1),
      rooms: [
        for (final id in ids) StageRoom(_t(id.replaceAll('~', '')), id.endsWith('~')),
      ],
    );

/// 1장: 잠든 숲. '~' 가 붙은 방은 좌우를 뒤집어서 써요.
final List<StageDef> kStages = [
  _stage(1, '이끼 오솔길', '첫걸음. 달리고, 뛰고, 멈춰서 쏴요', ['t_intro', 'p1_steps', 'c1_glade']),
  _stage(2, '반딧불 언덕', '버섯을 밟으면 높이 튀어 올라요', ['c1_twin', 'p1_bounce', 'c1_hollow']),
  _stage(3, '개울 건너', '움직이는 발판을 타고 건너요', ['c1_hollow~', 'p1_steps~', 'p2_river', 'c1_twin~']),
  _stage(4, '버섯 골짜기', '무너지는 발판 위에서는 멈추지 마세요', ['c2_pits', 'p2_springs', 'c2_lift', 'p2_crumble']),
  _stage(5, '킹 슬라임의 둥지', '숲을 지키는 커다란 슬라임', ['c1_glade~', 'p2_river~', 'reward', 'boss_king']),
  _stage(6, '흔들다리 숲', '발판과 적이 함께 몰려와요', ['c2_lift~', 'p2_crumble~', 'c2_pits~', 'p2_springs~']),
  _stage(7, '가시덤불 길', '가시덩굴이 들어가는 순간을 노려요', ['c3_thorns', 'p3_thorns', 'c2_pits', 'p3_bridge']),
  _stage(8, '고목의 뿌리', '위로, 더 위로', ['c3_storm', 'p3_climb', 'p2_river', 'c3_thorns~']),
  _stage(9, '잠든 나무 꼭대기', '지금까지 배운 모든 것', ['p3_bridge~', 'c3_storm~', 'p3_climb~', 'c3_thorns', 'p2_crumble']),
  _stage(10, '꿈의 군주', '잠든 숲의 끝', ['c3_storm', 'p3_thorns~', 'reward', 'boss_lord']),
];

/// 10스테이지를 깨면 열리는 끝없는 숲. 깊이마다 방 조합이 새로 섞여요.
StageDef endlessStage(int depth, int seed) {
  final rng = math.Random(seed);
  final combat = kRoomTemplates.where((t) => t.type == RoomType.combat && t.id != 't_intro').toList();
  final platform = kRoomTemplates.where((t) => t.type == RoomType.platform).toList();
  final rooms = <StageRoom>[];
  for (var i = 0; i < 5; i++) {
    final pool = i.isEven ? combat : platform;
    rooms.add(StageRoom(pool[rng.nextInt(pool.length)], rng.nextBool()));
  }
  if (depth % 3 == 0) {
    rooms
      ..removeLast()
      ..add(StageRoom(_t('reward'), false))
      ..add(StageRoom(_t(depth % 2 == 0 ? 'boss_lord' : 'boss_king'), rng.nextBool()));
  }
  return StageDef(number: 0, name: '끝없는 숲 · 깊이 $depth', subtitle: '어디까지 갈 수 있을까요', rooms: rooms, power: 2.6 + 0.3 * depth);
}
