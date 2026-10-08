import 'package:flutter/material.dart';

import '../app/l10n.dart';
import '../app/missions.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/level.dart';
import '../services/services.dart';
import '../widgets/icons.dart';
import '../widgets/ui.dart';
import 'meta_sheets.dart';

/// 오늘의 미션: 3줄 + 하단 상자. 남은 시간(자정까지)을 보여 줘 "오늘 안에"를 만든다.
class MissionsSheet extends StatefulWidget {
  const MissionsSheet({super.key});
  @override
  State<MissionsSheet> createState() => _MissionsSheetState();
}

class _MissionsSheetState extends State<MissionsSheet> {
  Future<void> _claim(int i) async {
    final r = Missions.claim(i);
    Sfx.instance.play('coin');
    Sfx.instance.haptic();
    setState(() {});
    Analytics.log('mission_claim', {'id': Missions.today[i].id, 'coins': r.coins});
  }

  Future<void> _chest() async {
    final r = Missions.claimChest();
    setState(() {});
    await showSheet<void>(context, GiftSheet(title: tr('m_chest'), body: tr('m_chest_body'), reward: r));
  }

  @override
  Widget build(BuildContext context) {
    final ms = Missions.today;
    final prog = Missions.progress;
    final now = DateTime.now();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    final allClaimed = [0, 1, 2].every(Missions.claimed);
    final chestOpen = Profile.instance.missionChest;
    return SheetFrame(
      title: tr('missions'),
      accent: Palette.moss,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('m_reset_in', {'t': fmtDur(left)}), style: ko(TypeScale.caption, color: Palette.inkSoft)),
          const SizedBox(height: Space.m),
          for (var i = 0; i < 3; i++) _MissionRow(mission: ms[i], value: prog[i], claimed: Missions.claimed(i), onClaim: () => _claim(i)),
          const SizedBox(height: Space.m),
          Container(
            padding: const EdgeInsets.all(Space.m),
            decoration: BoxDecoration(
              color: allClaimed && !chestOpen ? const Color(0x33FFD36B) : const Color(0x66101640),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: allClaimed && !chestOpen ? Palette.moon : Palette.line, width: 1.5),
            ),
            child: Row(
              children: [
                Opacity(opacity: chestOpen ? 0.4 : 1, child: const GameIcon(GI.chest, size: 54)),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('m_chest'), style: ko(TypeScale.label)),
                      const SizedBox(height: 4),
                      Row(children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Missions.claimed(i) ? Palette.moss : const Color(0x33FFFFFF), border: Border.all(color: Colors.white24)),
                            child: Missions.claimed(i) ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                          ),
                      ]),
                    ],
                  ),
                ),
                if (chestOpen)
                  Text(tr('claimed'), style: ko(TypeScale.body, color: Palette.inkSoft))
                else
                  SizedBox(width: 92, child: Btn(tr('open'), height: 44, style: allClaimed ? BtnStyle.moon : BtnStyle.ghost, onTap: allClaimed ? _chest : null, sound: 'chest')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission, required this.value, required this.claimed, required this.onClaim});
  final Mission mission;
  final int value;
  final bool claimed;
  final VoidCallback onClaim;
  @override
  Widget build(BuildContext context) {
    final done = value >= mission.goal;
    final k = (value / mission.goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: Space.s),
      padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.s, Space.m),
      decoration: BoxDecoration(color: done && !claimed ? const Color(0x2A6FD39B) : const Color(0x66101640), borderRadius: BorderRadius.circular(16), border: Border.all(color: done && !claimed ? Palette.moss : Palette.line)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title, style: ko(TypeScale.body + 1, color: claimed ? Palette.inkSoft : Palette.ink)),
                const SizedBox(height: 6),
                Stack(children: [
                  Container(height: 10, decoration: BoxDecoration(color: const Color(0x44000000), borderRadius: BorderRadius.circular(6))),
                  FractionallySizedBox(
                    widthFactor: k,
                    child: Container(height: 10, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8DFFB5), Color(0xFF3FB86A)]), borderRadius: BorderRadius.circular(6))),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('${value.clamp(0, mission.goal)} / ${mission.goal}  ·  ${mission.reward.lines.join(' · ')}', style: numStyle(11, color: Palette.inkSoft)),
              ],
            ),
          ),
          const SizedBox(width: Space.s),
          SizedBox(
            width: 82,
            child: claimed
                ? const Center(child: GameIcon(GI.check, size: 30))
                : Btn(tr('claim'), height: 40, style: done ? BtnStyle.green : BtnStyle.ghost, onTap: done ? onClaim : null),
          ),
        ],
      ),
    );
  }
}

/// 월드 별 상자: 월드마다 별 20·40·60 에서 열리는 상자 3개.
class StarChestSheet extends StatefulWidget {
  const StarChestSheet({super.key, required this.world});
  final int world;
  @override
  State<StarChestSheet> createState() => _StarChestSheetState();
}

class _StarChestSheetState extends State<StarChestSheet> {
  late int world = widget.world;

  Future<void> _claim(int k) async {
    final r = StarChests.claim(world, k);
    setState(() {});
    await showSheet<void>(context, GiftSheet(title: tr('sc_title'), body: tr('sc_body', {'n': StarChests.marks[k]}), reward: r));
  }

  @override
  Widget build(BuildContext context) {
    final s = StarChests.starsIn(world);
    final maxW = LevelRepo.instance[Profile.instance.nextLevelIndex.clamp(0, LevelRepo.instance.count - 1)].world;
    return SheetFrame(
      title: tr('sc_title'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoundBtn(icon: Icons.chevron_left_rounded, label: tr('prev'), onTap: world > 1 ? () => setState(() => world--) : null, size: 36),
              const SizedBox(width: Space.m),
              Text(worldName(world), style: ko(TypeScale.label)),
              const SizedBox(width: Space.m),
              RoundBtn(icon: Icons.chevron_right_rounded, label: tr('next_w'), onTap: world < maxW ? () => setState(() => world++) : null, size: 36),
            ],
          ),
          const SizedBox(height: Space.s),
          Text(tr('sc_desc'), style: ko(TypeScale.caption, color: Palette.inkSoft), textAlign: TextAlign.center),
          const SizedBox(height: Space.l),
          // 진행 막대 + 상자 3개
          SizedBox(
            height: 110,
            child: LayoutBuilder(builder: (_, c) {
              final w = c.maxWidth;
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(left: 0, right: 0, top: 84, child: Container(height: 12, decoration: BoxDecoration(color: const Color(0x44000000), borderRadius: BorderRadius.circular(8)))),
                Positioned(
                  left: 0,
                  top: 84,
                  child: Container(width: s <= 0 ? 0 : (34 + (w - 68) * (s / 60)).clamp(0.0, w), height: 12, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFE09A2E)]), borderRadius: BorderRadius.circular(8))),
                ),
                for (var k = 0; k < 3; k++)
                  Positioned(
                    left: (w - 68) * StarChests.marks[k] / 60,
                    top: 0,
                    child: _ChestNode(mark: StarChests.marks[k], claimed: StarChests.claimed(world, k), ready: StarChests.ready(world, k), onTap: () => _claim(k)),
                  ),
              ]);
            }),
          ),
          const SizedBox(height: Space.m),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const GameIcon(GI.star, size: 22),
            const SizedBox(width: 6),
            Text('$s / 60', style: numStyle(18)),
          ]),
          const SizedBox(height: Space.s),
          Text(tr('sc_tip'), style: ko(TypeScale.caption, color: Palette.inkSoft), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ChestNode extends StatelessWidget {
  const _ChestNode({required this.mark, required this.claimed, required this.ready, required this.onTap});
  final int mark;
  final bool claimed, ready;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: ready ? onTap : null,
    sound: 'chest',
    child: SizedBox(
      width: 68,
      child: Column(children: [
        Opacity(opacity: claimed ? 0.35 : (ready ? 1 : 0.7), child: GameIcon(GI.chest, size: ready ? 58 : 50)),
        if (ready) Text(tr('open'), style: ko(12, color: Palette.moon)) else Text(claimed ? tr('claimed') : '★$mark', style: numStyle(12, color: Palette.inkSoft)),
      ]),
    ),
  );
}
