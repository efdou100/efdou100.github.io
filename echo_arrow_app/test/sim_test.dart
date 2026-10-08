import 'dart:io';

import 'package:echo_arrow/game/level.dart';
import 'package:echo_arrow/game/sim.dart';
import 'package:flutter_test/flutter_test.dart';

/// 레벨 생성기(JS 솔버)가 기록한 정답이 Flutter 시뮬레이션에서도 클리어되는지 확인한다.
/// 두 구현이 어긋나면 힌트가 틀리거나 풀 수 없는 판이 생긴다.
void main() {
  final levels = LevelRepo.parse(File('assets/levels/levels.json').readAsStringSync());

  test('레벨 100개, 월드당 20개', () {
    expect(levels.length, 100);
    for (var w = 1; w <= 5; w++) {
      expect(levels.where((l) => l.world == w).length, 20, reason: 'world $w');
    }
  });

  for (final l in levels) {
    test('${l.id} ${l.name}: 정답으로 클리어', () {
      final s = l.solution;
      expect(s, isNotNull);
      final shots = [for (var i = 0; i < s!.shots.length; i++) Shot(ang: s.shots[i].angDeg * kD2R, step: s.shots[i].step, idx: i, kind: s.shots[i].kind)];
      final run = simulate(l, shots, s.mirrors);
      expect(run.won, isTrue, reason: '정답 ${s.shots.map((e) => '${e.angDeg}°@${e.step}').join(', ')} 거울 ${s.mirrors}');
      expect(shots.length, lessThanOrEqualTo(l.par), reason: '정답 발 수가 기준 발 수 이하');
    });
  }

  test('조준선은 첫 반사점까지 이어진다', () {
    final l = levels.first;
    final run = Run(l, [], null);
    final r = run.ray(-90 * kD2R, 1, 70);
    expect(r.paths.first.length, greaterThanOrEqualTo(2));
  });
}
