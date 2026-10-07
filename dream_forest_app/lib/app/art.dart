import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// 이미지·사운드 교체 시스템.
///
/// assets/images/<분류>/<이름>.png 를 넣으면 id '<분류>/<이름>' 으로 쓰여요.
/// 파일이 없으면 각 그리기 코드가 지금처럼 벡터로 그려요. 그래서 그림을 하나씩 받아도 바로 바꿔 끼울 수 있어요.
/// 어떤 id 가 필요한지는 docs/ASSET_PIPELINE.md 와 docs/asset_manifest.json 에 정리돼 있어요.
class Art {
  Art._();
  static final Art instance = Art._();

  static const _imageRoot = 'assets/images/';
  static const _audioRoot = 'assets/audio/';
  static const _imageExt = ['.png', '.webp', '.jpg'];
  static const _audioExt = ['.ogg', '.mp3', '.wav', '.m4a'];

  final Map<String, String> _imagePaths = {}; // id → 파일 경로
  final Map<String, String> _audioPaths = {}; // 'sfx/hit' → 'audio/sfx/hit.ogg' (FlameAudio 기준 경로)
  final Map<String, ui.Image> _images = {};
  final Set<String> _loading = {};

  /// 앱 시작 때 한 번: 어떤 파일이 들어 있는지만 읽어요. 실제 이미지는 필요할 때 불러요.
  Future<void> scan() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final path in manifest.listAssets()) {
        final dot = path.lastIndexOf('.');
        if (dot < 0) continue;
        final ext = path.substring(dot).toLowerCase();
        if (path.startsWith(_imageRoot) && _imageExt.contains(ext)) {
          _imagePaths[path.substring(_imageRoot.length, dot)] = path;
        } else if (path.startsWith(_audioRoot) && _audioExt.contains(ext)) {
          _audioPaths[path.substring(_audioRoot.length, dot)] = path.substring('assets/'.length);
        }
      }
    } catch (_) {
      // 매니페스트를 못 읽어도 벡터 그림으로 돌아가요.
    }
  }

  bool has(String id) => _imagePaths.containsKey(id);

  /// Flutter Image.asset 용 경로
  String? pathOf(String id) => _imagePaths[id];

  /// 불러온 이미지. 아직 안 불렀으면 불러오기 시작하고 이번 프레임은 null (벡터로 그림).
  ui.Image? image(String id) {
    final img = _images[id];
    if (img != null) return img;
    if (_imagePaths.containsKey(id)) _load(id);
    return null;
  }

  /// 화면에 들어가기 전에 미리 불러두기 (스테이지 시작 전 등).
  Future<void> preload(Iterable<String> ids) => Future.wait([
    for (final id in ids)
      if (_imagePaths.containsKey(id)) _load(id),
  ]);

  /// 접두사로 미리 불러오기. 예: preloadPrefix('monster/'), preloadPrefix('tile/ch1_')
  Future<void> preloadPrefix(String prefix) => preload(_imagePaths.keys.where((k) => k.startsWith(prefix)));

  Future<void> _load(String id) async {
    if (_images.containsKey(id) || !_loading.add(id)) return;
    try {
      final data = await rootBundle.load(_imagePaths[id]!);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[id] = frame.image;
    } catch (_) {
      _imagePaths.remove(id);
    } finally {
      _loading.remove(id);
    }
  }

  /// 효과음 파일 경로: 받은 파일(sfx/이름) → 없으면 기본 합성음(default/이름)
  String? sfxPath(String name) => _audioPaths['sfx/$name'] ?? _audioPaths['default/$name'];

  /// 배경음 파일 경로 (없으면 null → 조용히 넘어가요)
  String? bgmPath(String name) => _audioPaths['bgm/$name'];

  Iterable<String> get imageIds => _imagePaths.keys;
}

/// 이미지를 사각형 안에 그려요. flipX 로 좌우 반전, tint 로 피격 하양·얼음 파랑 같은 색 덮기.
void drawArt(ui.Canvas c, ui.Image img, ui.Rect dst, {bool flipX = false, ui.Color? tint, double opacity = 1}) {
  final src = ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
  final p = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  if (tint != null) p.colorFilter = ui.ColorFilter.mode(tint, ui.BlendMode.srcATop);
  if (opacity < 1) p.color = ui.Color.fromRGBO(0, 0, 0, opacity);
  if (flipX) {
    c.save();
    c.translate(dst.center.dx, 0);
    c.scale(-1, 1);
    c.translate(-dst.center.dx, 0);
    c.drawImageRect(img, src, dst, p);
    c.restore();
  } else {
    c.drawImageRect(img, src, dst, p);
  }
}

/// 이미지 비율을 지키며 바닥 가운데(발 위치) 기준으로 그려요. height 는 월드 단위.
void drawArtFeet(ui.Canvas c, ui.Image img, double footX, double footY, double height, {bool flipX = false, ui.Color? tint}) {
  final w = height * img.width / img.height;
  drawArt(c, img, ui.Rect.fromLTWH(footX - w / 2, footY - height, w, height), flipX: flipX, tint: tint);
}
