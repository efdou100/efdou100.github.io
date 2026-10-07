import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/skills.dart';

class UpgradeDef {
  final String id, name, desc;
  const UpgradeDef(this.id, this.name, this.desc);
}

const kUpgrades = [
  UpgradeDef('attack', '날카로운 화살촉', '공격력 +8%'),
  UpgradeDef('hp', '단단한 망토', '최대 체력 +10%'),
  UpgradeDef('speed', '가벼운 활시위', '공격 속도 +5%'),
  UpgradeDef('crit', '매의 눈', '치명타 확률 +2%'),
];

/// 진행 상황 저장: 별, 코인, 영구 강화, 설정.
class SaveData {
  SaveData._();
  static final SaveData instance = SaveData._();

  SharedPreferences? _prefs;
  final Map<int, int> stars = {}; // 스테이지 번호 → 최고 별(1~3)
  final Map<int, Set<int>> shardsFound = {}; // 스테이지 → 찾은 꿈 조각 번호
  final Map<String, int> upgrades = {for (final u in kUpgrades) u.id: 0};
  int coins = 0;
  int endlessBest = 0;
  bool sound = true;
  bool haptics = true;

  Future<void> load() async {
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      final raw = p.getString('stars');
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) => stars[int.parse(k)] = v as int);
      }
      final rawShards = p.getString('shards');
      if (rawShards != null) {
        (jsonDecode(rawShards) as Map<String, dynamic>).forEach((k, v) => shardsFound[int.parse(k)] = (v as List).map((e) => e as int).toSet());
      }
      for (final u in kUpgrades) {
        upgrades[u.id] = p.getInt('upg_${u.id}') ?? 0;
      }
      coins = p.getInt('coins') ?? 0;
      endlessBest = p.getInt('endlessBest') ?? 0;
      sound = p.getBool('sound') ?? true;
      haptics = p.getBool('haptics') ?? true;
    } catch (_) {
      // 저장소를 못 쓰는 환경에서도 게임은 돌아가야 해요.
    }
  }

  Future<void> _flush() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString('stars', jsonEncode(stars.map((k, v) => MapEntry('$k', v))));
    await p.setString('shards', jsonEncode(shardsFound.map((k, v) => MapEntry('$k', v.toList()))));
    for (final u in kUpgrades) {
      await p.setInt('upg_${u.id}', upgrades[u.id] ?? 0);
    }
    await p.setInt('coins', coins);
    await p.setInt('endlessBest', endlessBest);
    await p.setBool('sound', sound);
    await p.setBool('haptics', haptics);
  }

  /// 마지막으로 깬 스테이지 + 1 까지 열려 있어요.
  int get unlockedStage => stars.isEmpty ? 1 : (stars.keys.reduce((a, b) => a > b ? a : b) + 1);
  bool get endlessUnlocked => stars.containsKey(10);
  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  int upgradeCost(String id) {
    final lv = upgrades[id] ?? 0;
    return (60 * (1 + lv * 0.6) * (1 + lv * 0.08)).round();
  }

  static const int upgradeMax = 20;

  bool buyUpgrade(String id) {
    final lv = upgrades[id] ?? 0;
    final cost = upgradeCost(id);
    if (lv >= upgradeMax || coins < cost) return false;
    coins -= cost;
    upgrades[id] = lv + 1;
    _flush();
    return true;
  }

  BaseStats get baseStats =>
      RunStats.baseFromUpgrades(attack: upgrades['attack'] ?? 0, hp: upgrades['hp'] ?? 0, speed: upgrades['speed'] ?? 0, crit: upgrades['crit'] ?? 0);

  void recordRun({required int stage, required int starCount, required int earnedCoins, required Set<int> shards, int? endlessDepth}) {
    coins += earnedCoins;
    if (stage > 0 && starCount > 0) {
      stars[stage] = (stars[stage] ?? 0) > starCount ? stars[stage]! : starCount;
    }
    if (stage > 0) {
      shardsFound.putIfAbsent(stage, () => <int>{}).addAll(shards);
    }
    if (endlessDepth != null && endlessDepth > endlessBest) endlessBest = endlessDepth;
    _flush();
  }

  void setSound(bool v) {
    sound = v;
    _flush();
  }

  void setHaptics(bool v) {
    haptics = v;
    _flush();
  }
}
