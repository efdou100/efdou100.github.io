import 'dart:ui';

import 'enemy.dart';

class Arrow {
  double x, y, vx, vy, dmg, life;
  int pierce; // 남은 관통 수 (-1 이면 무제한)
  int bounces; // 남은 적→적 연쇄 수
  int wallBounces; // 남은 벽 튕김 수
  int bounced = 0; // 지금까지 튕긴 횟수 (밝기·크기 연출)
  final bool crit;
  final Set<Enemy> hit = {};
  final List<Offset> trail = [];
  bool dead = false;
  Arrow({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.dmg,
    required this.life,
    this.pierce = 0,
    this.bounces = 0,
    this.wallBounces = 0,
    this.crit = false,
  });
}

enum PickupKind { xp, coin, heal, shard }

class Pickup {
  final PickupKind kind;
  double x, y, vx, vy, t = 0;
  final double value;
  final int index; // 꿈 조각 번호
  bool dead = false;
  bool homing = false;
  Pickup(this.kind, this.x, this.y, {this.vx = 0, this.vy = 0, this.value = 1, this.index = -1});
}
