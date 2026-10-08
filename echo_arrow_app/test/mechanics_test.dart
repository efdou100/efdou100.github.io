import 'dart:convert';
import 'dart:io';

import 'package:echo_arrow/game/level.dart';
import 'package:echo_arrow/game/sim.dart';
import 'package:flutter_test/flutter_test.dart';

/// 새 장치(등불·유리 마개·되쏘기 고리·째깍 거울)가 JS 시뮬레이션과 step 단위로 똑같이 움직이는지 확인한다.
/// 기준값은 echo-arrow/sim.js 로 만든 test/fixtures/new_mechanics.json.
void main() {
  final j = jsonDecode(File('test/fixtures/new_mechanics.json').readAsStringSync()) as Map<String, dynamic>;
  final levels = {for (final l in LevelRepo.parse(jsonEncode(j))) l.id: l};
  final cases = j['cases'] as List;
  test('새 장치 패리티 ${cases.length}건', () {
    var i = 0;
    for (final c in cases) {
      final l = levels[c['id']]!;
      final shots = [
        for (final s in c['shots'] as List) Shot(ang: (s['ang'] as num).toDouble() * kD2R, step: s['step'] as int, idx: s['idx'] as int),
      ];
      final run = simulate(l, shots, [for (final m in c['mirrors'] as List) m as int]);
      final tag = 'case $i (${l.name})';
      expect(run.won, c['won'], reason: '$tag won');
      expect(run.failed, c['failed'], reason: '$tag failed');
      expect(run.step, c['step'], reason: '$tag step');
      expect(run.hit, [for (final h in c['hit'] as List) h as bool], reason: '$tag hit');
      expect(run.crys, [for (final h in c['crys'] as List) h as bool], reason: '$tag crys');
      expect(run.lit, [for (final h in c['lit'] as List) h as bool], reason: '$tag lit');
      i++;
    }
  });
}
