import 'package:flutter/material.dart';

import '../app/economy.dart';
import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../services/services.dart';
import '../widgets/icons.dart';
import '../widgets/ui.dart';

/// 화살 패스 탭: 별을 모아 칸을 연다. 무료 줄(왼쪽) + 프리미엄 줄(오른쪽)
class PassPage extends StatefulWidget {
  const PassPage({super.key, this.topInset = 0, this.bottomInset = 0});
  final double topInset, bottomInset;
  @override
  State<PassPage> createState() => _PassPageState();
}

class _PassPageState extends State<PassPage> with AutomaticKeepAliveClientMixin {
  Profile get p => Profile.instance;
  int get reached => (p.passStars ~/ Economy.passStep).clamp(0, Economy.passTiers);

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(Space.l, widget.topInset + Space.m, Space.l, Space.m),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                RibbonTitle(text: tr('pass_title'), color: Palette.echo),
                const SizedBox(height: Space.m),
                Container(
                  padding: const EdgeInsets.all(Space.l),
                  decoration: BoxDecoration(color: const Color(0xCC141A4A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Palette.line)),
                  child: Column(
                    children: [
                      Row(children: [
                        const GameIcon(GI.star, size: 28),
                        const SizedBox(width: Space.s),
                        Text('${p.passStars}', style: numStyle(TypeScale.title)),
                        const Spacer(),
                        Text(tr('pass_desc', {'n': Economy.passStep, 'a': reached, 'b': Economy.passTiers}), style: ko(TypeScale.caption, color: Palette.inkSoft)),
                      ]),
                      const SizedBox(height: Space.s),
                      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: reached / Economy.passTiers, minHeight: 12, color: Palette.moon, backgroundColor: const Color(0x33FFFFFF))),
                      if (!p.passPremium) ...[
                        const SizedBox(height: Space.m),
                        Btn(tr('premium_open', {'p': Economy.product('pass').priceLabel}), style: BtnStyle.echo, onTap: () async {
                          if (await StoreService.instance.buy(Economy.product('pass'))) setState(() {});
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.m),
                Row(children: [
                  Expanded(child: Text(tr('free'), style: ko(TypeScale.label), textAlign: TextAlign.center)),
                  const SizedBox(width: 44),
                  Expanded(child: Text(tr('premium'), style: ko(TypeScale.label, color: Palette.echo), textAlign: TextAlign.center)),
                ]),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(Space.l, 0, Space.l, widget.bottomInset + Space.xl),
          sliver: SliverList.builder(
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
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i < reached ? Palette.moon : const Color(0xFF232C66), border: Border.all(color: const Color(0x55FFFFFF))),
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: numStyle(TypeScale.body, color: i < reached ? const Color(0xFF2A1B05) : Palette.inkSoft)),
                      ),
                    ),
                  ),
                  Expanded(child: _Cell(reward: Economy.passPremiumReward(i), open: i < reached, claimed: p.passClaimedPremium.contains(i), locked: !p.passPremium, premium: true, onTap: () => _claim(i, true))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.reward, required this.open, required this.claimed, required this.locked, required this.onTap, this.premium = false});
  final Reward reward;
  final bool open, claimed, locked, premium;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ready = open && !claimed && !locked;
    final accent = premium ? Palette.echo : Palette.moon;
    return Pressable(
      onTap: ready ? onTap : null,
      semantic: reward.lines.join(', '),
      sound: null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: Space.s),
        decoration: BoxDecoration(
          gradient: ready ? LinearGradient(colors: [accent.withValues(alpha: 0.35), accent.withValues(alpha: 0.12)]) : null,
          color: ready ? null : const Color(0x99141A4A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ready ? accent : Palette.line, width: ready ? 2 : 1),
          boxShadow: ready ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            Expanded(child: Text(reward.lines.join('\n'), style: ko(TypeScale.caption + 1, color: open ? Palette.ink : Palette.inkSoft), maxLines: 2)),
            if (claimed)
              const GameIcon(GI.check, size: 24)
            else if (locked || !open)
              const GameIcon(GI.lock, size: 20)
            else
              const GameIcon(GI.chest, size: 26),
          ],
        ),
      ),
    );
  }
}
