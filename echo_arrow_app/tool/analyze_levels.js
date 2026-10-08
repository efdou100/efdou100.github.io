// 플레이테스트 시뮬레이션: 레벨이 "실력으로 깨지는지, 운으로 깨지는지", 사람이 맞힐 수 있는 폭인지 측정
//   node tool/analyze_levels.js [levels.json 경로] > report.json
// 측정 항목 (한 발 판 기준):
//   window   가장 넓은 성공 구간(°)  → 사람 손 오차를 견딜 수 있는가
//   ways     성공 구간 개수          → 풀이 갈래(다양성)
//   minB     정답 화살의 최소 튕김 수 → 계획해서 풀 수 있는 길이인가
//   luck     성공 각도 중 '4번 이상 튕겨야 맞는' 비율 → 높으면 운빨 판
//   p1       조준 오차 σ 일 때 한 번에 성공할 확률 (가장 넓은 구간 가운데를 노린다고 가정)
const fs = require('fs');
const path = require('path');
const SIM = require('../../echo-arrow/sim.js');
const { D2R } = SIM;

const file = process.argv[2] || path.join(__dirname, '..', 'assets', 'levels', 'levels.json');
const levels = JSON.parse(fs.readFileSync(file, 'utf8')).levels;
const SIGMA = [1.2, 2.0];

function erf(x) { const t = 1 / (1 + 0.3275911 * Math.abs(x)); const y = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * Math.exp(-x * x); return x >= 0 ? y : -y; }
const pHit = (w, s) => erf(w / (2 * Math.SQRT2 * s));

function configs(L) {
  let out = [(L.mirrors || []).map(m => m.s)];
  (L.mirrors || []).forEach((m, i) => { if (!m.rot) return; const n = []; for (const c of out) for (let s = 0; s < 4; s++) { const x = c.slice(); x[i] = s; n.push(x); } out = n; });
  return out;
}

function runOne(L, ang, cfg, kind, step = 0) {
  const run = SIM.newRun(L, [{ ang, step, idx: 0, kind }], cfg);
  let maxB = 0;
  const ev = [];
  while (run.step < 2600) {
    ev.length = 0;
    SIM.step(run, ev);
    for (const e of ev) if (e.type === 'hit') maxB = Math.max(maxB, e.b);
    if (run.won || SIM.done(run)) break;
  }
  return { won: run.won, maxB };
}

const rows = [];
for (const L0 of levels) {
  const L = JSON.parse(JSON.stringify(L0));
  if (L.par !== 1) { rows.push({ id: L.id, w: L.w, name: L.name, par: L.par, echo: true, tier: L.tier }); continue; }
  const moving = L.targets.some(t => t.per);
  const steps = moving ? [0, 60, 120, 180, 240, 300, 360, 420, 480, 540] : [0];
  const st = moving ? 0.5 : 0.25;
  let best = { w: 0 }, ways = 0, wins = 0, lucky = 0, minB = 99;
  for (const cfg of configs(L)) for (const kind of ['n', ...Object.keys(L.skills || {})]) for (const step of steps) {
    let run0 = null;
    for (let d = -180; d <= 180; d += st) {
      const r = d < 180 ? runOne(L, d * D2R, cfg, kind, step) : { won: false };
      if (r.won) { wins++; if (r.maxB >= 4) lucky++; minB = Math.min(minB, r.maxB); if (run0 === null) run0 = d; }
      else if (run0 !== null) { ways++; const w = d - run0; if (w > best.w) best = { w }; run0 = null; }
    }
  }
  rows.push({ id: L.id, w: L.w, name: L.name, par: 1, tier: L.tier, window: +best.w.toFixed(2), ways, minB, luck: +(lucky / Math.max(1, wins)).toFixed(2), p1: SIGMA.map(s => +pHit(best.w, s).toFixed(2)) });
}

// 월드 요약
const summary = {};
for (let w = 1; w <= 5; w++) {
  const r = rows.filter(x => x.w === w && x.par === 1);
  if (!r.length) continue;
  const avg = k => +(r.reduce((a, x) => a + (Array.isArray(x[k]) ? x[k][0] : x[k]), 0) / r.length).toFixed(2);
  summary[w] = {
    oneShotLevels: r.length,
    echoLevels: rows.filter(x => x.w === w && x.echo).length,
    avgWindow: avg('window'),
    under2deg: r.filter(x => x.window < 2).length,
    avgLuck: avg('luck'),
    luckyLevels: r.filter(x => x.luck >= 0.5).length,
    avgP1_sigma1_2: avg('p1'),
    minBounceAvg: avg('minB'),
  };
}
console.log(JSON.stringify({ summary, rows }, null, 1));
