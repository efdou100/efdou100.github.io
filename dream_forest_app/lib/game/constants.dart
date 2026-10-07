/// 게임 전체에서 쓰는 수치. 손맛 조정은 대부분 여기서 해요.
const double kTile = 40;
const double kViewH = 540;

class Phys {
  static const double run = 255;
  static const double groundAccel = 2700;
  static const double airAccel = 1900;
  static const double groundDecel = 3200;
  static const double jumpV = 840;
  static const double gravityUp = 2250;
  static const double gravityDown = 2900;
  static const double apexBand = 110;
  static const double apexScale = 0.6;
  static const double maxFall = 1050;
  static const double coyote = 0.1;
  static const double jumpBuffer = 0.15;
  static const double springV = 1150;
  static const double dropThrough = 0.25;
  static const double playerW = 26;
  static const double playerH = 38;
}

class Combat {
  static const double arrowSpeed = 980;
  static const double arrowLife = 1.25;
  static const double baseFireInterval = 0.46;
  static const double baseDamage = 10;
  static const double baseHp = 100;
  static const double baseCrit = 0.05;
  static const double critMult = 2.2;
  static const double autoAimRange = 620;
  static const double invuln = 1.0;
  static const double pitDamageRatio = 0.12;
}
