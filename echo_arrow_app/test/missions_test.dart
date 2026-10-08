import 'dart:io';
import 'dart:math' as math;

import 'package:echo_arrow/app/missions.dart';
import 'package:echo_arrow/app/profile.dart';
import 'package:echo_arrow/game/controller.dart';
import 'package:echo_arrow/game/level.dart';
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

  test('미션: 잠겨 있으면 진행되지 않는다', () {
    expect(Missions.bump('clear'), isEmpty);
    expect(Missions.anyClaimable, isFalse);
  });

  test('미션: 오늘의 미션 3개는 서로 다르고 첫 칸은 판 깨기', () {
    final ms = Missions.today;
    expect(ms.length, 3);
    expect(ms.first.id, 'clear');
    expect(ms.map((m) => m.id).toSet().length, 3);
  });

  test('미션: 진행 → 완료 → 받기 → 상자', () {
    final p = Profile.instance;
    for (var i = 1; i <= Missions.unlock; i++) {
      p.stars[i] = 3;
    }
    final ms = Missions.today;
    for (var i = 0; i < 3; i++) {
      final done = Missions.bump(ms[i].id, ms[i].goal);
      expect(done, [ms[i].title]);
      expect(Missions.done(i), isTrue);
    }
    expect(Missions.anyClaimable, isTrue);
    final c0 = p.coins;
    for (var i = 0; i < 3; i++) {
      Missions.claim(i);
    }
    expect(p.coins, greaterThan(c0));
    expect(Missions.chestReady, isTrue);
    Missions.claimChest();
    expect(Missions.chestReady, isFalse);
    expect(Missions.anyClaimable, isFalse);
  });

  test('미션: 날짜가 바뀌면 초기화', () {
    final p = Profile.instance;
    p.missionDate = '2000-01-01';
    p.missionProg = [3, 3, 3];
    p.missionClaimed = 7;
    expect(Missions.progress, [0, 0, 0]);
    expect(Missions.claimed(0), isFalse);
  });

  test('별 상자: 월드 별 20개에서 첫 상자가 열린다', () {
    final p = Profile.instance;
    final w1 = [for (var i = 0; i < LevelRepo.instance.count; i++) LevelRepo.instance[i]].where((l) => l.world == 1).toList();
    for (final l in w1.take(6)) {
      p.stars[l.id] = 3;
    }
    expect(StarChests.starsIn(1), 18);
    expect(StarChests.ready(1, 0), isFalse);
    p.stars[w1[6].id] = 2;
    expect(StarChests.ready(1, 0), isTrue);
    StarChests.claim(1, 0);
    expect(StarChests.ready(1, 0), isFalse);
    expect(StarChests.anyReady(1), isFalse);
  });

  test('정밀 조준: 길게 당기면 같은 손가락 이동에 각도가 덜 움직인다', () {
    double turn(double pullLen) {
      final g = GameController(LevelRepo.instance[0]);
      g.pointerDown(180, 300);
      g.pointerMove(180, 300 + pullLen);
      final a0 = g.aimAng;
      // 손가락을 옆으로 3px (원래라면 약 3/pullLen 라디안)
      g.pointerMove(183, 300 + pullLen);
      final d = (g.aimAng - a0).abs();
      g.dispose();
      return d;
    }

    final short = turn(30), long = turn(140);
    expect(short, closeTo(math.atan2(3, 30), 0.03));
    expect(long, lessThan(math.atan2(3, 140) * 0.5));
  });
}
