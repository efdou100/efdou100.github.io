import 'package:flutter/material.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import '../app/sfx.dart';
import '../app/theme.dart';
import '../services/services.dart';
import '../widgets/ui.dart';
import 'sheets.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  Profile get p => Profile.instance;

  @override
  void initState() {
    super.initState();
    p.addListener(_r);
    Analytics.log('shop_open');
  }

  void _r() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    p.removeListener(_r);
    super.dispose();
  }

  Future<void> _buy(Product prod) async {
    if (await StoreService.instance.buy(prod)) Sfx.instance.play('purchase');
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
                  Text('상점', style: ko(TypeScale.title)),
                  const Spacer(),
                  Pill(icon: const CoinIcon(), text: '${p.coins}'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, pad.bottom + Space.xl),
                children: [
                  if (p.starterActive) _Feature(
                    title: '스타터 팩',
                    sub: '처음 한 번만 · ${fmtDur(Duration(milliseconds: p.starterUntil - DateTime.now().millisecondsSinceEpoch))} 남음',
                    lines: Economy.product('starter').reward.lines,
                    price: Economy.product('starter').priceLabel,
                    color: Palette.blossom,
                    icon: Icons.card_giftcard_rounded,
                    onBuy: () => _buy(Economy.product('starter')),
                  ),
                  _Feature(
                    title: '별빛 저금통',
                    sub: '깰 때마다 코인이 쌓여요 (${p.piggy} / ${Economy.piggyMax})',
                    lines: ['지금 깨면 코인 ${p.piggy}'],
                    price: Economy.product('piggy').priceLabel,
                    color: Palette.moon,
                    icon: Icons.savings_rounded,
                    progress: p.piggy / Economy.piggyMax,
                    onBuy: p.piggy >= 1000 ? () => _buy(Economy.product('piggy')) : null,
                    disabledNote: '코인 1000개부터 깰 수 있어요',
                  ),
                  if (!p.adsRemoved)
                    _Feature(
                      title: '광고 제거',
                      sub: '판 사이 광고가 사라져요. 원할 때 보는 보상형 광고는 그대로예요.',
                      lines: const [],
                      price: Economy.product('noads').priceLabel,
                      color: Palette.echo,
                      icon: Icons.block_rounded,
                      onBuy: () => _buy(Economy.product('noads')),
                    ),
                  const SizedBox(height: Space.l),
                  Text('코인', style: ko(TypeScale.label)),
                  const SizedBox(height: Space.s),
                  for (final id in const ['coins_s', 'coins_m', 'coins_l', 'coins_xl', 'coins_xxl']) Padding(padding: const EdgeInsets.only(bottom: Space.s), child: ProductRow(product: Economy.product(id))),
                  const SizedBox(height: Space.l),
                  Text('부스터', style: ko(TypeScale.label)),
                  const SizedBox(height: Space.s),
                  for (final k in const ['aim', 'extra', 'split']) _BoosterRow(id: k),
                  const SizedBox(height: Space.l),
                  Text('화살 궤적', style: ko(TypeScale.label)),
                  const SizedBox(height: Space.s),
                  Text('다시보기와 공유 영상에 그대로 보여요', style: ko(TypeScale.caption, color: Palette.inkSoft)),
                  const SizedBox(height: Space.s),
                  Row(children: [for (final e in Economy.trails.entries) Expanded(child: _TrailCard(id: e.key, name: e.value))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.title, required this.sub, required this.lines, required this.price, required this.color, required this.icon, required this.onBuy, this.progress, this.disabledNote});
  final String title, sub, price;
  final List<String> lines;
  final Color color;
  final IconData icon;
  final VoidCallback? onBuy;
  final double? progress;
  final String? disabledNote;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: Space.m),
    padding: const EdgeInsets.all(Space.l),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.22), const Color(0x99141A4A)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(width: Space.m),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: ko(TypeScale.title)), Text(sub, style: ko(TypeScale.caption, color: Palette.inkSoft))])),
          ],
        ),
        if (lines.isNotEmpty) ...[const SizedBox(height: Space.s), Text(lines.join(' · '), style: ko(TypeScale.body))],
        if (progress != null) ...[
          const SizedBox(height: Space.s),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress!.clamp(0, 1), minHeight: 10, backgroundColor: const Color(0x33FFFFFF), color: color)),
        ],
        const SizedBox(height: Space.m),
        Btn(price, onTap: onBuy, height: 48),
        if (onBuy == null && disabledNote != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(disabledNote!, style: ko(TypeScale.caption, color: Palette.inkSoft))),
      ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: Space.s),
      padding: const EdgeInsets.all(Space.m),
      decoration: BoxDecoration(color: const Color(0x66101640), borderRadius: BorderRadius.circular(16), border: Border.all(color: Palette.line)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${Economy.boosterName[id]} ×3', style: ko(TypeScale.label)),
                Text('${Economy.boosterDesc[id]} · 보유 ${p.boosters[id]}', style: ko(TypeScale.caption, color: Palette.inkSoft)),
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
  const _TrailCard({required this.id, required this.name});
  final String id, name;
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
      semantic: '궤적 $name${owned ? '' : ', 패스 보상'}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: Space.m),
        decoration: BoxDecoration(color: const Color(0x66101640), borderRadius: BorderRadius.circular(16), border: Border.all(color: on ? col : Palette.line, width: on ? 2 : 1)),
        child: Column(
          children: [
            Container(height: 6, width: 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [col.withValues(alpha: 0), col]), borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: col.withValues(alpha: 0.6), blurRadius: 8)])),
            const SizedBox(height: Space.s),
            Text(name, style: ko(TypeScale.body)),
            Text(on ? '사용 중' : (owned ? '선택' : '패스 보상'), style: ko(TypeScale.caption, color: on ? col : Palette.inkSoft)),
          ],
        ),
      ),
    );
  }
}
