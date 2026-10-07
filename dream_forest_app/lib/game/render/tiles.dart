import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../app/theme.dart';
import '../constants.dart';
import '../rooms/room.dart';

int _hash(int x, int y) {
  var h = x * 374761393 + y * 668265263;
  h = (h ^ (h >> 13)) * 1274126177;
  return (h ^ (h >> 16)) & 0x7fffffff;
}

/// 땅·발판처럼 움직이지 않는 타일은 방마다 한 번 그려서 Picture 로 저장해요.
ui.Picture bakeStaticTiles(Room room) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final p = Paint();
  const t = kTile;
  bool solid(int x, int y) => room.cellAt(x, y) == Cell.solid || (x < 0 || x >= room.w) || y >= room.h && room.cellAt(x, room.h - 1) == Cell.solid;

  // 1) 흙 덩어리: 표면에서 깊어질수록 어두워져요.
  for (var y = 0; y < room.h; y++) {
    for (var x = 0; x < room.w; x++) {
      if (room.cells[y][x] != Cell.solid) continue;
      var depth = 0;
      while (depth < 5 && y - depth - 1 >= 0 && room.cells[y - depth - 1][x] == Cell.solid) {
        depth++;
      }
      final k = depth / 5;
      p.color = Color.lerp(const Color(0xFF314A47), const Color(0xFF142224), k)!;
      c.drawRect(Rect.fromLTWH(x * t - 0.5, y * t - 0.5, t + 1, t + 1), p);
      final hsh = _hash(x, y);
      // 돌멩이·뿌리 무늬
      if (hsh % 3 == 0) {
        p.color = Color.fromRGBO(255, 255, 255, 0.045 + (hsh % 5) * 0.006);
        c.drawOval(Rect.fromLTWH(x * t + 6 + hsh % 18, y * t + 10 + (hsh >> 3) % 18, 10 + hsh % 6, 6), p);
      }
      if (hsh % 7 == 1 && depth > 0) {
        p
          ..color = const Color(0x22000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        c.drawPath(
          Path()
            ..moveTo(x * t + 8, y * t + 4)
            ..quadraticBezierTo(x * t + 22, y * t + 18, x * t + 14, y * t + 36),
          p,
        );
        p.style = PaintingStyle.fill;
      }
      // 옆면 그늘
      if (!solid(x - 1, y)) {
        p.color = const Color(0x33000000);
        c.drawRect(Rect.fromLTWH(x * t, y * t, 4, t), p);
      }
      if (!solid(x + 1, y)) {
        p.color = const Color(0x40000000);
        c.drawRect(Rect.fromLTWH(x * t + t - 5, y * t, 5, t), p);
      }
      // 아래가 비어 있으면 매달린 뿌리
      if (y + 1 < room.h && room.cells[y + 1][x] != Cell.solid) {
        p.color = const Color(0x55000000);
        c.drawRect(Rect.fromLTWH(x * t, y * t + t - 6, t, 6), p);
        if (hsh % 2 == 0) {
          p
            ..color = const Color(0xFF2B4A3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          final rx = x * t + 10 + hsh % 20;
          c.drawPath(
            Path()
              ..moveTo(rx, y * t + t)
              ..quadraticBezierTo(rx + 6, y * t + t + 10, rx - 2, y * t + t + 18 + hsh % 10),
            p,
          );
          p.style = PaintingStyle.fill;
        }
      }
    }
  }

  // 2) 풀 덮개: 위가 열린 땅 위로 둥근 잔디 띠 + 풀잎 + 작은 꽃
  for (var y = 0; y < room.h; y++) {
    var x = 0;
    while (x < room.w) {
      final surface = room.cells[y][x] == Cell.solid && (y == 0 || room.cells[y - 1][x] != Cell.solid);
      if (!surface) {
        x++;
        continue;
      }
      final x0 = x;
      while (x < room.w && room.cells[y][x] == Cell.solid && (y == 0 || room.cells[y - 1][x] != Cell.solid)) {
        x++;
      }
      final left = x0 * t - 2, right = x * t + 2;
      final cap = RRect.fromLTRBAndCorners(
        left,
        y * t - 3,
        right,
        y * t + 9,
        topLeft: Radius.circular(solid(x0 - 1, y) ? 0 : 7),
        topRight: Radius.circular(solid(x, y) ? 0 : 7),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      );
      p.shader = ui.Gradient.linear(Offset(0, y * t - 3), Offset(0, y * t + 9), const [Color(0xFF8EDB93), Color(0xFF4E9E63)]);
      c.drawRRect(cap, p);
      p.shader = null;
      // 풀잎
      for (var gx = left + 3; gx < right - 3; gx += 5) {
        final hh = _hash(gx.toInt(), y);
        final gh = 3.0 + hh % 6;
        p.color = hh % 3 == 0 ? const Color(0xFF9BE59E) : const Color(0xFF6CC27E);
        c.drawPath(
          Path()
            ..moveTo(gx - 2, y * t)
            ..lineTo(gx + (hh % 3 - 1).toDouble(), y * t - gh)
            ..lineTo(gx + 2, y * t)
            ..close(),
          p,
        );
        if (hh % 41 == 0) {
          p.color = hh % 2 == 0 ? const Color(0xFFFFD6E7) : const Color(0xFFFFE9A8);
          c.drawCircle(Offset(gx, y * t - gh - 1), 2.2, p);
        }
      }
      // 풀 아래 이끼 늘어짐
      p.color = const Color(0x6643915A);
      for (var gx = left + 6; gx < right - 6; gx += 13) {
        final hh = _hash(gx.toInt(), y + 99);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gx, y * t + 7, 4, 4.0 + hh % 7), const Radius.circular(2)), p);
      }
    }
  }

  // 3) 나무 발판(위에서만 밟힘)
  for (var y = 0; y < room.h; y++) {
    var x = 0;
    while (x < room.w) {
      if (room.cells[y][x] != Cell.oneWay) {
        x++;
        continue;
      }
      final x0 = x;
      while (x < room.w && room.cells[y][x] == Cell.oneWay) {
        x++;
      }
      paintPlank(c, x0 * t, y * t, (x - x0) * t, const Color(0xFFA9773F), const Color(0xFF6C4423));
    }
  }

  // 4) 가시
  for (var y = 0; y < room.h; y++) {
    for (var x = 0; x < room.w; x++) {
      if (room.cells[y][x] != Cell.spike) continue;
      p.color = const Color(0xFF8C5BB8);
      for (var i = 0; i < 4; i++) {
        final bx = x * t + 2 + i * 9.5;
        c.drawPath(
          Path()
            ..moveTo(bx, y * t + t)
            ..lineTo(bx + 4.5, y * t + 14)
            ..lineTo(bx + 9, y * t + t)
            ..close(),
          p,
        );
      }
    }
  }
  return rec.endRecording();
}

void paintPlank(Canvas c, double x, double y, double w, Color wood, Color dark, {double alpha = 1, double jitter = 0}) {
  final p = Paint();
  final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x + jitter, y, w, 13), const Radius.circular(4));
  p.shader = ui.Gradient.linear(
    Offset(0, y),
    Offset(0, y + 13),
    [Color.lerp(wood, const Color(0xFFFFFFFF), 0.15)!.withValues(alpha: alpha), wood.withValues(alpha: alpha), dark.withValues(alpha: alpha)],
    const [0, 0.45, 1],
  );
  c.drawRRect(rect, p);
  p.shader = null;
  p.color = dark.withValues(alpha: 0.8 * alpha);
  for (var sx = x + kTile; sx < x + w - 1; sx += kTile) {
    c.drawRect(Rect.fromLTWH(sx + jitter - 1, y + 1, 2, 11), p);
  }
  p.color = const Color(0xFFE9D2A6).withValues(alpha: 0.7 * alpha);
  c.drawCircle(Offset(x + 5 + jitter, y + 6.5), 1.6, p);
  c.drawCircle(Offset(x + w - 5 + jitter, y + 6.5), 1.6, p);
  // 받침대
  p.color = dark.withValues(alpha: alpha);
  c.drawPath(
    Path()
      ..moveTo(x + 6 + jitter, y + 12)
      ..lineTo(x + 14 + jitter, y + 12)
      ..lineTo(x + 8 + jitter, y + 22)
      ..close(),
    p,
  );
  c.drawPath(
    Path()
      ..moveTo(x + w - 6 + jitter, y + 12)
      ..lineTo(x + w - 14 + jitter, y + 12)
      ..lineTo(x + w - 8 + jitter, y + 22)
      ..close(),
    p,
  );
}

/// 시간에 따라 바뀌는 타일: 부서지는 발판, 수정 다리, 가시덩굴, 스프링 버섯, 수정.
void paintDynamicTiles(Canvas c, Room room, double time, Rect view) {
  const t = kTile;
  final p = Paint();
  final x0 = math.max(0, (view.left / t).floor() - 1), x1 = math.min(room.w - 1, (view.right / t).ceil() + 1);
  final y0 = math.max(0, (view.top / t).floor() - 1), y1 = math.min(room.h - 1, (view.bottom / t).ceil() + 1);
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final cell = room.cells[y][x];
      switch (cell) {
        case Cell.crumble:
          final st = room.crumbles[y * room.w + x]!;
          if (st.down > 0) {
            p
              ..color = Color.fromRGBO(220, 200, 160, st.down < 0.6 ? 0.35 : 0.08)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x * t + 2, y * t + 1, t - 4, 11), const Radius.circular(4)), p);
            p.style = PaintingStyle.fill;
          } else {
            final jit = st.shake >= 0 ? math.sin(time * 70 + x) * 2.2 : 0.0;
            paintPlank(c, x * t, y * t, t, const Color(0xFFC9A57A), const Color(0xFF7A5634), jitter: jit);
            p
              ..color = const Color(0xFF4A3220)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4;
            c.drawPath(
              Path()
                ..moveTo(x * t + 12 + jit, y * t + 1)
                ..lineTo(x * t + 18 + jit, y * t + 6)
                ..lineTo(x * t + 15 + jit, y * t + 12)
                ..moveTo(x * t + 28 + jit, y * t + 1)
                ..lineTo(x * t + 25 + jit, y * t + 8),
              p,
            );
            p.style = PaintingStyle.fill;
          }
        case Cell.bridge:
          final on = room.bridgeTimer > 0;
          final warn = on && room.bridgeTimer < 2 && (time * 8).floor().isEven;
          if (on) {
            final a = warn ? 0.45 : 1.0;
            p.color = Palette.violet.withValues(alpha: 0.22 * a);
            c.drawRect(Rect.fromLTWH(x * t, y * t - 6, t, 26), p);
            p.color = const Color(0xFF8F6BD6).withValues(alpha: a);
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x * t + 1, y * t, t - 2, 12), const Radius.circular(3)), p);
            p.color = const Color(0xFFE6D8FF).withValues(alpha: a);
            c.drawRect(Rect.fromLTWH(x * t + 6, y * t + 3, t - 12, 2), p);
          } else {
            p
              ..color = Palette.violet.withValues(alpha: 0.18 + 0.08 * math.sin(time * 3 + x))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2;
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x * t + 3, y * t + 1, t - 6, 10), const Radius.circular(3)), p);
            p.style = PaintingStyle.fill;
          }
        case Cell.thorn:
          _thorn(c, p, x, y, room.thornWarn(x, y), room.thornActive(x, y), time);
        case Cell.spring:
          final anim = room.springAnim[y * room.w + x] ?? 0;
          _spring(c, p, x * t, y * t, anim, time);
        case Cell.crystal:
          final on = room.bridgeTimer > 0;
          final cx = x * t + t / 2, cy = y * t + t / 2 + math.sin(time * 2.4) * 3;
          final col = on ? const Color(0xFF7DFFB2) : Palette.violet;
          c.drawCircle(
            Offset(cx, cy),
            26 + 3 * math.sin(time * 4),
            Paint()
              ..color = col.withValues(alpha: 0.22)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          );
          p.color = col;
          c.drawPath(
            Path()
              ..moveTo(cx, cy - 18)
              ..lineTo(cx + 11, cy)
              ..lineTo(cx, cy + 18)
              ..lineTo(cx - 11, cy)
              ..close(),
            p,
          );
          p.color = const Color(0xCCFFFFFF);
          c.drawPath(
            Path()
              ..moveTo(cx - 2, cy - 12)
              ..lineTo(cx + 3, cy - 3)
              ..lineTo(cx - 3, cy)
              ..close(),
            p,
          );
      }
    }
  }
}

void _thorn(Canvas c, Paint p, int x, int y, double warn, bool active, double time) {
  const t = kTile;
  final base = y * t + t;
  if (warn > 0 && !active) {
    // 곧 튀어나와요: 빨갛게 흔들림
    p.color = Palette.danger.withValues(alpha: 0.25 * warn);
    c.drawRect(Rect.fromLTWH(x * t, base - 10, t, 10), p);
  }
  final grow = active ? 1.0 : warn * 0.25;
  final shake = (!active && warn > 0) ? math.sin(time * 60 + x) * 1.5 : 0.0;
  p.color = active ? const Color(0xFF9E4FC9) : const Color(0xFF5F3D7E);
  for (var i = 0; i < 3; i++) {
    final bx = x * t + 4 + i * 12 + shake;
    final hgt = 8 + 26 * grow;
    c.drawPath(
      Path()
        ..moveTo(bx, base)
        ..lineTo(bx + 6, base - hgt)
        ..lineTo(bx + 12, base)
        ..close(),
      p,
    );
  }
  if (active) {
    p.color = const Color(0xFFFF9BD1);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(x * t + 10 + i * 12, base - 34), 1.6, p);
    }
  }
}

void _spring(Canvas c, Paint p, double x, double y, double anim, double time) {
  // anim 0.35→0: 밟혔을 때 찌그러졌다 튕기는 모양
  final k = anim > 0 ? math.sin((0.35 - anim) / 0.35 * math.pi * 2.5) * (anim / 0.35) : 0.0;
  final squashY = 1 - k * 0.35, squashX = 1 + k * 0.25;
  final cx = x + kTile / 2, base = y + kTile;
  p.color = const Color(0xFFEFE0C2);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 6, base - 18, 12, 18), const Radius.circular(4)), p);
  final capW = 46 * squashX, capH = 28 * squashY;
  final capTop = base - 14 - capH * 0.75;
  c.drawOval(
    Rect.fromCenter(center: Offset(cx, capTop + capH * 0.5), width: capW + 10, height: capH + 12),
    Paint()
      ..color = const Color(0x33FF8FC0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  p.shader = ui.Gradient.linear(Offset(cx, capTop), Offset(cx, capTop + capH), const [Color(0xFFFF9CC8), Color(0xFFD0508A)]);
  c.drawArc(Rect.fromCenter(center: Offset(cx, capTop + capH * 0.75), width: capW, height: capH * 1.5), math.pi, math.pi, true, p);
  p.shader = null;
  p.color = const Color(0xE6FFF2F8);
  c.drawCircle(Offset(cx - 10 * squashX, capTop + capH * 0.35), 3.2, p);
  c.drawCircle(Offset(cx + 7 * squashX, capTop + capH * 0.25), 2.4, p);
  c.drawCircle(Offset(cx + 14 * squashX, capTop + capH * 0.55), 2, p);
}

void paintMover(Canvas c, double x, double y, double w, bool vertical, double time) {
  final p = Paint();
  if (vertical) {
    p.shader = ui.Gradient.linear(Offset(0, y), Offset(0, y + 16), const [Color(0xFF7C8C88), Color(0xFF3F4B4A)]);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, 16), const Radius.circular(5)), p);
    p.shader = null;
    p.color = Palette.amber.withValues(alpha: 0.6 + 0.3 * math.sin(time * 3));
    c.drawCircle(Offset(x + w / 2, y + 8), 3.5, p);
    return;
  }
  p.shader = ui.Gradient.linear(Offset(0, y), Offset(0, y + 16), const [Color(0xFF8C6A45), Color(0xFF4F3620)]);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, 16), const Radius.circular(8)), p);
  p.shader = null;
  p.color = const Color(0xFF5FAE6A);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 4, y - 2, w - 8, 5), const Radius.circular(3)), p);
  p.color = const Color(0xFF3B2715);
  c.drawOval(Rect.fromLTWH(x + 2, y + 3, 9, 10), p);
  c.drawOval(Rect.fromLTWH(x + w - 11, y + 3, 9, 10), p);
  for (var i = 0; i < 3; i++) {
    final a = 0.4 + 0.4 * math.sin(time * 3 + i * 1.3);
    p.color = Palette.sky.withValues(alpha: a);
    c.drawCircle(Offset(x + w * (0.3 + i * 0.2), y + 9), 2.2, p);
  }
}
