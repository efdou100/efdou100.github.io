import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 이미지 교체 시스템.
/// `assets/images/{id}.png` 가 있으면 그 이미지를, 없으면 코드로 그린 그림을 쓴다.
/// id 목록과 Gemini 프롬프트는 docs/ASSETS.md (tool/gen_asset_manifest.py 로 생성).
class Art {
  Art._();
  static final Art instance = Art._();

  final Set<String> _ids = {};
  final Map<String, ui.Image> _images = {};
  final Map<String, Future<ui.Image?>> _loading = {};

  /// 앱 시작 시 한 번: 번들에 들어 있는 이미지 목록을 읽고 미리 불러온다.
  Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final key in manifest.listAssets()) {
        if (key.startsWith('assets/images/') && key.endsWith('.png')) {
          _ids.add(key.substring('assets/images/'.length, key.length - 4));
        }
      }
      // 게임·홈에 바로 필요한 것만 먼저, 큰 배경은 쓰일 때 불러온다
      await Future.wait([for (final id in _ids) if (!id.startsWith('bg/')) load(id)]);
    } catch (_) {}
  }

  bool has(String id) => _ids.contains(id);

  /// 불러온 이미지 (아직 없으면 null → 코드 그림으로 대체)
  ui.Image? image(String id) {
    final img = _images[id];
    if (img == null && has(id)) load(id);
    return img;
  }

  Future<ui.Image?> load(String id) {
    if (_images.containsKey(id)) return Future.value(_images[id]);
    return _loading[id] ??= () async {
      try {
        final data = await rootBundle.load('assets/images/$id.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _images[id] = frame.image;
        return frame.image;
      } catch (_) {
        _ids.remove(id);
        return null;
      }
    }();
  }

  String path(String id) => 'assets/images/$id.png';
}

/// 캔버스에 이미지 그리기 도우미
extension ArtCanvas on Canvas {
  /// 중심 기준으로 지정한 크기에 맞춰 그리기 (회전 가능)
  void drawArt(ui.Image img, Offset center, Size size, {double rotation = 0, double opacity = 1, BlendMode? blend}) {
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    if (blend != null) paint.blendMode = blend;
    save();
    translate(center.dx, center.dy);
    if (rotation != 0) rotate(rotation);
    drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height), paint);
    restore();
  }

  /// 사각형을 꽉 채우기 (비율 유지, 넘치는 부분 잘림)
  void drawArtCover(ui.Image img, Rect dst, {double opacity = 1}) {
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final s = (dst.width / iw) > (dst.height / ih) ? dst.width / iw : dst.height / ih;
    final sw = dst.width / s, sh = dst.height / s;
    final src = Rect.fromLTWH((iw - sw) / 2, (ih - sh) / 2, sw, sh);
    drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.medium..color = Color.fromRGBO(255, 255, 255, opacity));
  }

  /// 가로로 반복되는 띠 이미지를 선분 a→b 를 따라 그리기 (벽 타일)
  void drawArtStrip(ui.Image img, Offset a, Offset b, double thickness) {
    final len = (b - a).distance;
    if (len < 1) return;
    final ang = (b - a).direction;
    save();
    translate(a.dx, a.dy);
    rotate(ang);
    final tileW = img.width * thickness / img.height;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    var x = -thickness * 0.3;
    final end = len + thickness * 0.3;
    while (x < end) {
      final w = (end - x).clamp(0.0, tileW);
      drawImageRect(img, Rect.fromLTWH(0, 0, img.width * (w / tileW), img.height.toDouble()), Rect.fromLTWH(x, -thickness / 2, w, thickness), paint);
      x += tileW;
    }
    restore();
  }
}

/// 위젯: 이미지가 있으면 이미지, 없으면 [fallback]
class ArtImage extends StatelessWidget {
  const ArtImage(this.id, {super.key, required this.fallback, this.size, this.fit = BoxFit.contain});
  final String id;
  final Widget fallback;
  final Size? size;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    if (!Art.instance.has(id)) return SizedBox(width: size?.width, height: size?.height, child: fallback);
    return Image.asset(Art.instance.path(id), width: size?.width, height: size?.height, fit: fit, filterQuality: FilterQuality.medium, errorBuilder: (_, _, _) => fallback);
  }
}
