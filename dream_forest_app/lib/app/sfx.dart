import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import 'art.dart';
import 'save_data.dart';

/// 효과음·배경음·진동.
/// 소리 파일은 assets/audio/sfx/<이름>.(ogg|mp3|wav) 에 넣으면 기본 합성음(assets/audio/default) 대신 쓰여요.
/// 배경음은 assets/audio/bgm/<이름>.(ogg|mp3) — 없으면 조용히 넘어가요.
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  /// 게임에서 쓰는 효과음 이름. 새 효과음을 추가하면 여기와 docs/asset_manifest.json 에 같이 적어요.
  static const names = [
    'shoot',
    'hit',
    'crit',
    'kill',
    'jump',
    'land',
    'spring',
    'coin',
    'xp',
    'levelup',
    'hurt',
    'portal',
    'crumble',
    'bridge',
    'tele',
    'boom',
    'thud',
    'select',
    'chest',
    'shield',
    'freeze',
    'zap',
    'focus',
    'bounce',
    'splat',
  ];
  static const _pooled = {'shoot': 4, 'hit': 4, 'xp': 3, 'coin': 3, 'kill': 3, 'bounce': 4};
  static const _volume = {'shoot': 0.35, 'hit': 0.5, 'xp': 0.35, 'coin': 0.5, 'tele': 0.4, 'land': 0.5, 'bounce': 0.45};

  final Map<String, AudioPool> _pools = {};
  final Map<String, String> _files = {};
  final Map<String, int> _last = {};
  int _lastHaptic = 0;
  String? _bgm;

  Future<void> init() async {
    try {
      FlameAudio.audioCache.prefix = 'assets/';
      for (final n in names) {
        final f = Art.instance.sfxPath(n);
        if (f != null) _files[n] = f;
      }
      await FlameAudio.audioCache.loadAll(_files.values.toList());
      for (final e in _pooled.entries) {
        final f = _files[e.key];
        if (f != null) _pools[e.key] = await FlameAudio.createPool(f, maxPlayers: e.value);
      }
    } catch (_) {}
  }

  void play(String name, {double volume = 1, int minGapMs = 35}) {
    if (!SaveData.instance.sound) return;
    final file = _files[name];
    if (file == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_last[name] ?? 0) < minGapMs) return;
    _last[name] = now;
    final v = (volume * (_volume[name] ?? 0.7)).clamp(0.0, 1.0);
    try {
      final pool = _pools[name];
      if (pool != null) {
        pool.start(volume: v);
      } else {
        FlameAudio.play(file, volume: v);
      }
    } catch (_) {}
  }

  /// 배경음 전환. 같은 곡이면 그대로 둬요. 이름 목록은 docs/ASSET_PIPELINE.md 참고 (title, map, camp, stage_ch1, boss ...).
  void music(String name) {
    if (_bgm == name) return;
    _bgm = name;
    try {
      final file = Art.instance.bgmPath(name);
      if (file == null || !SaveData.instance.sound) {
        FlameAudio.bgm.stop();
        return;
      }
      FlameAudio.bgm.play(file, volume: 0.45);
    } catch (_) {}
  }

  void refreshMusic() {
    final n = _bgm;
    _bgm = null;
    if (n != null) music(n);
  }

  void haptic({bool strong = false}) {
    if (!SaveData.instance.haptics) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHaptic < 60) return;
    _lastHaptic = now;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }
}
