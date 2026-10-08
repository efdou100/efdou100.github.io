import 'package:flutter/material.dart';

import '../app/economy.dart';
import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/level.dart';
import '../game/painter.dart' show WorldTheme;
import '../services/services.dart';
import '../widgets/icons.dart';
import '../widgets/ui.dart';
import 'sheets.dart';

/// 판 시작 팝업: 레벨 리본 + 목표 + 부스터 3칸 + 큰 플레이 버튼
class LevelStartSheet extends StatefulWidget {
  const LevelStartSheet({super.key, required this.index});
  final int index;
  @override
  State<LevelStartSheet> createState() => _LevelStartSheetState();
}

class _LevelStartSheetState extends State<LevelStartSheet> {
  final Set<String> picked = {};
  late final Set<String> free;

  @override
  void initState() {
    super.initState();
    free = Economy.unlocked(Economy.unlockStreak) ? Economy.streakBoosters(Profile.instance.streak).toSet() : {};
  }

  @override
  Widget build(BuildContext context) {
    final l = LevelRepo.instance[widget.index];
    final p = Profile.instance;
    final stars = p.stars[l.id] ?? 0;
    final th = WorldTheme.of(l.world);
    final tier = switch (l.tier) {
      Tier.hard => ('${tr('tier_hard')} · ${tr('coins_mult', {'n': 2})}', Palette.danger),
      Tier.superhard => ('${tr('tier_superhard')} · ${tr('coins_mult', {'n': 3})}', Palette.violet),
      Tier.boss => ('${tr('tier_boss')} · ${tr('coins_mult', {'n': 3})}', Palette.moon),
      _ => null,
    };
    return SheetFrame(
      title: tr('level_n', {'n': l.id}),
      accent: tier?.$2 ?? th.accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(worldName(l.world), style: ko(TypeScale.body, color: l.isEcho ? Palette.echo : th.accent)),
          Text(levelName(l.name), style: ko(TypeScale.display), textAlign: TextAlign.center),
          if (tier != null) Padding(padding: const EdgeInsets.only(top: Space.s), child: TierBadge(text: tier.$1, color: tier.$2)),
          const SizedBox(height: Space.m),
          StarRow(stars: stars, size: 34, animate: false),
          const SizedBox(height: Space.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
            decoration: BoxDecoration(color: const Color(0x66101640), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const GameIcon(GI.quiver, size: 20),
              const SizedBox(width: 6),
              Flexible(child: Text(tr('shots_info', {'s': l.shots, 'p': l.par}), style: ko(TypeScale.body, color: Palette.ink))),
            ]),
          ),
          if (Economy.unlocked(Economy.unlockBoosters)) ...[
            const SizedBox(height: Space.l),
            Row(children: [
              for (final k in const ['aim', 'extra', 'split']) ...[
                Expanded(child: _BoosterCard(id: k, picked: picked.contains(k) || free.contains(k), free: free.contains(k), onTap: () => _toggle(k))),
                if (k != 'split') const SizedBox(width: Space.s),
              ],
            ]),
            if (free.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(tr('streak_free', {'n': p.streak}), style: ko(TypeScale.caption, color: Palette.echo))),
          ],
          const SizedBox(height: Space.xl),
          Btn(p.canPlay ? tr('play') : tr('no_hearts'), style: BtnStyle.green, height: 64, icon: p.heartsActive && !p.infinite ? const HeartIcon(size: 22) : null, onTap: _start, sound: 'pop'),
          if (p.heartsActive && !p.infinite) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(tr('hearts_note'), style: ko(TypeScale.caption, color: Palette.inkSoft))),
        ],
      ),
    );
  }

  void _toggle(String k) {
    if (free.contains(k)) return;
    final p = Profile.instance;
    setState(() {
      if (picked.contains(k)) {
        picked.remove(k);
      } else if ((p.boosters[k] ?? 0) > 0 || p.coins >= Economy.boosterPrice[k]!) {
        picked.add(k);
        Sfx.instance.play('coin');
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('no_coins'), style: ko(TypeScale.body)), backgroundColor: Palette.dusk));
      }
    });
  }

  void _start() {
    final p = Profile.instance;
    if (!p.canPlay) {
      Navigator.pop(context, <String>{});
      return;
    }
    for (final k in picked) {
      if ((p.boosters[k] ?? 0) > 0) {
        p.boosters[k] = p.boosters[k]! - 1;
      } else {
        p.coins -= Economy.boosterPrice[k]!;
      }
      Analytics.log('booster_use', {'id': k});
    }
    p.save();
    Navigator.pop(context, {...picked, ...free});
  }
}

class _BoosterCard extends StatelessWidget {
  const _BoosterCard({required this.id, required this.picked, required this.free, required this.onTap});
  final String id;
  final bool picked, free;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final own = p.boosters[id] ?? 0;
    final icon = switch (id) { 'aim' => GI.aim, 'extra' => GI.extra, _ => GI.split };
    return Pressable(
      onTap: onTap,
      semantic: '${Economy.boosterName(id)}, ${Economy.boosterDesc(id)}',
      sound: null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(Space.xs, Space.m, Space.xs, Space.s),
        decoration: BoxDecoration(
          gradient: picked ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55FFD36B), Color(0x22FFD36B)]) : null,
          color: picked ? null : const Color(0x66101640),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: picked ? Palette.moon : Palette.line, width: picked ? 2.5 : 1),
          boxShadow: picked ? const [BoxShadow(color: Color(0x55FFD36B), blurRadius: 12)] : null,
        ),
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            GameIcon(icon, size: 40),
            if (picked) const Positioned(right: -10, top: -8, child: GameIcon(GI.check, size: 22)),
          ]),
          const SizedBox(height: 4),
          Text(Economy.boosterName(id), style: ko(13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          if (free)
            Text(tr('free'), style: ko(TypeScale.caption, color: Palette.echo))
          else if (own > 0)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1), decoration: BoxDecoration(color: Palette.moss, borderRadius: BorderRadius.circular(8)), child: Text('×$own', style: numStyle(TypeScale.caption, color: const Color(0xFF0B2B1C))))
          else
            Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 14), const SizedBox(width: 3), Text('${Economy.boosterPrice[id]}', style: numStyle(TypeScale.caption))]),
        ]),
      ),
    );
  }
}

/// 하트 충전
class HeartsSheet extends StatefulWidget {
  const HeartsSheet({super.key});
  @override
  State<HeartsSheet> createState() => _HeartsSheetState();
}

class _HeartsSheetState extends State<HeartsSheet> {
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final full = p.hearts >= Profile.maxHearts || p.infinite;
    return SheetFrame(
      title: p.infinite ? tr('infinite_on') : tr('hearts_title', {'n': p.hearts, 'm': Profile.maxHearts}),
      accent: Palette.blossom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < Profile.maxHearts; i++) Padding(padding: const EdgeInsets.all(3), child: Opacity(opacity: i < p.hearts || p.infinite ? 1 : 0.25, child: HeartIcon(size: 40, infinite: p.infinite)))]),
          const SizedBox(height: Space.s),
          Text(full ? tr('hearts_full') : tr('next_heart', {'t': fmtDur(p.nextHeartIn)}), style: ko(TypeScale.body, color: Palette.inkSoft)),
          const SizedBox(height: Space.xl),
          Btn(tr('refill'), style: BtnStyle.green, trailing: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 20), const SizedBox(width: 4), Text('${Economy.refillPrice}', style: numStyle(TypeScale.label, color: Colors.white))]), onTap: full
              ? null
              : () {
                  if (p.spend(Economy.refillPrice)) {
                    p.addHearts(Profile.maxHearts);
                    Analytics.log('hearts_refill_coins');
                    Navigator.pop(context);
                  } else {
                    showSheet<bool>(context, const CoinShortSheet()).then((_) => setState(() {}));
                  }
                }),
          const SizedBox(height: Space.m),
          Btn(tr('ad_heart'), style: BtnStyle.echo, icon: const GameIcon(GI.ad, size: 22), onTap: full
              ? null
              : () async {
                  if (await AdService.instance.rewarded('heart')) {
                    p.addHearts(1);
                    if (context.mounted) setState(() {});
                  }
                }),
        ],
      ),
    );
  }
}

/// 7일 출석 (빠진 날이 있어도 초기화하지 않음)
class CheckinSheet extends StatefulWidget {
  const CheckinSheet({super.key});
  @override
  State<CheckinSheet> createState() => _CheckinSheetState();
}

class _CheckinSheetState extends State<CheckinSheet> {
  bool claimed = false;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final day = p.checkinDay % 7;
    final can = p.checkinAvailable && !claimed;
    return SheetFrame(
      title: tr('checkin_title'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('checkin_desc'), style: ko(TypeScale.body, color: Palette.inkSoft), textAlign: TextAlign.center),
          const SizedBox(height: Space.l),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Space.s,
            crossAxisSpacing: Space.s,
            childAspectRatio: 0.9,
            children: [for (var i = 0; i < 6; i++) _DayCard(day: i, reward: Economy.checkin[i], state: i < day || (claimed && i == day) ? 2 : (i == day ? 1 : 0))],
          ),
          const SizedBox(height: Space.s),
          SizedBox(height: 92, child: _DayCard(day: 6, reward: Economy.checkin[6], state: 6 < day || (claimed && day == 6) ? 2 : (day == 6 ? 1 : 0), wide: true)),
          const SizedBox(height: Space.xl),
          Btn(can ? tr('claim_day', {'n': day + 1}) : tr('see_tomorrow'), style: BtnStyle.green, onTap: can ? () => _claim(1) : null, sound: 'chest'),
          if (can) ...[
            const SizedBox(height: Space.m),
            Btn(tr('claim_double'), style: BtnStyle.echo, icon: const GameIcon(GI.ad, size: 22), onTap: () async {
              if (await AdService.instance.rewarded('checkin_double')) _claim(2);
            }),
          ],
        ],
      ),
    );
  }

  void _claim(int mult) {
    final p = Profile.instance;
    final r = Economy.checkin[p.checkinDay % 7];
    for (var i = 0; i < mult; i++) {
      r.grant();
    }
    p.checkinDay++;
    p.checkinLast = Profile.today();
    p.save();
    Analytics.log('checkin', {'day': p.checkinDay, 'mult': mult});
    setState(() => claimed = true);
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.reward, required this.state, this.wide = false});
  final int day;
  final Reward reward;
  final int state; // 0 앞으로, 1 오늘, 2 받음
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final today = state == 1;
    final content = [
      Text(tr('day_n', {'n': day + 1}), style: ko(TypeScale.caption, color: today ? Palette.moon : Palette.inkSoft)),
      const SizedBox(height: 4, width: 8),
      reward.chest ? const GameIcon(GI.chest, size: 40) : const CoinIcon(size: 30),
      const SizedBox(height: 4, width: 8),
      Text(reward.chest ? reward.lines.take(2).join(' · ') : '${reward.coins}', style: numStyle(TypeScale.body), textAlign: TextAlign.center, maxLines: 2),
    ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: today ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55FFD36B), Color(0x22FFD36B)]) : null,
        color: today ? null : const Color(0x66101640),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: today ? Palette.moon : Palette.line, width: today ? 2.5 : 1),
        boxShadow: today ? const [BoxShadow(color: Color(0x55FFD36B), blurRadius: 14)] : null,
      ),
      padding: const EdgeInsets.all(6),
      child: Stack(children: [
        Center(child: wide ? Row(mainAxisAlignment: MainAxisAlignment.center, children: content) : Column(mainAxisAlignment: MainAxisAlignment.center, children: content)),
        if (state == 2) Positioned.fill(child: Container(decoration: BoxDecoration(color: const Color(0xAA080B22), borderRadius: BorderRadius.circular(12)), child: const Center(child: GameIcon(GI.check, size: 34)))),
      ]),
    );
  }
}

class StarterOfferSheet extends StatelessWidget {
  const StarterOfferSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final prod = Economy.product('starter');
    final left = Duration(milliseconds: p.starterUntil - DateTime.now().millisecondsSinceEpoch);
    return SheetFrame(
      title: prod.name,
      accent: Palette.blossom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon(GI.gift, size: 96),
          const SizedBox(height: Space.s),
          Text(tr('once_left', {'t': fmtDur(left)}), style: ko(TypeScale.body, color: Palette.blossom)),
          const SizedBox(height: Space.l),
          RewardChips(reward: prod.reward),
          const SizedBox(height: Space.xl),
          Btn(tr('buy_for', {'p': prod.priceLabel}), style: BtnStyle.green, height: 62, onTap: () async {
            if (await StoreService.instance.buy(prod)) {
              Sfx.instance.play('purchase');
              if (context.mounted) Navigator.pop(context);
            }
          }),
        ],
      ),
    );
  }
}

class RewardChips extends StatelessWidget {
  const RewardChips({super.key, required this.reward});
  final Reward reward;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: Space.s,
    runSpacing: Space.s,
    children: [
      for (final line in reward.lines)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0x66101640), borderRadius: BorderRadius.circular(14), border: Border.all(color: Palette.line)),
          child: Text(line, style: ko(TypeScale.body)),
        ),
    ],
  );
}

class GiftSheet extends StatelessWidget {
  const GiftSheet({super.key, required this.title, required this.body, required this.reward});
  final String title, body;
  final Reward reward;
  @override
  Widget build(BuildContext context) => SheetFrame(
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GameIcon(GI.chest, size: 88),
        const SizedBox(height: Space.m),
        Text(body, style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
        const SizedBox(height: Space.l),
        RewardChips(reward: reward),
        const SizedBox(height: Space.xl),
        Btn(tr('ok_great'), style: BtnStyle.green, onTap: () => Navigator.pop(context), sound: 'chest'),
      ],
    ),
  );
}

class DailySheet extends StatelessWidget {
  const DailySheet({super.key, required this.level});
  final LevelData level;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    return SheetFrame(
      title: tr('daily'),
      accent: const Color(0xFFFF9F5A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon(GI.sunrise, size: 80),
          const SizedBox(height: Space.m),
          Text(tr('daily_desc'), style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.m),
          Text(tr('daily_today', {'name': levelName(level.name)}), style: ko(TypeScale.label, color: Palette.moon)),
          const SizedBox(height: Space.xl),
          Btn(p.dailyAvailable ? tr('daily_go', {'n': 200}) : tr('daily_done'), style: BtnStyle.green, onTap: () {
            if (p.dailyAvailable) {
              p.dailyDone = Profile.today();
              p.earn(200);
              Analytics.log('daily_start');
            }
            Navigator.pop(context, true);
          }),
        ],
      ),
    );
  }
}

class StreakSheet extends StatelessWidget {
  const StreakSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    return SheetFrame(
      title: tr('streak_title', {'n': p.streak}),
      accent: Palette.echo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('streak_desc'), style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.l),
          for (var s = 1; s <= 3; s++)
            Container(
              margin: const EdgeInsets.only(bottom: Space.s),
              padding: const EdgeInsets.all(Space.m),
              decoration: BoxDecoration(color: p.streak >= s ? const Color(0x337EF0FF) : const Color(0x66101640), borderRadius: BorderRadius.circular(14), border: Border.all(color: p.streak >= s ? Palette.echo : Palette.line)),
              child: Row(children: [
                Opacity(opacity: p.streak >= s ? 1 : 0.4, child: const GameIcon(GI.flame, size: 28)),
                const SizedBox(width: Space.s),
                Text(s == 3 ? tr('streak_row_plus', {'n': s}) : tr('streak_row', {'n': s}), style: ko(TypeScale.label)),
                const Spacer(),
                for (final k in Economy.streakBoosters(s)) Padding(padding: const EdgeInsets.only(left: 4), child: GameIcon(switch (k) { 'aim' => GI.aim, 'extra' => GI.extra, _ => GI.split }, size: 26)),
              ]),
            ),
          const SizedBox(height: Space.s),
          Text(tr('streak_best', {'n': p.best}), style: ko(TypeScale.caption, color: Palette.inkSoft)),
        ],
      ),
    );
  }
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});
  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  @override
  Widget build(BuildContext context) => SheetFrame(
    title: tr('settings'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsToggles(onChanged: () => setState(() {}), showLanguage: true),
        const SizedBox(height: Space.m),
        Btn(tr('restore'), style: BtnStyle.dusk, height: 48, onTap: () => StoreService.instance.restore()),
        const SizedBox(height: Space.m),
        Text(tr('version', {'v': '1.0.0'}), style: ko(TypeScale.caption, color: Palette.inkSoft)),
      ],
    ),
  );
}
