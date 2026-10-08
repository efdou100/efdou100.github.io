// 레벨 생성·검증·배치 → assets/levels/levels.json
//   node tool/gen_levels.js            (전체 생성, 수 분 걸림)
// - 커리큘럼(CURRICULUM)대로 100판을 채운다: 새 요소는 소개 판(손으로 만듦) → 그 요소만 쓰는 연습 판 2~3개 → 아는 것끼리 섞기
// - 생성 판은 솔버로 검증하고, '꼭 써야 하는 장치'는 빼면 못 깨는지까지 확인한다
// - 각 판에 정답(힌트용), 성공 각도 폭(난이도), 풀이 갈래 수를 기록
const fs = require('fs');
const path = require('path');
const SIM = require('../../echo-arrow/sim.js');
const { DT, D2R, F } = SIM;

// ---------- 시드 난수 ----------
let seed = 20261008;
const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
const ri = (a, b) => Math.floor(a + rnd() * (b - a + 1));
const pick = arr => arr[Math.floor(rnd() * arr.length)];

// ---------- 솔버 ----------
function configs(L) {
  let out = [SIM.defaultMirrors(L)];
  (L.mirrors || []).forEach((m, i) => {
    if (!m.rot) return;
    const next = [];
    for (const c of out) for (let s = 0; s < (m.relay ? 8 : 4); s++) { const n = c.slice(); n[i] = s; next.push(n); }
    out = next;
  });
  return out;
}
const kinds = L => ['n', ...Object.keys(L.skills || {})];
const spinner = L => (L.mirrors || []).some(m => m.spin);
const moving = L => L.targets.some(t => t.per) || spinner(L);
// 시간에 따라 달라지는 판은 발사 시점도 훑는다. 째깍 거울은 한 바퀴(4칸) 동안 칸마다 두 번씩.
function stepsFor(L) {
  if (spinner(L)) {
    const per = Math.min(...L.mirrors.filter(m => m.spin).map(m => Math.round(m.spin / DT)));
    return Array.from({ length: 8 }, (_, k) => Math.round(per / 4 + (k * per) / 2));
  }
  return L.targets.some(t => t.per) ? [0, 48, 96, 144, 192, 240, 288, 336, 384, 432, 480, 528] : [0];
}

// 한 발 분석 (공정성 기준): 정답 화살이 maxB 번 이하로 튕겨서 맞히는 각도만 '공정한 성공'으로 친다.
// 조준선은 반사 2번까지 보이므로, 플레이어가 눈으로 계획해서 풀 수 있는 판만 남긴다.
function runOne(L, ang, cfg, kind, step) {
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
function analyzeOne(L, fairB = 3, stepDeg = 0.25) {
  const ts = stepsFor(L);
  const st = moving(L) ? 0.5 : stepDeg;
  let best = null, ways = 0, fairWays = 0, minB = 99;
  for (const cfg of configs(L)) for (const kind of kinds(L)) for (const step of ts) {
    let run0 = null, runAny = false;
    for (let d = -180; d < 180 + st; d += st) {
      const r = d < 180 ? runOne(L, d * D2R, cfg, kind, step) : { won: false, maxB: 99 };
      if (r.won) minB = Math.min(minB, r.maxB);
      if (r.won && !runAny) { ways++; runAny = true; } else if (!r.won) runAny = false;
      const fair = r.won && r.maxB <= fairB;
      if (fair) { if (run0 === null) run0 = d; }
      else if (run0 !== null) {
        fairWays++;
        const w = d - run0;
        if (!best || w > best.w) best = { w, ang: run0 + (w - st) / 2, step, kind, cfg: cfg.slice() };
        run0 = null;
      }
    }
  }
  if (!best) return null;
  if (!SIM.simulate(L, [{ ang: best.ang * D2R, step: best.step, idx: 0, kind: best.kind }], best.cfg).won) best.ang = best.ang - best.w / 2 + st / 2;
  return { width: +best.w.toFixed(2), ways, fairWays, minB, solution: { mirrors: best.cfg, shots: [{ ang: +best.ang.toFixed(3), step: best.step, kind: best.kind }] } };
}
function hasOneShot(L) {
  for (const cfg of configs(L)) for (const kind of kinds(L)) for (const step of stepsFor(L))
    for (let d = -180; d < 180; d += 0.25) if (SIM.simulate(L, [{ ang: d * D2R, step, idx: 0, kind }], cfg).won) return true;
  return false;
}
function switchAngles(L, cfg) {
  const res = [];
  for (let d = -180; d < 180; d += 0.5) {
    const run = SIM.newRun(L, [{ ang: d * D2R, step: 0, idx: 0, kind: 'n' }], cfg);
    while (!SIM.done(run) && run.step < 2600) SIM.step(run, null);
    if (!run.failed && (run.arrows.some(a => a.stuck === 's') || run.crys.some(Boolean))) res.push(d);
  }
  const groups = []; let g = [];
  for (const a of res) { if (g.length && a - g[g.length - 1] > 0.6) { groups.push(g); g = []; } g.push(a); }
  if (g.length) groups.push(g);
  return groups.map(g => g[Math.floor(g.length / 2)]);
}
// 두 발(메아리) 분석
function analyzeTwo(L) {
  let total = 0, wins = 0, found = null;
  for (const cfg of configs(L)) {
    for (const a1 of switchAngles(L, cfg).slice(0, 4)) {
      for (let s = 0; s <= 3; s += 0.1) {
        const step = Math.round(s / DT);
        for (let d = -180; d < 180; d += 0.5) {
          total++;
          for (const kind of kinds(L)) {
            if (SIM.simulate(L, [{ ang: a1 * D2R, step: 0, idx: 0, kind: 'n' }, { ang: d * D2R, step, idx: 1, kind }], cfg).won) {
              wins++;
              if (!found) found = { mirrors: cfg.slice(), shots: [{ ang: a1, step: 0, kind: 'n' }, { ang: +d.toFixed(3), step, kind }] };
              break;
            }
          }
        }
      }
      if (found && total > 30000) break;
    }
    if (found) break;
  }
  return found ? { width: +((wins / Math.max(1, total)) * 360).toFixed(2), ways: 1, solution: found } : null;
}
function analyzeThree(L) {
  for (const cfg of configs(L)) {
    const c0 = switchAnglesFor(L, cfg, 0), c1 = switchAnglesFor(L, cfg, 1);
    for (const a1 of c0.slice(0, 2)) for (const a2 of c1.slice(0, 2)) for (let s2 = 0; s2 <= 1; s2 += 0.1) {
      const st2 = Math.round(s2 / DT);
      for (let s = 0; s <= 3; s += 0.1) for (let d = -180; d < 180; d += 0.5) {
        const shots = [{ ang: a1 * D2R, step: 0, idx: 0, kind: 'n' }, { ang: a2 * D2R, step: st2, idx: 1, kind: 'n' }, { ang: d * D2R, step: Math.round(s / DT), idx: 2, kind: 'n' }];
        if (SIM.simulate(L, shots, cfg).won) return { width: 1, ways: 1, solution: { mirrors: cfg.slice(), shots: shots.map(x => ({ ang: +(x.ang / D2R).toFixed(3), step: x.step, kind: x.kind })) } };
      }
    }
  }
  return null;
}
function switchAnglesFor(L, cfg, idx) {
  const res = [];
  for (let d = -180; d < 180; d += 0.5) {
    const run = SIM.newRun(L, [{ ang: d * D2R, step: 0, idx: 0, kind: 'n' }], cfg);
    while (!SIM.done(run) && run.step < 2600) SIM.step(run, null);
    const sw = L.switches[idx];
    if (run.arrows.some(a => a.stuck === 's' && Math.hypot(a.x - sw.x, a.y - sw.y) < 22)) res.push(d);
  }
  const groups = []; let g = [];
  for (const a of res) { if (g.length && a - g[g.length - 1] > 0.6) { groups.push(g); g = []; } g.push(a); }
  if (g.length) groups.push(g);
  return groups.map(g => g[Math.floor(g.length / 2)]);
}
function analyze(L) {
  // 손으로 만든 판은 의도된 긴 튕김 풀이일 수 있으니, 공정 풀이가 없으면 제한 없이 다시 찾는다
  if (L.par === 1) return analyzeOne(L, FAIR_B[L.w] || 3) || analyzeOne(L, 99);
  if (L.par === 2) return analyzeTwo(L);
  return analyzeThree(L);
}

// ---------- 절차 생성 ----------
const BOW = [180, 590];
function overlaps(rects, r, pad = 14) {
  return rects.some(o => r[0] < o[0] + o[2] + pad && r[0] + r[2] + pad > o[0] && r[1] < o[1] + o[3] + pad && r[1] + r[3] + pad > o[1]);
}
const pointRect = (x, y, s = 20) => [x - s, y - s, s * 2, s * 2];

function genLevel(world, opts) {
  const L = { w: world, name: '', shots: 3, par: 1, guide: 1, bow: BOW.slice(), targets: [], blocks: [], walls: [], gen: true };
  const taken = [pointRect(BOW[0], BOW[1], 40)];
  const free = (x, y, s) => !overlaps(taken, pointRect(x, y, s), 4);
  const place = (s, yMin = 110, yMax = 470) => { for (let k = 0; k < 60; k++) { const x = ri(40, 320), y = ri(yMin, yMax); if (free(x, y, s)) { taken.push(pointRect(x, y, s)); return [x, y]; } } return null; };
  // 장애물 블록
  const nb = ri(opts.blocks[0], opts.blocks[1]);
  for (let i = 0; i < nb; i++) {
    for (let k = 0; k < 40; k++) {
      const horiz = rnd() < 0.7, w = horiz ? ri(60, 170) : ri(20, 28), h = horiz ? ri(20, 28) : ri(60, 150);
      const x = ri(F.x0, F.x1 - w), y = ri(150, 460);
      const r = [x, y, w, h];
      if (!overlaps(taken, r, 18)) { taken.push(r); L.blocks.push([x, y, w, h, rnd() < opts.moss ? 'm' : 'w']); break; }
    }
  }
  if (opts.edgesMoss && rnd() < opts.edgesMoss) {
    const side = pick(['left', 'right', 'top']);
    L.edges = { [side]: side === 'top' ? [[F.x0, F.x1, 'm']] : [[F.y0, ri(250, 420), 'w'], [0, 0, 'm']] };
    if (side !== 'top') { const cut = L.edges[side][0][1]; L.edges[side][1] = [cut, F.y1, 'm']; }
  }
  // 장치
  const dev = opts.devices || {};
  if (dev.mirror && rnd() < dev.mirror) { L.mirrors = []; const n = ri(1, dev.mirrorMax || 1); for (let i = 0; i < n; i++) { const p = place(36, 200, 500); if (p) L.mirrors.push({ x: p[0], y: p[1], s: ri(0, 3), rot: true, len: 60 }); } }
  if (dev.bumper && rnd() < dev.bumper) { L.bumpers = []; const p = place(30, 200, 480); if (p) L.bumpers.push({ x: p[0], y: p[1], r: ri(22, 30) }); }
  if (dev.ice && rnd() < dev.ice) { for (let k = 0; k < 20; k++) { const w = ri(40, 90), h = 12, x = ri(30, 290), y = ri(170, 420); if (!overlaps(taken, [x, y, w, h], 16)) { taken.push([x, y, w, h]); L.blocks.push([x, y, w, h, 'i']); break; } } }
  if (dev.portal && rnd() < dev.portal) { const a = place(22, 330, 500), b = place(22, 110, 260); if (a && b) L.portals = [{ a, b }]; }
  if (dev.prism && rnd() < dev.prism) { const p = place(20, 280, 480); if (p) L.prisms = [p.length ? { x: p[0], y: p[1] } : null].filter(Boolean); }
  // 정령
  const nt = ri(opts.targets[0], opts.targets[1]);
  for (let i = 0; i < nt; i++) {
    const p = place(24, 110, 420); if (!p) continue;
    const t = { x: p[0], y: p[1], mx: 0, my: 0, per: 0 };
    if (opts.shield && rnd() < opts.shield) t.shield = pick([90, 0, 180, -90, 45, 135]);
    if (opts.moving && rnd() < opts.moving && i === 0) { t.mx = ri(30, 70); t.per = +(1.8 + rnd() * 1.4).toFixed(1); t.x = Math.min(Math.max(t.x, 40 + t.mx), 320 - t.mx); }
    L.targets.push(t);
  }
  if (opts.avoid && rnd() < opts.avoid) { const n = ri(1, 2); for (let i = 0; i < n; i++) { const p = place(22, 150, 480); if (p) L.targets.push({ x: p[0], y: p[1], mx: 0, my: 0, per: 0, avoid: true }); } }
  if (opts.skill && rnd() < opts.skill) L.skills = { [pick(['split', 'pierce'])]: 1 };
  if (!L.targets.some(t => !t.avoid)) return null;
  return L;
}

// 메아리 판 템플릿: 문 달린 방 + 스위치 + 장애물
function genEcho(world, opts) {
  const side = pick(['left', 'center', 'right']);
  const x0 = side === 'left' ? F.x0 : side === 'center' ? 120 : 228, x1 = side === 'left' ? 132 : side === 'center' ? 240 : F.x1;
  const gy = ri(190, 240), dur = +(opts.durMin + rnd() * (opts.durMax - opts.durMin)).toFixed(1);
  const L = { w: world, name: '', shots: 4, par: 2, guide: 1, bow: BOW.slice(), blocks: [], walls: [], gen: true, targets: [], switches: [] };
  if (side !== 'left') L.walls.push([x0, F.y0, x0, gy, 'w']);
  if (side !== 'right') L.walls.push([x1, F.y0, x1, gy, 'w']);
  L.gates = [{ x1: x0, y1: gy, x2: x1, y2: gy, dur }];
  L.targets.push({ x: Math.round((x0 + x1) / 2), y: ri(120, gy - 50), mx: 0, my: 0, per: 0 });
  const taken = [[x0, F.y0, x1 - x0, gy - F.y0 + 30], pointRect(BOW[0], BOW[1], 40)];
  const place = (s, yMin, yMax) => { for (let k = 0; k < 80; k++) { const x = ri(36, 324), y = ri(yMin, yMax); if (!overlaps(taken, pointRect(x, y, s), 4)) { taken.push(pointRect(x, y, s)); return [x, y]; } } return null; };
  const sw = place(26, 110, 520); if (!sw) return null;
  L.switches.push({ x: sw[0], y: sw[1], g: [0] });
  const nb = ri(1, 3);
  for (let i = 0; i < nb; i++) for (let k = 0; k < 40; k++) {
    const w = ri(60, 140), h = ri(20, 26), x = ri(F.x0, F.x1 - w), y = ri(gy + 60, 480);
    if (!overlaps(taken, [x, y, w, h], 18)) { taken.push([x, y, w, h]); L.blocks.push([x, y, w, h, rnd() < 0.6 ? 'm' : 'w']); break; }
  }
  if (opts.avoid && rnd() < opts.avoid) { const p = place(22, gy + 40, 500); if (p) L.targets.push({ x: p[0], y: p[1], mx: 0, my: 0, per: 0, avoid: true }); }
  if (opts.mirror && rnd() < opts.mirror) { const p = place(36, gy + 60, 500); if (p) L.mirrors = [{ x: p[0], y: p[1], s: ri(0, 3), rot: true, len: 60 }]; }
  if (opts.shield && rnd() < opts.shield) L.targets[0].shield = 90;
  return L;
}

// ---------- 커리큘럼 생성 ----------
// 특징(feature): bumper moving lantern mirror mirror2 shield baby spinner ice portal prism split pierce relay mossEdge
// need: 반드시 들어가는 요소, allow: 이미 배운 것 중 섞어도 되는 요소(최대 extra 개)
function genCur(world, spec) {
  const L = { w: world, name: '', shots: 3, par: 1, guide: 1, bow: BOW.slice(), targets: [], blocks: [], walls: [], gen: true };
  const taken = [pointRect(BOW[0], BOW[1], 40)];
  const free = (x, y, sz) => !overlaps(taken, pointRect(x, y, sz), 4);
  const place = (sz, yMin = 110, yMax = 470, xMin = 40, xMax = 320) => { for (let k = 0; k < 80; k++) { const x = ri(xMin, xMax), y = ri(yMin, yMax); if (free(x, y, sz)) { taken.push(pointRect(x, y, sz)); return [x, y]; } } return null; };
  const feats = new Set(spec.need || []);
  const extra = (spec.allow || []).filter(f => !feats.has(f));
  const nExtra = Math.min(spec.extra ?? 1, extra.length);
  for (let k = 0; k < nExtra; k++) if (rnd() < (spec.extraP ?? 0.5)) feats.add(extra.splice(Math.floor(rnd() * extra.length), 1)[0]);
  const has = f => feats.has(f);
  // 장치 먼저 (정령보다 아래쪽에 놓이기 쉽게)
  if (has('lantern')) {
    L.lanterns = [];
    const p = place(18, 170, 360); if (!p) return null;
    L.lanterns.push({ x: p[0], y: p[1] });
    // 정령은 모두 등불 둘레에 (화살은 등불에서 멈추므로, 폭발로 깨우는 판이 되게)
    const n = Math.min(3, ri(...(spec.targets || [2, 3])));
    for (let i = 0; i < n; i++) for (let k = 0; k < 40; k++) {
      const a = rnd() * Math.PI * 2, d = ri(38, 64), x = Math.round(p[0] + Math.cos(a) * d), y = Math.round(p[1] + Math.sin(a) * d);
      if (x < 36 || x > 324 || y < 110 || y > 470 || !free(x, y, 16)) continue;
      taken.push(pointRect(x, y, 16)); L.targets.push({ x, y, mx: 0, my: 0, per: 0 }); break;
    }
    if (rnd() < 0.35) { const q = place(18, 150, 420); if (q && Math.hypot(q[0] - p[0], q[1] - p[1]) < 74) L.lanterns.push({ x: q[0], y: q[1] }); }
    if (L.targets.length < 2) return null;
  }
  const mirrors = [];
  if (has('mirror') || has('mirror2')) { const n = has('mirror2') ? 2 : 1; for (let i = 0; i < n; i++) { const p = place(36, 200, 500); if (p) mirrors.push({ x: p[0], y: p[1], s: ri(0, 3), rot: true, len: 60 }); } }
  if (has('spinner')) { const p = place(38, 230, 470); if (p) mirrors.push({ x: p[0], y: p[1], s: ri(0, 3), rot: false, len: 64, spin: pick([1.0, 1.2, 1.4]) }); }
  if (has('relay')) { const p = place(26, 260, 500); if (p) mirrors.push({ x: p[0], y: p[1], s: ri(0, 7), rot: true, relay: true, len: 0 }); }
  if (mirrors.length) L.mirrors = mirrors;
  if (has('bumper')) { const p = place(30, 200, 480); if (p) L.bumpers = [{ x: p[0], y: p[1], r: ri(22, 30) }]; }
  if (has('portal')) { const a = place(22, 330, 500), b = place(22, 110, 260); if (a && b) L.portals = [{ a, b }]; }
  if (has('prism')) { const p = place(20, 280, 480); if (p) L.prisms = [{ x: p[0], y: p[1] }]; }
  // 장애물
  const nb = ri(...(spec.blocks || [1, 3]));
  for (let i = 0; i < nb; i++) for (let k = 0; k < 40; k++) {
    const horiz = rnd() < 0.7, w = horiz ? ri(60, 160) : ri(20, 28), h = horiz ? ri(20, 28) : ri(60, 140);
    const x = ri(F.x0, F.x1 - w), y = ri(150, 460), r = [x, y, w, h];
    if (!overlaps(taken, r, 18)) { taken.push(r); L.blocks.push([x, y, w, h, rnd() < 0.6 ? 'm' : 'w']); break; }
  }
  if (has('ice')) { for (let k = 0; k < 30; k++) { const w = ri(40, 90), h = 12, x = ri(30, 290), y = ri(170, 420); if (!overlaps(taken, [x, y, w, h], 16)) { taken.push([x, y, w, h]); L.blocks.push([x, y, w, h, 'i']); break; } } }
  // 꼭 써야 하는 장치가 있으면 벽 튕김으로 우회하지 못하게 테두리를 이끼로 (거울류는 2~3면, 범퍼·포털은 1~2면)
  const needs = spec.need || [];
  const mirrorish = ['mirror', 'mirror2', 'spinner', 'relay'].some(f => needs.includes(f));
  const bouncy = ['bumper', 'portal', 'prism'].some(f => needs.includes(f));
  if (mirrorish || bouncy) {
    const sides = ['top', 'left', 'right'].sort(() => rnd() - 0.5).slice(0, mirrorish ? (rnd() < 0.6 ? 3 : 2) : (rnd() < 0.5 ? 2 : 1));
    L.edges = Object.fromEntries(sides.map(sd => [sd, [[sd === 'top' ? F.x0 : F.y0, sd === 'top' ? F.x1 : F.y1, 'm']]]));
  } else if (has('mossEdge') || ((has('mirror') || has('mirror2') || has('spinner') || has('relay')) && rnd() < 0.45)) {
    const side = pick(['left', 'right', 'top']);
    L.edges = { [side]: side === 'top' ? [[F.x0, F.x1, 'm']] : [[F.y0, ri(250, 420), 'w'], [0, 0, 'm']] };
    if (side !== 'top') { const cut = L.edges[side][0][1]; L.edges[side][1] = [cut, F.y1, 'm']; }
  }
  // 꼭 써야 하는 거울·고리·포털이 있으면, 첫 정령을 '그 장치를 거친 길' 위에 놓는다 (계획한 풀이가 반드시 존재)
  const guide = needs.find(f => ['mirror', 'mirror2', 'spinner', 'relay', 'portal', 'bumper'].includes(f));
  if (guide) {
    let dev = null, outs = [];
    const dirTo = (x, y) => { const dx = x - BOW[0], dy = y - BOW[1], d = Math.hypot(dx, dy); return [dx / d, dy / d]; };
    if (guide === 'bumper' && L.bumpers) {
      const u = L.bumpers[0], bx = BOW[0] - u.x, by = BOW[1] - u.y, bl = Math.hypot(bx, by);
      outs = Array.from({ length: 8 }, () => {
        const phi = Math.atan2(by / bl, bx / bl) + (rnd() < 0.5 ? -1 : 1) * (15 + rnd() * 45) * D2R, nx = Math.cos(phi), ny = Math.sin(phi);
        const px = u.x + nx * u.r, py = u.y + ny * u.r, d = dirTo(px, py), dn = d[0] * nx + d[1] * ny;
        return [px, py, d[0] - 2 * dn * nx, d[1] - 2 * dn * ny];
      });
    } else if (guide === 'portal' && L.portals) {
      const [ax, ay] = L.portals[0].a, [bx, by] = L.portals[0].b, d = dirTo(ax, ay);
      outs = [[bx, by, d[0], d[1]]];
    } else if (guide === 'relay') {
      dev = mirrors.find(m => m.relay);
      if (dev) outs = Array.from({ length: 8 }, (_, k) => [dev.x, dev.y, Math.cos(k * 45 * D2R), Math.sin(k * 45 * D2R)]);
    } else {
      dev = mirrors.find(m => (guide === 'spinner' ? m.spin : !m.relay && !m.spin));
      if (dev) {
        const d = dirTo(dev.x, dev.y);
        outs = Array.from({ length: 4 }, (_, k) => {
          const ux = Math.cos(k * 45 * D2R), uy = Math.sin(k * 45 * D2R), nx = -uy, ny = ux, dn = d[0] * nx + d[1] * ny;
          return [dev.x, dev.y, d[0] - 2 * dn * nx, d[1] - 2 * dn * ny];
        });
      }
    }
    outs.sort(() => rnd() - 0.5);
    let placed = false;
    for (const [ox, oy, vx, vy] of outs) {
      for (let k = 0; k < 6 && !placed; k++) {
        const dist = ri(90, 230), x = Math.round(ox + vx * dist), y = Math.round(oy + vy * dist);
        if (x < 40 || x > 320 || y < 110 || y > 440 || !free(x, y, 22)) continue;
        taken.push(pointRect(x, y, 22)); L.targets.push({ x, y, mx: 0, my: 0, per: 0 }); placed = true;
      }
      if (placed) break;
    }
    if (!placed) return null;
  }
  // 정령
  const [t0, t1] = spec.targets || [1, 2];
  const nt = has('lantern') ? 0 : Math.max(0, ri(t0, t1) - L.targets.length);
  for (let i = 0; i < nt; i++) { const p = place(24, 110, 420); if (p) L.targets.push({ x: p[0], y: p[1], mx: 0, my: 0, per: 0 }); }
  if (!L.targets.length) return null;
  // 거울·고리·포털을 꼭 써야 하는 판: 활과 첫 정령 사이에 이끼 가림막을 세워 직선 길을 막는다
  if (['mirror', 'mirror2', 'spinner', 'relay', 'portal', 'lantern', 'bumper'].some(f => (spec.need || []).includes(f)) || (spec.needOne && rnd() < 0.6)) {
    const t = L.targets[0], dx = t.x - BOW[0], dy = t.y - BOW[1], d = Math.hypot(dx, dy), k = 0.5 + rnd() * 0.25;
    const cx = BOW[0] + dx * k, cy = BOW[1] + dy * k, ux = -dy / d, uy = dx / d, half = ri(30, 55);
    L.walls.push([Math.round(cx - ux * half), Math.round(cy - uy * half), Math.round(cx + ux * half), Math.round(cy + uy * half), 'm']);
  }
  if (has('shield')) { const t = pick(L.targets); t.shield = pick([90, 0, 180, -90, 45, 135]); }
  if (has('moving')) { const t = L.targets[L.targets.length - 1]; t.mx = ri(30, 70); t.per = +(1.8 + rnd() * 1.4).toFixed(1); t.x = Math.min(Math.max(t.x, 40 + t.mx), 320 - t.mx); }
  if (has('baby')) { const n = ri(1, 2); for (let i = 0; i < n; i++) { const p = place(22, 150, 480); if (p) L.targets.push({ x: p[0], y: p[1], mx: 0, my: 0, per: 0, avoid: true }); } }
  if (has('split')) L.skills = { split: 1 };
  else if (has('pierce')) L.skills = { pierce: 1 };
  L._feats = [...feats];
  return L;
}

// 유리 마개 메아리 판: 정령은 이끼 벽 주머니 안, 입구는 유리 마개. 마개는 한쪽 옆면으로만 깨진다.
// 1발(메아리)이 옆에서 깨고, 2발이 그 '다음에' 들어가야 한다 → 발사 시점을 재는 퍼즐
function genCrystal(world, opts = {}) {
  const w = ri(84, 110), x0 = ri(60, 300 - w), x1 = x0 + w, gy = ri(190, 250), h = ri(24, 34);
  const L = { w: world, name: '', shots: 4, par: 2, guide: 1, bow: BOW.slice(), blocks: [], walls: [[x0, F.y0, x0, gy, 'm'], [x1, F.y0, x1, gy, 'm']], gen: true, targets: [],
    crystals: [{ x: x0, y: gy, w: x1 - x0, h, soft: pick(['l', 'r']) }] };
  L.targets.push({ x: Math.round((x0 + x1) / 2), y: ri(120, gy - 40), mx: 0, my: 0, per: 0 });
  const taken = [[x0 - 20, F.y0, x1 - x0 + 40, gy + h - F.y0 + 30], pointRect(BOW[0], BOW[1], 40)];
  const place = (sz, yMin, yMax) => { for (let k = 0; k < 80; k++) { const x = ri(36, 324), y = ri(yMin, yMax); if (!overlaps(taken, pointRect(x, y, sz), 4)) { taken.push(pointRect(x, y, sz)); return [x, y]; } } return null; };
  const nb = ri(0, 2);
  for (let i = 0; i < nb; i++) for (let k = 0; k < 40; k++) {
    const bw = ri(50, 120), bh = ri(20, 26), x = ri(F.x0, F.x1 - bw), y = ri(gy + h + 70, 480);
    if (!overlaps(taken, [x, y, bw, bh], 18)) { taken.push([x, y, bw, bh]); L.blocks.push([x, y, bw, bh, rnd() < 0.6 ? 'm' : 'w']); break; }
  }
  if (opts.avoid && rnd() < opts.avoid) { const p = place(22, gy + h + 40, 500); if (p) L.targets.push({ x: p[0], y: p[1], mx: 0, my: 0, per: 0, avoid: true }); }
  if (opts.mirror && rnd() < opts.mirror) { const p = place(36, gy + h + 60, 500); if (p) L.mirrors = [{ x: p[0], y: p[1], s: ri(0, 3), rot: true, len: 60 }]; }
  return L;
}

// 꼭 필요한 장치를 빼 본다: 빼도 한 발에 깨지면 그 장치는 '장식'이라 탈락
const NEEDABLE = {
  bumper: L => { delete L.bumpers; },
  lantern: L => { delete L.lanterns; },
  mirror: L => { L.mirrors = (L.mirrors || []).filter(m => m.relay || m.spin); },
  mirror2: L => { L.mirrors = (L.mirrors || []).filter(m => m.relay || m.spin); },
  spinner: L => { L.mirrors = (L.mirrors || []).filter(m => !m.spin); },
  relay: L => { L.mirrors = (L.mirrors || []).filter(m => !m.relay); },
  portal: L => { delete L.portals; },
  prism: L => { delete L.prisms; },
  split: L => { delete L.skills; },
  pierce: L => { delete L.skills; },
};
// 기준은 '계획해서 풀 수 있는 길'(튕김 fairB 번 이하)이 장치 없이는 없을 것. 운 좋은 긴 튕김은 셈하지 않는다.
function needed(L, f, fairB = 3) {
  if (!NEEDABLE[f]) return true;
  const c = JSON.parse(JSON.stringify(L));
  NEEDABLE[f](c);
  const a = analyzeOne(c, fairB, 0.5);
  return !a || a.width < 1;
}

// 슬롯 표기: { h: '손 레벨 이름' } | { need, allow, extra, targets, blocks, w: [폭 하한, 상한] } | { echo: 'gate'|'crystal', ...opts }
const P = (need, o = {}) => ({ need, ...o });
const CURRICULUM = {
  1: [
    { h: '첫 발' }, { h: '벽 튕기기' }, P([], { targets: [1, 1], blocks: [1, 2], w: [6, 40] }), { h: '꿰뚫기' }, P([], { targets: [2, 2], w: [4, 30] }),
    { h: '두 번 튕기기' }, P([], { targets: [1, 2], blocks: [2, 3], w: [3.5, 25] }), { h: '버섯 범퍼' }, P([], { allow: ['bumper'], extraP: 1, w: [3, 30] }), P([], { allow: ['bumper'], extraP: 1, targets: [2, 3], w: [2, 14] }),
    { h: '흔들리는 정령' }, P(['moving'], { w: [3, 30] }), P(['moving'], { allow: ['bumper'], extraP: 1, targets: [2, 2] }), { h: '세 정령' }, { h: '등불' },
    P(['lantern'], { targets: [2, 3], w: [4, 40] }), { h: '연쇄 등불' }, P(['lantern'], { allow: ['bumper', 'moving'], targets: [2, 3] }),
    P([], { allow: ['bumper', 'moving', 'lantern'], extra: 2, extraP: 1, targets: [2, 3], w: [1.5, 10] }), P(['lantern'], { allow: ['bumper', 'moving'], extra: 2, extraP: 1, targets: [3, 3], w: [1.2, 8] }),
  ],
  2: [
    { h: '은빛 거울' }, P(['mirror'], { targets: [1, 1], w: [4, 40] }), P(['mirror'], { targets: [1, 2] }), { h: '잠망경' }, P(['mirror2'], { targets: [1, 2], w: [3, 30] }),
    { h: '거울과 버섯' }, { h: '방패 정령' }, P(['shield'], { w: [4, 30] }), P(['shield', 'mirror']), P(['mirror'], { allow: ['shield', 'lantern', 'bumper'], extra: 2, w: [2, 14] }),
    { h: '아기 정령' }, P(['baby'], { w: [4, 30] }), P(['baby', 'mirror']), P(['baby', 'lantern'], { targets: [2, 3] }), { h: '째깍 거울' },
    P(['spinner'], { targets: [1, 1], w: [3, 30] }), P(['spinner'], { allow: ['shield', 'baby'] }), { h: '거울 미로' },
    P([], { allow: ['mirror2', 'shield', 'baby', 'spinner', 'lantern'], extra: 3, extraP: 1, w: [1.5, 10] }), P(['mirror'], { allow: ['shield', 'baby', 'spinner', 'lantern', 'bumper', 'moving'], extra: 3, extraP: 1, targets: [2, 3], w: [1.2, 8] }),
  ],
  3: [
    { h: '얼음문' }, P(['ice'], { w: [4, 30] }), P(['ice'], { allow: ['mirror'] }), { h: '포털' }, P(['portal'], { w: [4, 30] }),
    P(['portal'], { allow: ['ice', 'mirror', 'shield'] }), { h: '프리즘' }, P(['prism'], { targets: [2, 3], w: [4, 30] }), P(['prism'], { allow: ['baby'] }),
    P([], { allow: ['ice', 'portal', 'prism', 'mirror'], extra: 2, extraP: 1, w: [2, 14] }),
    { h: '갈라지는 화살' }, P(['split'], { targets: [2, 3], w: [3, 30] }), { h: '관통 화살' }, P(['pierce'], { w: [3, 30] }), { h: '되쏘기 고리' },
    P(['relay'], { targets: [1, 1], w: [3, 30] }), P(['relay'], { allow: ['ice', 'portal', 'lantern'] }), P([], { allow: ['ice', 'portal', 'prism', 'relay', 'mirror', 'shield'], extra: 2, extraP: 1, targets: [2, 3], w: [2.5, 20] }),
    P([], { allow: ['ice', 'portal', 'prism', 'relay', 'mirror', 'shield', 'baby'], extra: 3, extraP: 1, w: [1.5, 10] }),
    P(['relay'], { allow: ['ice', 'portal', 'prism', 'mirror', 'shield', 'baby', 'lantern'], extra: 2, extraP: 1, targets: [2, 3], w: [1.2, 8] }),
  ],
  4: [
    { h: '메아리' }, { echo: 'gate' }, { echo: 'gate' }, { h: '쉿!' }, { echo: 'gate', avoid: 0.8 },
    { h: '한 문, 두 정령' }, { h: '짧은 문' }, { echo: 'gate', avoid: 0.4, shield: 0.4 }, { h: '방패의 방' }, { echo: 'gate', mirror: 0.7, avoid: 0.4 },
    { h: '유리 마개' }, { echo: 'crystal' }, { echo: 'crystal', avoid: 0.6 }, { h: '거울의 역설' }, { echo: 'crystal', mirror: 0.6 },
    { echo: 'gate', mirror: 0.5, shield: 0.4 }, { h: '빛의 갈림길' }, { h: '이중 문' }, { echo: 'crystal', avoid: 0.6, mirror: 0.6 }, { h: '피날레' },
  ],
};
// 별의 끝: 새 요소 없이, 배운 것을 2개 → 3개씩 섞는다. 메아리 판(문/유리)도 사이사이.
const W5_POOL = ['bumper', 'moving', 'lantern', 'mirror', 'shield', 'baby', 'spinner', 'ice', 'portal', 'prism', 'split', 'pierce', 'relay'];
CURRICULUM[5] = Array.from({ length: 20 }, (_, i) => {
  if ([2, 7, 15].includes(i)) return { echo: 'gate', mirror: 0.5, avoid: 0.5, shield: 0.3 };
  if ([5, 12].includes(i)) return { echo: 'crystal', mirror: 0.5, avoid: 0.5 };
  const late = i >= 9;
  return { need: [], allow: W5_POOL, extra: late ? 3 : 2, extraP: 1, needOne: true, targets: late ? [2, 3] : [1, 3],
    w: i === 19 ? [1.2, 8] : i === 18 ? [1.5, 10] : i === 9 ? [2, 14] : late ? [2.5, 20] : [3, 25] };
});
const EXTRA_NAMES = { 5: ['별똥별 언덕', '은하수 다리', '유성의 길', '하늘섬', '별자리 숲'] };
const NAMES = {
  1: ['달빛 오솔길', '이끼 계단', '잠든 언덕', '반딧불 길', '나무뿌리 미로', '고요한 숲', '부엉이 둥지', '이슬 웅덩이', '안개 낀 숲', '바람결', '도토리 언덕', '별빛 숲길', '늙은 참나무', '조용한 개울', '버섯 마을'],
  2: ['은빛 회랑', '반사의 방', '두 개의 달', '거울 정원', '비친 그림자', '빛의 각도', '거울 숲', '은빛 호수', '꺾인 빛', '거울 너머', '빛 조각', '새벽 거울', '거울 계단', '반짝이는 길', '은빛 미로'],
  3: ['수정 동굴', '얼음 정원', '포털 숲', '무지개 샘', '깨진 얼음', '빛의 갈래', '수정 계단', '푸른 동굴', '서리 숲', '프리즘 언덕', '얼음 다리', '차원의 문', '수정 탑', '빛의 샘', '반짝 동굴'],
  4: ['메아리 계곡', '되돌아오는 길', '시간의 문', '과거의 화살', '울림 동굴', '닫히는 문', '메아리 숲', '잠긴 방', '두 번의 기회', '되울림', '시간의 틈', '기억의 화살', '열려라 문', '메아리 탑', '울리는 숲'],
  5: ['별의 끝', '모든 길', '마지막 숲', '정령의 왕관', '빛과 메아리', '혼돈의 숲', '별빛 성채', '끝없는 밤', '새벽 직전', '정령의 시험', '달의 정원', '꿈의 끝자락', '별의 노래', '마지막 화살', '여명'],
};

// ---------- 메인 ----------
const HAND = SIM.LEVELS.map(L => { const { _c, ...rest } = L; return JSON.parse(JSON.stringify(rest)); });
const handByName = Object.fromEntries(HAND.map(L => [L.name, L]));
const FAIR_B = { 1: 2, 2: 2, 3: 3, 4: 3, 5: 3 };
const DEFAULT_W = [3, 30];
module.exports = { analyze, analyzeOne, CURRICULUM, genCur, genCrystal, needed, hasOneShot, analyzeTwo };
if (require.main !== module) return;

const out = [];
const t0 = Date.now();
const log = m => process.stderr.write(`${m} (${((Date.now() - t0) / 1000).toFixed(0)}s)\n`);
for (let w = 1; w <= 5; w++) {
  const names = NAMES[w].slice();
  const extraNames = (EXTRA_NAMES[w] || []).slice();
  CURRICULUM[w].forEach((spec, slot) => {
    const tier = slot === 19 ? 'boss' : slot === 18 ? 'superhard' : slot === 9 ? 'hard' : 'normal';
    let L = null;
    if (spec.h) {
      const H = handByName[spec.h];
      if (!H) throw new Error(`손 레벨 없음: ${spec.h}`);
      L = { ...JSON.parse(JSON.stringify(H)), w, ...analyze(H) };
      log(`W${w} ${slot + 1} [손] ${spec.h}`);
    } else {
      for (let tries = 1; tries <= 600 && !L; tries++) {
        const relax = tries > 300 ? 0.5 : tries > 150 ? 0.75 : 1; // 오래 안 나오면 기준을 조금씩 푼다
        let C, a;
        if (spec.echo) {
          C = spec.echo === 'crystal' ? genCrystal(w, spec) : genEcho(w, { durMin: 1.0, durMax: 2.6, ...spec });
          if (!C) continue;
          C.w = w;
          if (hasOneShot(C)) continue;
          a = analyzeTwo(C);
          if (!a || a.width < 0.4 * relax) continue;
        } else {
          C = genCur(w, spec);
          if (!C) continue;
          a = analyzeOne(C, FAIR_B[w]);
          if (!a) continue;
          const [lo, hi] = spec.w || DEFAULT_W;
          if (a.width < lo * relax || a.width > hi / relax) continue;
          if (a.ways < 2 && tries < 300) continue;
          const must = spec.needOne ? C._feats.filter(f => NEEDABLE[f]).slice(0, 1) : (spec.need || []);
          if (tries <= 450 && !must.every(f => needed(C, f, FAIR_B[w]))) continue;
        }
        delete C._feats;
        C.name = names.length ? names.splice(Math.floor(rnd() * names.length), 1)[0] : extraNames.shift() || `${w}-${slot + 1}`;
        L = { ...C, ...a };
        log(`W${w} ${slot + 1} [생성 ${tries}회] ${spec.echo ? '메아리:' + spec.echo : (spec.need || []).join('+') || '-'} 폭 ${a.width}°`);
      }
      if (!L) throw new Error(`W${w} ${slot + 1} 생성 실패`);
    }
    L.tier = tier;
    if (!L.shots) L.shots = L.par + 2;
    L.guide = Math.max(L.guide || 1, 2);
    out.push(L);
  });
}
out.forEach((L, i) => { L.id = i + 1; });
const file = path.join(__dirname, '..', 'assets', 'levels', 'levels.json');
fs.mkdirSync(path.dirname(file), { recursive: true });
fs.writeFileSync(file, JSON.stringify({ version: 2, levels: out }));
console.log(`levels: ${out.length}, ${((Date.now() - t0) / 1000).toFixed(0)}s → ${file}`);
