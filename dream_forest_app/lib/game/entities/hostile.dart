import 'dart:ui';

enum HostileKind { spore, orb, wave, rain }

/// 적이 쏘는 공격. rain 은 경고 표시(warn) 뒤에 위에서 떨어져요.
class Hostile {
  HostileKind kind;
  double x, y, vx, vy, r, life, gravity, dmg;
  double homing;
  double warn;
  double t = 0;
  bool dead = false;
  final Color color;
  Hostile({
    required this.kind,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.r = 8,
    this.life = 4,
    this.gravity = 0,
    required this.dmg,
    this.homing = 0,
    this.warn = 0,
    required this.color,
  });
}
