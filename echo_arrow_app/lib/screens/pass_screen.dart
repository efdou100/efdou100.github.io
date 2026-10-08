import 'package:flutter/material.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../services/services.dart';
import '../widgets/ui.dart';

/// 화살 패스: 별을 모아 칸을 연다. 무료 줄 + 프리미엄 줄
class PassScreen extends StatefulWidget {
  const PassScreen({super.key});
  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {
  Profile get p => Profile.instance;
  int get reached => (p.passStars ~/ Economy.passStep).clamp(0, Economy.passTiers);

  void _claim(int i, bool premium) {
    final set = premium ? p.passClaimedPremium : p.passClaimed;
    if (set.contains(i) || i >= reached || (premium && !p.passPremium)) return;
    (premium ? Economy.passPremiumReward(i) : Economy.passFree(i)).grant();
    set.add(i);
    p.save();
    Sfx.instance.play('chest');
    Analytics.log('pass_claim', {'tier': i, 'premium': premium});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      body: NightSky(
        child: Column(
          children: [
            SizedBox(height: pad.top + Space.s),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Row(
                children: [
                  RoundBtn(icon: Icons.arrow_back_rounded, label: '뒤로', onTap: () => Navigator.pop(context)),
                  const SizedBox(width: Space.m),
                  Text('화살 패스', style: ko(TypeScale.title)),
                  const Spacer(),
                  Pill(icon: const Icon(Icons.star_rounded, color: Palette.moon, size: 22), text: '${p.passStars}'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                children: [
                  Text('별 ${Economy.passStep}개마다 한 칸씩 열려요 · $reached / ${Economy.passTiers}칸', style: ko(TypeScale.body, color: Palette.inkSoft)),
                  const SizedBox(height: Space.s),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: reached / Economy.passTiers, minHeight: 10, color: Palette.moon, backgroundColor: const Color(0x33FFFFFF))),
                  if (!p.passPremium) ...[
                    const SizedBox(height: Space.m),
                    Btn('프리미엄 열기 ${Economy.product('pass').priceLabel}', style: BtnStyle.echo, onTap: () async {
                      if (await StoreService.instance.buy(Economy.product('pass'))) setState(() {});
                    }),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Row(children: [Expanded(child: Text('무료', style: ko(TypeScale.label), textAlign: TextAlign.center)), const SizedBox(width: 44), Expanded(child: Text('프리미엄', style: ko(TypeScale.label, color: Palette.echo), textAlign: TextAlign.center))]),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, pad.bottom + Space.xl),
                itemCount: Economy.passTiers,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: Row(
                    children: [
                      Expanded(child: _Cell(reward: Economy.passFree(i), open: i < reached, claimed: p.passClaimed.contains(i), locked: false, onTap: () => _claim(i, false))),
                      SizedBox(
                        width: 44,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: i < reached ? Palette.moon : const Color(0xFF232C66)),
                            alignment: Alignment.center,
                            child: Text('${i + 1}', style: numStyle(TypeScale.body, color: i < reached ? const Color(0xFF2A1B05) : Palette.inkSoft)),
                          ),
                        ),
                      ),
                      Expanded(child: _Cell(reward: Economy.passPremiumReward(i), open: i < reached, claimed: p.passClaimedPremium.contains(i), locked: !p.passPremium, onTap: () => _claim(i, true))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.reward, required this.open, required this.claimed, required this.locked, required this.onTap});
  final Reward reward;
  final bool open, claimed, locked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ready = open && !claimed && !locked;
    return Pressable(
      onTap: ready ? onTap : null,
      semantic: reward.lines.join(', '),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: Space.s),
        decoration: BoxDecoration(
          color: ready ? const Color(0x33FFD36B) : const Color(0x66101640),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ready ? Palette.moon : Palette.line, width: ready ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(child: Text(reward.lines.join('\n'), style: ko(TypeScale.caption + 1, color: open ? Palette.ink : Palette.inkSoft), maxLines: 2)),
            Icon(claimed ? Icons.check_circle_rounded : (locked ? Icons.lock_rounded : (ready ? Icons.redeem_rounded : Icons.lock_clock_rounded)), color: claimed ? Palette.moss : (ready ? Palette.moon : Palette.inkSoft), size: 22),
          ],
        ),
      ),
    );
  }
}
