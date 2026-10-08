import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import '../app/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// 분석 이벤트를 한 곳으로 모은다. 출시 시 Firebase Analytics 등에 연결.
class Analytics {
  static final List<String> recent = [];
  static void log(String event, [Map<String, Object?> params = const {}]) {
    final line = '$event $params';
    recent.add(line);
    if (recent.length > 200) recent.removeAt(0);
    if (kDebugMode) debugPrint('[analytics] $line');
  }
}

/// 광고 인터페이스. 출시 시 google_mobile_ads 구현으로 교체 (docs/GDD.md 7장).
abstract class AdService {
  static AdService instance = MockAdService();

  /// 보상형 광고. 끝까지 보면 true.
  Future<bool> rewarded(String placement);

  /// 전면 광고 (규칙은 Economy.interstitialDue)
  Future<void> interstitial(String placement);
}

/// 개발용: 3초짜리 가짜 광고 화면
class MockAdService implements AdService {
  @override
  Future<bool> rewarded(String placement) async {
    Analytics.log('ad_rewarded_show', {'placement': placement});
    final ok = await _fakeAd('보상형 광고', placement, canSkip: false);
    Analytics.log(ok ? 'ad_rewarded_done' : 'ad_rewarded_cancel', {'placement': placement});
    return ok;
  }

  @override
  Future<void> interstitial(String placement) async {
    final p = Profile.instance;
    p.clearsSinceAd = 0;
    p.lastInterstitial = DateTime.now().millisecondsSinceEpoch;
    p.save();
    Analytics.log('ad_interstitial', {'placement': placement});
    await _fakeAd('전면 광고', placement, canSkip: true);
  }

  Future<bool> _fakeAd(String kind, String placement, {required bool canSkip}) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return true;
    final r = await showDialog<bool>(context: ctx, barrierDismissible: false, builder: (_) => _FakeAd(kind: kind, canSkip: canSkip));
    return r ?? false;
  }
}

class _FakeAd extends StatefulWidget {
  const _FakeAd({required this.kind, required this.canSkip});
  final String kind;
  final bool canSkip;
  @override
  State<_FakeAd> createState() => _FakeAdState();
}

class _FakeAdState extends State<_FakeAd> {
  int left = 3;
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => left--);
      if (left <= 0) {
        t?.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Palette.nightDeep,
    child: Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.kind, style: ko(TypeScale.label, color: Palette.inkSoft)),
          const SizedBox(height: Space.l),
          Container(
            height: 160,
            decoration: BoxDecoration(color: Palette.dusk, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(left > 0 ? '$left' : '✓', style: numStyle(TypeScale.hero, color: Palette.inkSoft)),
          ),
          const SizedBox(height: Space.m),
          Text('개발용 가짜 광고예요. 출시 빌드에서는 실제 광고가 나와요.', style: ko(TypeScale.caption, color: Palette.inkSoft), textAlign: TextAlign.center),
          if (widget.canSkip) TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('닫기', style: ko(TypeScale.body, color: Palette.inkSoft))),
        ],
      ),
    ),
  );
}

/// 결제 인터페이스. 출시 시 in_app_purchase 구현으로 교체.
abstract class StoreService {
  static StoreService instance = MockStoreService();
  Future<bool> buy(Product p);
}

class MockStoreService implements StoreService {
  @override
  Future<bool> buy(Product p) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    Analytics.log('iap_start', {'id': p.id, 'price': p.price});
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: Palette.dusk,
        title: Text(p.name, style: ko(TypeScale.title)),
        content: Text('개발용 테스트 결제예요. 실제로 돈이 나가지 않아요.\n${p.priceLabel}', style: ko(TypeScale.body, color: Palette.inkSoft)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('취소', style: ko(TypeScale.body, color: Palette.inkSoft))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('${p.priceLabel} 결제', style: ko(TypeScale.body, color: Palette.moon))),
        ],
      ),
    );
    if (ok != true) {
      Analytics.log('iap_cancel', {'id': p.id});
      return false;
    }
    _deliver(p);
    Analytics.log('iap_success', {'id': p.id, 'price': p.price});
    return true;
  }

  void _deliver(Product p) {
    final pr = Profile.instance;
    pr.spent += p.price;
    switch (p.id) {
      case 'noads':
        pr.adsRemoved = true;
      case 'starter':
        pr.starterBought = true;
      case 'piggy':
        pr.coins += pr.piggy;
        pr.piggy = 0;
      case 'pass':
        pr.passPremium = true;
    }
    p.reward.grant();
    pr.save();
  }
}
