import 'dart:math' as math;

import 'constants.dart';

/// 지형 판정에 필요한 것만 모은 인터페이스. 게임과 테스트(도달 가능성 검사)가 같이 써요.
abstract class Geometry {
  /// 0 = 통과, 1 = 위에서만 밟힘, 2 = 꽉 막힘
  int kindAt(int cx, int cy);
  bool springAt(int cx, int cy);
  Iterable<Platform> get platforms;
  void onStand(int cx, int cy) {}
}

class Platform {
  double x, y, w, h;
  double dx = 0, dy = 0;
  Platform(this.x, this.y, this.w, this.h);
}

class Body {
  double x, y, w, h;
  double vx = 0, vy = 0;
  bool onGround = false;
  Platform? riding;
  int groundCx = -1, groundCy = -1;
  Body(this.x, this.y, this.w, this.h);

  double get cx => x + w / 2;
  double get cy => y + h / 2;
  double get bottom => y + h;
  double get right => x + w;
}

int cellOf(double v) => (v / kTile).floor();

/// 가로 이동. 벽에 막히면 true.
bool moveX(Geometry g, Body b, double dx) {
  if (dx == 0) return false;
  var hit = false;
  var remaining = dx;
  while (remaining != 0) {
    final step = remaining.abs() > 16 ? 16 * remaining.sign : remaining;
    remaining -= step;
    b.x += step;
    final top = cellOf(b.y + 0.01), bot = cellOf(b.y + b.h - 0.01);
    if (step > 0) {
      final cx = cellOf(b.x + b.w - 0.001);
      for (var cy = top; cy <= bot; cy++) {
        if (g.kindAt(cx, cy) == 2) {
          b.x = cx * kTile - b.w;
          hit = true;
          break;
        }
      }
    } else {
      final cx = cellOf(b.x + 0.001);
      for (var cy = top; cy <= bot; cy++) {
        if (g.kindAt(cx, cy) == 2) {
          b.x = (cx + 1) * kTile;
          hit = true;
          break;
        }
      }
    }
    if (hit) break;
  }
  return hit;
}

/// 세로 이동. 착지·천장 충돌·움직이는 발판을 처리해요.
void moveY(Geometry g, Body b, double dy, {bool oneWay = true, bool platforms = true}) {
  b.onGround = false;
  b.riding = null;
  b.groundCx = -1;
  b.groundCy = -1;
  var remaining = dy;
  while (remaining != 0) {
    final step = remaining.abs() > 16 ? 16 * remaining.sign : remaining;
    remaining -= step;
    final prevBottom = b.y + b.h;
    b.y += step;
    final l = cellOf(b.x + 0.01), r = cellOf(b.x + b.w - 0.01);
    if (step > 0) {
      final cy = cellOf(b.y + b.h - 0.001);
      for (var cx = l; cx <= r; cx++) {
        final k = g.kindAt(cx, cy);
        if (k == 2 || (k == 1 && oneWay && prevBottom <= cy * kTile + 0.5)) {
          b.y = cy * kTile - b.h;
          b.vy = 0;
          b.onGround = true;
          b.groundCx = cx;
          b.groundCy = cy;
          g.onStand(cx, cy);
          return;
        }
      }
      if (platforms) {
        for (final p in g.platforms) {
          if (b.x + b.w > p.x && b.x < p.x + p.w && prevBottom <= p.y + 0.5 + (p.dy > 0 ? p.dy : 0) && b.y + b.h >= p.y) {
            b.y = p.y - b.h;
            b.vy = 0;
            b.onGround = true;
            b.riding = p;
            return;
          }
        }
      }
    } else if (step < 0) {
      final cy = cellOf(b.y + 0.001);
      for (var cx = l; cx <= r; cx++) {
        if (g.kindAt(cx, cy) == 2) {
          b.y = (cy + 1) * kTile;
          b.vy = 0;
          return;
        }
      }
    }
  }
}

bool overlaps(Body a, Body b, [double pad = 0]) => a.x + pad < b.x + b.w && a.x + a.w - pad > b.x && a.y + pad < b.y + b.h && a.y + a.h - pad > b.y;

/// 두 점 사이에 꽉 막힌 타일이 없는지.
bool lineClear(Geometry g, double x0, double y0, double x1, double y1) {
  final dx = x1 - x0, dy = y1 - y0;
  final n = math.max(1, (math.sqrt(dx * dx + dy * dy) / 12).ceil());
  for (var i = 1; i < n; i++) {
    final x = x0 + dx * i / n, y = y0 + dy * i / n;
    if (g.kindAt(cellOf(x), cellOf(y)) == 2) return false;
  }
  return true;
}
