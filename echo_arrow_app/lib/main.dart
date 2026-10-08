import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/profile.dart';
import 'app/sfx.dart';
import 'app/theme.dart';
import 'game/level.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Future.wait([Profile.instance.load(), LevelRepo.instance.load()]);
  await Sfx.instance.init();
  Analytics.log('app_open', {'cleared': Profile.instance.cleared});
  runApp(const EchoArrowApp());
}

class EchoArrowApp extends StatelessWidget {
  const EchoArrowApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '메아리 화살',
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
    theme: buildTheme(),
    // 첫 실행이면 메뉴 없이 바로 1단계 (온보딩: 첫 30초 안에 첫 명중)
    home: Profile.instance.cleared == 0 ? const GameScreen(index: 0) : const HomeScreen(),
  );
}
