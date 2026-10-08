import '../game/level.dart';
import 'l10n.dart';
import 'profile.dart';

/// 경제 수치와 해금 시점. 숫자는 여기서만 바꾼다. (근거: docs/GDD.md 5장)
class Economy {
  // ---- 해금 (클리어한 판 수 기준) ----
  static const unlockMap = 3;
  static const unlockCheckin = 3;
  static const unlockHearts = 5;
  static const unlockBoosters = 6;
  static const unlockShop = 7;
  static const unlockHint = 9;
  static const unlockDaily = 12;
  static const unlockPass = 14;
  static const unlockStreak = 19;
  static const unlockCollection = 10;
  static const interstitialFrom = 15;

  static bool unlocked(int threshold) => Profile.instance.cleared >= threshold;

  // ---- 보상 ----
  static int clearCoins(LevelData l, int stars) => l.coinReward * stars;
  static const piggyPerClear = 120;
  static const piggyMax = 5000;

  // ---- 이어하기 ----
  static const continueArrows = 2;
  static const continuePrices = [900, 1900, 2900];
  static int continuePrice(int used) => continuePrices[used.clamp(0, continuePrices.length - 1)];

  // ---- 힌트 / 하트 ----
  static const hintPrice = 300;
  static const refillPrice = 900;

  // ---- 부스터 ----
  static const boosterPrice = {'aim': 250, 'extra': 400, 'split': 350};
  static String boosterName(String id) => tr('b_$id');
  static String boosterDesc(String id) => tr('b_${id}_d');

  // ---- 연승 ----
  /// 연승 수에 따라 판 시작 시 무료로 켜지는 부스터
  static List<String> streakBoosters(int streak) => switch (streak) {
    0 => const [],
    1 => const ['aim'],
    2 => const ['aim', 'split'],
    _ => const ['aim', 'split', 'extra'],
  };

  // ---- 출석 (7일 순환, 빠져도 초기화 없음) ----
  static const checkin = [
    Reward(coins: 100),
    Reward(coins: 150, boosters: {'aim': 1}),
    Reward(coins: 200),
    Reward(coins: 250, hints: 1),
    Reward(coins: 300, boosters: {'extra': 1}),
    Reward(coins: 400, boosters: {'split': 1}),
    Reward(coins: 800, boosters: {'aim': 2, 'extra': 1, 'split': 1}, infinite: Duration(minutes: 30), chest: true),
  ];

  // ---- 화살 패스 (별 5개마다 한 칸, 30칸) ----
  static const passStep = 5;
  static const passTiers = 30;
  static Reward passFree(int i) => i % 5 == 4 ? Reward(coins: 300, boosters: const {'aim': 1}) : Reward(coins: 60 + i * 4);
  static Reward passPremiumReward(int i) => switch (i % 6) {
    0 => const Reward(coins: 250),
    1 => const Reward(boosters: {'split': 1}),
    2 => const Reward(hints: 1),
    3 => const Reward(boosters: {'extra': 1}),
    4 => const Reward(infinite: Duration(hours: 1)),
    _ => Reward(coins: 500, trail: i == 29 ? 'aurora' : i == 17 ? 'ember' : null),
  };

  // ---- 상점 상품 (가격은 스토어 연결 전 표시용) ----
  static const products = [
    Product('starter', 1.99, Reward(coins: 2000, boosters: {'aim': 3, 'extra': 3, 'split': 3}, infinite: Duration(hours: 1)), badge: 'badge_once'),
    Product('noads', 3.99, Reward(), badge: 'badge_rewarded'),
    Product('piggy', 2.99, Reward()),
    Product('pass', 4.99, Reward()),
    Product('coins_s', 0.99, Reward(coins: 500)),
    Product('coins_m', 4.99, Reward(coins: 3000), badge: '+20%'),
    Product('coins_l', 9.99, Reward(coins: 7000), badge: '+40%'),
    Product('coins_xl', 19.99, Reward(coins: 16000), badge: 'badge_popular'),
    Product('coins_xxl', 49.99, Reward(coins: 45000), badge: '+80%'),
  ];
  static Product product(String id) => products.firstWhere((p) => p.id == id);

  // ---- 광고 ----
  static bool interstitialDue() {
    final p = Profile.instance;
    if (p.adsRemoved || p.cleared < interstitialFrom) return false;
    final every = p.spent > 0 ? 6 : 3;
    final gap = DateTime.now().millisecondsSinceEpoch - p.lastInterstitial;
    return p.clearsSinceAd >= every && gap > 120000;
  }

  static const trailIds = ['moon', 'ember', 'aurora'];
  static String trailName(String id) => tr('trail_$id');
}

class Reward {
  const Reward({this.coins = 0, this.boosters = const {}, this.hints = 0, this.infinite = Duration.zero, this.hearts = 0, this.trail, this.chest = false});
  final int coins;
  final Map<String, int> boosters;
  final int hints;
  final Duration infinite;
  final int hearts;
  final String? trail;
  final bool chest;

  void grant() {
    final p = Profile.instance;
    p.coins += coins;
    boosters.forEach((k, v) => p.boosters[k] = (p.boosters[k] ?? 0) + v);
    p.hints += hints;
    if (hearts > 0) p.hearts = (p.hearts + hearts).clamp(0, Profile.maxHearts);
    if (trail != null) p.trails.add(trail!);
    if (infinite > Duration.zero) {
      p.addInfinite(infinite);
    } else {
      p.save();
    }
  }

  /// 짧은 설명 목록 (화면 표시용)
  List<String> get lines => [
    if (coins > 0) tr('rw_coins', {'n': coins}),
    for (final e in boosters.entries) tr('rw_booster', {'x': Economy.boosterName(e.key), 'n': e.value}),
    if (hints > 0) tr('rw_hints', {'n': hints}),
    if (hearts > 0) tr('rw_hearts', {'n': hearts}),
    if (infinite > Duration.zero) infinite.inMinutes >= 60 ? tr('rw_inf_h', {'n': infinite.inHours}) : tr('rw_inf_m', {'n': infinite.inMinutes}),
    if (trail != null) tr('rw_trail', {'x': Economy.trailName(trail!)}),
  ];
}

class Product {
  const Product(this.id, this.price, this.reward, {this.badge});
  final String id;
  String get name => tr('p_$id');
  String? get badgeText => badge == null ? null : tr(badge!);
  final double price;
  final Reward reward;
  final String? badge;
  String get priceLabel => '\$${price.toStringAsFixed(2)}';
}
