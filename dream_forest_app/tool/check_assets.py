"""에셋 상태 점검: 빠진 것, 규격이 다른 것, 목록에 없는 파일.

python3 tool/check_assets.py          # 지금 게임이 쓰는 것(used)만
python3 tool/check_assets.py --all    # 계획(planned)까지 전부
"""
import json, os, sys

ROOT = os.path.join(os.path.dirname(__file__), '..')
manifest = json.load(open(os.path.join(ROOT, 'docs', 'asset_manifest.json'), encoding='utf-8'))
everything = '--all' in sys.argv
want = [a for a in manifest['assets'] if everything or a['status'] == 'used']
AUDIO_EXT = ('.ogg', '.mp3', '.wav', '.m4a')
IMAGE_EXT = ('.png', '.webp', '.jpg')

def find(a):
    base = os.path.join(ROOT, os.path.splitext(a['path'])[0])
    for ext in (IMAGE_EXT if a['type'] == 'image' else AUDIO_EXT):
        if os.path.exists(base + ext):
            return base + ext
    return None

have, missing, wrong = 0, [], []
try:
    from PIL import Image
except ImportError:
    Image = None
for a in want:
    f = find(a)
    if not f:
        missing.append(a)
        continue
    have += 1
    if Image and a['type'] == 'image':
        w, h = Image.open(f).size
        if [w, h] != a['size']:
            wrong.append((a, (w, h)))

known = {os.path.splitext(a['path'])[0] for a in manifest['assets']}
extra = []
for folder in ('assets/images', 'assets/audio/sfx', 'assets/audio/bgm'):
    for dp, _, fs in os.walk(os.path.join(ROOT, folder)):
        for f in fs:
            if f.startswith('.'):
                continue
            rel = os.path.relpath(os.path.join(dp, os.path.splitext(f)[0]), ROOT)
            if rel not in known and not rel.endswith('_charge'):
                extra.append(rel)

print(f'{"전체" if everything else "지금 사용"} {len(want)}개 중 {have}개 있음')
if wrong:
    print('\n규격이 달라요 (게임은 늘려서 그리지만 흐려질 수 있어요):')
    for a, s in wrong:
        print(f'  {a["id"]}: {s[0]}×{s[1]} → 권장 {a["size"][0]}×{a["size"][1]}')
if extra:
    print('\n목록에 없는 파일 (이름 오타일 수 있어요):')
    for e in extra:
        print('  ' + e)
if missing:
    print(f'\n아직 없는 파일 {len(missing)}개 (없으면 벡터·합성음으로 대신 그려요)')
    for a in missing[:40]:
        print(f'  {a["path"]}  {a["ko"]}')
    if len(missing) > 40:
        print(f'  … 외 {len(missing) - 40}개')
