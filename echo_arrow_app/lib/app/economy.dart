import '../game/level.dart';
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
  static const boosterName = {'aim': '긴 조준선', 'extra': '화살 +1', 'split': '분열 화살'};
  static const boosterDesc = {'aim': '반사 3번까지 조준선이 보여요', 'extra': '이번 판 화살이 하나 늘어나요', 'split': '처음 튕길 때 세 갈래로 갈라지는 화살 1개'};

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
    Product('starter', '스타터 팩', 1.99, Reward(coins: 2000, boosters: {'aim': 3, 'extra': 3, 'split': 3}, infinite: Duration(hours: 1)), badge: '한 번만'),
    Product('noads', '광고 제거', 3.99, Reward(), badge: '보상형 광고는 유지'),
    Product('piggy', '별빛 저금통 깨기', 2.99, Reward()),
    Product('pass', '화살 패스 프리미엄', 4.99, Reward()),
    Product('coins_s', '코인 한 줌', 0.99, Reward(coins: 500)),
    Product('coins_m', '코인 주머니', 4.99, Reward(coins: 3000), badge: '+20%'),
    Product('coins_l', '코인 상자', 9.99, Reward(coins: 7000), badge: '+40%'),
    Product('coins_xl', '코인 궤짝', 19.99, Reward(coins: 16000), badge: '인기'),
    Product('coins_xxl', '코인 보물고', 49.99, Reward(coins: 45000), badge: '+80%'),
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

  static const trails = {'moon': '달빛', 'ember': '불씨', 'aurora': '오로라'};
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
    if (coins > 0) '코인 $coins',
    for (final e in boosters.entries) '${Economy.boosterName[e.key]} ×${e.value}',
    if (hints > 0) '힌트 ×$hints',
    if (hearts > 0) '하트 ×$hearts',
    if (infinite > Duration.zero) '무한 하트 ${infinite.inMinutes >= 60 ? '${infinite.inHours}시간' : '${infinite.inMinutes}분'}',
    if (trail != null) '궤적 「${Economy.trails[trail]}」',
  ];
}

class Product {
  const Product(this.id, this.name, this.price, this.reward, {this.badge});
  final String id, name;
  final double price;
  final Reward reward;
  final String? badge;
  String get priceLabel => '\$${price.toStringAsFixed(2)}';
}
