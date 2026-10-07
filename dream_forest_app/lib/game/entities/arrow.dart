import 'dart:ui';

import 'enemy.dart';

class Arrow {
  double x, y, vx, vy, dmg, life;
  int pierce; // 남은 관통 수 (-1 이면 무제한)
  int bounces;
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
