import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/art.dart';
import '../app/economy.dart';
import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../game/controller.dart';
import '../game/level.dart';
import '../services/services.dart';
import '../widgets/icons.dart';
import '../widgets/ui.dart';
import 'home_screen.dart' show AvatarPainter;

/// 클리어 축하 (전체 화면): 빛줄기 → 별이 하나씩 박힘 → 코인이 세어짐 → 버튼
class WinScreen extends StatefulWidget {
  const WinScreen({super.key, required this.level, required this.result, required this.coins, required this.streak, required this.isLast, this.replayed = false, this.missions = const []});
  final List<String> missions;
  final LevelData level;
  final WinResult result;
  final int coins, streak;
  final bool isLast, replayed;
  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  final List<bool> _starSfx = [false, false, false];

  @override
  void initState() {
    super.initState();
    _intro.addListener(() {
      for (var i = 0; i < widget.result.stars; i++) {
        final at = 0.18 + i * 0.12;
        if (!_starSfx[i] && _intro.value >= at) {
          _starSfx[i] = true;
          Sfx.instance.play('star');
          Sfx.instance.haptic(strong: i == 2);
        }
      }
    });
    if (widget.replayed) _intro.value = 1;
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.result.tricks > 0 && widget.result.stars == 3) return tr('trick_clear');
    if (widget.result.stars == 3) return tr('perfect');
    return tr('clear');
  }

  String _shareText() {
    final r = widget.result;
    final extra = (r.maxBounce > 0 ? tr('share_bounce', {'n': r.maxBounce}) : '') + (r.tricks > 0 ? tr('share_trick') : '');
    return tr('share_text', {'n': widget.level.id, 'stars': '⭐' * r.stars, 'used': r.used, 'extra': extra});
  }

  Animation<double> _at(double a, double b, [Curve curve = Curves.easeOutBack]) => CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: curve));

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final p = Profile.instance;
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: const Color(0xD9060920),
      body: Stack(
        children: [
          // 빛줄기
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_spin, _intro]),
              builder: (_, _) => CustomPaint(painter: _RaysPainter(_spin.value, _at(0, 0.3, Curves.easeOut).value)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: _at(0.0, 0.25),
                    child: Text(_title, style: ko(TypeScale.hero, color: Palette.moon, shadows: const [Shadow(color: Color(0xFF7A4A10), offset: Offset(0, 3)), Shadow(color: Color(0xAAFFD36B), blurRadius: 24)]), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: Space.s),
                  FadeTransition(opacity: _at(0.1, 0.3, Curves.easeOut), child: Text('${tr('level_n', {'n': widget.level.id})} · ${levelName(widget.level.name)}', style: ko(TypeScale.label, color: Palette.inkSoft))),
                  const SizedBox(height: Space.xl),
                  SizedBox(
                    height: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: i == 1 ? 22 : 0, left: 6, right: 6),
                            child: i < r.stars
                                ? ScaleTransition(
                                    scale: Tween(begin: 2.2, end: 1.0).animate(_at(0.18 + i * 0.12, 0.34 + i * 0.12, Curves.easeOutBack)),
                                    child: FadeTransition(opacity: _at(0.18 + i * 0.12, 0.24 + i * 0.12, Curves.easeOut), child: GameIcon(GI.star, size: i == 1 ? 86 : 70)),
                                  )
                                : GameIcon(GI.star, size: i == 1 ? 86 : 70, color: const Color(0xFF2A3266)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.m),
                  SizedBox(
                    height: 120,
                    child: ScaleTransition(
                      scale: _at(0.5, 0.75),
                      child: ArtImage('char/archer_cheer', size: const Size(120, 120), fallback: CustomPaint(size: const Size(96, 104), painter: AvatarPainter())),
                    ),
                  ),
                  const SizedBox(height: Space.m),
                  FadeTransition(
                    opacity: _at(0.55, 0.75, Curves.easeOut),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: Space.s,
                      runSpacing: Space.s,
                      children: [
                        _Chip(tr('r_used', {'n': r.used})),
                        if (r.maxBounce > 0) _Chip(tr('r_bounce', {'n': r.maxBounce})),
                        if (r.tricks > 0) _Chip(tr('r_tricks', {'n': r.tricks}), color: Palette.moon),
                        if (r.used > 1) _Chip(tr('r_echo', {'n': r.used - 1}), color: Palette.echo),
                        if (widget.streak >= 2 && Economy.unlocked(Economy.unlockStreak)) _Chip(tr('streak_n', {'n': widget.streak}), color: Palette.echo),
                        for (final m in widget.missions) _Chip(tr('m_done', {'x': m}), color: Palette.moss),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  ScaleTransition(
                    scale: _at(0.62, 0.85),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.s),
                      decoration: BoxDecoration(color: const Color(0xCC141A4A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x66FFD36B))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const CoinIcon(size: 32),
                        const SizedBox(width: Space.s),
                        widget.replayed ? Text('+${widget.coins}', style: numStyle(TypeScale.display, color: Palette.moon)) : _DelayedCount(anim: _at(0.7, 1, Curves.easeOutCubic), to: widget.coins),
                      ]),
                    ),
                  ),
                  if (r.stars < 3) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(tr('par_hint', {'n': widget.level.par}), style: ko(TypeScale.caption, color: Palette.inkSoft))),
                  if (p.cleared >= Economy.unlockShop && p.piggy > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text(tr('piggy_line', {'a': p.piggy, 'b': Economy.piggyMax}), style: ko(TypeScale.caption, color: Palette.inkSoft))),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _at(0.8, 1, Curves.easeOut),
                    child: Column(
                      children: [
                        Btn(widget.isLast ? tr('back_map') : tr('next'), style: BtnStyle.green, height: 62, onTap: () => Navigator.pop(context, 'next'), sound: 'pop'),
                        const SizedBox(height: Space.m),
                        Row(children: [
                          Expanded(child: Btn(tr('replay'), style: BtnStyle.dusk, icon: const GameIcon(GI.replay, size: 20), onTap: () => Navigator.pop(context, 'replay'))),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Btn(tr('share'), style: BtnStyle.dusk, icon: const GameIcon(GI.share, size: 20), onTap: () {
                              Clipboard.setData(ClipboardData(text: _shareText()));
                              Analytics.log('share', {'id': widget.level.id, 'stars': r.stars});
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(tr('copied'), style: ko(TypeScale.body)), backgroundColor: Palette.dusk));
                            }),
                          ),
                        ]),
                        if (r.stars < 3) ...[const SizedBox(height: Space.xs), Btn(tr('retry_stars'), style: BtnStyle.ghost, height: 48, onTap: () => Navigator.pop(context, 'retry'))],
                        SizedBox(height: pad.bottom > 0 ? 0 : Space.m),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayedCount extends StatelessWidget {
  const _DelayedCount({required this.anim, required this.to});
  final Animation<double> anim;
  final int to;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: anim, builder: (_, _) => Text('+${(to * anim.value).round()}', style: numStyle(TypeScale.display, color: Palette.moon)));
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.color = Palette.inkSoft});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.5))),
    child: Text(text, style: ko(TypeScale.body, color: color == Palette.inkSoft ? Palette.ink : color)),
  );
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t, this.k);
  final double t, k;
  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width / 2, s.height * 0.3);
    final r = s.longestSide;
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + t * math.pi * 2;
      final path = Path()..moveTo(o.dx, o.dy)..lineTo(o.dx + math.cos(a - 0.09) * r, o.dy + math.sin(a - 0.09) * r)..lineTo(o.dx + math.cos(a + 0.09) * r, o.dy + math.sin(a + 0.09) * r)..close();
      c.drawPath(path, Paint()..color = Palette.moon.withValues(alpha: 0.06 * k));
    }
    c.drawCircle(o, 160 * k, Paint()..color = Palette.moon.withValues(alpha: 0.18 * k)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60));
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => true;
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
    var hit = 0;
    for (var i = 0; i < g.level.targets.length; i++) {
      if (!g.level.targets[i].avoid && g.run.hit[i]) hit++;
    }
    final need = g.level.targets.where((t) => !t.avoid).length;
    final close = hit > 0 && hit < need;
    return SheetFrame(
      title: close ? tr('almost') : tr('out'),
      accent: Palette.blossom,
      closable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 84,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < need; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Opacity(opacity: i < hit ? 1 : 0.4, child: ArtImage(i < hit ? 'spirit/awake' : 'spirit/sleep', size: const Size(56, 56), fallback: _SpiritDot(awake: i < hit))),
                ),
            ]),
          ),
          Text(close ? tr('close_desc', {'n': need, 'h': hit}) : tr('out_desc'), style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          Btn(
            tr('plus_arrows', {'n': Economy.continueArrows}),
            style: BtnStyle.green,
            height: 62,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 20), const SizedBox(width: 4), Text('$price', style: numStyle(TypeScale.label, color: Colors.white))]),
            ),
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
            Btn(tr('ad_arrow', {'n': p.adContinuesLeft}), style: BtnStyle.echo, icon: const GameIcon(GI.ad, size: 22), onTap: () async {
              final ok = await AdService.instance.rewarded('continue');
              if (ok) {
                p.useAdContinue();
                if (context.mounted) Navigator.pop(context, 'ad');
              }
            }),
          const SizedBox(height: Space.m),
          Row(children: [
            Expanded(child: Btn(tr('restart'), style: BtnStyle.dusk, height: 48, onTap: () => Navigator.pop(context, 'retry'))),
            const SizedBox(width: Space.m),
            Expanded(child: Btn(tr('give_up'), style: BtnStyle.dusk, height: 48, onTap: () => Navigator.pop(context, 'quit'))),
          ]),
          if (p.heartsActive && !p.infinite) Padding(padding: const EdgeInsets.only(top: Space.s), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const HeartIcon(size: 14), const SizedBox(width: 4), Text(tr('heart_cost'), style: ko(TypeScale.caption, color: Palette.inkSoft))])),
        ],
      ),
    );
  }
}

class _SpiritDot extends StatelessWidget {
  const _SpiritDot({required this.awake});
  final bool awake;
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: awake ? const [Color(0xFFFFFBE6), Color(0xFFFFBF3F)] : const [Color(0xFFF2FDFF), Color(0xFF6FB7FF)]),
        boxShadow: [BoxShadow(color: (awake ? Palette.moon : const Color(0xFF8FD6FF)).withValues(alpha: 0.5), blurRadius: 12)],
      ),
    ),
  );
}

/// 코인이 모자랄 때 바로 살 수 있는 작은 상점
class CoinShortSheet extends StatelessWidget {
  const CoinShortSheet({super.key});
  @override
  Widget build(BuildContext context) => SheetFrame(
    title: tr('no_coins'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final id in const ['coins_s', 'coins_m', 'coins_l']) Padding(padding: const EdgeInsets.only(bottom: Space.m), child: ProductRow(product: Economy.product(id), onBought: () => Navigator.pop(context, true)))],
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
        ArtImage('shop/${product.id}', size: const Size(44, 44), fallback: const Center(child: CoinIcon(size: 34))),
        const SizedBox(width: Space.m),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: ko(TypeScale.label)),
            Text(product.reward.lines.join(' · '), style: ko(TypeScale.caption, color: Palette.inkSoft)),
          ]),
        ),
        SizedBox(
          width: 96,
          child: Btn(product.priceLabel, style: BtnStyle.green, height: 44, onTap: () async {
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
      title: tr('hint'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon(GI.bulb, size: 72),
          const SizedBox(height: Space.m),
          Text(tr('hint_desc'), style: ko(TypeScale.body, color: Palette.inkSoft, height: 1.45), textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          Btn(tr('hint_show'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [const CoinIcon(size: 20), const SizedBox(width: 4), Text('${Economy.hintPrice}', style: numStyle(TypeScale.label, color: const Color(0xFF2A1B05)))]), onTap: p.coins >= Economy.hintPrice ? () => Navigator.pop(context, 'coins') : null),
          const SizedBox(height: Space.m),
          Btn(tr('hint_ad'), style: BtnStyle.echo, icon: const GameIcon(GI.ad, size: 22), onTap: () async {
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
      title: levelName(widget.level.name),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Btn(tr('resume'), style: BtnStyle.green, onTap: () => Navigator.pop(context)),
          const SizedBox(height: Space.m),
          Btn(tr('restart'), style: BtnStyle.dusk, icon: const GameIcon(GI.restart, size: 20), onTap: () => Navigator.pop(context, 'restart')),
          const SizedBox(height: Space.m),
          Btn(tr('quit_map'), style: BtnStyle.dusk, onTap: () => Navigator.pop(context, 'home')),
          if (widget.shotsUsed && p.heartsActive && !p.infinite) Padding(padding: const EdgeInsets.only(top: Space.s), child: Text(tr('quit_note'), style: ko(TypeScale.caption, color: Palette.inkSoft))),
          const SizedBox(height: Space.l),
          SettingsToggles(onChanged: () => setState(() {})),
        ],
      ),
    );
  }
}

class SettingsToggles extends StatelessWidget {
  const SettingsToggles({super.key, required this.onChanged, this.showLanguage = false});
  final VoidCallback onChanged;
  final bool showLanguage;
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
        row(tr('sound'), p.sound, (v) => p.sound = v),
        row(tr('music'), p.music, (v) {
          p.music = v;
          Sfx.instance.refreshMusic();
        }),
        row(tr('haptics'), p.haptics, (v) => p.haptics = v),
        row(tr('reduce_motion'), p.reduceMotion, (v) => p.reduceMotion = v),
        if (showLanguage) ...[
          const SizedBox(height: Space.s),
          Row(children: [
            const GameIcon(GI.globe, size: 22),
            const SizedBox(width: Space.s),
            Text(tr('language'), style: ko(TypeScale.label)),
            const Spacer(),
            for (final code in ['', ...L10n.supported])
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(code.isEmpty ? tr('auto') : L10n.names[code]!, style: ko(TypeScale.body, color: p.lang == code ? const Color(0xFF2A1B05) : Palette.ink)),
                  selected: p.lang == code,
                  selectedColor: Palette.moon,
                  backgroundColor: const Color(0x66101640),
                  showCheckmark: false,
                  onSelected: (_) {
                    p.lang = code;
                    p.save();
                    onChanged();
                  },
                ),
              ),
          ]),
        ],
      ],
    );
  }
}
