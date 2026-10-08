import 'dart:io';

import 'package:echo_arrow/app/economy.dart';
import 'package:echo_arrow/app/profile.dart';
import 'package:echo_arrow/game/controller.dart';
import 'package:echo_arrow/game/level.dart';
import 'package:echo_arrow/screens/game_screen.dart';
import 'package:echo_arrow/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Profile.instance.load();
    Profile.instance.resetForTest();
    LevelRepo.instance.levels = LevelRepo.parse(File('assets/levels/levels.json').readAsStringSync());
  });

  testWidgets('홈 화면이 그려지고 시작 버튼이 보인다', (t) async {
    for (var i = 1; i <= 4; i++) {
      Profile.instance.stars[i] = 3;
    }
    Profile.instance.checkinLast = Profile.today();
    await t.pumpWidget(const MaterialApp(home: HomeScreen()));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('5단계 시작'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('게임 화면이 그려진다', (t) async {
    await t.pumpWidget(const MaterialApp(home: GameScreen(index: 0)));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('첫 발'), findsOneWidget);
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
    final g = GameController(l)..onOutOfArrows = () => out = true;
    for (var s = 0; s < l.shots; s++) {
      g.pointerDown(180, 400);
      g.pointerMove(180, 300); // 아래쪽으로 쏨 → 바닥 이끼 없음, 튕기다 소멸
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
