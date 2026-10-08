import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'profile.dart';

/// 효과음과 진동. 파일은 assets/audio/<이름>.wav (tool/gen_sfx.py 로 생성).
/// 같은 이름의 .ogg/.mp3 로 교체하려면 [_ext] 만 바꾸면 된다.
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();
  static const _ext = 'wav';

  static final names = [
    'twang', 'echo', 'stick', 'gate_stick', 'switch', 'gate_open', 'gate_close', 'win', 'fail', 'oops', 'fizzle', 'ice', 'portal',
    'prism', 'shield', 'rotate', 'click', 'coin', 'star', 'chest', 'purchase', 'pop',
    for (var i = 0; i < 10; i++) 'bounce_$i',
    for (var i = 0; i < 4; i++) 'hit_$i',
  ];
  static const _poolSize = {'click': 2, 'coin': 3, 'star': 3, 'pop': 2};

  final Map<String, List<AudioPlayer>> _players = {};
  final Map<String, int> _next = {};
  final Map<String, int> _last = {};
  int _lastHaptic = 0;
  bool _ready = false;

  Future<void> init() async {
    try {
      AudioCache.instance = AudioCache(prefix: 'assets/audio/');
      await AudioCache.instance.loadAll([for (final n in names) '$n.$_ext']);
      for (final n in names) {
        final count = _poolSize[n] ?? (n.startsWith('bounce') || n.startsWith('hit') ? 2 : 1);
        _players[n] = [
          for (var i = 0; i < count; i++)
            AudioPlayer()
              ..setReleaseMode(ReleaseMode.stop)
              ..setPlayerMode(PlayerMode.lowLatency),
        ];
      }
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  void play(String name, {double volume = 0.8, int minGapMs = 30}) {
    if (!_ready || !Profile.instance.sound) return;
    final list = _players[name];
    if (list == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_last[name] ?? 0) < minGapMs) return;
    _last[name] = now;
    final i = (_next[name] ?? 0) % list.length;
    _next[name] = i + 1;
    try {
      list[i].play(AssetSource('$name.$_ext'), volume: volume);
    } catch (_) {}
  }

  void bounce(int b) => play('bounce_${b.clamp(0, 9)}', volume: 0.6);
  void hit(int n) => play('hit_${n.clamp(0, 3)}');

  void haptic({bool strong = false}) {
    if (!Profile.instance.haptics) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHaptic < 50) return;
    _lastHaptic = now;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }
}
