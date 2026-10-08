import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/controller.dart';
import '../game/level.dart';
import '../services/services.dart';
import '../widgets/ui.dart';

/// 클리어 결과
class ClearSheet extends StatelessWidget {
  const ClearSheet({super.key, required this.level, required this.result, required this.coins, required this.streak, required this.isLast, this.replayed = false});
  final LevelData level;
  final WinResult result;
  final int coins, streak;
  final bool isLast, replayed;

  String get _title {
    if (result.tricks > 0 && result.stars == 3) return '트릭샷 클리어!';
    if (result.stars == 3) return '완벽해요!';
    return '클리어!';
  }

  String _shareText() {
    final stars = '⭐' * result.stars;
    final bounces = result.maxBounce > 0 ? ' · ${result.maxBounce}번 튕김' : '';
    return '🏹 메아리 화살 ${level.id}단계 $stars\n${result.used}발$bounces${result.tricks > 0 ? ' · 트릭샷!' : ''}\n너는 몇 발에 깰 수 있어?';
  }

  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    return SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarRow(stars: result.stars, animate: !replayed),
          const SizedBox(height: Space.s),
          Text(_title, style: ko(TypeScale.display, color: Palette.moon)),
          const SizedBox(height: Space.s),
          Text(
            [
              '${result.used}발',
              if (result.maxBounce > 0) '최대 ${result.maxBounce}번 튕김',
              if (result.tricks > 0) '트릭샷 ${result.tricks}',
              if (result.used > 1) '메아리 ${result.used - 1}',
            ].join(' · '),
            style: ko(TypeScale.body, color: Palette.inkSoft),
          ),
          const SizedBox(height: Space.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CoinIcon(size: 26),
              const SizedBox(width: Space.s),
              replayed ? Text('+$coins', style: numStyle(TypeScale.title)) : CountUp(to: coins, prefix: '+'),
              if (streak >= 2 && Economy.unlocked(Economy.unlockStreak)) ...[
                const SizedBox(width: Space.l),
                TierBadge(text: '메아리 연승 $streak', color: Palette.echo),
              ],
            ],
          ),
          if (result.stars < 3) ...[
            const SizedBox(height: Space.s),
            Text('${level.par}발 이하로 깨면 별 3개', style: ko(TypeScale.caption, color: Palette.inkSoft)),
          ],
          if (p.cleared >= Economy.unlockShop && p.piggy > 0) ...[
            const SizedBox(height: Space.s),
            Text('별빛 저금통 ${p.piggy} / ${Economy.piggyMax}', style: ko(TypeScale.caption, color: Palette.inkSoft)),
          ],
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(child: Btn('다시보기', style: BtnStyle.dusk, icon: const Icon(Icons.replay_rounded, color: Palette.ink, size: 20), onTap: () => Navigator.pop(context, 'replay'))),
              const SizedBox(width: Space.m),
              Expanded(
                child: Btn('공유하기', style: BtnStyle.dusk, icon: const Icon(Icons.ios_share_rounded, color: Palette.ink, size: 20), onTap: () {
                  Clipboard.setData(ClipboardData(text: _shareText()));
                  Analytics.log('share', {'id': level.id, 'stars': result.stars});
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('공유 문구를 복사했어요', style: ko(TypeScale.body)), backgroundColor: Palette.dusk));
                }),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          Btn(isLast ? '지도로 돌아가기' : '다음 단계', onTap: () => Navigator.pop(context, 'next'), sound: 'pop'),
          if (result.stars < 3) ...[const SizedBox(height: Space.s), Btn('다시 도전해서 별 더 받기', style: BtnStyle.ghost, height: 48, onTap: () => Navigator.pop(context, 'retry'))],
        ],
      ),
    );
  }
}

/// 화살을 다 썼을 때: 이어하기 제안 (과금 핵심 지점)
class ContinueSheet extends StatefulWidget {
  const ContinueSheet({super.key, required this.controller});
  final GameController controller;
  @override
  State<ContinueSheet> createState() => _ContinueSheetState();
}

class _ContinueSheetState extends State<ContinueSheet> {
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance, g = widget.controller;
    final price = Economy.continuePrice(g.continues);
    final hit = g.run.hit.asMap().entries.where((e) => !g.level.targets[e.key].avoid && e.value).length;
    final need = g.level.targets.where((t) => !t.avoid).length;
    final close = hit > 0 && hit < need;
    return SheetFrame(
      title: close ? '거의 다 됐어요!' : '화살을 다 썼어요',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(close ? '정령 $need마리 중 $hit마리를 깨웠어요. 메아리는 그대로 남아요.' : '화살을 더 받으면 지금까지의 메아리를 그대로 이어서 쏠 수 있어요.', style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          Btn(
            '화살 +${Economy.continueArrows}',
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF2A1B05)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 20), const SizedBox(width: 4), Text('$price', style: numStyle(TypeScale.label, color: const Color(0xFF2A1B05)))]),
            onTap: () async {
              if (p.spend(price)) {
                Analytics.log('continue_coins', {'id': g.level.id, 'price': price});
                Navigator.pop(context, 'coins');
              } else {
                final bought = await showSheet<bool>(context, const CoinShortSheet());
                if (bought == true && mounted) setState(() {});
              }
            },
          ),
          const SizedBox(height: Space.m),
          if (p.adContinuesLeft > 0)
            Btn('광고 보고 화살 +1 (오늘 ${p.adContinuesLeft}회)', style: BtnStyle.echo, icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF052A33)), onTap: () async {
              final ok = await AdService.instance.rewarded('continue');
              if (ok) {
                p.useAdContinue();
                if (context.mounted) Navigator.pop(context, 'ad');
              }
            }),
          const SizedBox(height: Space.m),
          Row(
            children: [
              Expanded(child: Btn('처음부터', style: BtnStyle.dusk, height: 48, onTap: () => Navigator.pop(context, 'retry'))),
              const SizedBox(width: Space.m),
              Expanded(child: Btn('포기하기', style: BtnStyle.dusk, height: 48, onTap: () => Navigator.pop(context, 'quit'))),
            ],
          ),
          if (p.heartsActive && !p.infinite) ...[
            const SizedBox(height: Space.s),
            Text('처음부터 / 포기하면 하트 1개가 줄어요', style: ko(TypeScale.caption, color: Palette.inkSoft)),
          ],
        ],
      ),
    );
  }
}

/// 코인이 모자랄 때 바로 살 수 있는 작은 상점
class CoinShortSheet extends StatelessWidget {
  const CoinShortSheet({super.key});
  @override
  Widget build(BuildContext context) => SheetFrame(
    title: '코인이 모자라요',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in const ['coins_s', 'coins_m', 'coins_l'])
          Padding(
            padding: const EdgeInsets.only(bottom: Space.m),
            child: ProductRow(product: Economy.product(id), onBought: () => Navigator.pop(context, true)),
          ),
      ],
    ),
  );
}

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, this.onBought});
  final Product product;
  final VoidCallback? onBought;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Space.m),
    decoration: BoxDecoration(color: const Color(0x66101640), borderRadius: BorderRadius.circular(16), border: Border.all(color: Palette.line)),
    child: Row(
      children: [
        const CoinIcon(size: 32),
        const SizedBox(width: Space.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: ko(TypeScale.label)),
              Text(product.reward.lines.join(' · '), style: ko(TypeScale.caption, color: Palette.inkSoft)),
            ],
          ),
        ),
        if (product.badge != null) ...[TierBadge(text: product.badge!, color: Palette.moss), const SizedBox(width: Space.s)],
        SizedBox(
          width: 92,
          child: Btn(product.priceLabel, height: 44, onTap: () async {
            final ok = await StoreService.instance.buy(product);
            if (ok) {
              Sfx.instance.play('purchase');
              onBought?.call();
            }
          }),
        ),
      ],
    ),
  );
}

class HintSheet extends StatelessWidget {
  const HintSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    return SheetFrame(
      title: '힌트',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('첫 화살이 날아갈 방향을 유령 화살로 보여 줘요.\n거울이 있으면 정답 방향으로 돌려 놓아요.', style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          Btn('힌트 보기', trailing: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 20), const SizedBox(width: 4), Text('${Economy.hintPrice}', style: numStyle(TypeScale.label, color: const Color(0xFF2A1B05)))]), onTap: p.coins >= Economy.hintPrice ? () => Navigator.pop(context, 'coins') : null),
          const SizedBox(height: Space.m),
          Btn('광고 보고 힌트', style: BtnStyle.echo, icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF052A33)), onTap: () async {
            final ok = await AdService.instance.rewarded('hint');
            if (ok && context.mounted) Navigator.pop(context, 'ad');
          }),
        ],
      ),
    );
  }
}

class PauseSheet extends StatefulWidget {
  const PauseSheet({super.key, required this.level, required this.shotsUsed});
  final LevelData level;
  final bool shotsUsed;
  @override
  State<PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends State<PauseSheet> {
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    return SheetFrame(
      title: widget.level.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Btn('계속하기', onTap: () => Navigator.pop(context)),
          const SizedBox(height: Space.m),
          Btn('처음부터', style: BtnStyle.dusk, onTap: () => Navigator.pop(context, 'restart')),
          const SizedBox(height: Space.m),
          Btn('지도로 나가기', style: BtnStyle.dusk, onTap: () => Navigator.pop(context, 'home')),
          if (widget.shotsUsed && p.heartsActive && !p.infinite) ...[const SizedBox(height: Space.s), Text('도중에 나가면 하트 1개가 줄어요', style: ko(TypeScale.caption, color: Palette.inkSoft))],
          const SizedBox(height: Space.l),
          SettingsToggles(onChanged: () => setState(() {})),
        ],
      ),
    );
  }
}

class SettingsToggles extends StatelessWidget {
  const SettingsToggles({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    Widget row(String label, bool v, void Function(bool) set) => SwitchListTile(
      value: v,
      onChanged: (x) {
        set(x);
        p.save();
        onChanged();
      },
      title: Text(label, style: ko(TypeScale.label)),
      activeThumbColor: Palette.moon,
      contentPadding: EdgeInsets.zero,
    );
    return Column(
      children: [
        row('소리', p.sound, (v) => p.sound = v),
        row('진동', p.haptics, (v) => p.haptics = v),
        row('화면 흔들림 줄이기', p.reduceMotion, (v) => p.reduceMotion = v),
      ],
    );
  }
}
