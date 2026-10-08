import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 플레이어 저장 데이터. 모든 진행·재화·설정이 여기 있다.
class Profile extends ChangeNotifier {
  Profile._();
  static final Profile instance = Profile._();
  static const _key = 'echo_arrow.profile.v1';
  SharedPreferences? _prefs;

  // 진행
  Map<int, int> stars = {}; // 레벨 id → 별
  int get cleared => stars.length;
  int get totalStars => stars.values.fold(0, (a, b) => a + b);
  int get nextLevelIndex => cleared; // 순서대로 열림

  // 재화
  int coins = 300;
  int hearts = 5;
  int heartStamp = 0; // 마지막 하트 계산 시각(ms)
  int infiniteUntil = 0; // 무한 하트 종료 시각(ms)
  Map<String, int> boosters = {'aim': 0, 'extra': 0, 'split': 0};
  int hints = 0;

  // 리텐션
  int checkinDay = 0; // 받은 날 수 (7일 순환, 초기화 없음)
  String checkinLast = '';
  int streak = 0; // 메아리 연승(첫 시도 연속 클리어)
  int best = 0;
  String dailyDone = '';
  int piggy = 0;
  int passStars = 0; // 이번 시즌에 모은 별
  bool passPremium = false;
  Set<int> passClaimed = {};
  Set<int> passClaimedPremium = {};

  // 수익
  bool adsRemoved = false;
  double spent = 0;
  int starterUntil = 0; // 스타터 팩 마감
  bool starterBought = false;
  int clearsSinceAd = 0;
  int lastInterstitial = 0;
  String adContinueDate = '';
  int adContinues = 0;

  // 꾸미기
  String trail = 'moon';
  Set<String> trails = {'moon'};

  // 온보딩·설정
  Set<String> seen = {};
  bool sound = true;
  bool haptics = true;
  bool reduceMotion = false;

  static const maxHearts = 5;
  static const heartRegenMs = 30 * 60 * 1000;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (heartStamp == 0) heartStamp = DateTime.now().millisecondsSinceEpoch;
    tickHearts();
  }

  void save() {
    _prefs?.setString(_key, jsonEncode(_toJson()));
    notifyListeners();
  }

  // ---------- 하트 ----------
  bool get infinite => DateTime.now().millisecondsSinceEpoch < infiniteUntil;
  bool get heartsActive => cleared >= 5; // 6단계부터 하트 사용 (온보딩)

  void tickHearts() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (hearts >= maxHearts) {
      heartStamp = now;
      return;
    }
    final gained = (now - heartStamp) ~/ heartRegenMs;
    if (gained > 0) {
      hearts = (hearts + gained).clamp(0, maxHearts);
      heartStamp += gained * heartRegenMs;
      if (hearts >= maxHearts) heartStamp = now;
    }
  }

  /// 다음 하트까지 남은 시간
  Duration get nextHeartIn {
    tickHearts();
    if (hearts >= maxHearts) return Duration.zero;
    final now = DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: heartRegenMs - (now - heartStamp));
  }

  bool get canPlay => !heartsActive || infinite || hearts > 0;

  void loseHeart() {
    if (!heartsActive || infinite) return;
    tickHearts();
    if (hearts >= maxHearts) heartStamp = DateTime.now().millisecondsSinceEpoch;
    hearts = (hearts - 1).clamp(0, maxHearts);
    save();
  }

  void addHearts(int n) {
    hearts = (hearts + n).clamp(0, maxHearts);
    save();
  }

  void addInfinite(Duration d) {
    final now = DateTime.now().millisecondsSinceEpoch;
    infiniteUntil = (infiniteUntil > now ? infiniteUntil : now) + d.inMilliseconds;
    save();
  }

  // ---------- 재화 ----------
  bool spend(int c) {
    if (coins < c) return false;
    coins -= c;
    save();
    return true;
  }

  void earn(int c) {
    coins += c;
    save();
  }

  // ---------- 날짜 ----------
  static String today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool get checkinAvailable => cleared >= 3 && checkinLast != today();
  bool get dailyAvailable => cleared >= 12 && dailyDone != today();

  int get adContinuesLeft {
    if (adContinueDate != today()) return 3;
    return (3 - adContinues).clamp(0, 3);
  }

  void useAdContinue() {
    if (adContinueDate != today()) {
      adContinueDate = today();
      adContinues = 0;
    }
    adContinues++;
    save();
  }

  bool get starterActive => !starterBought && starterUntil > DateTime.now().millisecondsSinceEpoch;

  // ---------- 직렬화 ----------
  Map<String, dynamic> _toJson() => {
    'stars': stars.map((k, v) => MapEntry('$k', v)),
    'coins': coins,
    'hearts': hearts,
    'heartStamp': heartStamp,
    'infiniteUntil': infiniteUntil,
    'boosters': boosters,
    'hints': hints,
    'checkinDay': checkinDay,
    'checkinLast': checkinLast,
    'streak': streak,
    'best': best,
    'dailyDone': dailyDone,
    'piggy': piggy,
    'passStars': passStars,
    'passPremium': passPremium,
    'passClaimed': passClaimed.toList(),
    'passClaimedPremium': passClaimedPremium.toList(),
    'adsRemoved': adsRemoved,
    'spent': spent,
    'starterUntil': starterUntil,
    'starterBought': starterBought,
    'clearsSinceAd': clearsSinceAd,
    'lastInterstitial': lastInterstitial,
    'adContinueDate': adContinueDate,
    'adContinues': adContinues,
    'trail': trail,
    'trails': trails.toList(),
    'seen': seen.toList(),
    'sound': sound,
    'haptics': haptics,
    'reduceMotion': reduceMotion,
  };

  void _fromJson(Map<String, dynamic> j) {
    stars = (j['stars'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int));
    coins = j['coins'] as int? ?? coins;
    hearts = j['hearts'] as int? ?? hearts;
    heartStamp = j['heartStamp'] as int? ?? 0;
    infiniteUntil = j['infiniteUntil'] as int? ?? 0;
    boosters = {...boosters, ...(j['boosters'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int))};
    hints = j['hints'] as int? ?? 0;
    checkinDay = j['checkinDay'] as int? ?? 0;
    checkinLast = j['checkinLast'] as String? ?? '';
    streak = j['streak'] as int? ?? 0;
    best = j['best'] as int? ?? 0;
    dailyDone = j['dailyDone'] as String? ?? '';
    piggy = j['piggy'] as int? ?? 0;
    passStars = j['passStars'] as int? ?? 0;
    passPremium = j['passPremium'] as bool? ?? false;
    passClaimed = {for (final v in j['passClaimed'] as List? ?? []) v as int};
    passClaimedPremium = {for (final v in j['passClaimedPremium'] as List? ?? []) v as int};
    adsRemoved = j['adsRemoved'] as bool? ?? false;
    spent = (j['spent'] as num? ?? 0).toDouble();
    starterUntil = j['starterUntil'] as int? ?? 0;
    starterBought = j['starterBought'] as bool? ?? false;
    clearsSinceAd = j['clearsSinceAd'] as int? ?? 0;
    lastInterstitial = j['lastInterstitial'] as int? ?? 0;
    adContinueDate = j['adContinueDate'] as String? ?? '';
    adContinues = j['adContinues'] as int? ?? 0;
    trail = j['trail'] as String? ?? 'moon';
    trails = {for (final v in j['trails'] as List? ?? ['moon']) v as String};
    seen = {for (final v in j['seen'] as List? ?? []) v as String};
    sound = j['sound'] as bool? ?? true;
    haptics = j['haptics'] as bool? ?? true;
    reduceMotion = j['reduceMotion'] as bool? ?? false;
  }

  @visibleForTesting
  void resetForTest() => _fromJson({});
}
