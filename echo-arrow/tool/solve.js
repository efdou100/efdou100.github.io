// 레벨 검증 솔버: node echo-arrow/tool/solve.js [레벨번호...]
// - 거울 배치(모든 회전 조합) × 화살 종류 × 각도 × 발사 시각을 전수 탐색
// - par 발 수로 클리어 가능한지 / 거울·스킬 없이도 풀리는지 / 해법 갈래 수 / par보다 적은 발로 풀리는지 확인
const SIM = require('../sim.js');
const { DT, D2R } = SIM;

const hasMoving = L => L.targets.some(t => t.per);
function angles(stepDeg) { const out = []; for (let d = -180; d < 180; d += stepDeg) out.push(d * D2R); return out; }
function times(maxS, stepS) { const out = []; for (let s = 0; s <= maxS + 1e-9; s += stepS) out.push(Math.round(s / DT)); return out; }
function configs(L) {
  let out = [SIM.defaultMirrors(L)];
  (L.mirrors || []).forEach((m, i) => {
    if (!m.rot) return;
    const next = [];
    for (const c of out) for (let s = 0; s < 4; s++) { const n = c.slice(); n[i] = s; next.push(n); }
    out = next;
  });
  const key = c => c.join(',');
  const seen = new Set(); return out.filter(c => !seen.has(key(c)) && seen.add(key(c)));
}
const kinds = L => ['n', ...Object.keys(L.skills || {})];

// 한 발 탐색: 해법 각도 구간(갈래) 수와 성공률
function oneShot(L, prior, cfgs, ks, angStep, ts, stopAtFirst) {
  let wins = 0, total = 0, first = null, ways = 0;
  for (const cfg of cfgs) for (const kind of ks) for (const st of ts) {
    let prevWin = false;
    for (const ang of angles(angStep)) {
      total++;
      const ok = SIM.simulate(L, [...prior, { ang, step: st, idx: prior.length, kind }], cfg).won;
      if (ok) { wins++; if (!prevWin) ways++; if (!first) first = { ang: ang / D2R, t: st * DT, cfg: cfg.join(''), kind }; if (stopAtFirst) return { wins, total, first, ways }; }
      prevWin = ok;
    }
  }
  return { wins, total, first, ways };
}
function switchShots(L, cfg, i) {
  const res = [];
  for (const ang of angles(0.5)) {
    const run = SIM.newRun(L, [{ ang, step: 0, idx: 0, kind: 'n' }], cfg);
    while (!SIM.done(run) && run.step < 2600) SIM.step(run, null);
    const sw = L.switches[i];
    if (run.arrows.some(a => a.stuck === 's' && Math.hypot(a.x - sw.x, a.y - sw.y) < 22)) res.push(ang);
  }
  const groups = []; let g = [];
  for (const a of res) { if (g.length && a - g[g.length - 1] > 0.6 * D2R) { groups.push(g); g = []; } g.push(a); }
  if (g.length) groups.push(g);
  return groups.map(g => g[Math.floor(g.length / 2)]);
}

const only = process.argv.slice(2).map(Number);
SIM.LEVELS.forEach((L, li) => {
  const n = li + 1;
  if (only.length && !only.includes(n)) return;
  const t0 = Date.now(), mv = hasMoving(L), cfgs = configs(L), ks = kinds(L);
  let line = `${String(n).padStart(2)} ${L.name.padEnd(9)} par${L.par} 배치${cfgs.length} `;
  if (L.par === 1) {
    const ts = mv ? times(2.6, 0.1) : [0], st = mv ? 0.5 : 0.25;
    const r = oneShot(L, [], cfgs, ks, st, ts);
    let best = 0, bestCfg = '';
    for (const c of cfgs) for (const k of ks) { const q = oneShot(L, [], [c], [k], st, ts); if (q.wins / q.total > best) { best = q.wins / q.total; bestCfg = c.join('') + k; } }
    line += `최적배치[${bestCfg}] ${(best * 360 / ts.length).toFixed(1)}°폭 `;
    const plain = oneShot(L, [], [SIM.defaultMirrors(L)], ['n'], st, ts);
    line += r.first ? `✅ 성공률 ${(100 * r.wins / r.total).toFixed(2)}% 갈래 ${r.ways} (예: ${r.first.ang.toFixed(1)}° 거울[${r.first.cfg}] ${r.first.kind})` : '❌ 해 없음';
    if ((L.mirrors && L.mirrors.some(m => m.rot)) || L.skills) line += ` | 기본상태·스킬없이 ${plain.wins ? '⚠️ 풀림 ' + (100 * plain.wins / plain.total).toFixed(2) + '%' : '불가(장치 필수)'}`;
  } else {
    const one = oneShot(L, [], cfgs, ks, mv ? 0.5 : 0.2, mv ? times(1.8, 0.1) : [0], true);
    line += `1발 해 ${one.wins ? '⚠️ 있음' : '없음'} | `;
    let found = null;
    outer: for (const cfg of cfgs) {
      const nsw = (L.switches || []).length, cands = [];
      for (let i = 0; i < nsw; i++) cands.push(switchShots(L, cfg, i));
      if (L.par === 2) {
        for (const a1 of cands[0].slice(0, 5)) {
          const r = oneShot(L, [{ ang: a1, step: 0, idx: 0, kind: 'n' }], [cfg], ks, 0.5, times(3, 0.1), true);
          if (r.first) { found = `거울[${cfg.join('')}] 1발 ${(a1 / D2R).toFixed(1)}° → 2발 ${r.first.ang.toFixed(1)}° @${r.first.t.toFixed(2)}s ${r.first.kind}`; break outer; }
        }
      } else if (L.par === 3) {
        for (const a1 of cands[0].slice(0, 2)) for (const a2 of cands[1].slice(0, 2)) for (const t2 of times(1.0, 0.1)) {
          const prior = [{ ang: a1, step: 0, idx: 0, kind: 'n' }, { ang: a2, step: t2, idx: 1, kind: 'n' }];
          const r = oneShot(L, prior, [cfg], ks, 0.5, times(3, 0.1), true);
          if (r.first) { found = `1발 ${(a1 / D2R).toFixed(1)}°, 2발 ${(a2 / D2R).toFixed(1)}°@${(t2 * DT).toFixed(1)}s → 3발 ${r.first.ang.toFixed(1)}° @${r.first.t.toFixed(2)}s`; break outer; }
        }
      }
    }
    line += found ? `✅ ${found}` : '❌ par 해 없음';
  }
  console.log(line + `  [${((Date.now() - t0) / 1000).toFixed(1)}s]`);
});
