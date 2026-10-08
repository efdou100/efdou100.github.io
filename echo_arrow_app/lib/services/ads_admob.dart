import 'dart:async';
import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app/profile.dart';
import 'services.dart';

/// 애드몹 광고. 지금은 구글 공식 테스트 광고 ID 를 쓴다.
/// 출시 전: [AdIds] 의 값을 애드몹 콘솔에서 만든 광고 단위 ID 로 바꾸고,
/// AndroidManifest.xml / Info.plist 의 APPLICATION_ID 도 실제 앱 ID 로 바꾼다. (docs/RELEASE_CHECKLIST.md)
class AdIds {
  static const testMode = true;

  static String get rewarded => Platform.isIOS
      ? (testMode ? 'ca-app-pub-3940256099942544/1712485313' : 'YOUR_IOS_REWARDED_ID')
      : (testMode ? 'ca-app-pub-3940256099942544/5224354917' : 'YOUR_ANDROID_REWARDED_ID');

  static String get interstitial => Platform.isIOS
      ? (testMode ? 'ca-app-pub-3940256099942544/4411468910' : 'YOUR_IOS_INTERSTITIAL_ID')
      : (testMode ? 'ca-app-pub-3940256099942544/1033173712' : 'YOUR_ANDROID_INTERSTITIAL_ID');
}

class AdMobService implements AdService {
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _canRequest = false;
  int _retry = 0;

  /// 앱 시작 시: 유럽 등 동의가 필요한 지역이면 동의 창(UMP)을 띄운 뒤 광고 SDK 초기화
  Future<void> init() async {
    final consent = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!consent.isCompleted) consent.complete();
      },
      (_) {
        if (!consent.isCompleted) consent.complete();
      },
    );
    await consent.future.timeout(const Duration(seconds: 8), onTimeout: () {});
    _canRequest = await ConsentInformation.instance.canRequestAds();
    if (!_canRequest) return;
    await MobileAds.instance.initialize();
    _loadRewarded();
    _loadInterstitial();
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _retry = 0;
        },
        onAdFailedToLoad: (e) {
          _rewarded = null;
          _retry++;
          Future<void>.delayed(Duration(seconds: (5 * _retry).clamp(5, 60)), _loadRewarded);
        },
      ),
    );
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) {
          _interstitial = null;
          Future<void>.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  @override
  Future<bool> rewarded(String placement) async {
    final ad = _rewarded;
    Analytics.log('ad_rewarded_show', {'placement': placement, 'ready': ad != null});
    if (ad == null) {
      if (_canRequest) _loadRewarded();
      return false;
    }
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    final ok = await done.future;
    Analytics.log(ok ? 'ad_rewarded_done' : 'ad_rewarded_cancel', {'placement': placement});
    return ok;
  }

  @override
  Future<void> interstitial(String placement) async {
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    final p = Profile.instance;
    p.clearsSinceAd = 0;
    p.lastInterstitial = DateTime.now().millisecondsSinceEpoch;
    p.save();
    Analytics.log('ad_interstitial', {'placement': placement});
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    await done.future;
  }
}
