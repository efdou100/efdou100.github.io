# src.html + sim.js -> index.html(저장소/깃허브 페이지용) + artifact.html(아티팩트용, 문서 골격 없음)
import pathlib, sys
root = pathlib.Path(__file__).resolve().parent.parent
src = (root / 'src.html').read_text(encoding='utf-8')
sim = (root / 'sim.js').read_text(encoding='utf-8').replace("if (typeof module !== 'undefined') module.exports = SIM;", '')
body = src.replace('/*SIM*/', sim)
(root / 'index.html').write_text('<!doctype html>\n<html lang="ko">\n<head>\n<meta charset="utf-8">\n' + body + '\n</html>\n', encoding='utf-8')
if len(sys.argv) > 1:
    pathlib.Path(sys.argv[1]).write_text(body, encoding='utf-8')
print('ok', len(body))
