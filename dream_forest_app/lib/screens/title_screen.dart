import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/art.dart';
import '../app/save_data.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../widgets/ui_kit.dart';
import 'camp_screen.dart';
import 'world_map_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});
  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _float.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    Sfx.instance.music('title');
    final logo = Art.instance.pathOf('ui/logo');
    return Scaffold(
      body: ForestBackdrop(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_float, _intro]),
            builder: (_, _) {
              final k = Curves.easeOutCubic.transform(_intro.value);
              final bob = math.sin(_float.value * math.pi * 2) * 6;
              return Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 16,
                    child: Row(
                      children: [
                        CoinBadge(save.coins),
                        const SizedBox(width: 10),
                        RoundIconButton(
                          save.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          onTap: () => setState(() {
                            save.setSound(!save.sound);
                            Sfx.instance.refreshMusic();
                          }),
                        ),
                        const SizedBox(width: 8),
                        RoundIconButton(
                          save.haptics ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                          onTap: () => setState(() => save.setHaptics(!save.haptics)),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Opacity(
                      opacity: k,
                      child: Transform.translate(
                        offset: Offset(0, (1 - k) * 30 + bob),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('DREAM FOREST', style: display(16, color: Palette.mute).copyWith(letterSpacing: 8)),
                            const SizedBox(height: 4),
                            logo != null ? Image.asset(logo, height: 130) : const ShinyTitle('꿈의 숲', size: 88),
                            const SizedBox(height: 6),
                            Text('고른 스킬로 강해지고, 잠든 숲을 끝까지 올라가요', style: TextStyle(fontSize: 15, color: Palette.ink.withValues(alpha: 0.85))),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GlowButton(
                                  label: '모험 떠나기',
                                  icon: Icons.play_arrow_rounded,
                                  fontSize: 24,
                                  onTap: () => Navigator.of(context).push(fadeRoute(const WorldMapScreen())).then((_) => setState(() {})),
                                ),
                                const SizedBox(width: 16),
                                GlowButton(
                                  label: '캠프',
                                  icon: Icons.local_fire_department_rounded,
                                  colors: GlowButton.secondary,
                                  textColor: Palette.ink,
                                  onTap: () => Navigator.of(context).push(fadeRoute(const CampScreen())).then((_) => setState(() {})),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text('★ ${save.totalStars} / 30', style: display(15, color: Palette.gold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
