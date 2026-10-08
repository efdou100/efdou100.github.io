import 'package:flutter/material.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/level.dart';
import '../services/services.dart';
import '../widgets/ui.dart';
import 'sheets.dart';

/// 판 시작 전: 정보 + 부스터 선택
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
    final tier = switch (l.tier) { Tier.hard => ('어려움 · 코인 2배', Palette.danger), Tier.superhard => ('아주 어려움 · 코인 3배', Palette.violet), Tier.boss => ('보스 · 코인 3배', Palette.moon), _ => null };
    return SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${LevelRepo.worldNames[l.world]} · ${l.id}단계', style: ko(TypeScale.body, color: l.isEcho ? Palette.echo : Palette.inkSoft)),
          Text(l.name, style: ko(TypeScale.display)),
          if (tier != null) Padding(padding: const EdgeInsets.only(top: Space.s), child: TierBadge(text: tier.$1, color: tier.$2)),
          const SizedBox(height: Space.m),
          StarRow(stars: stars, size: 30, animate: false),
          const SizedBox(height: Space.s),
          Text('화살 ${l.shots}발 · ${l.par}발 안에 깨면 별 3개', style: ko(TypeScale.body, color: Palette.inkSoft)),
          if (Economy.unlocked(Economy.unlockBoosters)) ...[
            const SizedBox(height: Space.xl),
            Align(alignment: Alignment.centerLeft, child: Text('부스터', style: ko(TypeScale.label))),
            const SizedBox(height: Space.s),
            Row(
              children: [
                for (final k in const ['aim', 'extra', 'split']) ...[
                  Expanded(child: _BoosterCard(id: k, picked: picked.contains(k) || free.contains(k), free: free.contains(k), onTap: () => _toggle(k))),
                  if (k != 'split') const SizedBox(width: Space.s),
                ],
              ],
            ),
            if (free.isNotEmpty) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text('메아리 연승 ${p.streak} · 무료 부스터가 켜졌어요', style: ko(TypeScale.caption, color: Palette.echo))),
          ],
          const SizedBox(height: Space.xl),
          Btn(p.canPlay ? '시작' : '하트가 없어요', icon: p.heartsActive && !p.infinite ? const HeartIcon(size: 20) : null, onTap: _start, sound: 'pop'),
          if (p.heartsActive && !p.infinite) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text('클리어하면 하트는 줄지 않아요', style: ko(TypeScale.caption, color: Palette.inkSoft))),
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
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('코인이 모자라요', style: ko(TypeScale.body)), backgroundColor: Palette.dusk));
      }
    });
  }

  void _start() {
    final p = Profile.instance;
    if (!p.canPlay) {
      Navigator.pop(context, <String>{});
      return;
    }
    // 보유분 먼저 쓰고, 없으면 코인으로 구매
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
    final icon = switch (id) { 'aim' => Icons.timeline_rounded, 'extra' => Icons.add_circle_outline_rounded, _ => Icons.call_split_rounded };
    return Pressable(
      onTap: onTap,
      semantic: '${Economy.boosterName[id]}, ${Economy.boosterDesc[id]}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: Space.m, horizontal: Space.s),
        decoration: BoxDecoration(
          color: picked ? const Color(0x33FFD36B) : const Color(0x66101640),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: picked ? Palette.moon : Palette.line, width: picked ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: picked ? Palette.moon : Palette.ink, size: 28),
            const SizedBox(height: 4),
            Text(Economy.boosterName[id]!, style: ko(TypeScale.body), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            if (free)
              Text('무료', style: ko(TypeScale.caption, color: Palette.echo))
            else if (own > 0)
              Text('보유 $own', style: ko(TypeScale.caption, color: Palette.moss))
            else
              Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 14), const SizedBox(width: 3), Text('${Economy.boosterPrice[id]}', style: numStyle(TypeScale.caption))]),
          ],
        ),
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
      title: p.infinite ? '무한 하트 사용 중' : '하트 ${p.hearts} / ${Profile.maxHearts}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < Profile.maxHearts; i++) Padding(padding: const EdgeInsets.all(3), child: Opacity(opacity: i < p.hearts || p.infinite ? 1 : 0.25, child: HeartIcon(size: 34, infinite: p.infinite)))]),
          const SizedBox(height: Space.s),
          Text(full ? '하트가 가득 찼어요' : '다음 하트까지 ${fmtDur(p.nextHeartIn)}', style: ko(TypeScale.body, color: Palette.inkSoft)),
          const SizedBox(height: Space.xl),
          Btn('하트 가득 채우기', trailing: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 20), const SizedBox(width: 4), Text('${Economy.refillPrice}', style: numStyle(TypeScale.label, color: const Color(0xFF2A1B05)))]), onTap: full
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
          Btn('광고 보고 하트 +1', style: BtnStyle.echo, icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF052A33)), onTap: full
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
      title: '출석 선물',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('하루에 한 번 받아요. 빠진 날이 있어도 이어서 받을 수 있어요.', style: ko(TypeScale.body, color: Palette.inkSoft), textAlign: TextAlign.center),
          const SizedBox(height: Space.l),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Space.s,
            crossAxisSpacing: Space.s,
            childAspectRatio: 0.82,
            children: [
              for (var i = 0; i < 7; i++) _DayCard(day: i, reward: Economy.checkin[i], state: i < day || (claimed && i == day) ? 2 : (i == day ? 1 : 0)),
            ],
          ),
          const SizedBox(height: Space.xl),
          Btn(can ? '${day + 1}일차 받기' : '내일 또 만나요', onTap: can ? () => _claim(1) : null, sound: 'chest'),
          if (can) ...[
            const SizedBox(height: Space.m),
            Btn('광고 보고 2배로 받기', style: BtnStyle.echo, icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF052A33)), onTap: () async {
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
  const _DayCard({required this.day, required this.reward, required this.state});
  final int day;
  final Reward reward;
  final int state; // 0 앞으로, 1 오늘, 2 받음
  @override
  Widget build(BuildContext context) {
    final big = reward.chest;
    return Container(
      decoration: BoxDecoration(
        color: state == 1 ? const Color(0x33FFD36B) : const Color(0x66101640),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: state == 1 ? Palette.moon : Palette.line, width: state == 1 ? 2 : 1),
      ),
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${day + 1}일', style: ko(TypeScale.caption, color: Palette.inkSoft)),
              const SizedBox(height: 4),
              big ? const Icon(Icons.redeem_rounded, color: Palette.moon, size: 30) : const CoinIcon(size: 26),
              const SizedBox(height: 4),
              Text(big ? '상자' : '${reward.coins}', style: numStyle(TypeScale.body)),
            ],
          ),
          if (state == 2) Positioned.fill(child: Container(decoration: BoxDecoration(color: const Color(0x99080B22), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_rounded, color: Palette.moss, size: 30))),
        ],
      ),
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
      title: '스타터 팩',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('처음 한 번만 · ${fmtDur(left)} 남음', style: ko(TypeScale.body, color: Palette.blossom)),
          const SizedBox(height: Space.l),
          _RewardList(reward: prod.reward),
          const SizedBox(height: Space.xl),
          Btn('${prod.priceLabel}에 받기', onTap: () async {
            if (await StoreService.instance.buy(prod)) {
              Sfx.instance.play('purchase');
              if (context.mounted) Navigator.pop(context);
            }
          }),
          const SizedBox(height: Space.s),
          Btn('다음에', style: BtnStyle.ghost, height: 48, onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _RewardList extends StatelessWidget {
  const _RewardList({required this.reward});
  final Reward reward;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: Space.s,
    runSpacing: Space.s,
    children: [for (final line in reward.lines) Chip(label: Text(line, style: ko(TypeScale.body)), backgroundColor: const Color(0x66101640), side: const BorderSide(color: Palette.line))],
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
        Text(body, style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
        const SizedBox(height: Space.l),
        _RewardList(reward: reward),
        const SizedBox(height: Space.xl),
        Btn('좋아요', onTap: () => Navigator.pop(context), sound: 'chest'),
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
      title: '오늘의 한 발',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('전 세계가 같은 판을 풀어요. 한 발에 깨고 결과를 공유해 보세요.', style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.m),
          Text('오늘의 판: ${level.name}', style: ko(TypeScale.label, color: Palette.moon)),
          const SizedBox(height: Space.xl),
          Btn(p.dailyAvailable ? '도전하기 (보상 코인 200)' : '오늘은 완료했어요 · 다시 풀기', onTap: () {
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
      title: '메아리 연승 ${p.streak}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('처음 시도에 깨면 연승이 올라가요. 연승이 높을수록 판을 시작할 때 무료 부스터가 켜져요. 실패하거나 이어하기를 쓰면 처음부터예요.', style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.l),
          for (var s = 1; s <= 3; s++)
            ListTile(
              leading: Icon(Icons.local_fire_department_rounded, color: p.streak >= s ? Palette.moon : Palette.inkSoft),
              title: Text('$s연승${s == 3 ? ' 이상' : ''}', style: ko(TypeScale.label)),
              trailing: Text(Economy.streakBoosters(s).map((k) => Economy.boosterName[k]).join(', '), style: ko(TypeScale.caption, color: Palette.inkSoft)),
            ),
          const SizedBox(height: Space.s),
          Text('최고 기록 ${p.best}연승', style: ko(TypeScale.caption, color: Palette.inkSoft)),
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
    title: '설정',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsToggles(onChanged: () => setState(() {})),
        const SizedBox(height: Space.m),
        Text('메아리 화살 · 0.1.0', style: ko(TypeScale.caption, color: Palette.inkSoft)),
      ],
    ),
  );
}
