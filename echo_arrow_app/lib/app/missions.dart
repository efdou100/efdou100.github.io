import '../game/controller.dart';
import '../game/level.dart';
import 'economy.dart';
import 'l10n.dart';
import 'profile.dart';

/// 일일 미션 3개 + 다 깨면 상자. "오늘 할 일"을 만들어 매일 들어올 이유를 준다.
/// 미션은 날짜로 정해지므로 모든 플레이어가 같은 날 같은 미션을 받는다 (공유·대화 거리).
class Mission {
  const Mission(this.id, this.goal, this.reward);
  final String id;
  final int goal;
  final Reward reward;
  String get title => tr('m_$id', {'n': goal});
}

class Missions {
  Missions._();
  static const unlock = 8; // 8판 클리어 후 열림

  /// 미션 후보. 'clear'는 매일 첫 칸 고정, 나머지 2칸은 날짜로 고른다.
  static const pool = [
    Mission('clear', 3, Reward(coins: 80)),
    Mission('stars', 7, Reward(coins: 100)),
    Mission('trick', 2, Reward(coins: 120, boosters: {'aim': 1})),
    Mission('echo', 3, Reward(coins: 120)),
    Mission('oneshot', 2, Reward(coins: 100, boosters: {'split': 1})),
    Mission('first', 2, Reward(coins: 120)),
    Mission('near', 3, Reward(coins: 80)),
    Mission('perfect', 2, Reward(coins: 120, boosters: {'extra': 1})),
  ];
  static const chest = Reward(coins: 300, boosters: {'aim': 1, 'extra': 1}, hints: 1, chest: true);

  static bool get unlocked => Profile.instance.cleared >= unlock;

  static int _day() => DateTime.now().difference(DateTime(2026)).inDays;

  /// 오늘의 미션 3개
  static List<Mission> get today {
    final d = _day();
    final rest = pool.sublist(1);
    final a = (d * 5 + 1) % rest.length;
    var b = (d * 3 + 4) % rest.length;
    if (b == a) b = (b + 1) % rest.length;
    return [pool[0], rest[a], rest[b]];
  }

  static void _roll() {
    final p = Profile.instance;
    final t = Profile.today();
    if (p.missionDate == t) return;
    p.missionDate = t;
    p.missionProg = [0, 0, 0];
    p.missionClaimed = 0;
    p.missionChest = false;
  }

  static List<int> get progress {
    _roll();
    return Profile.instance.missionProg;
  }

  static bool done(int i) => progress[i] >= today[i].goal;
  static bool claimed(int i) {
    _roll();
    return Profile.instance.missionClaimed & (1 << i) != 0;
  }

  static bool get chestReady => [0, 1, 2].every(claimed) && !Profile.instance.missionChest;
  static bool get anyClaimable => unlocked && ([0, 1, 2].any((i) => done(i) && !claimed(i)) || chestReady);
  static int get doneCount => [0, 1, 2].where(done).length;

  /// 진행을 올린다. 방금 끝난 미션 제목 목록을 돌려준다 (화면에 알림용).
  static List<String> bump(String id, [int n = 1]) {
    if (!unlocked || n <= 0) return const [];
    _roll();
    final p = Profile.instance;
    final out = <String>[];
    final ms = today;
    for (var i = 0; i < 3; i++) {
      if (ms[i].id != id || p.missionProg[i] >= ms[i].goal) continue;
      p.missionProg[i] = (p.missionProg[i] + n).clamp(0, ms[i].goal);
      if (p.missionProg[i] >= ms[i].goal) out.add(ms[i].title);
    }
    p.save();
    return out;
  }

  /// 클리어 결과를 한 번에 반영
  static List<String> recordWin(WinResult r, LevelData l) => [
    ...bump('clear'),
    ...bump('stars', r.stars),
    if (r.used == 1) ...bump('oneshot'),
    if (r.firstTry) ...bump('first'),
    if (r.stars == 3) ...bump('perfect'),
  ];

  static Reward claim(int i) {
    final r = today[i].reward;
    final p = Profile.instance;
    p.missionClaimed |= 1 << i;
    r.grant();
    return r;
  }

  static Reward claimChest() {
    Profile.instance.missionChest = true;
    chest.grant();
    return chest;
  }
}

/// 월드별 별 상자: 한 월드에서 별 20·40·60개를 모으면 열린다.
/// 이미 깬 판을 별 3개로 다시 깨러 갈 이유가 된다.
class StarChests {
  StarChests._();
  static const marks = [20, 40, 60];
  static const rewards = [
    Reward(coins: 300, boosters: {'aim': 1}),
    Reward(coins: 500, boosters: {'extra': 1, 'split': 1}),
    Reward(coins: 1000, hints: 2, infinite: Duration(minutes: 30), chest: true),
  ];

  static int starsIn(int world) {
    final p = Profile.instance;
    final repo = LevelRepo.instance;
    var s = 0;
    for (var i = 0; i < repo.count; i++) {
      final l = repo[i];
      if (l.world == world) s += p.stars[l.id] ?? 0;
    }
    return s;
  }

  static bool claimed(int world, int k) => Profile.instance.starChests.contains('$world-$k');
  static bool ready(int world, int k) => !claimed(world, k) && starsIn(world) >= marks[k];
  static bool anyReady(int upToWorld) {
    for (var w = 1; w <= upToWorld; w++) {
      for (var k = 0; k < 3; k++) {
        if (ready(w, k)) return true;
      }
    }
    return false;
  }

  static Reward claim(int world, int k) {
    Profile.instance.starChests.add('$world-$k');
    rewards[k].grant();
    return rewards[k];
  }
}
