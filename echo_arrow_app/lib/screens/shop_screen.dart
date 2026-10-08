import 'package:flutter/material.dart';

import '../app/art.dart';
import '../app/economy.dart';
import '../app/l10n.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../services/services.dart';
import '../widgets/icons.dart';
import '../widgets/ui.dart';

/// 상점 탭. 위에서부터: 한정 패키지 → 저금통 → 광고 제거 → 코인 → 부스터 → 꾸미기
class ShopPage extends StatefulWidget {
  const ShopPage({super.key, this.topInset = 0, this.bottomInset = 0});
  final double topInset, bottomInset;
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with AutomaticKeepAliveClientMixin {
  Profile get p => Profile.instance;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    p.addListener(_r);
  }

  void _r() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    p.removeListener(_r);
    super.dispose();
  }

  Future<void> _buy(Product prod) async {
    Analytics.log('shop_tap', {'id': prod.id});
    if (await StoreService.instance.buy(prod)) Sfx.instance.play('purchase');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final starter = Economy.product('starter');
    return ListView(
      padding: EdgeInsets.fromLTRB(Space.l, widget.topInset + Space.m, Space.l, widget.bottomInset + Space.xl),
      children: [
        Center(child: RibbonTitle(text: tr('shop'))),
        const SizedBox(height: Space.l),
        if (p.starterActive)
          _OfferCard(
            art: 'shop/starter',
            fallback: GI.gift,
            title: starter.name,
            sub: tr('once_left', {'t': fmtDur(Duration(milliseconds: p.starterUntil - DateTime.now().millisecondsSinceEpoch))}),
            lines: starter.reward.lines,
            price: starter.priceLabel,
            color: Palette.blossom,
            ribbon: tr('badge_once'),
            onBuy: () => _buy(starter),
          ),
        _OfferCard(
          art: 'shop/piggy',
          fallback: GI.coin,
          title: tr('piggy'),
          sub: tr('piggy_sub', {'a': p.piggy, 'b': Economy.piggyMax}),
          lines: [tr('piggy_now', {'n': p.piggy})],
          price: Economy.product('piggy').priceLabel,
          color: Palette.moon,
          progress: p.piggy / Economy.piggyMax,
          onBuy: p.piggy >= 1000 ? () => _buy(Economy.product('piggy')) : null,
          disabledNote: tr('piggy_min'),
        ),
        if (!p.adsRemoved)
          _OfferCard(art: 'shop/noads', fallback: GI.ad, title: tr('noads'), sub: tr('noads_sub'), lines: const [], price: Economy.product('noads').priceLabel, color: Palette.echo, onBuy: () => _buy(Economy.product('noads'))),
        const SizedBox(height: Space.m),
        _SectionTitle(tr('coins')),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Space.s,
          crossAxisSpacing: Space.s,
          childAspectRatio: 0.72,
          children: [for (final id in const ['coins_s', 'coins_m', 'coins_l', 'coins_xl', 'coins_xxl']) _CoinTile(product: Economy.product(id), onBuy: () => _buy(Economy.product(id)))],
        ),
        const SizedBox(height: Space.l),
        _SectionTitle(tr('boosters')),
        for (final k in const ['aim', 'extra', 'split']) _BoosterRow(id: k),
        const SizedBox(height: Space.l),
        _SectionTitle(tr('trails')),
        Text(tr('trails_sub'), style: ko(TypeScale.caption, color: Palette.inkSoft)),
        const SizedBox(height: Space.s),
        Row(children: [for (final id in Economy.trailIds) Expanded(child: _TrailCard(id: id))]),
        const SizedBox(height: Space.l),
        Center(child: Btn(tr('restore'), style: BtnStyle.ghost, height: 48, expand: false, onTap: () => StoreService.instance.restore())),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.s, left: 4),
    child: Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: Palette.moon, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: Space.s),
      Text(text, style: ko(TypeScale.label)),
    ]),
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.art, required this.fallback, required this.title, required this.sub, required this.lines, required this.price, required this.color, required this.onBuy, this.progress, this.disabledNote, this.ribbon});
  final String art, title, sub, price;
  final GI fallback;
  Widget get _fallbackArt => fallback == GI.coin
      ? const Stack(alignment: Alignment.center, children: [Positioned(left: 8, top: 26, child: CoinIcon(size: 40)), Positioned(right: 6, top: 30, child: CoinIcon(size: 36)), Positioned(top: 8, child: CoinIcon(size: 46))])
      : Center(child: GameIcon(fallback, size: 64));
  final List<String> lines;
  final Color color;
  final VoidCallback? onBuy;
  final double? progress;
  final String? disabledNote, ribbon;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: Space.m),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.32), const Color(0xF0161D52)]),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 18)],
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Row(
            children: [
              SizedBox(width: 84, height: 84, child: ArtImage(art, fallback: _fallbackArt)),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ko(TypeScale.title)),
                    Text(sub, style: ko(TypeScale.caption, color: Palette.inkSoft)),
                    if (lines.isNotEmpty) ...[const SizedBox(height: 4), Text(lines.join(' · '), style: ko(TypeScale.body))],
                    if (progress != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress!.clamp(0, 1), minHeight: 10, backgroundColor: const Color(0x33FFFFFF), color: color)),
                    ],
                    const SizedBox(height: Space.s),
                    Btn(price, style: BtnStyle.green, onTap: onBuy, height: 46),
                    if (onBuy == null && disabledNote != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(disabledNote!, style: ko(TypeScale.caption, color: Palette.inkSoft))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (ribbon != null)
          Positioned(
            right: 14,
            top: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Palette.danger, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))]),
              child: Text(ribbon!, style: ko(TypeScale.caption, color: Colors.white)),
            ),
          ),
      ],
    ),
  );
}

class _CoinTile extends StatelessWidget {
  const _CoinTile({required this.product, required this.onBuy});
  final Product product;
  final VoidCallback onBuy;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onBuy,
    semantic: '${product.name} ${product.priceLabel}',
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F3B86), Color(0xFF1A2058)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x55A0B4FF)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              const SizedBox(height: Space.s),
              Expanded(child: ArtImage('shop/${product.id}', fallback: const Center(child: CoinIcon(size: 44)))),
              Text('${product.reward.coins}', style: numStyle(TypeScale.label, color: Palette.moon)),
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA8F07A), Color(0xFF4CC24A)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0xFF2B8A33), offset: Offset(0, 3))],
                ),
                child: Text(product.priceLabel, style: numStyle(TypeScale.body, color: const Color(0xFF0B2E0E))),
              ),
            ],
          ),
          if (product.badgeText != null)
            Positioned(
              left: 0,
              right: 0,
              top: -8,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Palette.danger, borderRadius: BorderRadius.circular(8)),
                  child: Text(product.badgeText!, style: ko(11, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _BoosterRow extends StatelessWidget {
  const _BoosterRow({required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final price = Economy.boosterPrice[id]! * 3;
    final icon = switch (id) { 'aim' => GI.aim, 'extra' => GI.extra, _ => GI.split };
    return Container(
      margin: const EdgeInsets.only(bottom: Space.s),
      padding: const EdgeInsets.all(Space.m),
      decoration: BoxDecoration(color: const Color(0x99141A4A), borderRadius: BorderRadius.circular(18), border: Border.all(color: Palette.line)),
      child: Row(
        children: [
          Container(width: 52, height: 52, decoration: const BoxDecoration(color: Color(0x33FFD36B), shape: BoxShape.circle), alignment: Alignment.center, child: GameIcon(icon, size: 34)),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${Economy.boosterName(id)} ×3', style: ko(TypeScale.label)),
                Text('${Economy.boosterDesc(id)} · ${tr('own_n', {'n': p.boosters[id]})}', style: ko(TypeScale.caption, color: Palette.inkSoft)),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: Btn('$price', icon: const CoinIcon(size: 18), height: 44, onTap: p.coins >= price
                ? () {
                    p.spend(price);
                    p.boosters[id] = (p.boosters[id] ?? 0) + 3;
                    p.save();
                    Sfx.instance.play('coin');
                    Analytics.log('booster_buy', {'id': id});
                  }
                : null),
          ),
        ],
      ),
    );
  }
}

class _TrailCard extends StatelessWidget {
  const _TrailCard({required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final p = Profile.instance;
    final owned = p.trails.contains(id), on = p.trail == id;
    final col = switch (id) { 'ember' => const Color(0xFFFF8A4C), 'aurora' => const Color(0xFF9DFFCB), _ => Palette.moon };
    return Pressable(
      onTap: owned
          ? () {
              p.trail = id;
              p.save();
            }
          : null,
      semantic: '${Economy.trailName(id)}${owned ? '' : ', ${tr('pass_reward')}'}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: Space.m),
        decoration: BoxDecoration(color: const Color(0x99141A4A), borderRadius: BorderRadius.circular(16), border: Border.all(color: on ? col : Palette.line, width: on ? 2 : 1)),
        child: Column(
          children: [
            Container(height: 6, width: 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [col.withValues(alpha: 0), col]), borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: col.withValues(alpha: 0.6), blurRadius: 8)])),
            const SizedBox(height: Space.s),
            Text(Economy.trailName(id), style: ko(TypeScale.body)),
            Text(on ? tr('in_use') : (owned ? tr('equip') : tr('pass_reward')), style: ko(TypeScale.caption, color: on ? col : Palette.inkSoft)),
          ],
        ),
      ),
    );
  }
}
