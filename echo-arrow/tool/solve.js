// 레벨 검증 솔버: node echo-arrow/tool/solve.js [레벨번호...]
// - par 발 수로 클리어 가능한지, par-1 발로는 불가능한지(메아리 레벨) 확인
// - 한 발 레벨은 성공 각도 비율(난이도 지표)을 출력
const SIM = require('../sim.js');
const { DT } = SIM;
const D2R = Math.PI / 180;

const hasMoving = L => L.targets.some(t => t.per);
const won = (L, shots) => SIM.simulate(L, shots).won;

function angles(stepDeg) { const out = []; for (let d = -180; d < 180; d += stepDeg) out.push(d * D2R); return out; }
function times(maxS, stepS) { const out = []; for (let s = 0; s <= maxS + 1e-9; s += stepS) out.push(Math.round(s / DT)); return out; }

function oneShot(L, prior, angStep, ts) {
  let wins = 0, total = 0, first = null;
  for (const st of ts) for (const ang of angles(angStep)) {
    total++;
    if (won(L, [...prior, { ang, step: st, idx: prior.length }])) { wins++; if (!first) first = { ang: ang / D2R, t: st * DT }; }
  }
  return { wins, total, first };
}

// 스위치를 맞히는 각도 대표값
function switchShots(L, i) {
  const res = [];
  for (const ang of angles(0.25)) {
    const run = SIM.newRun(L, [{ ang, step: 0, idx: 0 }]);
    while (!SIM.done(run) && run.step < 2400) SIM.step(run, null);
    const a = run.arrows[0];
    const sw = L.switches[i];
    if (a.stuck === 's' && Math.hypot(a.x - sw.x, a.y - sw.y) < 20) res.push(ang);
  }
  // 연속 구간의 가운데만
  const groups = []; let g = [];
  for (const a of res) { if (g.length && a - g[g.length - 1] > 0.3 * D2R) { groups.push(g); g = []; } g.push(a); }
  if (g.length) groups.push(g);
  return groups.map(g => g[Math.floor(g.length / 2)]);
}

const only = process.argv.slice(2).map(Number);
SIM.LEVELS.forEach((L, li) => {
  const n = li + 1;
  if (only.length && !only.includes(n)) return;
  const t0 = Date.now();
  const mv = hasMoving(L);
  let line = `${String(n).padStart(2)} ${L.name.padEnd(10)} par${L.par} `;
  if (L.par === 1) {
    const r = oneShot(L, [], mv ? 0.5 : 0.1, mv ? times(2.6, 0.05) : [0]);
    line += `1발 성공률 ${(100 * r.wins / r.total).toFixed(2)}% ${r.first ? `(예: ${r.first.ang.toFixed(1)}°, ${r.first.t.toFixed(2)}s)` : '❌ 해 없음'}`;
  } else {
    const one = oneShot(L, [], mv ? 0.5 : 0.1, mv ? times(1.8, 0.1) : [0]);
    line += `1발 해 ${one.wins ? '⚠️ 있음 ' + one.wins : '없음'} | `;
    const nsw = (L.switches || []).length;
    const cands = [];
    for (let i = 0; i < nsw; i++) cands.push(switchShots(L, i));
    line += `스위치 각도 후보 ${cands.map(c => c.length).join('/')} | `;
    let found = null, wins = 0, total = 0;
    if (L.par === 2) {
      for (const a1 of cands[0].slice(0, 4)) {
        const r = oneShot(L, [{ ang: a1, step: 0, idx: 0 }], 0.5, times(3, 0.05));
        wins += r.wins; total += r.total;
        if (r.first && !found) found = `1발 ${(a1 / D2R).toFixed(1)}° → 2발 ${r.first.ang.toFixed(1)}° @${r.first.t.toFixed(2)}s`;
      }
    } else if (L.par === 3) {
      outer: for (const a1 of cands[0].slice(0, 2)) for (const a2 of cands[1].slice(0, 2)) for (const t2 of times(1.0, 0.1)) {
        const prior = [{ ang: a1, step: 0, idx: 0 }, { ang: a2, step: t2, idx: 1 }];
        const r = oneShot(L, prior, 0.5, times(3, 0.1));
        wins += r.wins; total += r.total;
        if (r.first) { found = `1발 ${(a1 / D2R).toFixed(1)}°, 2발 ${(a2 / D2R).toFixed(1)}°@${(t2 * DT).toFixed(1)}s → 3발 ${r.first.ang.toFixed(1)}° @${r.first.t.toFixed(2)}s`; break outer; }
      }
    }
    line += found ? `✅ ${found} (성공 조합 ${(100 * wins / Math.max(1, total)).toFixed(2)}%)` : '❌ par 해 없음';
  }
  console.log(line + `  [${((Date.now() - t0) / 1000).toFixed(1)}s]`);
});
