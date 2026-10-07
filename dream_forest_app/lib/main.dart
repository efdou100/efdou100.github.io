import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/art.dart';
import 'app/save_data.dart';
import 'app/sfx.dart';
import 'app/theme.dart';
import 'screens/title_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SaveData.instance.load();
  await Art.instance.scan();
  Sfx.instance.init();
  runApp(const DreamForestApp());
}

class DreamForestApp extends StatelessWidget {
  const DreamForestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: '꿈의 숲', debugShowCheckedModeBanner: false, theme: buildTheme(), home: const TitleScreen());
  }
}
