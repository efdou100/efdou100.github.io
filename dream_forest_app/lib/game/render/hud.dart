import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../app/theme.dart';
import '../constants.dart';
import '../dream_game.dart';
import '../entities/enemy.dart';
import '../rooms/room_template.dart';
import '../skills.dart';
import 'actors.dart';
import 'skill_icons.dart';

/// 게임 화면 위 정보: 체력·경험치·집중 게이지, 방 진행도, 코인, 콤보, 보스 체력, 알림.
class Hud {
  final DreamGame g;
  Hud(this.g);

  double hpShown = 1, hpLag = 1, xpShown = 0;
  String bannerTitle = '', bannerSub = '';
  double bannerT = 0;
  String? toastText;
  Color toastColor = Palette.amber;
  double toastT = 0;
  String? hintText;
  double hintT = 0;
  final Map<String, TextPainter> _cache = {};
  final Paint _p = Paint();

  void roomBanner(int index, int count, String sub) {
    bannerTitle = g.stage.name;
    bannerSub = '${index + 1} / $count · $sub';
    bannerT = 2.8;
  }

  void toast(String text, {Color color = Palette.amber}) {
    toastText = text;
    toastColor = color;
    toastT = 2.2;
  }

  void hint(String text) {
    hintText = text;
    hintT = 5;
  }

  void update(double dt) {
    bannerT -= dt;
    toastT -= dt;
    hintT -= dt;
    final hpR = (g.run.hp / g.run.maxHp).clamp(0.0, 1.0);
    hpShown += (hpR - hpShown) * math.min(1, dt * 14);
    if (hpLag < hpShown) {
      hpLag = hpShown;
    } else {
      hpLag += (hpShown - hpLag) * math.min(1, dt * 2.2);
    }
    final xpR = (g.run.xp / g.run.xpNeeded).clamp(0.0, 1.0);
    xpShown += (xpR - xpShown) * math.min(1, dt * 10);
    if (_cache.length > 160) _cache.clear();
  }

  TextPainter _t(String s, double size, Color color, {bool display = true, FontWeight? weight}) {
    final key = '$s|$size|${color.toARGB32()}|$display';
    return _cache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: display ? kDisplayFont : null,
            fontSize: size,
            color: color,
            fontWeight: weight,
            shadows: const [Shadow(color: Color(0xCC061012), offset: Offset(0, 1.5), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
  }

  void _glass(Canvas c, RRect r) {
    _p
      ..shader = ui.Gradient.linear(r.outerRect.topLeft, r.outerRect.bottomLeft, const [Color(0xCC1B3238), Color(0xCC0E1C21)])
      ..style = PaintingStyle.fill;
    c.drawRRect(r, _p);
    _p
      ..shader = ui.Gradient.linear(
        r.outerRect.topLeft,
        r.outerRect.bottomRight,
        const [Color(0x88A8F0C0), Color(0x22A8F0C0), Color(0x55F5B85C)],
        const [0, 0.5, 1],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    c.drawRRect(r, _p);
    _p
      ..shader = null
      ..style = PaintingStyle.fill;
  }

  void _bar(Canvas c, Rect r, double v, List<Color> colors, {double lag = -1, bool shine = true}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
    _p.color = const Color(0xAA061013);
    c.drawRRect(rr, _p);
    if (lag > v) {
      _p.color = const Color(0xCCFFF0E0);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width * lag, r.height), Radius.circular(r.height / 2)), _p);
    }
    if (v > 0) {
      final fill = Rect.fromLTWH(r.left, r.top, math.max(r.height, r.width * v), r.height);
      _p.shader = ui.Gradient.linear(fill.topLeft, fill.topRight, colors);
      c.drawRRect(RRect.fromRectAndRadius(fill, Radius.circular(r.height / 2)), _p);
      _p.shader = null;
      if (shine) {
        _p.color = const Color(0x55FFFFFF);
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(fill.left + 3, fill.top + 1.5, fill.width - 6, fill.height * 0.32), Radius.circular(r.height / 3)),
          _p,
        );
      }
    }
  }

  void render(Canvas c) {
    final run = g.run;
    final w = g.viewW;
    final time = g.time;

    // ── 왼쪽 위: 체력 / 경험치 / 집중
    _glass(c, RRect.fromLTRBR(12, 10, 268, 82, const Radius.circular(16)));
    // 레벨 배지
    final lvCenter = const Offset(42, 46);
    _p.shader = ui.Gradient.radial(lvCenter, 24, const [Color(0xFFFFE3A0), Color(0xFFE8A13E)]);
    c.drawCircle(lvCenter, 22, _p);
    _p.shader = null;
    _p
      ..color = const Color(0xFF6E4420)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawCircle(lvCenter, 22, _p);
    _p.style = PaintingStyle.fill;
    final lvLabel = _t('Lv', 10, const Color(0xFF5A3510));
    lvLabel.paint(c, Offset(lvCenter.dx - lvLabel.width / 2, lvCenter.dy - 17));
    final lv = _t('${run.level}', 20, const Color(0xFF3A2008));
    lv.paint(c, Offset(lvCenter.dx - lv.width / 2, lvCenter.dy - 7));
    // 체력
    drawHeart(c, const Offset(76, 18), 13, const Color(0xFFFF6B88));
    _bar(c, const Rect.fromLTWH(94, 20, 160, 14), hpShown, const [Color(0xFFFF5470), Color(0xFFFF8FA8)], lag: hpLag);
    final hpText = _t('${run.hp.ceil()} / ${run.maxHp.round()}', 11, Palette.ink);
    hpText.paint(c, Offset(174 - hpText.width / 2, 20.5));
    // 경험치
    _bar(c, const Rect.fromLTWH(74, 42, 180, 9), xpShown, const [Color(0xFF8BE07A), Color(0xFFE8F57A)]);
    // 집중
    final focusing = g.player.focusT > 0;
    final fv = focusing ? g.player.focusT / run.focusDuration : run.focus / 100;
    final full = !focusing && run.focus >= 100;
    _bar(
      c,
      const Rect.fromLTWH(74, 60, 120, 8),
      fv,
      focusing
          ? const [Color(0xFF6FB7FF), Color(0xFFBFE6FF)]
          : full
          ? [Palette.sky, Color.fromRGBO(255, 255, 255, 0.7 + 0.3 * math.sin(time * 8))]
          : const [Color(0xFF4F8FD0), Color(0xFF8FD3FF)],
    );
    final fl = _t(
      focusing
          ? '집중 중'
          : full
          ? '집중 준비! 멈추면 발동'
          : '집중',
      11,
      full || focusing ? Palette.sky : Palette.mute,
    );
    fl.paint(c, Offset(200, 57));

    // 스킬 배지
    var ix = 16.0;
    for (final s in kSkills) {
      final n = run.stack(s.id);
      if (n == 0 || s.id == 'heart') continue;
      final r = Rect.fromLTWH(ix, 90, 30, 30);
      final col = rarityColor(s.rarity);
      _p.shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [col.withValues(alpha: 0.55), const Color(0xCC0E1C21)]);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(9)), _p);
      _p.shader = null;
      paintSkillIcon(c, s.id, r.deflate(6));
      if (n > 1) {
        final tn = _t('$n', 11, Palette.gold);
        tn.paint(c, Offset(r.right - tn.width - 1, r.bottom - tn.height + 2));
      }
      ix += 34;
      if (ix > 16 + 34 * 8) break;
    }

    // ── 가운데 위: 방 진행도
    final n = g.roomCount;
    const gap = 26.0;
    final startX = w / 2 - (n - 1) * gap / 2;
    _glass(c, RRect.fromLTRBR(startX - 22, 12, startX + (n - 1) * gap + 22, 40, const Radius.circular(14)));
    for (var i = 0; i < n; i++) {
      final x = startX + i * gap;
      if (i < n - 1) {
        _p.color = i < g.roomIndex ? Palette.amber : const Color(0x449DB3A8);
        c.drawRect(Rect.fromLTWH(x + 6, 25, gap - 12, 2), _p);
      }
      final isBoss = g.stage.rooms[i].tpl.type == RoomType.boss;
      final done = i < g.roomIndex, cur = i == g.roomIndex;
      if (cur) {
        _p
          ..color = Palette.amber.withValues(alpha: 0.35 + 0.2 * math.sin(time * 5))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        c.drawCircle(Offset(x, 26), 11, _p);
        _p.maskFilter = null;
      }
      _p.color = done
          ? Palette.amber
          : cur
          ? const Color(0xFFFFE3A0)
          : const Color(0xFF3A5056);
      if (isBoss) {
        c.drawPath(
          Path()
            ..moveTo(x - 8, 31)
            ..lineTo(x - 8, 21)
            ..lineTo(x - 4, 25)
            ..lineTo(x, 18)
            ..lineTo(x + 4, 25)
            ..lineTo(x + 8, 21)
            ..lineTo(x + 8, 31)
            ..close(),
          _p,
        );
      } else {
        c.drawCircle(Offset(x, 26), cur ? 6.5 : 5, _p);
      }
    }

    // ── 오른쪽 위: 코인·꿈 조각 (일시정지 버튼 자리 비워둠)
    final rx = w - 70;
    _glass(c, RRect.fromLTRBR(rx - 168, 12, rx - 6, 40, const Radius.circular(14)));
    _p.color = Palette.gold;
    c.drawCircle(Offset(rx - 150, 26), 7, _p);
    _p.color = const Color(0xFFE0A93A);
    c.drawCircle(Offset(rx - 150, 26), 4.5, _p);
    _t('${run.coins}', 15, Palette.gold).paint(c, Offset(rx - 138, 17));
    drawShard(c, rx - 72, 26, time, 0.55);
    _t('${g.foundShardCount()}/${g.stage.shardCount}', 15, const Color(0xFFBFE9FF)).paint(c, Offset(rx - 60, 17));

    // ── 보스 체력
    Enemy? boss;
    for (final e in g.enemies) {
      if (e.isBoss) boss = e;
    }
    if (boss != null) {
      final bw = math.min(420.0, w * 0.42);
      final r = Rect.fromLTWH(w / 2 - bw / 2, 58, bw, 14);
      final name = _t(boss.kind == EnemyKind.king ? '킹 슬라임' : '꿈의 군주', 15, const Color(0xFFFFD6E7));
      name.paint(c, Offset(w / 2 - name.width / 2, 44));
      _bar(
        c,
        r,
        (boss.hp / boss.maxHp).clamp(0, 1),
        boss.kind == EnemyKind.king ? const [Color(0xFFE0457F), Color(0xFFFF9CC8)] : const [Color(0xFF7A4FD0), Color(0xFFD7B8FF)],
      );
      _p.color = const Color(0x99FFFFFF);
      c.drawRect(Rect.fromLTWH(r.center.dx - 1, r.top - 2, 2, r.height + 4), _p);
    } else if (g.room.tpl.needsClear && g.waves > 1 && g.enemies.isNotEmpty) {
      _pill(c, '웨이브 ${g.wave}/${g.waves} · 남은 적 ${g.enemies.length}', w / 2, 56, 13, Palette.mute);
    }

    // ── 콤보
    if (g.combo >= 2) {
      final s = 1 + g.comboPop * 0.45;
      c.save();
      c.translate(w - 82, 150);
      c.scale(s);
      c.rotate(-0.06);
      final col = g.combo >= 25
          ? Palette.rose
          : g.combo >= 10
          ? Palette.gold
          : Palette.ink;
      final label = _t('COMBO', 13, Palette.mute);
      label.paint(c, Offset(-label.width / 2, -34));
      final num = _t('${g.combo}', 44, col);
      _p
        ..color = col.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      c.drawCircle(Offset.zero, 30, _p);
      _p.maskFilter = null;
      num.paint(c, Offset(-num.width / 2, -num.height / 2));
      _p.color = const Color(0x33FFFFFF);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-32, 28, 64, 4), const Radius.circular(2)), _p);
      _p.color = col;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-32, 28, 64 * (g.comboT / 2.4).clamp(0, 1), 4), const Radius.circular(2)), _p);
      c.restore();
    }

    // ── 힌트 / 알림
    if (hintT > 0 && hintText != null) {
      final a = math.min(1.0, math.min(hintT, 5 - hintT) * 3);
      _pill(c, hintText!, w / 2, kViewH - 40, 16, Palette.ink, alpha: a);
    }
    if (toastT > 0 && toastText != null) {
      final k = 2.2 - toastT;
      final pop = k < 0.12 ? 0.6 + k / 0.12 * 0.5 : 1.1 - math.min(0.1, (k - 0.12));
      final a = math.min(1.0, toastT * 3);
      c.save();
      c.translate(w / 2, kViewH - 96);
      c.scale(pop);
      _pill(c, toastText!, 0, 0, 19, toastColor, alpha: a, glow: toastColor);
      c.restore();
    }

    // ── 방 시작 배너
    if (bannerT > 0) {
      final k = 2.8 - bannerT;
      final a = math.min(1.0, math.min(k * 3, bannerT * 2));
      final slide = (1 - math.min(1.0, k * 2.5)) * 40;
      c.saveLayer(Rect.fromLTWH(0, 0, w, kViewH), Paint()..color = Color.fromRGBO(0, 0, 0, a));
      _p.shader = ui.Gradient.linear(
        Offset(0, kViewH / 2 - 60),
        Offset(0, kViewH / 2 + 50),
        const [Color(0x00061012), Color(0xAA061012), Color(0x00061012)],
        const [0, 0.5, 1],
      );
      c.drawRect(Rect.fromLTWH(0, kViewH / 2 - 60, w, 110), _p);
      _p.shader = null;
      final title = TextPainter(
        text: TextSpan(
          text: bannerTitle,
          style: TextStyle(
            fontFamily: kDisplayFont,
            fontSize: 52,
            foreground: Paint()
              ..shader = ui.Gradient.linear(
                const Offset(0, 0),
                const Offset(0, 56),
                const [Color(0xFFFFF1C8), Color(0xFFF5B85C), Color(0xFFE86FA6)],
                const [0, 0.55, 1],
              ),
            shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      title.paint(c, Offset(w / 2 - title.width / 2 + slide, kViewH / 2 - 44));
      final sub = _t(bannerSub, 18, const Color(0xFFCFE3D6));
      sub.paint(c, Offset(w / 2 - sub.width / 2 - slide, kViewH / 2 + 14));
      _p
        ..shader = ui.Gradient.linear(
          Offset(w / 2 - 200, 0),
          Offset(w / 2 + 200, 0),
          const [Color(0x00F5B85C), Color(0xFFF5B85C), Color(0x00F5B85C)],
          const [0, 0.5, 1],
        )
        ..strokeWidth = 1.5;
      c.drawLine(Offset(w / 2 - 200, kViewH / 2 + 8), Offset(w / 2 + 200, kViewH / 2 + 8), _p);
      _p.shader = null;
      c.restore();
    }
  }

  void _pill(Canvas c, String text, double cx, double cy, double size, Color color, {double alpha = 1, Color? glow}) {
    final tp = _t(text, size, color);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: tp.width + 34, height: tp.height + 16),
      Radius.circular((tp.height + 16) / 2),
    );
    if (alpha < 1) c.saveLayer(r.outerRect.inflate(30), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    if (glow != null) {
      _p
        ..color = glow.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      c.drawRRect(r, _p);
      _p.maskFilter = null;
    }
    _glass(c, r);
    tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));
    if (alpha < 1) c.restore();
  }
}
