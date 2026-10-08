"""Gemini 결과물 정리: 초록 배경 제거 → 여백 자르기 → 목표 크기로 맞춤 → assets/images/<id>.png
사용: python3 tool/process_assets.py raw/            (raw/ 안의 <id에서 / 를 __ 로 바꾼 이름>.png|jpg|webp)
      python3 tool/process_assets.py raw/ --dry      (무엇을 할지 출력만)
필요: pip install pillow
"""
import json, os, sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
manifest = json.load(open(os.path.join(ROOT, 'docs', 'asset_manifest.json'), encoding='utf-8'))
by_id = {a['id']: a for a in manifest['assets']}


def key_out_green(img):
    """순수 초록(#00FF00) 근처를 투명으로. 가장자리는 부드럽게, 초록 번짐(스필)은 줄인다."""
    img = img.convert('RGBA')
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dom = g - max(r, b)  # 초록이 얼마나 우세한지
            if dom > 90 and g > 120:
                px[x, y] = (r, g, b, 0)
            elif dom > 35 and g > 90:
                alpha = int(255 * (1 - (dom - 35) / 55))
                g2 = max(r, b) + (g - max(r, b)) // 4  # 스필 제거
                px[x, y] = (r, g2, b, min(a, alpha))
            elif dom > 10:
                px[x, y] = (r, max(r, b) + (g - max(r, b)) // 2, b, a)
    return img


def fit(img, size, transparent):
    tw, th = size
    if transparent:
        bbox = img.getbbox()
        if bbox: img = img.crop(bbox)
        # 비율 유지하며 목표 안에 넣고, 투명 여백으로 채움 (4% 여유)
        scale = min(tw * 0.96 / img.width, th * 0.96 / img.height)
        img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.LANCZOS)
        canvas = Image.new('RGBA', (tw, th), (0, 0, 0, 0))
        canvas.paste(img, ((tw - img.width) // 2, (th - img.height) // 2), img)
        return canvas
    # 배경: 비율 유지하며 꽉 채우고 가운데 자르기
    scale = max(tw / img.width, th / img.height)
    img = img.convert('RGB').resize((int(img.width * scale + 0.5), int(img.height * scale + 0.5)), Image.LANCZOS)
    l, t = (img.width - tw) // 2, (img.height - th) // 2
    return img.crop((l, t, l + tw, t + th))


def main():
    if len(sys.argv) < 2:
        print(__doc__); return
    src, dry = sys.argv[1], '--dry' in sys.argv
    done, unknown = 0, []
    for name in sorted(os.listdir(src)):
        base, ext = os.path.splitext(name)
        if ext.lower() not in ('.png', '.jpg', '.jpeg', '.webp'): continue
        id = base.replace('__', '/')
        a = by_id.get(id)
        if not a:
            unknown.append(name); continue
        out = os.path.join(ROOT, a['path'])
        print(f"{name} → {a['path']} ({a['size'][0]}x{a['size'][1]}{', 배경 제거' if a['transparent'] else ''})")
        if dry: continue
        img = Image.open(os.path.join(src, name))
        if a['transparent']: img = key_out_green(img)
        img = fit(img, a['size'], a['transparent'])
        os.makedirs(os.path.dirname(out), exist_ok=True)
        img.save(out, optimize=True)
        done += 1
    print(f'처리 {done}개')
    if unknown:
        print('목록에 없는 파일(이름 확인):', ', '.join(unknown))


if __name__ == '__main__':
    main()
