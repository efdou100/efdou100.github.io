import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/save_data.dart';
import '../app/theme.dart';
import '../game/dream_game.dart';
import '../game/skills.dart';
import '../game/stages.dart';
import '../widgets/ui_kit.dart';
import 'camp_screen.dart';

class GameScreen extends StatefulWidget {
  final StageDef stage;
  final int endlessDepth;
  const GameScreen({super.key, required this.stage, this.endlessDepth = 0});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late DreamGame game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    game = DreamGame(widget.stage, endlessDepth: widget.endlessDepth);
  }

  /// 포커스 위치와 상관없이 키보드를 받아요.
  bool _onKey(KeyEvent e) {
    if (e.logicalKey == LogicalKeyboardKey.escape && e is KeyDownEvent) {
      game.phase.value == GamePhase.paused ? game.resume() : game.pause();
      return true;
    }
    return game.input.key(e);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) game.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  void _restart() {
    setState(() => game = DreamGame(widget.stage, endlessDepth: widget.endlessDepth));
  }

  void _next() {
    final s = widget.stage;
    if (s.isEndless) {
      final depth = widget.endlessDepth + 1;
      Navigator.of(context).pushReplacement(fadeRoute(GameScreen(stage: endlessStage(depth, DateTime.now().millisecondsSinceEpoch), endlessDepth: depth)));
    } else if (s.number < kStages.length) {
      Navigator.of(context).pushReplacement(fadeRoute(GameScreen(stage: kStages[s.number])));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.night,
      body: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => game.input.down(e.pointer, e.localPosition),
              onPointerMove: (e) => game.input.move(e.pointer, e.localPosition),
              onPointerUp: (e) => game.input.up(e.pointer),
              onPointerCancel: (e) => game.input.up(e.pointer),
              child: GameWidget(key: ObjectKey(game), game: game),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: RoundIconButton(Icons.pause_rounded, onTap: game.pause),
              ),
            ),
          ),
          ValueListenableBuilder<GamePhase>(
            valueListenable: game.phase,
            builder: (_, phase, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: switch (phase) {
                GamePhase.playing => const SizedBox.shrink(),
                GamePhase.levelUp => _LevelUp(key: ValueKey(game.offer.map((s) => s.id).join()), game: game),
                GamePhase.paused => game.result != null ? const SizedBox.shrink() : _Pause(game: game, onRestart: _restart),
                GamePhase.cleared => _Result(game: game, onNext: _next, onRetry: _restart),
                GamePhase.failed => _Result(game: game, onNext: _next, onRetry: _restart),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Dim extends StatelessWidget {
  final Widget child;
  final Color tint;
  const _Dim({required this.child, this.tint = const Color(0x99061012)});
  @override
  Widget build(BuildContext context) => BackdropFilter(
    filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
    child: Container(
      color: tint,
      alignment: Alignment.center,
      child: SafeArea(child: child),
    ),
  );
}

class _LevelUp extends StatelessWidget {
  final DreamGame game;
  const _LevelUp({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    final chest = game.offerFromChest;
    return _Dim(
      tint: const Color(0xAA0A0C1C),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShinyTitle(chest ? '보물상자!' : '레벨 업!', size: 44),
              const SizedBox(height: 2),
              Text(
                chest ? '스킬을 하나 더 골라요' : 'Lv ${game.run.level - game.pendingLevels + 1} · 스킬을 하나 골라요',
                style: const TextStyle(color: Palette.mute, fontSize: 14),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < game.offer.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: SkillCard(
                        skill: game.offer[i],
                        currentStack: game.run.stack(game.offer[i].id),
                        index: i,
                        onTap: () => game.pickSkill(game.offer[i]),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pause extends StatelessWidget {
  final DreamGame game;
  final VoidCallback onRestart;
  const _Pause({required this.game, required this.onRestart});
  @override
  Widget build(BuildContext context) {
    final owned = kSkills.where((s) => game.run.has(s.id)).toList();
    return _Dim(
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ShinyTitle('잠깐 쉬어요', size: 34),
            const SizedBox(height: 4),
            Text('${game.stage.name} · ${game.roomIndex + 1}/${game.roomCount}번째 방', style: const TextStyle(color: Palette.mute)),
            const SizedBox(height: 14),
            if (owned.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in owned)
                    Tooltip(
                      message: s.name,
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0x33FFFFFF)),
                        child: SkillIcon(s.id, size: 24),
                      ),
                    ),
                ],
              )
            else
              const Text('아직 고른 스킬이 없어요', style: TextStyle(color: Palette.mute)),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlowButton(label: '계속하기', icon: Icons.play_arrow_rounded, onTap: game.resume),
                const SizedBox(width: 12),
                GlowButton(label: '처음부터', colors: GlowButton.secondary, textColor: Palette.ink, fontSize: 18, onTap: onRestart),
                const SizedBox(width: 12),
                GlowButton(label: '지도로', colors: GlowButton.secondary, textColor: Palette.ink, fontSize: 18, onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final DreamGame game;
  final VoidCallback onNext, onRetry;
  const _Result({required this.game, required this.onNext, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = game.result!;
    final save = SaveData.instance;
    return _Dim(
      tint: r.cleared ? const Color(0xAA0B1A14) : const Color(0xAA1A0A10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: GlassPanel(
          glow: r.cleared ? const Color(0x66F5B85C) : const Color(0x55FF5A4F),
          padding: const EdgeInsets.fromLTRB(36, 22, 36, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShinyTitle(
                r.cleared ? (r.endlessDepth != null ? '깊이 ${r.endlessDepth} 돌파!' : '스테이지 클리어!') : '쓰러졌어요',
                size: 42,
                colors: r.cleared
                    ? const [Color(0xFFFFF4D2), Color(0xFFF5B85C), Color(0xFFE86FA6)]
                    : const [Color(0xFFFFD6D6), Color(0xFFFF8A8A), Color(0xFFB04A6A)],
              ),
              Text(game.stage.name, style: const TextStyle(color: Palette.mute)),
              const SizedBox(height: 12),
              if (r.cleared && r.endlessDepth == null) ...[
                StarRow(stars: r.stars, size: 52, animate: true),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [_tag('클리어', r.stars[0]), _tag('체력 절반 이상', r.stars[1]), _tag('꿈 조각 ${r.shardsFound}/${r.shardsTotal}', r.stars[2])],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stat('처치', '${r.kills}'),
                  _stat('최고 콤보', '${r.bestCombo}'),
                  _stat('레벨', '${r.level}'),
                  _stat('코인', '+${r.coins}', color: Palette.gold),
                ],
              ),
              const SizedBox(height: 6),
              Text(r.cleared ? '모은 코인은 캠프에서 강화에 쓸 수 있어요' : '모은 코인은 그대로 남아요. 강화하고 다시 도전해요', style: const TextStyle(color: Palette.mute, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r.cleared)
                    GlowButton(
                      label: game.stage.isEndless ? '더 깊이' : (game.stage.number < kStages.length ? '다음 스테이지' : '지도로'),
                      icon: Icons.arrow_forward_rounded,
                      onTap: onNext,
                    )
                  else
                    GlowButton(label: '다시 도전', icon: Icons.refresh_rounded, onTap: onRetry),
                  const SizedBox(width: 12),
                  if (!r.cleared)
                    GlowButton(
                      label: '강화하기 (${save.coins})',
                      colors: GlowButton.violet,
                      textColor: Colors.white,
                      fontSize: 18,
                      onTap: () => Navigator.of(context).pushReplacement(fadeRoute(const CampScreen())),
                    ),
                  if (!r.cleared) const SizedBox(width: 12),
                  GlowButton(label: '지도로', colors: GlowButton.secondary, textColor: Palette.ink, fontSize: 18, onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String t, bool on) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(t, style: TextStyle(fontSize: 12, color: on ? Palette.gold : Palette.mute)),
  );

  Widget _stat(String label, String value, {Color color = Palette.ink}) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(14)),
    child: Column(
      children: [
        Text(label, style: const TextStyle(color: Palette.mute, fontSize: 12)),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, k, _) {
            final n = int.tryParse(value.replaceAll('+', ''));
            final shown = n == null ? value : '${value.startsWith('+') ? '+' : ''}${(n * k).round()}';
            return Text(shown, style: display(24, color: color));
          },
        ),
      ],
    ),
  );
}
