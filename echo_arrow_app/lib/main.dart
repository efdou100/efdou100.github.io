import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/art.dart';
import 'app/l10n.dart';
import 'app/profile.dart';
import 'app/sfx.dart';
import 'app/theme.dart';
import 'game/level.dart';
import 'screens/game_screen.dart';
import 'screens/shell.dart';
import 'services/ads_admob.dart';
import 'services/iap_store.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Future.wait([Profile.instance.load(), LevelRepo.instance.load()]);
  await Future.wait([Sfx.instance.init(), Art.instance.init()]);
  // 휴대폰에서는 실제 광고·결제, 웹(개발 확인용)에서는 가짜 구현
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    final ads = AdMobService();
    final store = PlayStoreService();
    AdService.instance = ads;
    StoreService.instance = store;
    unawaited(ads.init());
    unawaited(store.init());
  }
  Analytics.log('app_open', {'cleared': Profile.instance.cleared});
  runApp(const EchoArrowApp());
}

class EchoArrowApp extends StatefulWidget {
  const EchoArrowApp({super.key});
  @override
  State<EchoArrowApp> createState() => _EchoArrowAppState();
}

class _EchoArrowAppState extends State<EchoArrowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱이 뒤로 가면 배경음을 멈추고 저장, 돌아오면 하트 시간 갱신
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final away = state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden;
    Sfx.instance.refreshMusic(paused: away);
    if (away) {
      Profile.instance.save();
    } else {
      Profile.instance.tickHearts();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (_) => tr('app_title'),
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
    theme: buildTheme(),
    // 첫 실행이면 메뉴 없이 바로 1단계 (온보딩: 첫 30초 안에 첫 명중)
    home: Profile.instance.cleared == 0 ? const GameScreen(index: 0) : const MainShell(),
  );
}
