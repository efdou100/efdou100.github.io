/// 방 템플릿 정의. 실제 맵 데이터는 room_templates.dart (생성 파일)에 있어요.
enum RoomType { combat, platform, reward, boss }

class RoomHint {
  final int x;
  final String text;
  const RoomHint(this.x, this.text);
}

class RoomTemplate {
  final String id;
  final RoomType type;
  final int tier;
  final int waves;
  final List<RoomHint> hints;
  final List<String> rows;

  const RoomTemplate({required this.id, required this.type, required this.tier, required this.waves, required this.hints, required this.rows});

  int get width => rows.first.length;
  int get height => rows.length;
  bool get needsClear => type == RoomType.combat || type == RoomType.boss;
}
