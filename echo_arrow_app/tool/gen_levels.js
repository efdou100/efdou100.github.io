// 레벨 생성·검증·배치 → assets/levels/levels.json
//   node tool/gen_levels.js            (전체 생성, 수 분 걸림)
// - 손으로 만든 28판(echo-arrow/sim.js) + 절차 생성 판을 솔버로 검증한 뒤 월드별 20판으로 배치
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
    for (const c of out) for (let s = 0; s < 4; s++) { const n = c.slice(); n[i] = s; next.push(n); }
    out = next;
  });
  return out;
}
const kinds = L => ['n', ...Object.keys(L.skills || {})];
const moving = L => L.targets.some(t => t.per);

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
  const ts = moving(L) ? [0, 48, 96, 144, 192, 240, 288, 336, 384, 432, 480, 528] : [0];
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
  for (const cfg of configs(L)) for (const kind of kinds(L)) for (const step of moving(L) ? [0, 48, 96, 144, 192, 240, 288, 336, 384, 432] : [0])
    for (let d = -180; d < 180; d += 0.25) if (SIM.simulate(L, [{ ang: d * D2R, step, idx: 0, kind }], cfg).won) return true;
  return false;
}
function switchAngles(L, cfg) {
  const res = [];
  for (let d = -180; d < 180; d += 0.5) {
    const run = SIM.newRun(L, [{ ang: d * D2R, step: 0, idx: 0, kind: 'n' }], cfg);
    while (!SIM.done(run) && run.step < 2600) SIM.step(run, null);
    if (!run.failed && run.arrows.some(a => a.stuck === 's')) res.push(d);
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
  if (L.par === 1) return analyzeOne(L, FAIR_B[L.w] || 3);
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

const WORLD_GEN = {
  1: { blocks: [1, 3], moss: 0.6, targets: [1, 3], moving: 0.25, edgesMoss: 0.3, devices: { bumper: 0.25 } },
  2: { blocks: [1, 3], moss: 0.6, targets: [1, 2], shield: 0.2, avoid: 0.3, skill: 0.15, edgesMoss: 0.3, devices: { mirror: 0.9, mirrorMax: 2, bumper: 0.3 } },
  3: { blocks: [1, 3], moss: 0.6, targets: [1, 3], shield: 0.2, avoid: 0.25, skill: 0.2, devices: { mirror: 0.3, ice: 0.6, portal: 0.5, prism: 0.45, bumper: 0.2 } },
  4: { echo: true, durMin: 1.0, durMax: 2.6, avoid: 0.4, mirror: 0.3, shield: 0.15 },
  5: { blocks: [2, 3], moss: 0.55, targets: [2, 3], moving: 0.3, shield: 0.3, avoid: 0.4, skill: 0.3, edgesMoss: 0.3, devices: { mirror: 0.5, mirrorMax: 2, ice: 0.4, portal: 0.4, prism: 0.4, bumper: 0.3 } },
};
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
const handByWorld = { 1: [], 2: [], 3: [], 4: [], 5: [] };
HAND.forEach(L => handByWorld[L.w].push(L));
// 공정한 성공 구간(°) 하한/상한, 정답 튕김 수 상한
const TIERS = { 1: [3, 40], 2: [2.5, 30], 3: [2.5, 25], 4: [0.4, 40], 5: [2, 18] };
const FAIR_B = { 1: 2, 2: 2, 3: 3, 4: 3, 5: 3 };
const ECHO_SHARE = { 5: 6 }; // 별의 끝: 20판 중 6판은 메아리 판

const out = [];
const t0 = Date.now();
for (let w = 1; w <= 5; w++) {
  const hand = handByWorld[w].map(L => ({ ...L, ...analyze(L) }));
  const need = 20 - hand.length;
  const gen = [];
  let tries = 0;
  const names = NAMES[w].slice();
  while (gen.length < need && tries < 900) {
    tries++;
    const cfg = WORLD_GEN[w];
    const wantEcho = cfg.echo || (ECHO_SHARE[w] && gen.filter(x => x.par > 1).length < ECHO_SHARE[w] && gen.length % 3 === 0);
    const L = wantEcho ? genEcho(w, WORLD_GEN[4]) : genLevel(w, cfg);
    if (L) L.w = w;
    if (!L) continue;
    let a;
    if (wantEcho) { if (hasOneShot(L)) continue; a = analyzeTwo(L); }
    else a = analyzeOne(L, FAIR_B[w]);
    if (!a) continue;
    const [lo, hi] = TIERS[w];
    if (!wantEcho && (a.width < lo || a.width > hi)) continue;
    if (wantEcho && a.width < 0.4) continue;
    if (!wantEcho && a.ways < 2) continue;
    // 정답이 장치/스킬 없이도 되는지 기록
    L.name = names.length ? names.splice(Math.floor(rnd() * names.length), 1)[0] : (EXTRA_NAMES[w] || []).shift() || `${w}-${gen.length + 1}`;
    gen.push({ ...L, ...a });
    process.stderr.write(`W${w} ${gen.length}/${need} (시도 ${tries}, ${((Date.now() - t0) / 1000).toFixed(0)}s) 폭 ${a.width}°\n`);
  }
  // 배치: 손 레벨은 앞쪽에 소개용으로 흩뿌리고, 생성 레벨은 난이도 톱니형으로
  gen.sort((a, b) => b.width - a.width); // 쉬운 순
  const slots = new Array(20).fill(null);
  const handSlots = { 7: [0, 2, 4, 7, 10, 13, 16], 6: [0, 2, 5, 8, 11, 14], 5: [0, 3, 6, 9, 12], 9: [0, 1, 3, 5, 7, 9, 11, 13, 16] }[hand.length] || hand.map((_, i) => i * 2);
  hand.forEach((L, i) => (slots[handSlots[i]] = L));
  const pool = gen.slice();
  const takeHardest = () => pool.splice(pool.length - 1, 1)[0];
  const takeEasiest = () => pool.splice(0, 1)[0];
  for (const s of [19, 18, 9]) if (!slots[s] && pool.length) slots[s] = takeHardest();
  for (const s of [4, 14]) if (!slots[s] && pool.length) slots[s] = takeEasiest();
  for (let s = 0; s < 20; s++) if (!slots[s] && pool.length) slots[s] = takeEasiest();
  slots.forEach((L, s) => {
    if (!L) return;
    L.tier = s === 19 ? 'boss' : s === 18 ? 'superhard' : s === 9 ? 'hard' : 'normal';
    if (!L.shots) L.shots = L.par + 2;
    L.guide = Math.max(L.guide || 1, 2);
    out.push(L);
  });
}
out.forEach((L, i) => { L.id = i + 1; });
const file = path.join(__dirname, '..', 'assets', 'levels', 'levels.json');
fs.mkdirSync(path.dirname(file), { recursive: true });
fs.writeFileSync(file, JSON.stringify({ version: 1, levels: out }));
console.log(`levels: ${out.length}, ${((Date.now() - t0) / 1000).toFixed(0)}s → ${file}`);
