import 'dart:math' as math;

import 'constants.dart';
import 'physics.dart';

class MotorInput {
  int dir = 0;
  bool jump = false;
  bool drop = false;
  bool jumpHeld = true;
}

/// 플레이어 이동 로직. 화면·효과와 분리되어 있어서 테스트에서 그대로 시뮬레이션해요.
class PlayerMotor {
  final Body body;
  double coyote = 0, buffer = 0, dropT = 0;
  int face = 1;
  bool _cutDone = true;

  // 지난 step 에서 일어난 일 (연출용)
  bool jumped = false, landed = false, bounced = false;
  double landImpact = 0;
  int bounceCx = -1, bounceCy = -1;

  PlayerMotor(double x, double y) : body = Body(x, y, Phys.playerW, Phys.playerH);

  bool _onOneWay(Geometry g) {
    final b = body;
    if (b.riding != null) return true;
    return b.groundCx >= 0 && g.kindAt(b.groundCx, b.groundCy) == 1;
  }

  void step(Geometry g, MotorInput inp, double dt, {double speedMul = 1}) {
    jumped = landed = bounced = false;
    final b = body;
    final ride = b.riding;
    if (ride != null) {
      moveX(g, b, ride.dx);
      b.y += ride.dy;
    }
    if (inp.dir != 0) face = inp.dir;

    final target = inp.dir * Phys.run * speedMul;
    final accel = b.onGround ? (inp.dir == 0 ? Phys.groundDecel : Phys.groundAccel) : Phys.airAccel;
    b.vx = _approach(b.vx, target, accel * dt);
    if (moveX(g, b, b.vx * dt)) b.vx = 0;

    if (inp.jump) {
      buffer = Phys.jumpBuffer;
    } else {
      buffer -= dt;
    }
    coyote = b.onGround ? Phys.coyote : coyote - dt;
    if (inp.drop && b.onGround && _onOneWay(g)) {
      dropT = Phys.dropThrough;
      coyote = 0;
    }
    dropT -= dt;

    if (buffer > 0 && coyote > 0) {
      b.vy = -Phys.jumpV;
      buffer = 0;
      coyote = 0;
      jumped = true;
      _cutDone = false;
      b.onGround = false;
      b.riding = null;
    }
    if (!inp.jumpHeld && !_cutDone && b.vy < 0) {
      b.vy *= 0.5;
      _cutDone = true;
    }

    var grav = b.vy < 0 ? Phys.gravityUp : Phys.gravityDown;
    if (b.vy.abs() < Phys.apexBand) grav *= Phys.apexScale;
    b.vy = math.min(b.vy + grav * dt, Phys.maxFall);

    final wasGround = b.onGround;
    final vyBefore = b.vy;
    moveY(g, b, b.vy * dt, oneWay: dropT <= 0, platforms: dropT <= 0);
    if (b.onGround && !wasGround) {
      landed = true;
      landImpact = vyBefore;
    }
    if (b.onGround && b.groundCx >= 0 && g.springAt(b.groundCx, b.groundCy)) {
      bounceCx = b.groundCx;
      bounceCy = b.groundCy;
      b.vy = -Phys.springV;
      b.onGround = false;
      coyote = 0;
      bounced = true;
      _cutDone = true;
    }
  }

  static double _approach(double v, double target, double step) {
    if (v < target) return math.min(v + step, target);
    if (v > target) return math.max(v - step, target);
    return v;
  }
}
