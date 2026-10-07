import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../app/art.dart';
import '../../app/theme.dart';
import '../entities/arrow.dart';
import '../entities/enemy.dart';
import '../entities/hostile.dart';
import '../entities/player.dart';
import '../rooms/room.dart';

final Paint _p = Paint();
final Paint _stroke = Paint()..style = PaintingStyle.stroke;
final Paint _glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

final TextPainter _bang = TextPainter(
  text: const TextSpan(
    text: '!',
    style: TextStyle(fontFamily: kDisplayFont, fontSize: 22, color: Color(0xFFFFFFFF)),
  ),
  textDirection: TextDirection.ltr,
)..layout();

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// 교체 이미지가 있으면 그 사각형에 그리고 true. (부위 좌표는 docs/ASSET_PIPELINE.md 의 피벗 표 참고)
bool _part(Canvas c, String id, Rect r, {Color? tint}) {
  final img = Art.instance.image(id);
  if (img == null) return false;
  drawArt(c, img, r, tint: tint);
  return true;
}

/// 공격 신호: 빨간 말풍선 느낌표
void drawBang(Canvas c, double x, double y, double time) {
  final s = 1 + 0.12 * math.sin(time * 22);
  c.save();
  c.translate(x, y);
  c.scale(s);
  _glow.color = Palette.danger.withValues(alpha: 0.6);
  c.drawCircle(Offset.zero, 15, _glow);
  _p.color = Palette.danger;
  c.drawCircle(Offset.zero, 12, _p);
  _bang.paint(c, Offset(-_bang.width / 2, -_bang.height / 2 - 1));
  c.restore();
}

// ───────────────────────── 플레이어 ─────────────────────────
void drawPlayer(Canvas c, Player pl, double time, {bool focus = false}) {
  final b = pl.body;
  if (pl.inv > 0 && (pl.inv * 16).floor().isOdd) return;
  // 스카프 (월드 좌표)
  if (pl.scarf.length > 1) {
    for (var i = 0; i < pl.scarf.length - 1; i++) {
      _stroke
        ..color = _mix(Palette.amber, const Color(0xFFE0874A), i / pl.scarf.length)
        ..strokeWidth = 5.5 - i * 0.7
        ..strokeCap = StrokeCap.round;
      c.drawLine(pl.scarf[i], pl.scarf[i + 1], _stroke);
    }
  }
  final face = pl.face.toDouble();
  final hurt = pl.hurtFlash > 0;
  c.save();
  c.translate(b.cx, b.bottom);
  c.rotate(pl.lean);
  c.scale(pl.sx * face, pl.sy);
  if (focus) {
    _glow.color = Palette.sky.withValues(alpha: 0.35 + 0.15 * math.sin(time * 10));
    c.drawOval(Rect.fromCenter(center: const Offset(0, -20), width: 46, height: 56), _glow);
  }
  final run = b.onGround && b.vx.abs() > 20;
  final air = !b.onGround;
  final hurtTint = hurt ? Palette.danger : null;
  // 부위 이미지가 없고 통짜 이미지(player/full)만 있으면 통째로 그리고 활만 따로 그려요.
  final fullArt = Art.instance.has('player/body') ? null : Art.instance.image('player/full');
  if (fullArt != null) {
    final bob = run ? math.sin(pl.runPhase * 2) * 1.2 : math.sin(time * 2.2) * 0.6;
    drawArtFeet(c, fullArt, 0, bob, 54, tint: hurtTint);
    _bow(c, pl, face);
    c.restore();
    return;
  }
  // 다리
  double legA, legB;
  if (air) {
    legA = b.vy < 0 ? -0.6 : -0.2;
    legB = b.vy < 0 ? 0.5 : 0.25;
  } else if (run) {
    legA = math.sin(pl.runPhase) * 0.75;
    legB = -legA;
  } else {
    legA = 0.08;
    legB = -0.08;
  }
  void leg(double ang, double x, Color col) {
    c.save();
    c.translate(x, -12);
    c.rotate(ang);
    if (!_part(c, x < 0 ? 'player/leg_back' : 'player/leg_front', const Rect.fromLTWH(-4, -1, 9, 14), tint: hurt ? Palette.danger : null)) {
      _p.color = col;
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2.6, 0, 5.2, 11), const Radius.circular(2.6)), _p);
      _p.color = const Color(0xFF5A3A22);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 8.5, 7.5, 4), const Radius.circular(2)), _p);
    }
    c.restore();
  }

  leg(legB, -3, const Color(0xFF243D30));
  // 망토 뒷자락
  final sway = math.sin(time * 6 + pl.runPhase * 0.5) * 2 + (b.vx.abs() / 255) * 6;
  if (!_part(c, 'player/cape', Rect.fromLTWH(-21 - sway, -33, 20 + sway, 28), tint: hurtTint)) {
    _p.color = hurt ? Palette.danger : Palette.cloakDark;
    c.drawPath(
      Path()
        ..moveTo(-6, -30)
        ..quadraticBezierTo(-16 - sway, -18, -14 - sway * 1.4, -7)
        ..lineTo(-2, -10)
        ..close(),
      _p,
    );
  }
  // 몸통
  if (!_part(c, 'player/body', const Rect.fromLTWH(-12, -34, 24, 28), tint: hurtTint)) {
    _p.shader = ui.Gradient.linear(
      const Offset(0, -32),
      const Offset(0, -8),
      hurt ? [const Color(0xFFFF8F8F), Palette.danger] : [const Color(0xFF63B97E), Palette.cloakDark],
    );
    c.drawPath(
      Path()
        ..moveTo(-8, -29)
        ..quadraticBezierTo(0, -33, 8, -29)
        ..lineTo(10, -10)
        ..quadraticBezierTo(0, -6, -10, -10)
        ..close(),
      _p,
    );
    _p.shader = null;
    // 허리띠
    _p.color = const Color(0xFF6E4726);
    c.drawRect(const Rect.fromLTWH(-9, -17, 19, 3), _p);
  }
  leg(legA, 3, const Color(0xFF2D4A3A));
  // 머리 (후드)
  final bob = run ? math.sin(pl.runPhase * 2) * 0.8 : math.sin(time * 2.2) * 0.6;
  c.translate(0, bob);
  if (!_part(c, 'player/head', const Rect.fromLTWH(-17, -53, 32, 30), tint: hurtTint)) {
    _p.color = hurt ? Palette.danger : Palette.cloak;
    c.drawCircle(const Offset(0, -35), 11.5, _p);
    c.drawPath(
      Path()
        ..moveTo(-9, -40)
        ..quadraticBezierTo(-14, -50, -19, -46)
        ..quadraticBezierTo(-14, -42, -8, -33)
        ..close(),
      _p,
    );
    _p.color = Palette.skin;
    c.drawCircle(const Offset(3, -33.5), 7.6, _p);
    // 앞머리
    _p.color = const Color(0xFF3E2A1C);
    c.drawPath(
      Path()
        ..moveTo(-3, -41)
        ..quadraticBezierTo(5, -43, 10, -37)
        ..quadraticBezierTo(4, -38, -1, -36)
        ..close(),
      _p,
    );
    // 눈 (깜빡임)
    final eyeH = pl.blink < 0 ? 0.6 : 3.4;
    _p.color = const Color(0xFF1A1A22);
    c.drawOval(Rect.fromCenter(center: const Offset(5.2, -33), width: 2.4, height: eyeH), _p);
    c.drawOval(Rect.fromCenter(center: const Offset(9.2, -33), width: 2.2, height: eyeH), _p);
    _p.color = const Color(0x66FF8FA8);
    c.drawCircle(const Offset(2.5, -29.5), 1.8, _p);
  }
  c.translate(0, -bob);
  _bow(c, pl, face);
  c.restore();
}

/// 활: 조준 방향으로 돌아가고 시위를 당겨요. (player/bow 이미지가 있으면 그걸로)
void _bow(Canvas c, Player pl, double face) {
  final la = math.atan2(math.sin(pl.aim), math.cos(pl.aim) * face);
  c.save();
  c.translate(6 - pl.recoil * 3, -22);
  c.rotate(la);
  final pull = pl.bowPull;
  if (_part(c, 'player/bow', Rect.fromLTWH(-6 - pull * 3, -16, 22, 32))) {
    c.restore();
    return;
  }
  _stroke
    ..color = const Color(0xFFB5813F)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  c.drawArc(Rect.fromCenter(center: const Offset(4, 0), width: 14 + pull * 2, height: 28), -1.25, 2.5, false, _stroke);
  final tipY = math.sin(1.25) * 14, tipX = 4 + math.cos(1.25) * (7 + pull);
  _stroke
    ..color = const Color(0xDDF4ECD8)
    ..strokeWidth = 1;
  c.drawLine(Offset(tipX, -tipY), Offset(tipX - pull * 9, 0), _stroke);
  c.drawLine(Offset(tipX - pull * 9, 0), Offset(tipX, tipY), _stroke);
  if (pull > 0.15) {
    _stroke
      ..color = Palette.cream
      ..strokeWidth = 2;
    c.drawLine(Offset(tipX - pull * 9, 0), Offset(tipX + 14, 0), _stroke);
  }
  // 손
  _p.color = Palette.skin;
  c.drawCircle(const Offset(2, 0), 3, _p);
  c.restore();
}

// ───────────────────────── 적 ─────────────────────────
void drawEnemy(Canvas c, Enemy e, double time, double playerX) {
  final b = e.body;
  final white = e.flash > 0;
  final blink = (time * 16).floor().isEven;
  final tele = e.telegraphing;
  var base = e.spec.color;
  if (e.slow > 0) base = _mix(base, Palette.sky, 0.45);
  if (tele && blink) base = _mix(base, Palette.danger, 0.65);
  if (white) base = const Color(0xFFFFFFFF);
  final spawnK = e.spawnIn > 0 ? 1 - e.spawnIn / (e.isBoss ? 0.8 : 0.35) : 1.0;
  final look = (playerX - b.cx).sign;

  // 킹 슬라임 착지 지점
  if (e.kind == EnemyKind.king && e.state == 'air') {
    final r = b.w * 0.6;
    _p.color = Palette.danger.withValues(alpha: 0.22 + 0.12 * math.sin(time * 18));
    c.drawOval(Rect.fromCenter(center: Offset(e.landX, e.floorY - 3), width: r * 2, height: 18), _p);
    _stroke
      ..color = Palette.danger.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    c.drawOval(Rect.fromCenter(center: Offset(e.landX, e.floorY - 3), width: r * 2, height: 18), _stroke);
  }
  // 박쥐·군주 돌진 조준선
  if ((e.kind == EnemyKind.bat && e.state == 'aim') || (e.kind == EnemyKind.lord && e.state == 'cast' && e.pattern == 'dash')) {
    final ex = b.cx + (e.lx - b.cx) * 1.8, ey = b.cy + (e.ly - b.cy) * 1.8;
    _stroke
      ..color = Palette.danger.withValues(alpha: blink ? 0.85 : 0.4)
      ..strokeWidth = e.isBoss ? 5 : 2.5;
    _dashed(c, Offset(b.cx, b.cy), Offset(ex, ey), _stroke);
  }

  c.save();
  c.translate(b.cx, b.bottom);
  c.scale(e.sx * spawnK, e.sy * spawnK);
  // 교체 이미지: monster/<id>.png (공격 예고 중이면 <id>_charge.png 가 있으면 그걸로). 오른쪽을 보는 그림 기준.
  final artId = 'monster/${enemyArtId(e.kind)}';
  final art = (tele ? Art.instance.image('${artId}_charge') : null) ?? Art.instance.image(artId);
  if (art != null) {
    final bob = e.spec.flying ? math.sin(time * 6 + b.x) * 3 : 0.0;
    final tint = white
        ? const Color(0xFFFFFFFF)
        : (tele && blink)
        ? const Color(0x99FF5A4F)
        : e.slow > 0
        ? const Color(0x668FD3FF)
        : null;
    drawArtFeet(c, art, 0, bob, b.h * (e.isBoss ? 1.25 : 1.35), flipX: look < 0, tint: tint);
  } else {
    switch (e.kind) {
      case EnemyKind.slime || EnemyKind.splitter || EnemyKind.splitling || EnemyKind.king:
        _slimeBody(c, b.w, b.h, base, look, e.kind, white, time);
      case EnemyKind.mushroom:
        final k = e.state == 'charge' ? 1 + 0.4 * (1 - e.tele / 0.75) : 1.0;
        if (e.state == 'charge') {
          _glow.color = Palette.danger.withValues(alpha: 0.3);
          c.drawCircle(Offset(0, -22 * k), 26 * k, _glow);
        }
        _p.color = white ? const Color(0xFFFFFFFF) : const Color(0xFFF0E2C4);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -18, 14, 18), const Radius.circular(5)), _p);
        _p.color = const Color(0xFF1B2422);
        c.drawOval(Rect.fromCenter(center: Offset(-3 + look * 1.5, -11), width: 2.4, height: 3.6), _p);
        c.drawOval(Rect.fromCenter(center: Offset(3 + look * 1.5, -11), width: 2.4, height: 3.6), _p);
        _p.shader = ui.Gradient.linear(Offset(0, -34 * k), const Offset(0, -16), [_mix(base, const Color(0xFFFFFFFF), 0.25), base]);
        c.drawArc(Rect.fromCenter(center: const Offset(0, -16), width: 36 * k, height: 30 * k), math.pi, math.pi, true, _p);
        _p.shader = null;
        _p.color = const Color(0xE6FFF2E0);
        c.drawCircle(Offset(-8 * k, -24 * k), 3 * k, _p);
        c.drawCircle(Offset(5 * k, -28 * k), 2.6 * k, _p);
        c.drawCircle(Offset(10 * k, -20 * k), 2 * k, _p);
      case EnemyKind.bat:
        final flap = math.sin(time * 18 + b.x) * 9;
        _p.color = base;
        for (final s in [-1.0, 1.0]) {
          c.drawPath(
            Path()
              ..moveTo(s * 5, -10)
              ..quadraticBezierTo(s * 16, -22 - flap, s * 22, -12 - flap)
              ..quadraticBezierTo(s * 17, -10, s * 19, -4 - flap * 0.3)
              ..quadraticBezierTo(s * 12, -8, s * 5, -6)
              ..close(),
            _p,
          );
        }
        c.drawCircle(const Offset(0, -9), 9, _p);
        c.drawPath(
          Path()
            ..moveTo(-6, -15)
            ..lineTo(-4, -22)
            ..lineTo(-1, -16)
            ..moveTo(6, -15)
            ..lineTo(4, -22)
            ..lineTo(1, -16),
          _p,
        );
        _p.color = const Color(0xFFFFE07A);
        c.drawCircle(Offset(-3 + look, -10), 1.8, _p);
        c.drawCircle(Offset(3 + look, -10), 1.8, _p);
      case EnemyKind.wisp:
        final fl = math.sin(time * 9) * 3;
        _glow.color = base.withValues(alpha: 0.5);
        c.drawCircle(const Offset(0, -14), 20, _glow);
        _p.shader = ui.Gradient.radial(const Offset(0, -12), 18, [const Color(0xFFFFFFFF), base, base.withValues(alpha: 0)], const [0, 0.5, 1]);
        c.drawPath(
          Path()
            ..moveTo(0, -30 - fl)
            ..quadraticBezierTo(14, -18, 10, -6)
            ..quadraticBezierTo(0, 2 + fl, -10, -6)
            ..quadraticBezierTo(-14, -18, 0, -30 - fl)
            ..close(),
          _p,
        );
        _p.shader = null;
        _p.color = const Color(0xFF16303A);
        c.drawCircle(Offset(-3.5 + look * 1.5, -13), 2.2, _p);
        c.drawCircle(Offset(3.5 + look * 1.5, -13), 2.2, _p);
        if (e.state == 'cast') {
          _stroke
            ..color = Palette.sky.withValues(alpha: 0.8)
            ..strokeWidth = 2;
          c.drawCircle(const Offset(0, -14), 22 + 6 * math.sin(time * 20), _stroke);
        }
      case EnemyKind.lord:
        _lordBody(c, b.w, b.h, base, look, white, time, e);
    }
  }
  c.restore();

  if (e.frozen > 0 && !(e.frozen < 0.6 && blink)) {
    _p.color = const Color(0xB8BEEBFF);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.x - 3, b.y - 3, b.w + 6, b.h + 6), const Radius.circular(6)), _p);
    _p.color = const Color(0xDDFFFFFF);
    c.drawRect(Rect.fromLTWH(b.x + 2, b.y, b.w * 0.5, 3), _p);
    c.drawRect(Rect.fromLTWH(b.x + 2, b.y + 4, 3, b.h * 0.4), _p);
  }
  if (tele) drawBang(c, b.cx, b.y - (e.isBoss ? 34 : 18), time);
  if (!e.isBoss && e.hp < e.maxHp && e.spawnIn <= 0) {
    _p.color = const Color(0x99000000);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.cx - 16, b.y - 9, 32, 4), const Radius.circular(2)), _p);
    _p.color = const Color(0xFFFF7A7A);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.cx - 16, b.y - 9, 32 * (e.hp / e.maxHp).clamp(0, 1), 4), const Radius.circular(2)), _p);
  }
}

void _slimeBody(Canvas c, double w, double h, Color base, double look, EnemyKind kind, bool white, double time) {
  final big = kind == EnemyKind.king;
  final path = Path()
    ..moveTo(-w / 2, 0)
    ..lineTo(-w / 2, -h * 0.45)
    ..quadraticBezierTo(-w / 2, -h, 0, -h)
    ..quadraticBezierTo(w / 2, -h, w / 2, -h * 0.45)
    ..lineTo(w / 2, 0)
    ..close();
  _p.shader = ui.Gradient.linear(
    Offset(0, -h),
    Offset.zero,
    [_mix(base, const Color(0xFFFFFFFF), 0.3), base, _mix(base, const Color(0xFF000000), 0.25)],
    const [0, 0.55, 1],
  );
  c.drawPath(path, _p);
  _p.shader = null;
  _p.color = const Color(0x66FFFFFF);
  c.drawOval(Rect.fromCenter(center: Offset(-w * 0.22, -h * 0.72), width: w * 0.2, height: h * 0.18), _p);
  if (kind == EnemyKind.splitter) {
    _p.color = const Color(0xCCE6F7FF);
    for (final (dx, dy) in [(-0.2, 0.4), (0.18, 0.3), (0.05, 0.62)]) {
      c.drawPath(
        Path()
          ..moveTo(w * dx, -h * dy - 5)
          ..lineTo(w * dx + 4, -h * dy)
          ..lineTo(w * dx, -h * dy + 5)
          ..lineTo(w * dx - 4, -h * dy)
          ..close(),
        _p,
      );
    }
  }
  final eyeR = big ? 7.0 : w * 0.08;
  _p.color = const Color(0xFF1B2422);
  c.drawCircle(Offset(-w * 0.14 + look * w * 0.06, -h * 0.48), eyeR, _p);
  c.drawCircle(Offset(w * 0.14 + look * w * 0.06, -h * 0.48), eyeR, _p);
  _p.color = const Color(0xCCFFFFFF);
  c.drawCircle(Offset(-w * 0.14 + look * w * 0.06 + eyeR * 0.3, -h * 0.48 - eyeR * 0.35), eyeR * 0.35, _p);
  c.drawCircle(Offset(w * 0.14 + look * w * 0.06 + eyeR * 0.3, -h * 0.48 - eyeR * 0.35), eyeR * 0.35, _p);
  if (big) {
    _p.color = white ? const Color(0xFFFFFFFF) : Palette.gold;
    c.drawPath(
      Path()
        ..moveTo(-w * 0.22, -h + 8)
        ..lineTo(-w * 0.2, -h - 16)
        ..lineTo(-w * 0.09, -h - 4)
        ..lineTo(0, -h - 22)
        ..lineTo(w * 0.09, -h - 4)
        ..lineTo(w * 0.2, -h - 16)
        ..lineTo(w * 0.22, -h + 8)
        ..close(),
      _p,
    );
    _p.color = Palette.rose;
    c.drawCircle(Offset(0, -h - 6), 3.5, _p);
    // 볼 터치
    _p.color = const Color(0x55FF6B9A);
    c.drawCircle(Offset(-w * 0.28, -h * 0.34), 7, _p);
    c.drawCircle(Offset(w * 0.28, -h * 0.34), 7, _p);
  }
}

void _lordBody(Canvas c, double w, double h, Color base, double look, bool white, double time, Enemy e) {
  final casting = e.state == 'cast';
  if (casting) {
    _glow.color = Palette.violet.withValues(alpha: 0.45 + 0.2 * math.sin(time * 14));
    c.drawCircle(Offset(0, -h * 0.55), w * 0.9, _glow);
  }
  // 망토 몸통
  final sway = math.sin(time * 2) * 4;
  _p.shader = ui.Gradient.linear(
    Offset(0, -h * 0.7),
    Offset.zero,
    white ? [const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)] : [const Color(0xFF4B3A78), const Color(0xFF1F1838)],
  );
  c.drawPath(
    Path()
      ..moveTo(-w * 0.3, -h * 0.66)
      ..quadraticBezierTo(-w * 0.6 + sway, -h * 0.2, -w * 0.45 + sway, 0)
      ..quadraticBezierTo(0, -h * 0.08, w * 0.45 + sway, 0)
      ..quadraticBezierTo(w * 0.6 + sway, -h * 0.2, w * 0.3, -h * 0.66)
      ..close(),
    _p,
  );
  _p.shader = null;
  // 얼굴 그림자 + 눈
  _p.color = const Color(0xFF120E22);
  c.drawOval(Rect.fromCenter(center: Offset(0, -h * 0.62), width: w * 0.5, height: h * 0.2), _p);
  _p.color = casting ? Palette.danger : const Color(0xFFFFE07A);
  c.drawCircle(Offset(-w * 0.1 + look * 3, -h * 0.62), 3.4, _p);
  c.drawCircle(Offset(w * 0.1 + look * 3, -h * 0.62), 3.4, _p);
  // 커다란 버섯 모자
  _p.shader = ui.Gradient.linear(
    Offset(0, -h * 1.05),
    Offset(0, -h * 0.68),
    white ? [const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)] : [const Color(0xFFD9A8FF), base],
  );
  c.drawArc(Rect.fromCenter(center: Offset(0, -h * 0.7), width: w * 1.5, height: h * 0.62), math.pi, math.pi, true, _p);
  _p.shader = null;
  for (var i = 0; i < 5; i++) {
    final a = 0.5 + 0.5 * math.sin(time * 3 + i);
    _p.color = Color.fromRGBO(255, 240, 200, 0.5 + 0.4 * a);
    c.drawCircle(Offset(-w * 0.5 + i * w * 0.25, -h * 0.82 - (i % 2) * 8), 3 + (i % 3).toDouble(), _p);
  }
}

void _dashed(Canvas c, Offset a, Offset b, Paint p) {
  final d = b - a;
  final len = d.distance;
  if (len < 1) return;
  final u = d / len;
  for (var s = 0.0; s < len; s += 16) {
    c.drawLine(a + u * s, a + u * math.min(len, s + 9), p);
  }
}

// ───────────────────────── 투사체 ─────────────────────────
void drawArrow(Canvas c, Arrow a, Color color) {
  if (a.trail.length > 1) {
    for (var i = 0; i < a.trail.length - 1; i++) {
      final k = i / a.trail.length;
      _stroke
        ..color = color.withValues(alpha: 0.5 * k)
        ..strokeWidth = 1 + 3 * k
        ..strokeCap = StrokeCap.round;
      c.drawLine(a.trail[i], a.trail[i + 1], _stroke);
    }
  }
  final ang = math.atan2(a.vy, a.vx);
  c.save();
  c.translate(a.x, a.y);
  c.rotate(ang);
  if (a.bounced > 0) {
    final k = math.min(1.0, a.bounced / 4);
    c.scale(1 + k * 0.35);
    _glow.color = Color.lerp(const Color(0x88FFE9A8), const Color(0xCCFFB347), k)!;
    c.drawCircle(Offset.zero, 8 + k * 6, _glow);
  }
  if (a.crit) {
    _glow.color = Palette.gold.withValues(alpha: 0.7);
    c.drawCircle(Offset.zero, 9, _glow);
  }
  _stroke
    ..color = color
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(-20, 0), const Offset(2, 0), _stroke);
  _p.color = a.crit ? Palette.gold : const Color(0xFFF4ECD8);
  c.drawPath(
    Path()
      ..moveTo(9, 0)
      ..lineTo(0, -4.5)
      ..lineTo(2, 0)
      ..lineTo(0, 4.5)
      ..close(),
    _p,
  );
  _p.color = const Color(0xCCFFFFFF);
  c.drawPath(
    Path()
      ..moveTo(-21, 0)
      ..lineTo(-26, -5)
      ..lineTo(-17, 0)
      ..lineTo(-26, 5)
      ..close(),
    _p,
  );
  c.restore();
}

void drawHostile(Canvas c, Hostile h, double time) {
  switch (h.kind) {
    case HostileKind.rain when h.warn > 0:
      final k = (time * 10).floor().isEven ? 0.85 : 0.5;
      _p.color = h.color.withValues(alpha: 0.18);
      c.drawOval(Rect.fromCenter(center: Offset(h.x, h.y - 3), width: 64, height: 16), _p);
      _stroke
        ..color = Palette.danger.withValues(alpha: k)
        ..strokeWidth = 2.4;
      c.drawOval(Rect.fromCenter(center: Offset(h.x, h.y - 3), width: 64 * (1 - h.warn * 0.4), height: 16), _stroke);
    case HostileKind.wave:
      _glow.color = h.color.withValues(alpha: 0.5);
      c.drawOval(Rect.fromCenter(center: Offset(h.x, h.y + 4), width: 44, height: 30), _glow);
      _p.color = h.color;
      final dir = h.vx.sign;
      c.drawPath(
        Path()
          ..moveTo(h.x - dir * 18, h.y + 14)
          ..quadraticBezierTo(h.x + dir * 4, h.y - 22, h.x + dir * 16, h.y + 14)
          ..close(),
        _p,
      );
      _p.color = const Color(0xCCFFFFFF);
      c.drawCircle(Offset(h.x + dir * 6, h.y - 2), 3, _p);
    default:
      _glow.color = h.color.withValues(alpha: 0.55);
      c.drawCircle(Offset(h.x, h.y), h.r * 1.9, _glow);
      _p.color = h.color;
      c.drawCircle(Offset(h.x, h.y), h.r, _p);
      _p.color = const Color(0xDDFFFFFF);
      c.drawCircle(Offset(h.x - h.r * 0.3, h.y - h.r * 0.3), h.r * 0.35, _p);
  }
}

// ───────────────────────── 아이템·포털·상자 ─────────────────────────
void drawPickup(Canvas c, Pickup p, double time) {
  switch (p.kind) {
    case PickupKind.xp:
      _glow.color = const Color(0x99C8FF8A);
      c.drawCircle(Offset(p.x, p.y), 7, _glow);
      _p.color = const Color(0xFFE6FFB0);
      c.drawCircle(Offset(p.x, p.y), 3.4, _p);
    case PickupKind.coin:
      final sx = math.cos(time * 6 + p.x * 0.05).abs() * 0.85 + 0.15;
      final coinArt = Art.instance.image('item/coin');
      if (coinArt != null) {
        drawArt(c, coinArt, Rect.fromCenter(center: Offset(p.x, p.y), width: 18 * sx, height: 18));
        return;
      }
      _glow.color = Palette.gold.withValues(alpha: 0.35);
      c.drawCircle(Offset(p.x, p.y), 11, _glow);
      _p.color = const Color(0xFFE0A93A);
      c.drawOval(Rect.fromCenter(center: Offset(p.x, p.y), width: 16 * sx, height: 16), _p);
      _p.color = Palette.gold;
      c.drawOval(Rect.fromCenter(center: Offset(p.x, p.y), width: 11 * sx, height: 11), _p);
      _p.color = const Color(0xCCFFF6D0);
      c.drawRect(Rect.fromCenter(center: Offset(p.x, p.y), width: 2 * sx, height: 6), _p);
    case PickupKind.heal:
      final healArt = Art.instance.image('item/heal_heart');
      if (healArt != null) {
        drawArt(c, healArt, Rect.fromCenter(center: Offset(p.x, p.y), width: 22, height: 22));
        return;
      }
      _glow.color = const Color(0x88FF7A9A);
      c.drawCircle(Offset(p.x, p.y), 12, _glow);
      drawHeart(c, Offset(p.x, p.y - 6), 14, const Color(0xFFFF6B88));
    case PickupKind.shard:
      drawShard(c, p.x, p.y + math.sin(time * 2.5) * 4, time, 1);
  }
}

void drawShard(Canvas c, double x, double y, double time, double scale) {
  final art = Art.instance.image('item/dream_shard');
  if (art != null) {
    _glow.color = const Color(0x99A9E6FF);
    c.drawCircle(Offset(x, y), 18 * scale, _glow);
    drawArt(c, art, Rect.fromCenter(center: Offset(x, y), width: 30 * scale, height: 30 * scale));
    return;
  }
  c.save();
  c.translate(x, y);
  c.scale(scale);
  _glow.color = const Color(0x99A9E6FF);
  c.drawCircle(Offset.zero, 18 + 3 * math.sin(time * 4), _glow);
  c.rotate(math.sin(time * 1.5) * 0.25);
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? 13.0 : 5.5;
    final a = -math.pi / 2 + i * math.pi / 5;
    i == 0 ? path.moveTo(math.cos(a) * r, math.sin(a) * r) : path.lineTo(math.cos(a) * r, math.sin(a) * r);
  }
  path.close();
  _p.shader = ui.Gradient.linear(const Offset(0, -13), const Offset(0, 13), const [Color(0xFFFFFFFF), Color(0xFF9FD8FF), Color(0xFFB993FF)], const [0, 0.5, 1]);
  c.drawPath(path, _p);
  _p.shader = null;
  c.restore();
}

void drawHeart(Canvas c, Offset o, double s, Color color) {
  final x = o.dx, y = o.dy;
  final path = Path()
    ..moveTo(x, y + s * 0.3)
    ..cubicTo(x, y, x - s * 0.5, y, x - s * 0.5, y + s * 0.3)
    ..cubicTo(x - s * 0.5, y + s * 0.6, x, y + s * 0.8, x, y + s)
    ..cubicTo(x, y + s * 0.8, x + s * 0.5, y + s * 0.6, x + s * 0.5, y + s * 0.3)
    ..cubicTo(x + s * 0.5, y, x, y, x, y + s * 0.3)
    ..close();
  _p.color = color;
  c.drawPath(path, _p);
}

void drawPortal(Canvas c, Room room, bool open, double time, double openAnim) {
  final cx = room.portalX + Room.portalW / 2, cy = room.portalY + Room.portalH / 2;
  final art = Art.instance.image(open ? 'item/portal_open' : 'item/portal_closed');
  if (art != null) {
    if (open) {
      _glow.color = const Color(0x8890FFB8);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 80 + openAnim * 30, height: 110 + openAnim * 30), _glow);
    }
    drawArtFeet(c, art, cx, room.portalY + Room.portalH + 4, 96);
    return;
  }
  c.save();
  c.translate(cx, cy);
  if (open) {
    _glow.color = const Color(0x8890FFB8);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 70 + openAnim * 30, height: 100 + openAnim * 30), _glow);
    _p.shader = ui.Gradient.radial(Offset.zero, 46, const [Color(0xFFFFFFFF), Color(0xFF9AF5C2), Color(0x0090FFB8)], const [0, 0.35, 1]);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 52, height: 82), _p);
    _p.shader = null;
  } else {
    _p.color = const Color(0x22A0B0B0);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 52, height: 82), _p);
  }
  for (var i = 0; i < 3; i++) {
    final rot = time * (open ? 2.6 : 0.5) + i * 2.1;
    _stroke
      ..color = open ? (i == 0 ? const Color(0xFF8BF0B0) : Palette.amber).withValues(alpha: 0.9 - i * 0.2) : const Color(0x6696A6A6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawArc(Rect.fromCenter(center: Offset.zero, width: 40.0 - i * 8, height: 74.0 - i * 14), rot, 4.0, false, _stroke);
  }
  // 바닥 돌 받침
  _p.color = const Color(0xFF55605E);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 40), width: 56, height: 8), const Radius.circular(4)), _p);
  c.restore();
}

void drawChest(Canvas c, Spot s, bool opened, double time) {
  final x = s.x, y = s.y;
  final art = Art.instance.image(opened ? 'item/chest_open' : 'item/chest_closed');
  if (art != null) {
    if (!opened) {
      _glow.color = Palette.gold.withValues(alpha: 0.35 + 0.15 * math.sin(time * 4));
      c.drawOval(Rect.fromCenter(center: Offset(x, y - 16), width: 70, height: 50), _glow);
    }
    drawArtFeet(c, art, x, y, 40);
    return;
  }
  final bob = opened ? 0.0 : math.sin(time * 3) * 1.5;
  if (!opened) {
    _glow.color = Palette.gold.withValues(alpha: 0.35 + 0.15 * math.sin(time * 4));
    c.drawOval(Rect.fromCenter(center: Offset(x, y - 16), width: 70, height: 50), _glow);
  }
  _p.shader = ui.Gradient.linear(Offset(x, y - 26), Offset(x, y), const [Color(0xFFB07A44), Color(0xFF6E4726)]);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, y - 22 + bob, 40, 22), const Radius.circular(3)), _p);
  _p.shader = null;
  c.save();
  c.translate(x - 20, y - 22 + bob);
  if (opened) c.rotate(-0.9);
  _p.color = const Color(0xFFC08A50);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -12, 40, 13), Radius.circular(6)), _p);
  _p.color = Palette.gold;
  c.drawRect(const Rect.fromLTWH(0, -2, 40, 3), _p);
  c.restore();
  _p.color = Palette.gold;
  c.drawRect(Rect.fromLTWH(x - 3, y - 16 + bob, 6, 8), _p);
}

void drawOrbitOrb(Canvas c, double x, double y) {
  _glow.color = const Color(0xAA9FE8FF);
  c.drawCircle(Offset(x, y), 12, _glow);
  _p.color = const Color(0xFFE6FAFF);
  c.drawCircle(Offset(x, y), 6, _p);
}
