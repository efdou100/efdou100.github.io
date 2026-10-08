import 'dart:io';
import 'dart:math' as math;

import 'package:echo_arrow/app/economy.dart';
import 'package:echo_arrow/app/profile.dart';
import 'package:echo_arrow/game/controller.dart';
import 'package:echo_arrow/game/level.dart';
import 'package:echo_arrow/game/sim.dart';
import 'package:echo_arrow/screens/game_screen.dart';
import 'package:echo_arrow/screens/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Profile.instance.load();
    Profile.instance.resetForTest();
    Profile.instance.lang = 'ko';
    LevelRepo.instance.levels = LevelRepo.parse(File('assets/levels/levels.json').readAsStringSync());
  });

  testWidgets('메인 화면(탭 구조)이 그려지고 플레이 버튼이 보인다', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    for (var i = 1; i <= 4; i++) {
      Profile.instance.stars[i] = 3;
    }
    Profile.instance.checkinLast = Profile.today();
    await t.pumpWidget(const MaterialApp(home: MainShell()));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('5단계'), findsWidgets);
    expect(find.text('홈'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('게임 화면이 그려진다', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: GameScreen(index: 0)));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(seconds: 3));
    expect(find.text('첫 발'), findsWidgets);
    await t.pumpWidget(const SizedBox());
  });

  test('하트: 온보딩 동안은 줄지 않고, 이후에는 줄어든다', () {
    final p = Profile.instance;
    p.loseHeart();
    expect(p.hearts, Profile.maxHearts);
    for (var i = 1; i <= Economy.unlockHearts; i++) {
      p.stars[i] = 1;
    }
    p.loseHeart();
    expect(p.hearts, Profile.maxHearts - 1);
  });

  test('이어하기 가격은 횟수마다 오른다', () {
    expect(Economy.continuePrice(0), lessThan(Economy.continuePrice(1)));
    expect(Economy.continuePrice(5), Economy.continuePrices.last);
  });

  test('컨트롤러: 화살을 다 쓰면 실패 콜백, 이어하기로 화살이 늘어난다', () {
    final l = LevelRepo.instance[1];
    var out = false;
    // 시뮬레이션으로 확실히 빗나가는 각도를 고른다 (레벨 배치가 바뀌어도 안전)
    var miss = 0.0;
    for (var d = 0; d < 360; d += 7) {
      final ang = d * math.pi / 180;
      final r = Run(l, [Shot(ang: ang, step: 0, idx: 0, kind: 'n'), Shot(ang: ang, step: 0, idx: 1, kind: 'n')], l.defaultMirrors);
      for (var i = 0; i < 3000 && !r.done; i++) {
        r.tick();
      }
      if (!r.won) {
        miss = ang;
        break;
      }
    }
    final g = GameController(l)..onOutOfArrows = () => out = true;
    for (var s = 0; s < l.shots; s++) {
      g.pointerDown(180, 400);
      g.pointerMove(180 - math.cos(miss) * 60, 400 - math.sin(miss) * 60);
      g.pointerUp();
      for (var i = 0; i < 2000 && g.mode == Mode.fly; i++) {
        g.update(1 / 60);
      }
    }
    expect(out, isTrue);
    final before = g.remaining;
    g.addArrows(2);
    expect(g.remaining, before + 2);
    g.dispose();
  });
}
