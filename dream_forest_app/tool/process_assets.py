"""받은 이미지를 게임 규격에 맞게 정리해서 저장해요.

python3 tool/process_assets.py 받은파일.png monster/slime
python3 tool/process_assets.py --dir 받은폴더/
"""
import json, os, sys

ROOT = os.path.join(os.path.dirname(__file__), '..')
try:
    from PIL import Image
except ImportError:
    sys.exit('Pillow 가 필요해요: pip install pillow')

manifest = json.load(open(os.path.join(ROOT, 'docs', 'asset_manifest.json'), encoding='utf-8'))
by_id = {a['id']: a for a in manifest['assets'] if a['type'] == 'image'}
by_tail = {a['id'].split('/')[-1]: a for a in by_id.values()}


def remove_bg(img):
    try:
        from rembg import remove  # 선택: 설치돼 있으면 배경 제거
        return remove(img)
    except Exception:
        return img


def process(src, asset_id):
    a = by_id.get(asset_id)
    if not a:
        print(f'목록에 없는 id: {asset_id}')
        return
    img = Image.open(src).convert('RGBA')
    if a['transparent']:
        alpha = img.getchannel('A')
        if alpha.getextrema()[0] == 255:
            img = remove_bg(img)
            if img.getchannel('A').getextrema()[0] == 255:
                print(f'⚠ {asset_id}: 배경이 투명하지 않아요 (rembg 를 설치하거나 다시 생성하세요)')
        box = img.getchannel('A').getbbox()
        if box:
            img = img.crop(box)
    tw, th = a['size']
    if a['category'] in ('bg',) or not a['transparent']:
        img = img.resize((tw, th), Image.LANCZOS)
    else:
        # 비율을 지키며 규격 안에 넣고, 캐릭터는 발이 아래에 닿게 아래 가운데 정렬
        k = min(tw / img.width, th / img.height)
        img = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))), Image.LANCZOS)
        canvas = Image.new('RGBA', (tw, th), (0, 0, 0, 0))
        bottom = a['category'] in ('player', 'monster', 'boss')
        x = (tw - img.width) // 2
        y = th - img.height if bottom else (th - img.height) // 2
        canvas.paste(img, (x, y), img)
        img = canvas
    out = os.path.join(ROOT, a['path'])
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out, optimize=True)
    print(f'✓ {asset_id} → {a["path"]} ({tw}×{th})')


if len(sys.argv) >= 3 and sys.argv[1] == '--dir':
    folder = sys.argv[2]
    for f in sorted(os.listdir(folder)):
        name, ext = os.path.splitext(f)
        if ext.lower() not in ('.png', '.webp', '.jpg', '.jpeg'):
            continue
        a = by_id.get(name.replace('__', '/')) or by_tail.get(name)
        if a:
            process(os.path.join(folder, f), a['id'])
        else:
            print(f'· 건너뜀 (이름이 목록과 안 맞음): {f}')
elif len(sys.argv) == 3:
    process(sys.argv[1], sys.argv[2])
else:
    print(__doc__)
