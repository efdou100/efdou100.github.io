import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import 'save_data.dart';

/// 효과음과 진동. 자주 나는 소리는 풀로 돌려 끊김을 줄이고, 같은 소리는 너무 촘촘히 겹치지 않게 해요.
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  static const names = [
    'shoot', 'hit', 'crit', 'kill', 'jump', 'land', 'spring', 'coin', 'xp', 'levelup', 'hurt', 'portal', 'crumble',
    'bridge', 'tele', 'boom', 'thud', 'select', 'chest', 'shield', 'freeze', 'zap', 'focus',
  ];
  static const _pooled = {'shoot': 4, 'hit': 4, 'xp': 3, 'coin': 3, 'kill': 3};
  static const _volume = {'shoot': 0.35, 'hit': 0.5, 'xp': 0.35, 'coin': 0.5, 'tele': 0.4, 'land': 0.5};

  final Map<String, AudioPool> _pools = {};
  final Map<String, int> _last = {};
  int _lastHaptic = 0;
  bool _ready = false;

  Future<void> init() async {
    try {
      FlameAudio.audioCache.prefix = 'assets/audio/';
      await FlameAudio.audioCache.loadAll([for (final n in names) '$n.wav']);
      for (final e in _pooled.entries) {
        _pools[e.key] = await FlameAudio.createPool('${e.key}.wav', maxPlayers: e.value);
      }
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  void play(String name, {double volume = 1, int minGapMs = 35}) {
    if (!_ready || !SaveData.instance.sound) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_last[name] ?? 0) < minGapMs) return;
    _last[name] = now;
    final v = (volume * (_volume[name] ?? 0.7)).clamp(0.0, 1.0);
    try {
      final pool = _pools[name];
      if (pool != null) {
        pool.start(volume: v);
      } else {
        FlameAudio.play('$name.wav', volume: v);
      }
    } catch (_) {}
  }

  void haptic({bool strong = false}) {
    if (!SaveData.instance.haptics) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHaptic < 60) return;
    _lastHaptic = now;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }
}
