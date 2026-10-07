import 'dart:math' as math;

import 'constants.dart';

enum Rarity { common, rare, epic }

class SkillDef {
  final String id;
  final String name;
  final String desc;
  final int maxStack;
  final Rarity rarity;
  const SkillDef(this.id, this.name, this.desc, this.maxStack, this.rarity);
}

/// 스킬은 전투에만 영향을 줘요. 지형을 바꾸는 스킬은 없어서 길이 막히는 일이 없어요.
const List<SkillDef> kSkills = [
  SkillDef('multishot', '멀티샷', '화살을 한 번 더 연달아 쏴요', 3, Rarity.rare),
  SkillDef('front', '정면 화살 +1', '나란히 나가는 화살이 하나 늘어요', 3, Rarity.common),
  SkillDef('diagonal', '사선 화살', '비스듬한 화살 2발을 함께 쏴요', 2, Rarity.rare),
  SkillDef('back', '뒤쪽 화살', '등 뒤로도 화살이 나가요', 2, Rarity.common),
  SkillDef('pierce', '관통', '화살이 적을 꿰뚫고 계속 날아가요', 1, Rarity.rare),
  SkillDef('ricochet', '도탄', '맞힌 화살이 가까운 적에게 한 번 더 튕겨요', 3, Rarity.epic),
  SkillDef('fire', '화염 화살', '적을 불태워요. 불붙은 적은 쓰러질 때 터져요', 1, Rarity.rare),
  SkillDef('frost', '빙결 화살', '적을 느리게 하고, 세 번 맞히면 얼려요', 1, Rarity.rare),
  SkillDef('lightning', '번개 화살', '맞은 적 근처 두 명에게 번개가 튀어요', 1, Rarity.epic),
  SkillDef('attack', '공격력 +25%', '모든 공격이 더 아파요', 5, Rarity.common),
  SkillDef('haste', '속사', '공격 속도가 18% 빨라져요', 5, Rarity.common),
  SkillDef('crit', '급소 노리기', '치명타 확률 +10%', 4, Rarity.common),
  SkillDef('orbit', '수호 구슬', '몸 주위를 도는 구슬이 적을 때려요', 3, Rarity.rare),
  SkillDef('vampire', '흡혈', '적을 쓰러뜨릴 때마다 체력을 조금 회복해요', 2, Rarity.common),
  SkillDef('heart', '생명의 이슬', '최대 체력 +20%, 체력을 모두 회복해요', 99, Rarity.common),
  SkillDef('shield', '나뭇잎 방패', '8초마다 공격 한 번을 막아줘요', 1, Rarity.epic),
  SkillDef('focus', '깊은 집중', '집중 게이지가 빨리 차고 더 오래가요', 2, Rarity.common),
];

SkillDef skillById(String id) => kSkills.firstWhere((s) => s.id == id);

/// 영구 강화(캠프)에서 넘어오는 기본 능력치.
class BaseStats {
  final double damage, maxHp, fireInterval, crit;
  const BaseStats({required this.damage, required this.maxHp, required this.fireInterval, required this.crit});
}

/// 한 번의 스테이지 도전 동안만 유지되는 상태 (로그라이크).
class RunStats {
  final BaseStats base;
  final Map<String, int> stacks = {};
  int level = 1;
  double xp = 0;
  late double maxHp;
  late double hp;
  double focus = 0;
  double shieldCd = 0;
  int coins = 0;
  int kills = 0;
  int bestCombo = 0;
  final Set<String> shards = {};

  RunStats(this.base) {
    maxHp = base.maxHp;
    hp = maxHp;
  }

  int stack(String id) => stacks[id] ?? 0;
  bool has(String id) => stack(id) > 0;

  double get damage => base.damage * (1 + 0.25 * stack('attack'));
  double get fireInterval => base.fireInterval / (1 + 0.18 * stack('haste'));
  double get crit => math.min(0.75, base.crit + 0.1 * stack('crit'));
  double get xpNeeded => 22.0 + level * 12;
  double get focusGain => 1 + 0.5 * stack('focus');
  double get focusDuration => 3.5 + 1.2 * stack('focus');
  bool get shieldReady => has('shield') && shieldCd <= 0;

  bool canTake(SkillDef s) => stack(s.id) < s.maxStack;

  void add(String id) {
    stacks[id] = stack(id) + 1;
    if (id == 'heart') {
      maxHp *= 1.2;
      hp = maxHp;
    }
  }

  /// 레벨업 카드 3장. 희귀도에 따라 확률이 달라요.
  List<SkillDef> offer(math.Random rng, {int count = 3}) {
    final pool = kSkills.where(canTake).toList();
    final picked = <SkillDef>[];
    double weight(SkillDef s) => switch (s.rarity) { Rarity.common => 10, Rarity.rare => 6, Rarity.epic => 3 };
    while (picked.length < count && pool.isNotEmpty) {
      final total = pool.fold<double>(0, (a, s) => a + weight(s));
      var r = rng.nextDouble() * total;
      for (final s in pool) {
        r -= weight(s);
        if (r <= 0) {
          picked.add(s);
          pool.remove(s);
          break;
        }
      }
    }
    return picked;
  }

  static BaseStats baseFromUpgrades({required int attack, required int hp, required int speed, required int crit}) =>
      BaseStats(
        damage: Combat.baseDamage * (1 + 0.08 * attack),
        maxHp: Combat.baseHp * (1 + 0.1 * hp),
        fireInterval: Combat.baseFireInterval / (1 + 0.05 * speed),
        crit: Combat.baseCrit + 0.02 * crit,
      );
}
