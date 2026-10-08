"""이미지 에셋 점검: 있는 것 / 없는 것 / 크기가 다른 것
python3 tool/check_assets.py
"""
import json, os

ROOT = os.path.join(os.path.dirname(__file__), '..')
manifest = json.load(open(os.path.join(ROOT, 'docs', 'asset_manifest.json'), encoding='utf-8'))
try:
    from PIL import Image
except ImportError:
    Image = None

have, missing, wrong = [], [], []
for a in manifest['assets']:
    p = os.path.join(ROOT, a['path'])
    if not os.path.exists(p):
        missing.append(a); continue
    have.append(a)
    if Image:
        with Image.open(p) as im:
            if list(im.size) != a['size']:
                wrong.append((a, im.size))
            if a['transparent'] and im.mode != 'RGBA':
                wrong.append((a, '투명 아님'))

total = len(manifest['assets'])
print(f'완료 {len(have)} / {total}')
groups = {}
for a in missing: groups.setdefault(a['group'], []).append(a['id'])
for g, ids in groups.items():
    print(f'- 없음 [{g}] ' + ', '.join(ids))
for a, s in wrong:
    print(f"- 확인 필요 {a['id']}: {s} (기대 {a['size'][0]}x{a['size'][1]})")
