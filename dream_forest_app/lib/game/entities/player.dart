import 'dart:math' as math;
import 'dart:ui';

import '../motor.dart';
import '../physics.dart';

/// 플레이어: 이동은 PlayerMotor, 여기는 전투 상태와 애니메이션 상태.
class Player {
  final PlayerMotor motor;
  double inv = 0;
  double cool = 0.25;
  double bowPull = 0; // 0..1 활시위 당김
  double recoil = 0;
  double aim = 0; // 조준 각도
  double runPhase = 0;
  double blink = 3;
  double hurtFlash = 0;
  double focusT = 0;
  double safeX, safeY, safeT = 0;
  bool moving = false;
  double sx = 1, sy = 1, svx = 0, svy = 0;
  double lean = 0;
  double dustT = 0;
  final List<Offset> scarf = List.generate(6, (_) => Offset.zero);
  bool scarfInit = false;

  Player(double x, double y) : motor = PlayerMotor(x, y), safeX = x, safeY = y;

  Body get body => motor.body;
  int get face => motor.face;

  void squash(double amount) {
    svy -= amount * 10;
    svx += amount * 10;
  }

  void stretch(double amount) {
    svy += amount * 10;
    svx -= amount * 10;
  }

  void animate(double dt) {
    svx += (1 - sx) * 260 * dt - svx * 15 * dt;
    svy += (1 - sy) * 260 * dt - svy * 15 * dt;
    sx += svx * dt;
    sy += svy * dt;
    final b = body;
    final targetLean = (b.vx / 255).clamp(-1.0, 1.0) * 0.12;
    lean += (targetLean - lean) * math.min(1, dt * 12);
    if (b.onGround && b.vx.abs() > 20) runPhase += dt * (b.vx.abs() / 255) * 15;
    blink -= dt;
    if (blink < -0.12) blink = 2.5 + (runPhase % 1.7);
    bowPull = math.max(0, bowPull - dt * 3.2);
    recoil = math.max(0, recoil - dt * 6);
    hurtFlash = math.max(0, hurtFlash - dt);
    // 스카프: 목에 매달린 줄. 앞 점을 따라가며 바람에 날려요.
    final anchor = Offset(b.cx - face * 4, b.y + 15);
    if (!scarfInit) {
      for (var i = 0; i < scarf.length; i++) {
        scarf[i] = anchor;
      }
      scarfInit = true;
    }
    scarf[0] = anchor;
    for (var i = 1; i < scarf.length; i++) {
      final prev = scarf[i - 1];
      final wind = Offset(-face * 26 - b.vx * 0.05, 9 + math.sin(runPhase * 0.7 + i) * 3 - b.vy * 0.02);
      var p = scarf[i] + wind * dt * 6;
      final d = p - prev;
      final len = d.distance;
      const seg = 6.0;
      if (len > 0) p = prev + d / len * seg;
      scarf[i] = p;
    }
  }
}
