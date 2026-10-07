import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../app/save_data.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import 'constants.dart';
import 'entities/arrow.dart';
import 'entities/enemy.dart';
import 'entities/hostile.dart';
import 'entities/player.dart';
import 'fx.dart';
import 'input.dart';
import 'motor.dart';
import 'physics.dart';
import 'render/actors.dart';
import 'render/background.dart';
import 'render/hud.dart';
import 'render/tiles.dart';
import 'rooms/room.dart';
import 'rooms/room_template.dart';
import 'skills.dart';
import 'stages.dart';

enum GamePhase { playing, levelUp, paused, cleared, failed }

class RunResult {
  final bool cleared;
  final List<bool> stars;
  final int coins, kills, bestCombo, level, shardsFound, shardsTotal;
  final int? endlessDepth;
  const RunResult({
    required this.cleared,
    required this.stars,
    required this.coins,
    required this.kills,
    required this.bestCombo,
    required this.level,
    required this.shardsFound,
    required this.shardsTotal,
    this.endlessDepth,
  });
}

class Bolt {
  final List<Offset> pts;
  double life = 0.16;
  Bolt(this.pts);
}

class Volley {
  double delay;
  final double angle;
  Volley(this.delay, this.angle);
}

class DreamGame extends Game implements EnemyHost {
  final StageDef stage;
  final int endlessDepth;
  DreamGame(this.stage, {this.endlessDepth = 0});

  final ValueNotifier<GamePhase> phase = ValueNotifier(GamePhase.playing);
  List<SkillDef> offer = [];
  bool offerFromChest = false;
  RunResult? result;

  late RunStats run;
  final GameInput input = GameInput();
  @override
  final Fx fx = Fx();
  final math.Random rng = math.Random();
  late Background bg;
  late Hud hud;
  bool _ready = false;

  // 방
  int roomIndex = 0;
  @override
  late Room room;
  ui.Picture? _tiles;
  late Player player;
  List<Enemy> enemies = [];
  List<Arrow> arrows = [];
  List<Hostile> hostiles = [];
  List<Pickup> pickups = [];
  final List<Bolt> bolts = [];
  final List<Volley> volleys = [];
  final Set<int> openedChests = {};
  final Set<int> hintsShown = {};
  int wave = 1, waves = 1;
  double waveDelay = 0;
  bool portalAnnounced = false;
  double portalAnim = 0;
  late int shardBase;

  // 시간 연출
  double time = 0, hitstop = 0, slowMo = 0, slowScale = 1, worldScale = 1;
  // 카메라
  double camX = 0, camY = 0, look = 0, trauma = 0, zoomPunch = 0;
  double scale = 1, viewW = 960;
  // 화면 연출
  double fade = 1, damageVignette = 0;
  int _fadeDir = -1; // -1 밝아짐, 1 어두워짐, 0 없음
  VoidCallback? _afterFade;
  int combo = 0;
  double comboT = 0, comboPop = 0;
  int pendingLevels = 0;
  double levelUpDelay = -1;
  double orbitAngle = 0;
  double invulnAfterPick = 0;

  // ───────────────────────── 준비 ─────────────────────────
  @override
  Future<void> onLoad() async {
    bg = Background();
    hud = Hud(this);
    run = RunStats(SaveData.instance.baseStats);
    _loadRoom(0);
    _ready = true;
  }

  @override
  Color backgroundColor() => Palette.night;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    scale = size.y / kViewH;
    viewW = size.x / scale;
  }

  int get roomCount => stage.rooms.length;
  bool get isLastRoom => roomIndex == roomCount - 1;

  void _loadRoom(int index) {
    roomIndex = index;
    final sr = stage.rooms[index];
    room = Room(sr.tpl, mirrored: sr.mirrored);
    _tiles = bakeStaticTiles(room);
    player = Player(room.startX, room.startY);
    enemies = [for (final s in room.spawns) Enemy(enemyKindFromChar(s.kind)!, s.x, s.y, stage.power, rng)];
    arrows = [];
    hostiles = [];
    bolts.clear();
    volleys.clear();
    pickups = [for (final c in room.coins) Pickup(PickupKind.coin, c.x, c.y, value: 1)];
    shardBase = 0;
    for (var i = 0; i < index; i++) {
      shardBase += stage.rooms[i].tpl.rows.join().split('*').length - 1;
    }
    for (var i = 0; i < room.shards.length; i++) {
      pickups.add(Pickup(PickupKind.shard, room.shards[i].x, room.shards[i].y, index: shardBase + i));
    }
    openedChests.clear();
    hintsShown.clear();
    fx.clear();
    wave = 1;
    waves = room.tpl.waves + (stage.power > 2.2 && room.tpl.type == RoomType.combat ? 1 : 0);
    waveDelay = 0;
    portalAnnounced = false;
    portalAnim = 0;
    combo = 0;
    comboT = 0;
    input.reset();
    _snapCamera();
    hud.roomBanner(index, roomCount, _roomTitle(room.tpl.type));
    fade = 1;
    _fadeDir = -1;
  }

  String _roomTitle(RoomType t) => switch (t) {
    RoomType.combat => '적을 모두 물리치면 포털이 열려요',
    RoomType.platform => '포털까지 가요',
    RoomType.reward => '보물상자를 열어요',
    RoomType.boss => '보스를 쓰러뜨려요!',
  };

  // ───────────────────────── 루프 ─────────────────────────
  @override
  void update(double dt) {
    if (!_ready) return;
    dt = math.min(dt, 1 / 30);
    time += dt;
    hud.update(dt);
    comboPop = math.max(0, comboPop - dt * 4);
    damageVignette = math.max(0, damageVignette - dt * 1.8);
    portalAnim = math.max(0, portalAnim - dt);
    if (_fadeDir != 0) {
      fade = (fade + _fadeDir * dt / 0.32).clamp(0.0, 1.0);
      if (_fadeDir > 0 && fade >= 1) {
        _fadeDir = 0;
        final cb = _afterFade;
        _afterFade = null;
        cb?.call();
      } else if (_fadeDir < 0 && fade <= 0) {
        _fadeDir = 0;
      }
    }
    if (phase.value != GamePhase.playing) return;
    if (hitstop > 0) {
      hitstop -= dt;
      trauma = math.max(0, trauma - dt * 0.6);
      return;
    }
    var sim = dt;
    if (slowMo > 0) {
      slowMo -= dt;
      sim *= slowScale;
    }
    if (levelUpDelay >= 0) {
      levelUpDelay -= dt;
      if (levelUpDelay < 0) _openLevelUp(false);
    }
    _step(sim, dt);
  }

  void _step(double dt, double realDt) {
    room.update(dt);
    _roomEvents();
    _updatePlayer(dt);
    _updateVolleys(dt);
    _updateArrows(dt);
    _updateEnemies(dt);
    _updateHostiles(dt);
    _updateOrbit(dt);
    _updatePickups(dt);
    for (final b in bolts) {
      b.life -= dt;
    }
    bolts.removeWhere((b) => b.life <= 0);
    fx.update(dt);
    comboT -= dt;
    if (comboT <= 0 && combo > 0) combo = 0;
    _updateWaves(dt);
    _updateCamera(realDt);
    _hints();
  }

  void _roomEvents() {
    for (final e in room.events) {
      final x = e.cx * kTile + kTile / 2, y = e.cy * kTile + 6;
      switch (e.kind) {
        case RoomEventKind.crumbleFall:
          sound('crumble');
          fx.burst(x, y, const Color(0xFFC9A57A), n: 10, speed: 160, size: 4, gravity: 900, shape: PShape.square);
        case RoomEventKind.crumbleBack:
          fx.burst(x, y, const Color(0x88F4ECD8), n: 5, speed: 60, gravity: 0, size: 2);
        case RoomEventKind.bridgeOn:
          sound('bridge');
          hud.toast('수정 다리가 생겼어요! 서둘러요', color: Palette.violet);
        case RoomEventKind.bridgeWarn:
          sound('tele');
        case RoomEventKind.bridgeOff:
          sound('crumble');
      }
    }
    room.events.clear();
  }

  // ───────────────────────── 플레이어 ─────────────────────────
  final MotorInput _mi = MotorInput();
  bool get _leaving => _fadeDir > 0;

  void _updatePlayer(double dt) {
    final b = player.body;
    _mi
      ..dir = _leaving ? 0 : input.dir
      ..jump = !_leaving && input.consumeJump()
      ..drop = input.consumeDrop()
      ..jumpHeld = input.jumpHeld;
    final m = player.motor;
    m.step(room, _mi, dt);
    if (m.jumped) {
      sound('jump');
      player.stretch(0.4);
      fx.dust(b.cx, b.bottom, n: 5, power: 0.8);
    }
    if (m.landed) {
      final k = math.min(0.55, m.landImpact / 1500);
      player.squash(k);
      if (m.landImpact > 420) {
        fx.dust(b.cx, b.bottom, n: 7);
        sound('land', volume: math.min(1, m.landImpact / 900));
      }
    }
    if (m.bounced) {
      room.springAnim[m.bounceCy * room.w + m.bounceCx] = 0.35;
      sound('spring');
      player.stretch(0.7);
      fx.ring(m.bounceCx * kTile + kTile / 2, m.bounceCy * kTile + 8, const Color(0xFFFF9CC8), to: 70);
      fx.burst(m.bounceCx * kTile + kTile / 2, m.bounceCy * kTile + 4, const Color(0xFFFFC2DE), n: 10, speed: 200, gravity: 300, shape: PShape.star, size: 3);
    }
    player.moving = _mi.dir != 0;
    if (player.moving) look += ((_mi.dir * 90) - look) * math.min(1, dt * 3);
    player.animate(dt);
    if (b.onGround && b.vx.abs() > 200) {
      player.dustT -= dt;
      if (player.dustT <= 0) {
        player.dustT = 0.16;
        fx.dust(b.cx - player.face * 8, b.bottom, n: 2, dir: -player.face.toDouble(), power: 0.6);
      }
    }
    // 안전 지점 기억 (낭떠러지에 떨어지면 여기로)
    if (b.onGround && b.riding == null && b.groundCx >= 0 && room.cellAt(b.groundCx, b.groundCy) == Cell.solid && !_nearHazard()) {
      player.safeT += dt;
      if (player.safeT > 0.15) {
        player.safeX = b.x;
        player.safeY = b.y;
      }
    } else {
      player.safeT = 0;
    }
    player.inv -= dt;
    invulnAfterPick -= dt;
    run.shieldCd -= dt;
    _hazards();
    if (b.y > room.pixelH + 60) _fellInPit();
    // 포털
    if (_portalOpen &&
        !_leaving &&
        b.x < room.portalX + Room.portalW &&
        b.right > room.portalX &&
        b.y < room.portalY + Room.portalH &&
        b.bottom > room.portalY) {
      _enterPortal();
    }
    // 보물상자
    for (var i = 0; i < room.chests.length; i++) {
      final c = room.chests[i];
      if (!openedChests.contains(i) && (b.cx - c.x).abs() < 30 && (b.bottom - c.y).abs() < 40) {
        openedChests.add(i);
        sound('chest');
        fx.burst(c.x, c.y - 20, Palette.gold, n: 26, speed: 300, gravity: 500, shape: PShape.star, size: 4, glow: true);
        fx.ring(c.x, c.y - 16, Palette.gold, to: 90);
        run.hp = math.min(run.maxHp, run.hp + run.maxHp * 0.25);
        for (var k = 0; k < 6; k++) {
          pickups.add(Pickup(PickupKind.coin, c.x, c.y - 20, vx: fx.rand(-160, 160), vy: fx.rand(-420, -220), value: 2));
        }
        Future.delayed(const Duration(milliseconds: 450), () {
          if (phase.value == GamePhase.playing) _openLevelUp(true);
        });
      }
    }
    // 집중
    if (player.focusT > 0) {
      player.focusT -= dt;
    } else if (run.focus >= 100 && !player.moving && enemies.isNotEmpty) {
      player.focusT = run.focusDuration;
      run.focus = 0;
      sound('focus');
      trauma = math.max(trauma, 0.2);
      fx.ring(b.cx, b.cy, Palette.sky, to: 160, life: 0.5, width: 6);
      hud.toast('집중! 시간이 느려지고 연사해요', color: Palette.sky);
    }
    final target = player.focusT > 0 ? 0.38 : 1.0;
    worldScale += (target - worldScale) * math.min(1, dt * 10);
    // 사격
    player.cool -= dt;
    final aimTarget = _target();
    final want = aimTarget != null ? math.atan2(aimTarget.dy - (b.y + 16), aimTarget.dx - b.cx) : (player.face > 0 ? 0.0 : math.pi);
    player.aim = _lerpAngle(player.aim, want, math.min(1, dt * 18));
    if (!player.moving && player.cool <= 0 && !_leaving) {
      _shoot(aimTarget);
      player.cool = run.fireInterval * (player.focusT > 0 ? 0.5 : 1);
    }
  }

  static double _lerpAngle(double a, double b, double t) {
    var d = (b - a) % (math.pi * 2);
    if (d > math.pi) d -= math.pi * 2;
    if (d < -math.pi) d += math.pi * 2;
    return a + d * t;
  }

  bool _nearHazard() {
    final b = player.body;
    for (var cx = cellOf(b.x) - 1; cx <= cellOf(b.right) + 1; cx++) {
      for (var cy = cellOf(b.y); cy <= cellOf(b.bottom) + 1; cy++) {
        final c = room.cellAt(cx, cy);
        if (c == Cell.spike || c == Cell.thorn) return true;
      }
    }
    return false;
  }

  void _hazards() {
    final b = player.body;
    for (var cx = cellOf(b.x + 3); cx <= cellOf(b.right - 3); cx++) {
      for (var cy = cellOf(b.y + 3); cy <= cellOf(b.bottom - 2); cy++) {
        final c = room.cellAt(cx, cy);
        final top = cy * kTile;
        if (c == Cell.spike && b.bottom > top + 16) {
          _hurt(18 * stage.power, cx * kTile + kTile / 2, bounce: true);
        } else if (c == Cell.thorn && room.thornActive(cx, cy) && b.bottom > top + 6) {
          _hurt(16 * stage.power, cx * kTile + kTile / 2, bounce: true);
        }
      }
    }
  }

  void _fellInPit() {
    final b = player.body;
    final dmg = run.maxHp * Combat.pitDamageRatio;
    fx.burst(b.cx, room.pixelH - 10, const Color(0xFF9FD8FF), n: 20, speed: 260, gravity: 600);
    b
      ..x = player.safeX
      ..y = player.safeY
      ..vx = 0
      ..vy = 0;
    player.inv = 0;
    _hurt(dmg, b.cx, silentKnock: true);
    player.inv = 1.2;
    _snapCamera();
    fade = 0.6;
    _fadeDir = -1;
  }

  void _hurt(double amount, double fromX, {bool bounce = false, bool silentKnock = false}) {
    if (player.inv > 0 || invulnAfterPick > 0 || phase.value != GamePhase.playing) return;
    final b = player.body;
    if (run.shieldReady) {
      run.shieldCd = 8;
      player.inv = 0.6;
      sound('shield');
      fx.ring(b.cx, b.cy, Palette.moss, to: 70, width: 6);
      fx.leaves(b.cx, b.cy, n: 10);
      hud.toast('나뭇잎 방패가 막았어요', color: Palette.moss);
      return;
    }
    run.hp -= amount;
    player.inv = Combat.invuln;
    player.hurtFlash = 0.25;
    if (!silentKnock) {
      b.vx = (b.cx < fromX ? -1 : 1) * 380;
      b.vy = bounce ? -560 : -400;
    }
    hitstop = 0.08;
    trauma = math.max(trauma, 0.5);
    damageVignette = 1;
    sound('hurt');
    Sfx.instance.haptic(strong: true);
    fx.burst(b.cx, b.cy, Palette.danger, n: 14, speed: 240, gravity: 400);
    fx.text(b.cx, b.y - 8, '-${amount.round()}', color: const Color(0xFFFF7A7A), size: 22);
    if (combo >= 5) hud.toast('$combo 콤보가 끊겼어요', color: Palette.mute);
    combo = 0;
    if (run.hp <= 0) {
      run.hp = 0;
      _fail();
    }
  }

  // ───────────────────────── 사격 ─────────────────────────
  Offset? _target() {
    final b = player.body;
    final ox = b.cx, oy = b.y + 16;
    Enemy? best;
    var bd = Combat.autoAimRange;
    for (final e in enemies) {
      if (e.spawnIn > 0) continue;
      final d = math.sqrt(math.pow(e.cx - ox, 2) + math.pow(e.cy - oy, 2));
      if (d < bd && lineClear(room, ox, oy, e.cx, e.cy)) {
        bd = d;
        best = e;
      }
    }
    if (best != null) return Offset(best.cx, best.cy);
    // 적이 없으면 시야 안의 수정을 노려요
    for (var cy = 0; cy < room.h; cy++) {
      for (var cx = 0; cx < room.w; cx++) {
        if (room.cells[cy][cx] != Cell.crystal) continue;
        final tx = cx * kTile + kTile / 2, ty = cy * kTile + kTile / 2;
        if ((tx - ox).abs() < 760 && (ty - oy).abs() < 140 && lineClear(room, ox, oy, tx, ty)) return Offset(tx, ty);
      }
    }
    return null;
  }

  void _shoot(Offset? target) {
    final b = player.body;
    double ang;
    if (target != null) {
      ang = math.atan2(target.dy - (b.y + 16), target.dx - b.cx);
      player.motor.face = math.cos(ang) >= 0 ? 1 : -1;
    } else {
      ang = player.face > 0 ? 0 : math.pi;
    }
    player.aim = ang;
    _volley(ang);
    for (var k = 1; k <= run.stack('multishot'); k++) {
      volleys.add(Volley(0.085 * k, ang));
    }
    player.bowPull = 1;
    player.recoil = 1;
    sound('shoot');
  }

  void _volley(double ang) {
    final b = player.body;
    final ox = b.cx + math.cos(ang) * 14, oy = b.y + 16 + math.sin(ang) * 6;
    final n = 1 + run.stack('front');
    final nx = -math.sin(ang), ny = math.cos(ang);
    for (var i = 0; i < n; i++) {
      final off = (i - (n - 1) / 2) * 9;
      _spawnArrow(ox + nx * off, oy + ny * off, ang);
    }
    for (var k = 1; k <= run.stack('diagonal'); k++) {
      _spawnArrow(ox, oy, ang - 0.34 * k);
      _spawnArrow(ox, oy, ang + 0.34 * k);
    }
    for (var k = 0; k < run.stack('back'); k++) {
      _spawnArrow(b.cx, oy, ang + math.pi + (k - (run.stack('back') - 1) / 2) * 0.2);
    }
    fx.sparks(ox, oy, ang, Palette.cream, n: 3, spread: 0.4, speed: 260);
  }

  void _spawnArrow(double x, double y, double ang) {
    final crit = rng.nextDouble() < run.crit;
    final dmg = run.damage * (crit ? Combat.critMult : 1) * (player.focusT > 0 ? 1.3 : 1);
    arrows.add(
      Arrow(
        x: x,
        y: y,
        vx: math.cos(ang) * Combat.arrowSpeed,
        vy: math.sin(ang) * Combat.arrowSpeed,
        dmg: dmg,
        life: Combat.arrowLife,
        pierce: run.has('pierce') ? -1 : 0,
        bounces: run.stack('ricochet'),
        crit: crit,
      ),
    );
  }

  void _updateVolleys(double dt) {
    for (final v in volleys) {
      v.delay -= dt;
      if (v.delay <= 0) {
        _volley(v.angle);
        sound('shoot', volume: 0.7);
      }
    }
    volleys.removeWhere((v) => v.delay <= 0);
  }

  Color get arrowColor {
    if (run.has('fire')) return const Color(0xFFFF9A4A);
    if (run.has('frost')) return const Color(0xFF9BE6FF);
    if (run.has('lightning')) return const Color(0xFFFFE36A);
    return Palette.cream;
  }

  void _updateArrows(double dt) {
    for (final a in arrows) {
      a.life -= dt;
      if (a.life <= 0) {
        a.dead = true;
        continue;
      }
      a.trail.add(Offset(a.x, a.y));
      if (a.trail.length > 7) a.trail.removeAt(0);
      final dist = math.sqrt(a.vx * a.vx + a.vy * a.vy) * dt;
      final steps = math.max(1, (dist / 8).ceil());
      for (var s = 0; s < steps && !a.dead; s++) {
        a.x += a.vx * dt / steps;
        a.y += a.vy * dt / steps;
        final cx = cellOf(a.x), cy = cellOf(a.y);
        if (a.x < 0 || a.x > room.pixelW || a.y < -200 || a.y > room.pixelH + 40) {
          a.dead = true;
          break;
        }
        final cell = room.cellAt(cx, cy);
        if (cell == Cell.crystal) {
          room.triggerBridge();
          fx.ring(cx * kTile + kTile / 2, cy * kTile + kTile / 2, const Color(0xFF7DFFB2), to: 80, width: 5);
          fx.burst(cx * kTile + kTile / 2, cy * kTile + kTile / 2, const Color(0xFFCFFFE2), n: 14, speed: 240, gravity: 0, shape: PShape.star, size: 3);
          a.dead = true;
          break;
        }
        if (room.kindAt(cx, cy) == 2) {
          fx.sparks(a.x, a.y, math.atan2(a.vy, a.vx) + math.pi, const Color(0xFFE8DCC0), n: 5, speed: 260);
          a.dead = true;
          break;
        }
        for (final e in enemies) {
          if (e.dead || e.spawnIn > 0 || a.hit.contains(e)) continue;
          final eb = e.body;
          if (a.x > eb.x - 6 && a.x < eb.right + 6 && a.y > eb.y - 6 && a.y < eb.bottom + 6) {
            a.hit.add(e);
            _hitEnemy(e, a.dmg, a.crit, math.atan2(a.vy, a.vx), a.x, a.y);
            if (a.pierce != 0) {
              a.dmg *= 0.75;
            } else if (a.bounces > 0) {
              final next = _nearestEnemy(a.x, a.y, 380, a.hit);
              if (next != null) {
                a.bounces--;
                final ang = math.atan2(next.cy - a.y, next.cx - a.x);
                a.vx = math.cos(ang) * Combat.arrowSpeed;
                a.vy = math.sin(ang) * Combat.arrowSpeed;
                a.life = math.max(a.life, 0.6);
                fx.ring(a.x, a.y, Palette.epic, to: 24, life: 0.2, width: 3);
              } else {
                a.dead = true;
              }
            } else {
              a.dead = true;
            }
            break;
          }
        }
      }
    }
    arrows.removeWhere((a) => a.dead);
  }

  Enemy? _nearestEnemy(double x, double y, double range, Set<Enemy> exclude) {
    Enemy? best;
    var bd = range;
    for (final e in enemies) {
      if (e.dead || e.spawnIn > 0 || exclude.contains(e)) continue;
      final d = math.sqrt(math.pow(e.cx - x, 2) + math.pow(e.cy - y, 2));
      if (d < bd) {
        bd = d;
        best = e;
      }
    }
    return best;
  }

  void _hitEnemy(Enemy e, double dmg, bool crit, double ang, double hx, double hy, {bool chained = false}) {
    if (e.dead) return;
    var d = dmg;
    if (e.frozen > 0) d *= 1.5;
    e.hp -= d;
    e.flash = 0.09;
    e.squash(crit ? 0.6 : 0.35);
    if (!e.isBoss && e.frozen <= 0) {
      e.kx = math.cos(ang) * (crit ? 330 : 210);
      if (!e.spec.flying && e.body.onGround) e.body.vy = -140;
    }
    fx.text(e.cx, e.body.y - 6, '${d.round()}${crit ? '!' : ''}', color: crit ? Palette.gold : Palette.ink, size: crit ? 28 : 19, crit: crit);
    fx.sparks(hx, hy, ang, crit ? Palette.gold : arrowColor, n: crit ? 12 : 7, speed: crit ? 520 : 400);
    if (crit) {
      fx.ring(hx, hy, Palette.gold, to: 46, life: 0.25, width: 4);
      zoomPunch = math.max(zoomPunch, 0.025);
      Sfx.instance.haptic();
    }
    hitstop = math.max(hitstop, crit ? 0.055 : 0.022);
    trauma = math.max(trauma, crit ? 0.16 : 0.06);
    sound(crit ? 'crit' : 'hit');
    run.focus = math.min(100, run.focus + 2.2 * run.focusGain);
    if (run.has('fire')) e.burn = 2.4;
    if (run.has('frost')) {
      e.slow = 2.2;
      if (!e.isBoss && e.frozen <= 0 && ++e.chill >= 3) {
        e.chill = 0;
        e.frozen = 1.6;
        e.state = e.spec.flying ? 'hover' : (e.kind == EnemyKind.mushroom ? 'idle' : 'walk');
        sound('freeze');
        fx.burst(e.cx, e.cy, const Color(0xFFDFF8FF), n: 12, speed: 200, gravity: 200, shape: PShape.square, size: 3);
      }
    }
    if (run.has('lightning') && !chained) {
      final hit = <Enemy>{e};
      var from = Offset(e.cx, e.cy);
      for (var i = 0; i < 2; i++) {
        final n = _nearestEnemy(from.dx, from.dy, 190, hit);
        if (n == null) break;
        hit.add(n);
        bolts.add(Bolt(_jagged(from, Offset(n.cx, n.cy))));
        _hitEnemy(n, dmg * 0.45, false, ang, n.cx, n.cy, chained: true);
        from = Offset(n.cx, n.cy);
      }
      if (hit.length > 1) sound('zap');
    }
  }

  List<Offset> _jagged(Offset a, Offset b) {
    final pts = <Offset>[a];
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      pts.add(Offset.lerp(a, b, t)! + Offset(fx.rand(-10, 10), fx.rand(-10, 10)));
    }
    pts.add(b);
    return pts;
  }

  // ───────────────────────── 적 ─────────────────────────
  void _updateEnemies(double dt) {
    final edt = dt * worldScale;
    final pb = player.body;
    for (final e in enemies) {
      if (e.dead) continue;
      e.flash -= dt;
      e.slow -= dt;
      if (e.burn > 0) {
        e.burn -= dt;
        e.burnTick -= dt;
        if (e.burnTick <= 0) {
          e.burnTick = 0.5;
          final d = run.damage * 0.22;
          e.hp -= d;
          e.flash = 0.05;
          fx.text(e.cx, e.body.y, '${d.round()}', color: const Color(0xFFFFB15C), size: 15);
        }
        if (rng.nextDouble() < 0.5) {
          fx.add(
            Particle(
              e.body.x + rng.nextDouble() * e.body.w,
              e.body.y + rng.nextDouble() * e.body.h * 0.6,
              0,
              -70,
              life: 0.4,
              size: 3.5,
              color: rng.nextBool() ? const Color(0xFFFFB15C) : const Color(0xFFFF6A2C),
              gravity: -80,
              glow: true,
            ),
          );
        }
      }
      if (e.frozen > 0) {
        e.frozen -= dt;
        if (e.frozen <= 0) fx.burst(e.cx, e.cy, const Color(0xFFDFF8FF), n: 10, speed: 180, shape: PShape.square, size: 3);
      } else {
        e.update(this, edt * (e.slow > 0 ? 0.55 : 1), rng);
        if (e.spawnIn <= 0 && e.hp > 0 && overlaps(pb, e.body, 6)) _hurt(e.contactDamage, e.cx);
      }
      if (e.hp <= 0) e.dead = true;
    }
    final dead = enemies.where((e) => e.dead).toList();
    if (dead.isEmpty) return;
    enemies.removeWhere((e) => e.dead);
    for (final e in dead) {
      _onKill(e);
    }
  }

  void _onKill(Enemy e) {
    final cx = e.cx, cy = e.cy;
    fx.burst(cx, cy, e.spec.color, n: e.isBoss ? 70 : 20, speed: e.isBoss ? 480 : 280, size: e.isBoss ? 7 : 5, gravity: 500);
    fx.burst(cx, cy, const Color(0xFFFFFFFF), n: e.isBoss ? 30 : 8, speed: e.isBoss ? 380 : 200, size: 3, gravity: 0, shape: PShape.star, glow: true);
    fx.ring(cx, cy, Color.lerp(e.spec.color, const Color(0xFFFFFFFF), 0.4)!, to: e.isBoss ? 260 : 64, life: e.isBoss ? 0.7 : 0.32, width: e.isBoss ? 10 : 5);
    sound(e.isBoss ? 'boom' : 'kill');
    Sfx.instance.haptic(strong: e.isBoss);
    hitstop = math.max(hitstop, e.isBoss ? 0.3 : 0.05);
    trauma = math.max(trauma, e.isBoss ? 0.9 : 0.2);
    zoomPunch = math.max(zoomPunch, e.isBoss ? 0.08 : 0.02);
    run.kills++;
    combo++;
    comboT = 2.4;
    comboPop = 1;
    run.bestCombo = math.max(run.bestCombo, combo);
    if (const [10, 25, 50, 100].contains(combo)) {
      hud.toast('$combo 콤보!', color: Palette.gold);
      sound('levelup', volume: 0.6);
    }
    final orbs = e.spec.xp.round();
    for (var i = 0; i < orbs; i++) {
      pickups.add(Pickup(PickupKind.xp, cx, cy, vx: fx.rand(-200, 200), vy: fx.rand(-380, -140), value: 4));
    }
    final coins = e.isBoss ? 18 : (rng.nextDouble() < e.spec.coinChance ? 1 + rng.nextInt(2) : 0);
    for (var i = 0; i < coins; i++) {
      pickups.add(Pickup(PickupKind.coin, cx, cy, vx: fx.rand(-220, 220), vy: fx.rand(-420, -180), value: 1));
    }
    if (!e.fromBoss && rng.nextDouble() < 0.05) pickups.add(Pickup(PickupKind.heal, cx, cy, vy: -300));
    if (run.has('vampire')) run.hp = math.min(run.maxHp, run.hp + run.maxHp * 0.015 * run.stack('vampire'));
    if (e.kind == EnemyKind.splitter) {
      for (final s in [-1, 1]) {
        final child = Enemy(EnemyKind.splitling, cx + s * 14, e.body.bottom, stage.power, rng)
          ..spawnIn = 0
          ..kx = s * 260.0;
        child.body.vy = -380;
        enemies.add(child);
      }
    }
    if (e.burn > 0 && run.has('fire')) {
      fx.ring(cx, cy, const Color(0xFFFF8A3D), to: 110, width: 7);
      fx.burst(cx, cy, const Color(0xFFFFA24A), n: 26, speed: 320, gravity: 200, glow: true);
      sound('boom');
      for (final o in enemies) {
        if (math.sqrt(math.pow(o.cx - cx, 2) + math.pow(o.cy - cy, 2)) < 110) {
          o.hp -= run.damage * 1.2;
          o.burn = 2.4;
          o.flash = 0.1;
          fx.text(o.cx, o.body.y, '${(run.damage * 1.2).round()}', color: const Color(0xFFFF8A3D), size: 20);
          if (o.hp <= 0) o.dead = true;
        }
      }
    }
    if (e.isBoss) {
      slowMo = 1.4;
      slowScale = 0.2;
      for (final o in enemies) {
        o.hp = 0;
        o.dead = true;
      }
      hostiles.clear();
      hud.toast('${e.kind == EnemyKind.king ? '킹 슬라임' : '꿈의 군주'} 처치!', color: Palette.gold);
    } else if (enemies.where((o) => !o.dead).isEmpty && wave >= waves && room.tpl.needsClear) {
      // 마지막 한 마리: 슬로모션 + 확대
      slowMo = 0.5;
      slowScale = 0.25;
      zoomPunch = 0.06;
    }
  }

  void _updateWaves(double dt) {
    if (!room.tpl.needsClear || enemies.isNotEmpty) return;
    if (wave < waves) {
      waveDelay += dt;
      if (waveDelay > 0.9) _spawnWave();
    } else if (!portalAnnounced) {
      portalAnnounced = true;
      portalAnim = 1;
      sound('portal');
      hud.toast('포털이 열렸어요!', color: const Color(0xFF8BF0B0));
    }
  }

  void _spawnWave() {
    wave++;
    waveDelay = 0;
    final kinds = room.spawns.map((s) => s.kind).where((k) => k != 'K' && k != 'L').toList();
    if (kinds.isEmpty) kinds.add('s');
    final count = kinds.length + 2 * (wave - 1);
    final b = player.body;
    for (var i = 0; i < count; i++) {
      var kind = enemyKindFromChar(kinds[i % kinds.length])!;
      if (kind == EnemyKind.slime && rng.nextDouble() < 0.35) kind = EnemyKind.mushroom;
      final side = i.isEven ? 1 : -1;
      final x = (b.cx + side * (220 + rng.nextDouble() * 300)).clamp(kTile * 1.5, room.pixelW - kTile * 1.5);
      double y;
      if (kEnemySpecs[kind]!.flying) {
        y = math.max(kTile * 2, b.y - 60 - rng.nextDouble() * 100);
      } else {
        final g = _groundBelow(x, b.y - kTile * 4);
        if (g == null) continue;
        y = g;
      }
      final e = Enemy(kind, x, y, stage.power, rng)..dir = -side;
      enemies.add(e);
      fx.ring(x, y - e.body.h / 2, Palette.violet, to: 50, life: 0.4);
      fx.burst(x, y - e.body.h / 2, const Color(0xFFD7C2FF), n: 10, speed: 160, gravity: 0, shape: PShape.star, size: 2.5);
    }
    if (enemies.isEmpty) enemies.add(Enemy(EnemyKind.bat, b.cx + 260, b.y, stage.power, rng));
    sound('tele');
    hud.toast('웨이브 $wave / $waves · 몰려와요!', color: Palette.rose);
  }

  double? _groundBelow(double x, double fromY) {
    final cx = cellOf(x);
    for (var cy = math.max(0, cellOf(fromY)); cy < room.h; cy++) {
      if (room.kindAt(cx, cy) >= 1 && room.kindAt(cx, cy - 1) == 0) return cy * kTile;
    }
    return null;
  }

  // ───────────────────────── 적의 공격 ─────────────────────────
  void _updateHostiles(double dt) {
    final sdt = dt * worldScale;
    final pb = player.body;
    for (final h in hostiles) {
      h.t += sdt;
      if (h.kind == HostileKind.rain && h.warn > 0) {
        h.warn -= sdt;
        if (h.warn <= 0) {
          h.kind = HostileKind.spore;
          h.y -= 460;
          h.vy = 720;
          h.gravity = 0;
        }
        continue;
      }
      h.life -= sdt;
      if (h.homing > 0) {
        final want = math.atan2(pb.cy - h.y, pb.cx - h.x);
        final cur = math.atan2(h.vy, h.vx);
        final sp = math.sqrt(h.vx * h.vx + h.vy * h.vy);
        final na = _lerpAngle(cur, want, math.min(1, h.homing * sdt));
        h.vx = math.cos(na) * sp;
        h.vy = math.sin(na) * sp;
      }
      h.vy += h.gravity * sdt;
      h.x += h.vx * sdt;
      h.y += h.vy * sdt;
      if (h.kind == HostileKind.wave) {
        if (room.kindAt(cellOf(h.x + h.vx.sign * 14), cellOf(h.y)) == 2 || room.kindAt(cellOf(h.x), cellOf(h.y + 20)) == 0) h.life = 0;
        if (rng.nextDouble() < 0.6) fx.dust(h.x, h.y + 14, n: 1, power: 0.7);
      } else if (room.kindAt(cellOf(h.x), cellOf(h.y)) == 2) {
        h.life = 0;
        fx.burst(h.x, h.y, h.color, n: 6, speed: 120, gravity: 200, size: 3);
      }
      if (h.life > 0 && h.x > pb.x - h.r + 4 && h.x < pb.right + h.r - 4 && h.y > pb.y - h.r + 4 && h.y < pb.bottom + h.r - 4) {
        h.life = 0;
        _hurt(h.dmg, h.x);
      }
      if (h.life <= 0) h.dead = true;
    }
    hostiles.removeWhere((h) => h.dead);
  }

  // ───────────────────────── 수호 구슬 ─────────────────────────
  Iterable<Offset> get orbitPositions sync* {
    final n = run.stack('orbit');
    final b = player.body;
    for (var i = 0; i < n; i++) {
      final a = orbitAngle + i * math.pi * 2 / n;
      yield Offset(b.cx + math.cos(a) * 52, b.cy + math.sin(a) * 40);
    }
  }

  void _updateOrbit(double dt) {
    if (!run.has('orbit')) return;
    orbitAngle += dt * 3.4;
    for (final o in orbitPositions) {
      for (final e in enemies) {
        if (e.dead || e.spawnIn > 0 || e.hitCd > 0) continue;
        if (o.dx > e.body.x - 8 && o.dx < e.body.right + 8 && o.dy > e.body.y - 8 && o.dy < e.body.bottom + 8) {
          e.hitCd = 0.4;
          _hitEnemy(e, run.damage * 0.6, false, math.atan2(e.cy - player.body.cy, e.cx - player.body.cx), o.dx, o.dy, chained: true);
        }
      }
    }
  }

  // ───────────────────────── 아이템 ─────────────────────────
  void _updatePickups(double dt) {
    final b = player.body;
    for (final p in pickups) {
      p.t += dt;
      final dx = b.cx - p.x, dy = b.cy - p.y;
      final d = math.sqrt(dx * dx + dy * dy);
      final magnet = p.kind == PickupKind.xp ? 99999.0 : (p.kind == PickupKind.shard ? 46.0 : 110.0);
      final settle = p.kind == PickupKind.xp ? 0.45 : 0.6;
      if ((p.vx != 0 || p.vy != 0) && p.t < settle && !p.homing) {
        p.vy += 1100 * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        if (room.kindAt(cellOf(p.x), cellOf(p.y + 6)) >= 1 && p.vy > 0) {
          p.vy *= -0.4;
          p.vx *= 0.6;
        }
        continue;
      }
      if (d < magnet || p.homing) {
        p.homing = true;
        final sp = 300 + p.t * 900;
        p.x += dx / math.max(1, d) * math.min(d, sp * dt);
        p.y += dy / math.max(1, d) * math.min(d, sp * dt);
      }
      if (d < 22) {
        p.dead = true;
        _collect(p);
      }
    }
    pickups.removeWhere((p) => p.dead);
  }

  void _collect(Pickup p) {
    final b = player.body;
    switch (p.kind) {
      case PickupKind.xp:
        sound('xp', minGap: 50);
        run.xp += p.value;
        while (run.xp >= run.xpNeeded) {
          run.xp -= run.xpNeeded;
          run.level++;
          pendingLevels++;
        }
        if (pendingLevels > 0 && levelUpDelay < 0) {
          levelUpDelay = 0.4;
          slowMo = 0.4;
          slowScale = 0.15;
          sound('levelup');
          fx.ring(b.cx, b.cy, Palette.gold, to: 120, life: 0.5, width: 6);
          fx.burst(b.cx, b.cy, Palette.gold, n: 24, speed: 280, gravity: 0, shape: PShape.star, size: 3.5, glow: true);
        }
      case PickupKind.coin:
        sound('coin', minGap: 40);
        run.coins += p.value.round();
        fx.sparks(p.x, p.y, -math.pi / 2, Palette.gold, n: 4, spread: 1.4, speed: 160);
      case PickupKind.heal:
        sound('levelup', volume: 0.5);
        final heal = run.maxHp * 0.15;
        run.hp = math.min(run.maxHp, run.hp + heal);
        fx.text(b.cx, b.y - 10, '+${heal.round()}', color: const Color(0xFF8BF0B0), size: 22);
      case PickupKind.shard:
        sound('chest');
        run.shards.add('${p.index}');
        fx.ring(p.x, p.y, const Color(0xFFA9E6FF), to: 100, width: 6);
        fx.burst(p.x, p.y, const Color(0xFFDDF4FF), n: 26, speed: 300, gravity: 0, shape: PShape.star, size: 4, glow: true);
        zoomPunch = 0.04;
        hud.toast('꿈 조각을 찾았어요! (${foundShardCount()} / ${stage.shardCount})', color: const Color(0xFFA9E6FF));
    }
  }

  int foundShardCount() {
    final saved = SaveData.instance.shardsFound[stage.number] ?? {};
    final all = {...saved, ...run.shards.map(int.parse)};
    return all.length;
  }

  // ───────────────────────── 진행 ─────────────────────────
  bool get _portalOpen => !room.tpl.needsClear || (enemies.isEmpty && wave >= waves);

  void _enterPortal() {
    sound('portal');
    fx.ring(room.portalX + Room.portalW / 2, room.portalY + Room.portalH / 2, const Color(0xFF8BF0B0), to: 140, width: 8);
    if (isLastRoom) {
      _fadeTo(_clear);
    } else {
      _fadeTo(() => _loadRoom(roomIndex + 1));
    }
  }

  void _fadeTo(VoidCallback after) {
    _fadeDir = 1;
    _afterFade = after;
  }

  void _openLevelUp(bool fromChest) {
    if (!fromChest && pendingLevels <= 0) return;
    offer = run.offer(rng);
    offerFromChest = fromChest;
    if (offer.isEmpty) {
      pendingLevels = 0;
      return;
    }
    input.reset();
    phase.value = GamePhase.levelUp;
  }

  void pickSkill(SkillDef s) {
    run.add(s.id);
    sound('select');
    if (!offerFromChest) pendingLevels = math.max(0, pendingLevels - 1);
    final b = player.body;
    fx.ring(b.cx, b.cy, Palette.gold, to: 90, width: 5);
    invulnAfterPick = 0.6;
    if (!offerFromChest && pendingLevels > 0) {
      offer = run.offer(rng);
      phase.value = GamePhase.paused; // 카드 다시 그리기용
      phase.value = GamePhase.levelUp;
      return;
    }
    offerFromChest = false;
    phase.value = GamePhase.playing;
  }

  void pause() {
    if (phase.value == GamePhase.playing) {
      input.reset();
      phase.value = GamePhase.paused;
    }
  }

  void resume() {
    if (phase.value == GamePhase.paused) phase.value = GamePhase.playing;
  }

  void _clear() {
    final saved = SaveData.instance.shardsFound[stage.number] ?? {};
    final runShards = run.shards.map(int.parse).toSet();
    final total = stage.shardCount;
    final found = {...saved, ...runShards}.length;
    final stars = [true, run.hp >= run.maxHp * 0.5, total > 0 && found >= total];
    final starCount = stars.where((s) => s).length;
    SaveData.instance.recordRun(
      stage: stage.number,
      starCount: starCount,
      earnedCoins: run.coins,
      shards: runShards,
      endlessDepth: stage.isEndless ? endlessDepth : null,
    );
    result = RunResult(
      cleared: true,
      stars: stars,
      coins: run.coins,
      kills: run.kills,
      bestCombo: run.bestCombo,
      level: run.level,
      shardsFound: found,
      shardsTotal: total,
      endlessDepth: stage.isEndless ? endlessDepth : null,
    );
    sound('levelup');
    phase.value = GamePhase.cleared;
  }

  void _fail() {
    SaveData.instance.recordRun(stage: stage.number, starCount: 0, earnedCoins: run.coins, shards: run.shards.map(int.parse).toSet());
    result = RunResult(
      cleared: false,
      stars: const [false, false, false],
      coins: run.coins,
      kills: run.kills,
      bestCombo: run.bestCombo,
      level: run.level,
      shardsFound: foundShardCount(),
      shardsTotal: stage.shardCount,
    );
    slowMo = 0;
    Future.delayed(const Duration(milliseconds: 700), () => phase.value = GamePhase.failed);
    phase.value = GamePhase.paused;
  }

  void _hints() {
    final px = player.body.cx / kTile;
    for (var i = 0; i < room.hints.length; i++) {
      final h = room.hints[i];
      final passed = room.mirrored ? px <= h.x + 1 : px >= h.x - 1;
      if (!hintsShown.contains(i) && passed) {
        hintsShown.add(i);
        hud.hint(h.text);
      }
    }
  }

  // ───────────────────────── 카메라 ─────────────────────────
  void _snapCamera() {
    final b = player.body;
    camX = _clampX(b.cx - viewW / 2);
    camY = _clampY(b.cy - kViewH * 0.58);
  }

  double _clampX(double x) {
    final max = room.pixelW - viewW;
    return max <= 0 ? max / 2 : x.clamp(0.0, max);
  }

  double _clampY(double y) {
    final max = room.pixelH - kViewH;
    return max <= 0 ? max / 2 : y.clamp(0.0, max);
  }

  void _updateCamera(double dt) {
    final b = player.body;
    final tx = _clampX(b.cx - viewW / 2 + look);
    final ty = _clampY(b.cy - kViewH * 0.58);
    camX += (tx - camX) * math.min(1, dt * 7);
    camY += (ty - camY) * math.min(1, dt * (b.vy > 600 ? 9 : 5));
    trauma = math.max(0, trauma - dt * 1.4);
    zoomPunch = math.max(0, zoomPunch - dt * 0.18);
  }

  // ───────────────────────── 그리기 ─────────────────────────
  @override
  void render(Canvas c) {
    if (!_ready) return;
    c.save();
    c.scale(scale);
    bg.render(c, viewW, camX, camY, room.pixelH, time);
    final shake = trauma * trauma;
    final sx = shake * 16 * math.sin(time * 47.3), sy = shake * 12 * math.cos(time * 53.1);
    final z = 1 + zoomPunch;
    c.save();
    c.translate(viewW / 2, kViewH / 2);
    c.scale(z);
    c.translate(-viewW / 2 + sx, -kViewH / 2 + sy);
    c.translate(-camX, -camY);
    final view = Rect.fromLTWH(camX, camY, viewW, kViewH);
    drawPortal(c, room, _portalOpen, time, portalAnim);
    final tiles = _tiles;
    if (tiles != null) c.drawPicture(tiles);
    paintDynamicTiles(c, room, time, view);
    for (final m in room.movers) {
      paintMover(c, m.x, m.y, m.w, m.vertical, time);
    }
    for (var i = 0; i < room.chests.length; i++) {
      drawChest(c, room.chests[i], openedChests.contains(i), time);
    }
    for (final p in pickups) {
      drawPickup(c, p, time);
    }
    for (final e in enemies) {
      if (!e.isBoss) drawEnemy(c, e, time, player.body.cx);
    }
    for (final e in enemies) {
      if (e.isBoss) drawEnemy(c, e, time, player.body.cx);
    }
    drawPlayer(c, player, time, focus: player.focusT > 0);
    for (final o in orbitPositions) {
      drawOrbitOrb(c, o.dx, o.dy);
    }
    final col = arrowColor;
    for (final a in arrows) {
      drawArrow(c, a, col);
    }
    for (final h in hostiles) {
      drawHostile(c, h, time);
    }
    _drawBolts(c);
    fx.render(c);
    c.restore();
    _screenEffects(c);
    hud.render(c);
    if (input.touching && !input.usingKeys) _drawStick(c);
    if (fade > 0) c.drawRect(Rect.fromLTWH(0, 0, viewW, kViewH), Paint()..color = Color.fromRGBO(8, 14, 16, fade));
    c.restore();
  }

  void _drawBolts(Canvas c) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final b in bolts) {
      final path = Path()..moveTo(b.pts.first.dx, b.pts.first.dy);
      for (final pt in b.pts.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      final a = (b.life / 0.16).clamp(0.0, 1.0);
      p
        ..color = Color.fromRGBO(255, 230, 120, 0.5 * a)
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      c.drawPath(path, p);
      p
        ..color = Color.fromRGBO(255, 255, 230, a)
        ..strokeWidth = 2.5
        ..maskFilter = null;
      c.drawPath(path, p);
    }
  }

  void _screenEffects(Canvas c) {
    final rect = Rect.fromLTWH(0, 0, viewW, kViewH);
    final center = Offset(viewW / 2, kViewH / 2);
    if (worldScale < 0.97) {
      final k = (1 - worldScale) / 0.62;
      c.drawRect(
        rect,
        Paint()..shader = ui.Gradient.radial(center, viewW * 0.65, [const Color(0x005A8CFF), Color.fromRGBO(90, 140, 255, 0.35 * k)], const [0.55, 1]),
      );
    }
    final low = run.hp / run.maxHp < 0.3 ? 0.25 + 0.15 * math.sin(time * 6) : 0.0;
    final red = math.max(damageVignette * 0.55, low);
    if (red > 0) {
      c.drawRect(rect, Paint()..shader = ui.Gradient.radial(center, viewW * 0.62, [const Color(0x00FF3B3B), Color.fromRGBO(255, 59, 59, red)], const [0.5, 1]));
    }
    // 은은한 비네트
    c.drawRect(rect, Paint()..shader = ui.Gradient.radial(center, viewW * 0.75, [const Color(0x00000000), const Color(0x66050A0C)], const [0.6, 1]));
  }

  void _drawStick(Canvas c) {
    final o = input.origin / scale, cur = input.current / scale;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x40EFF4E8);
    c.drawCircle(o, 64 / scale, p);
    final d = cur - o;
    final lim = d.distance > 64 / scale ? d / d.distance * (64 / scale) : d;
    c.drawCircle(o + lim, 20 / scale, Paint()..color = const Color(0x55EFF4E8));
  }

  // ───────────────────────── EnemyHost ─────────────────────────
  @override
  Body get playerBody => player.body;

  @override
  void fireHostile(Hostile h) => hostiles.add(h);

  @override
  void spawnEnemy(EnemyKind kind, double x, double bottomY, {bool fromBoss = false}) {
    final e = Enemy(kind, x, bottomY, stage.power, rng)..fromBoss = fromBoss;
    enemies.add(e);
    fx.ring(x, bottomY - e.body.h / 2, Palette.violet, to: 46);
  }

  @override
  void sound(String name, {double volume = 1, int minGap = 35}) => Sfx.instance.play(name, volume: volume, minGapMs: minGap);

  @override
  void shakeCam(double t) => trauma = math.max(trauma, t);

  @override
  int countEnemies(EnemyKind kind) => enemies.where((e) => e.kind == kind && !e.dead).length;
}
