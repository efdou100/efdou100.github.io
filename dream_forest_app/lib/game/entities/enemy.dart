import 'dart:math' as math;
import 'dart:ui';

import '../../app/theme.dart';
import '../constants.dart';
import '../fx.dart';
import '../physics.dart';
import '../rooms/room.dart';
import 'hostile.dart';

enum EnemyKind { slime, splitter, splitling, mushroom, bat, wisp, king, lord }

class EnemySpec {
  final double hp, w, h, contact, xp, coinChance;
  final Color color;
  final bool flying;
  const EnemySpec(this.hp, this.w, this.h, this.contact, this.xp, this.coinChance, this.color, {this.flying = false});
}

const Map<EnemyKind, EnemySpec> kEnemySpecs = {
  EnemyKind.slime: EnemySpec(34, 34, 26, 14, 3, 0.25, Color(0xFF7AD37A)),
  EnemyKind.splitter: EnemySpec(72, 46, 36, 18, 5, 0.45, Color(0xFF6FB7E8)),
  EnemyKind.splitling: EnemySpec(20, 24, 19, 10, 1, 0.1, Color(0xFF8FCBF0)),
  EnemyKind.mushroom: EnemySpec(44, 30, 34, 12, 4, 0.3, Color(0xFFE8644A)),
  EnemyKind.bat: EnemySpec(26, 30, 20, 12, 3, 0.25, Color(0xFF8A68C0), flying: true),
  EnemyKind.wisp: EnemySpec(40, 28, 28, 14, 4, 0.35, Color(0xFF9FE8FF), flying: true),
  EnemyKind.king: EnemySpec(750, 120, 92, 22, 40, 1, Color(0xFFE46AA0)),
  EnemyKind.lord: EnemySpec(1150, 84, 116, 24, 60, 1, Color(0xFFB993FF), flying: true),
};

/// 교체 이미지 id (`assets/images/monster/{id}.png`). docs/asset_manifest.json 의 몬스터 목록과 같아요.
String enemyArtId(EnemyKind k) => switch (k) {
  EnemyKind.slime => 'slime',
  EnemyKind.splitter => 'slime_split',
  EnemyKind.splitling => 'slime_mini',
  EnemyKind.mushroom => 'mush_spore',
  EnemyKind.bat => 'bat',
  EnemyKind.wisp => 'wisp',
  EnemyKind.king => 'boss_king_slime',
  EnemyKind.lord => 'boss_dream_lord',
};

EnemyKind? enemyKindFromChar(String c) => switch (c) {
  's' => EnemyKind.slime,
  'x' => EnemyKind.splitter,
  'm' => EnemyKind.mushroom,
  'b' => EnemyKind.bat,
  'w' => EnemyKind.wisp,
  'K' => EnemyKind.king,
  'L' => EnemyKind.lord,
  _ => null,
};

/// 적이 게임에 요청하는 일들.
abstract class EnemyHost {
  Room get room;
  Body get playerBody;
  Fx get fx;
  void fireHostile(Hostile h);
  void spawnEnemy(EnemyKind kind, double x, double bottomY, {bool fromBoss});
  void sound(String name);
  void shakeCam(double trauma);
  int countEnemies(EnemyKind kind);
  void wallSplat(Enemy e, double speed);
}

class Enemy {
  final EnemyKind kind;
  final EnemySpec spec;
  final Body body;
  double hp, maxHp;
  final double power;
  String state = 'idle';
  double tele = 0, cd, t, wait = 1.6;
  double flash = 0, slow = 0, burn = 0, burnTick = 0, frozen = 0, stun = 0, spawnIn = 0.35;
  int chill = 0, dir, jumps = 0;
  double kx = 0;
  double lx = 0, ly = 0, dashT = 0, leapT = 0, landX = 0, floorY = 0, baseY = 0;
  String pattern = '';
  int patternIdx = 0;
  // 찌그러짐 스프링 (맞거나 착지할 때 말랑하게)
  double sx = 1, sy = 1, svx = 0, svy = 0;
  bool dead = false;
  bool fromBoss = false;
  double hitCd = 0; // 수호 구슬 다단히트 간격

  Enemy(this.kind, double x, double bottomY, this.power, math.Random rng)
    : spec = kEnemySpecs[kind]!,
      body = Body(x - kEnemySpecs[kind]!.w / 2, bottomY - kEnemySpecs[kind]!.h, kEnemySpecs[kind]!.w, kEnemySpecs[kind]!.h),
      hp = kEnemySpecs[kind]!.hp * power,
      maxHp = kEnemySpecs[kind]!.hp * power,
      cd = 1 + rng.nextDouble() * 1.5,
      t = rng.nextDouble() * 6,
      dir = rng.nextBool() ? 1 : -1 {
    baseY = body.y;
    if (kind == EnemyKind.slime || kind == EnemyKind.splitter || kind == EnemyKind.splitling) state = 'walk';
    if (kind == EnemyKind.bat || kind == EnemyKind.wisp) state = 'hover';
    if (isBoss) {
      wait = 2.0;
      spawnIn = 0.8;
    }
  }

  bool get isBoss => kind == EnemyKind.king || kind == EnemyKind.lord;
  bool get telegraphing => state == 'charge' || state == 'aim' || state == 'crouch' || state == 'cast';
  double get contactDamage => spec.contact * (0.85 + 0.15 * power);
  double get cx => body.cx;
  double get cy => body.cy;
  bool get phase2 => hp < maxHp / 2;

  void squash(double amount) {
    svy -= amount * 9;
    svx += amount * 9;
  }

  void update(EnemyHost h, double dt, math.Random rng) {
    // 말랑한 스프링
    svx += (1 - sx) * 220 * dt - svx * 14 * dt;
    svy += (1 - sy) * 220 * dt - svy * 14 * dt;
    sx += svx * dt;
    sy += svy * dt;
    if (spawnIn > 0) {
      spawnIn -= dt;
      return;
    }
    t += dt;
    cd -= dt;
    hitCd -= dt;
    if (kx != 0) {
      final hitWall = spec.flying ? _flyKnock(h, kx * dt) : moveX(h.room, body, kx * dt);
      if (hitWall && kx.abs() > 150) {
        h.wallSplat(this, kx.abs());
        kx = -kx * 0.25;
      }
      kx *= math.exp(-9 * dt);
      if (kx.abs() < 6) kx = 0;
    }
    if (stun > 0) {
      stun -= dt;
      if (!spec.flying) _gravity(h, dt);
      return;
    }
    switch (kind) {
      case EnemyKind.slime || EnemyKind.splitter || EnemyKind.splitling:
        _slime(h, dt);
      case EnemyKind.mushroom:
        _mushroom(h, dt, rng);
      case EnemyKind.bat:
        _bat(h, dt);
      case EnemyKind.wisp:
        _wisp(h, dt);
      case EnemyKind.king:
        _king(h, dt, rng);
      case EnemyKind.lord:
        _lord(h, dt, rng);
    }
  }

  bool _flyKnock(EnemyHost h, double dx) {
    body.x += dx;
    final cx = cellOf(dx > 0 ? body.right : body.x);
    if (h.room.kindAt(cx, cellOf(body.cy)) == 2) {
      body.x -= dx;
      return true;
    }
    return false;
  }

  void _gravity(EnemyHost h, double dt) {
    final was = body.onGround;
    final vyBefore = body.vy;
    body.vy = math.min(body.vy + Phys.gravityDown * dt, Phys.maxFall);
    moveY(h.room, body, body.vy * dt, platforms: false);
    if (body.onGround && !was && vyBefore > 250) squash(math.min(0.5, vyBefore / 1400));
  }

  double _dxToPlayer(EnemyHost h) => h.playerBody.cx - body.cx;
  double _dyToPlayer(EnemyHost h) => h.playerBody.cy - body.cy;

  // ───────── 슬라임: 다가오다가 웅크리고(!) 덮쳐요 ─────────
  void _slime(EnemyHost h, double dt) {
    final dx = _dxToPlayer(h), dy = _dyToPlayer(h);
    final big = kind == EnemyKind.splitter;
    final speed = big
        ? 50.0
        : kind == EnemyKind.splitling
        ? 95.0
        : 70.0;
    if (state == 'charge') {
      tele -= dt;
      if (tele <= 0 && body.onGround) {
        state = 'leap';
        leapT = 0;
        body.vy = big ? -620 : -560;
        body.vx = (dx.sign == 0 ? dir : dx.sign) * (big ? 240 : 290);
        dir = body.vx.sign.toInt();
        sx = 0.8;
        sy = 1.3;
        h.sound('jump');
      }
      _gravity(h, dt);
      return;
    }
    if (state == 'leap') {
      leapT += dt;
      if (moveX(h.room, body, body.vx * dt)) body.vx = -body.vx * 0.3;
      _gravity(h, dt);
      if (body.onGround && leapT > 0.12) {
        state = 'walk';
        cd = 1.4 + (t % 1.0);
        if (big) {
          h.shakeCam(0.18);
          h.fx.dust(body.cx, body.bottom, n: 10);
        }
      }
      return;
    }
    if (body.onGround && cd <= 0 && dx.abs() < 260 && dy.abs() < 100) {
      state = 'charge';
      tele = big ? 0.7 : 0.55;
      dir = dx.sign == 0 ? dir : dx.sign.toInt();
      h.sound('tele');
      _gravity(h, dt);
      return;
    }
    if (body.onGround && dx.abs() < 340 && dy.abs() < 80 && dx.sign != 0) dir = dx.sign.toInt();
    if (body.onGround) {
      final ahead = dir > 0 ? body.right + 2 : body.x - 2;
      final atx = cellOf(ahead);
      final wall = h.room.kindAt(atx, cellOf(body.cy)) == 2;
      final noFloor = h.room.kindAt(atx, cellOf(body.bottom + 2)) == 0;
      if (wall || noFloor) dir = -dir;
    }
    if (moveX(h.room, body, dir * speed * dt)) dir = -dir;
    _gravity(h, dt);
  }

  // ───────── 포자버섯: 부풀었다가(!) 포자 3발 ─────────
  void _mushroom(EnemyHost h, double dt, math.Random rng) {
    _gravity(h, dt);
    final px = h.playerBody.cx, py = h.playerBody.cy;
    final ox = body.cx, oy = body.y + 10;
    final dist = math.sqrt((px - ox) * (px - ox) + (py - oy) * (py - oy));
    if (state == 'charge') {
      tele -= dt;
      if (tele <= 0) {
        final a = math.atan2(py - oy, px - ox);
        for (final k in [-0.2, 0.0, 0.2]) {
          h.fireHostile(
            Hostile(kind: HostileKind.spore, x: ox, y: oy, vx: math.cos(a + k) * 250, vy: math.sin(a + k) * 250, r: 7, dmg: 12 * power, color: Palette.rose),
          );
        }
        state = 'idle';
        cd = 2.1 + rng.nextDouble() * 0.8;
        sx = 1.35;
        sy = 0.7;
        h.sound('shoot');
        h.fx.burst(ox, oy, const Color(0xFFFFB3C9), n: 8, speed: 140, gravity: 0, size: 3);
      }
    } else if (cd <= 0 && dist < 560 && lineClear(h.room, ox, oy, px, py)) {
      state = 'charge';
      tele = 0.75;
      h.sound('tele');
    }
  }

  // ───────── 박쥐: 맴돌다가 조준선(!) 뒤 돌진 ─────────
  void _bat(EnemyHost h, double dt) {
    final dx = _dxToPlayer(h), dy = _dyToPlayer(h);
    final d = math.max(1.0, math.sqrt(dx * dx + dy * dy));
    if (state == 'aim') {
      tele -= dt;
      if (tele <= 0) {
        final ax = lx - body.cx, ay = ly - body.cy, ad = math.max(1.0, math.sqrt(ax * ax + ay * ay));
        body.vx = ax / ad * 560;
        body.vy = ay / ad * 560;
        state = 'dash';
        dashT = 0.55;
        h.sound('jump');
      }
      return;
    }
    if (state == 'dash') {
      body.x += body.vx * dt;
      body.y += body.vy * dt;
      dashT -= dt;
      if (dashT <= 0 || h.room.kindAt(cellOf(body.cx), cellOf(body.cy)) == 2) {
        state = 'hover';
        cd = 1.5;
      }
      return;
    }
    if (d < 500) {
      final want = d > 210
          ? 1.0
          : d < 150
          ? -0.6
          : 0.0;
      body.x += dx / d * 100 * want * dt;
      body.y += (dy - 100).sign * 60 * dt + math.sin(t * 5) * 40 * dt;
      if (cd <= 0 && d < 350) {
        state = 'aim';
        tele = 0.65;
        lx = h.playerBody.cx;
        ly = h.playerBody.cy;
        h.sound('tele');
      }
    } else {
      body.y += math.sin(t * 3) * 24 * dt;
    }
  }

  // ───────── 도깨비불: 거리를 두고 떠다니며 느린 유도탄 ─────────
  void _wisp(EnemyHost h, double dt) {
    final dx = _dxToPlayer(h), dy = _dyToPlayer(h);
    final d = math.max(1.0, math.sqrt(dx * dx + dy * dy));
    final want = d > 300
        ? 1.0
        : d < 220
        ? -1.0
        : 0.0;
    body.x += dx / d * 70 * want * dt;
    body.y += (dy - 120).sign * 40 * dt + math.cos(t * 2.4) * 30 * dt;
    if (state == 'cast') {
      tele -= dt;
      if (tele <= 0) {
        final a = math.atan2(dy, dx);
        h.fireHostile(
          Hostile(
            kind: HostileKind.orb,
            x: body.cx,
            y: body.cy,
            vx: math.cos(a) * 190,
            vy: math.sin(a) * 190,
            r: 9,
            dmg: 14 * power,
            homing: 1.8,
            life: 4.5,
            color: Palette.sky,
          ),
        );
        state = 'hover';
        cd = 2.6;
        h.sound('zap');
      }
    } else if (cd <= 0 && d < 520) {
      state = 'cast';
      tele = 0.7;
      h.sound('tele');
    }
  }

  // ───────── 킹 슬라임: 착지 지점 표시 → 쿵! 땅을 타고 오는 충격파는 점프로 넘어요 ─────────
  void _king(EnemyHost h, double dt, math.Random rng) {
    if (state == 'air') {
      if (moveX(h.room, body, body.vx * dt)) body.vx = 0;
      body.vy = math.min(body.vy + Phys.gravityDown * 0.85 * dt, Phys.maxFall);
      moveY(h.room, body, body.vy * dt, platforms: false);
      if (body.onGround) {
        state = 'idle';
        wait = phase2 ? 0.9 : 1.4;
        jumps++;
        squash(0.6);
        h.shakeCam(0.45);
        h.sound('thud');
        h.fx.dust(body.cx - 40, body.bottom, n: 10, dir: -1, power: 1.4);
        h.fx.dust(body.cx + 40, body.bottom, n: 10, dir: 1, power: 1.4);
        h.fx.ring(body.cx, body.bottom - 6, Palette.rose, from: 20, to: 140, life: 0.4, width: 6);
        for (final s in [-1, 1]) {
          h.fireHostile(
            Hostile(
              kind: HostileKind.wave,
              x: body.cx + s * 50,
              y: body.bottom - 14,
              vx: s * (phase2 ? 380 : 320),
              r: 14,
              dmg: 16 * power,
              life: 3,
              color: Palette.rose,
            ),
          );
        }
        final n = phase2 ? 7 : 5;
        for (var i = 0; i < n; i++) {
          final a = -math.pi + math.pi * (i + 0.5) / n;
          h.fireHostile(
            Hostile(
              kind: HostileKind.spore,
              x: body.cx,
              y: body.y + 20,
              vx: math.cos(a) * 240,
              vy: math.sin(a) * 330,
              r: 8,
              gravity: 520,
              dmg: 14 * power,
              color: Palette.rose,
            ),
          );
        }
        if (jumps % 3 == 0 && h.countEnemies(EnemyKind.slime) < 4) {
          h.spawnEnemy(EnemyKind.slime, body.x - 10, body.bottom, fromBoss: true);
          h.spawnEnemy(EnemyKind.slime, body.right + 10, body.bottom, fromBoss: true);
        }
      }
      return;
    }
    _gravity(h, dt);
    wait -= dt;
    if (wait < 0.45 && state != 'crouch' && body.onGround) {
      state = 'crouch';
      h.sound('tele');
    }
    if (state == 'crouch') {
      sy = 0.78 + math.sin(t * 40) * 0.02;
      sx = 1.18;
    }
    if (wait <= 0 && body.onGround) {
      const air = 2 * 980 / (Phys.gravityDown * 0.85);
      final dx = _dxToPlayer(h);
      state = 'air';
      body.vy = -980;
      body.vx = (dx / air).clamp(-400.0, 400.0);
      landX = (body.cx + body.vx * air).clamp(kTile + body.w / 2, h.room.pixelW - kTile - body.w / 2);
      floorY = body.bottom;
      sx = 0.8;
      sy = 1.25;
      h.sound('jump');
    }
  }

  // ───────── 꿈의 군주: 떠다니며 패턴 순환 (포자 비, 돌진, 소환, 2페이즈 회전탄) ─────────
  void _lord(EnemyHost h, double dt, math.Random rng) {
    final px = h.playerBody.cx;
    final room = h.room;
    if (state == 'idle') {
      final hoverY = baseY - 70 + math.sin(t * 1.6) * 14;
      body.y += (hoverY - body.y) * math.min(1, dt * 3);
      final targetX = (px + (body.cx < px ? -220 : 220)).clamp(kTile * 2, room.pixelW - kTile * 2);
      body.x += ((targetX - body.w / 2) - body.x) * math.min(1, dt * 0.9);
      wait -= dt;
      if (wait <= 0) {
        final list = phase2 ? ['rain', 'dash', 'spiral', 'summon', 'rain', 'spiral'] : ['rain', 'dash', 'summon', 'rain'];
        pattern = list[patternIdx % list.length];
        patternIdx++;
        state = 'cast';
        tele = pattern == 'dash' ? 0.85 : 0.6;
        if (pattern == 'dash') {
          lx = px;
          ly = h.playerBody.cy;
        }
        h.sound('tele');
      }
      return;
    }
    if (state == 'cast') {
      tele -= dt;
      if (tele > 0) return;
      switch (pattern) {
        case 'rain':
          final n = phase2 ? 6 : 4;
          for (var i = 0; i < n; i++) {
            final x = (px + (i - (n - 1) / 2) * 120 + rng.nextDouble() * 50).clamp(kTile * 1.5, room.pixelW - kTile * 1.5);
            final gy = _groundY(room, x);
            h.fireHostile(Hostile(kind: HostileKind.rain, x: x, y: gy, r: 12, dmg: 16 * power, warn: 0.95 + i * 0.08, color: Palette.violet));
          }
          state = 'idle';
          wait = phase2 ? 1.2 : 1.7;
        case 'dash':
          final ax = lx - body.cx, ay = ly - body.cy, ad = math.max(1.0, math.sqrt(ax * ax + ay * ay));
          body.vx = ax / ad * 640;
          body.vy = ay / ad * 640;
          state = 'dash';
          dashT = 0.7;
          h.sound('boom');
        case 'summon':
          if (h.countEnemies(EnemyKind.wisp) < 3) {
            h.spawnEnemy(EnemyKind.wisp, body.cx - 80, body.y + 20, fromBoss: true);
            h.spawnEnemy(EnemyKind.wisp, body.cx + 80, body.y + 20, fromBoss: true);
          }
          state = 'idle';
          wait = 1.4;
        case 'spiral':
          for (var ring = 0; ring < 2; ring++) {
            for (var i = 0; i < 12; i++) {
              final a = i * math.pi / 6 + ring * math.pi / 12;
              final sp = 170.0 + ring * 70;
              h.fireHostile(
                Hostile(
                  kind: HostileKind.orb,
                  x: body.cx,
                  y: body.cy,
                  vx: math.cos(a) * sp,
                  vy: math.sin(a) * sp,
                  r: 8,
                  dmg: 13 * power,
                  life: 3.5,
                  color: Palette.violet,
                ),
              );
            }
          }
          h.sound('zap');
          state = 'idle';
          wait = 1.3;
      }
      return;
    }
    if (state == 'dash') {
      body.x += body.vx * dt;
      body.y += body.vy * dt;
      body.x = body.x.clamp(kTile, room.pixelW - kTile - body.w);
      body.y = math.min(body.y, baseY);
      dashT -= dt;
      if (dashT <= 0) {
        state = 'idle';
        wait = 0.9;
        h.shakeCam(0.25);
      }
    }
  }

  static double _groundY(Room room, double x) {
    final cx = cellOf(x);
    for (var cy = 1; cy < room.h; cy++) {
      if (room.kindAt(cx, cy) >= 1) return cy * kTile;
    }
    return room.pixelH;
  }
}
