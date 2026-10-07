import 'package:flutter/material.dart';

import '../app/save_data.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../widgets/ui_kit.dart';

/// 캠프: 모은 코인으로 영구 강화.
class CampScreen extends StatefulWidget {
  const CampScreen({super.key});
  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen> {
  String? _flash;

  static const _icons = {'attack': 'attack', 'hp': 'heart', 'speed': 'haste', 'crit': 'crit'};
  static const _colors = {
    'attack': [Color(0xFFFFB37A), Color(0xFFE0663A)],
    'hp': [Color(0xFFFF9CB4), Color(0xFFD94A72)],
    'speed': [Color(0xFFB0F0FF), Color(0xFF4FA8E0)],
    'crit': [Color(0xFFFFE89A), Color(0xFFE0A93A)],
  };

  void _buy(String id) {
    if (SaveData.instance.buyUpgrade(id)) {
      Sfx.instance.play('levelup');
      Sfx.instance.haptic();
      setState(() => _flash = id);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _flash = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveData.instance;
    return Scaffold(
      body: ForestBackdrop(
        dim: 0.35,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    RoundIconButton(Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 14),
                    const ShinyTitle('모닥불 캠프', size: 30),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        '스테이지에서 모은 코인으로 영구 강화해요',
                        style: TextStyle(color: Palette.mute, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    CoinBadge(save.coins),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final u in kUpgrades)
                        Expanded(
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: _card(u, save)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(UpgradeDef u, SaveData save) {
    final lv = save.upgrades[u.id] ?? 0;
    final maxed = lv >= SaveData.upgradeMax;
    final cost = save.upgradeCost(u.id);
    final cols = _colors[u.id]!;
    return AnimatedScale(
      scale: _flash == u.id ? 1.06 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: GlassPanel(
        glow: cols.last.withValues(alpha: _flash == u.id ? 0.7 : 0.25),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: cols),
                boxShadow: [BoxShadow(color: cols.last.withValues(alpha: 0.55), blurRadius: 20)],
              ),
              child: SkillIcon(_icons[u.id]!, size: 40),
            ),
            const SizedBox(height: 10),
            Text(
              u.name,
              style: display(19, color: Palette.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(u.desc, style: const TextStyle(color: Palette.mute, fontSize: 12)),
            const SizedBox(height: 8),
            Text('Lv $lv', style: display(28, color: cols.first)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: lv / SaveData.upgradeMax,
                minHeight: 6,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: AlwaysStoppedAnimation(cols.first),
              ),
            ),
            const Spacer(),
            GlowButton(
              label: maxed ? '최대' : '$cost',
              icon: maxed ? Icons.check_rounded : Icons.monetization_on_rounded,
              fontSize: 18,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              onTap: !maxed && save.coins >= cost ? () => _buy(u.id) : null,
            ),
          ],
        ),
      ),
    );
  }
}
