// 메아리 화살 — 결정론적 시뮬레이션 (게임과 솔버가 함께 사용)
const SIM = (() => {
  const DT = 1 / 240, SPEED = 560, MAXB = 10, LIFE = 5.5, TR = 15, SR = 13;
  const F = { x0: 12, y0: 84, x1: 348, y1: 624 };

  // 레벨 정의 도우미
  const B = (x, y, w, h, k = 'w') => [x, y, w, h, k];
  const S = (x1, y1, x2, y2, k = 'w') => [x1, y1, x2, y2, k];
  const T = (x, y, mx = 0, my = 0, per = 0) => ({ x, y, mx, my, per });

  const LEVELS = [
    { name: '첫 발', shots: 3, par: 1, guide: 2, bow: [180, 590], targets: [T(180, 250)],
      hint: '화면 아무 곳이나 누르고 뒤로 당겨 조준, 놓으면 발사!' },
    { name: '벽 튕기기', shots: 3, par: 1, guide: 2, bow: [180, 590], blocks: [B(110, 300, 140, 40, 'm')], targets: [T(180, 170)],
      hint: '초록 이끼는 화살을 붙잡아요. 나무 벽에 튕겨서 맞혀 보세요.' },
    { name: '꿰뚫기', shots: 3, par: 1, guide: 2, bow: [180, 590], blocks: [B(220, 200, 128, 24, 'm')], targets: [T(120, 400), T(60, 210)],
      hint: '화살은 정령을 꿰뚫고 계속 날아가요. 한 발로 둘 다!' },
    { name: '두 번 튕기기', shots: 3, par: 1, guide: 2, bow: [180, 590], blocks: [B(12, 300, 250, 26, 'm')], targets: [T(70, 150)],
      hint: '틈으로 들어가 두 번 튕겨 보세요.' },
    { name: '이끼 숲', shots: 3, par: 1, guide: 2, bow: [180, 590],
      edges: { left: [[84, 330, 'w'], [330, 624, 'm']], right: [[84, 330, 'w'], [330, 624, 'm']] },
      blocks: [B(120, 210, 120, 26, 'm')], targets: [T(180, 150)] },
    { name: '주머니', shots: 3, par: 1, guide: 1, bow: [80, 590], walls: [S(262, 84, 262, 190)], blocks: [B(12, 330, 230, 26, 'm')], targets: [T(305, 130)] },
    { name: '세 정령', shots: 3, par: 1, guide: 1, bow: [180, 590], blocks: [B(150, 420, 60, 24, 'm')], targets: [T(70, 160), T(290, 160), T(180, 330)],
      hint: '한 발로 셋 다 맞히면 별 3개. 못 하면 여러 발로 나눠 쏴도 돼요.' },
    { name: '흔들리는 정령', shots: 3, par: 1, guide: 1, bow: [180, 590], walls: [S(12, 300, 160, 300, 'm'), S(200, 300, 348, 300, 'm')], targets: [T(180, 170, 120, 0, 2.6)],
      hint: '누르고 있는 동안 시간이 느려져요. 타이밍을 노려 놓으세요.' },
    { name: '좁은 틈', shots: 3, par: 1, guide: 1, bow: [290, 590], blocks: [B(12, 360, 150, 26, 'm'), B(186, 360, 162, 26, 'm')], targets: [T(60, 140)] },
    { name: '다이아몬드', shots: 3, par: 1, guide: 1, bow: [180, 590],
      walls: [S(180, 250, 240, 330), S(240, 330, 180, 410), S(180, 410, 120, 330), S(120, 330, 180, 250)], targets: [T(60, 130), T(300, 130)] },
    { name: '메아리', shots: 4, par: 2, guide: 1, bow: [180, 590], echoIntro: true,
      walls: [S(130, 84, 130, 200), S(230, 84, 230, 200)], gates: [{ x1: 130, y1: 200, x2: 230, y2: 200, dur: 2.2 }],
      switches: [{ x: 50, y: 340, g: [0] }], targets: [T(180, 140)],
      hint: '1발: 스위치를 맞혀 문을 열어요. 2발: 지난 화살(메아리)이 다시 스위치를 맞히는 동안 문으로 쏘세요!' },
    { name: '한 문, 두 정령', shots: 4, par: 2, guide: 1, bow: [180, 590],
      walls: [S(110, 84, 110, 200), S(250, 84, 250, 200)],
      gates: [{ x1: 12, y1: 200, x2: 110, y2: 200, dur: 3 }, { x1: 250, y1: 200, x2: 348, y2: 200, dur: 3 }],
      switches: [{ x: 180, y: 300, g: [0, 1] }], targets: [T(60, 140), T(300, 140)] },
    { name: '짧은 문', shots: 4, par: 2, guide: 1, bow: [180, 590],
      walls: [S(130, 84, 130, 210), S(230, 84, 230, 210), S(250, 160, 348, 160, 'm')], gates: [{ x1: 130, y1: 210, x2: 230, y2: 210, dur: 0.7 }],
      switches: [{ x: 320, y: 120, g: [0] }], targets: [T(180, 140)],
      hint: '문이 금방 닫혀요. 메아리가 스위치를 맞히는 순간을 노리세요.' },
    { name: '이중 문', shots: 5, par: 3, guide: 1, bow: [180, 590],
      walls: [S(110, 84, 110, 260), S(250, 84, 250, 260)],
      gates: [{ x1: 110, y1: 260, x2: 250, y2: 260, dur: 2.6 }, { x1: 110, y1: 180, x2: 250, y2: 180, dur: 2.6 }],
      switches: [{ x: 45, y: 420, g: [0] }, { x: 315, y: 420, g: [1] }], targets: [T(180, 130)] },
    { name: '피날레', shots: 5, par: 2, guide: 1, bow: [180, 590],
      walls: [S(110, 84, 110, 220), S(250, 84, 250, 220)], blocks: [B(250, 380, 98, 22, 'm')],
      gates: [{ x1: 110, y1: 220, x2: 250, y2: 220, dur: 1.8 }],
      switches: [{ x: 320, y: 470, g: [0] }], targets: [T(180, 140, 45, 0, 1.8), T(45, 470)] },
  ];

  function edgeSegs(edges = {}) {
    const out = [];
    const side = (name, a0, a1, mk) => { for (const [a, b, k] of edges[name] || [[a0, a1, 'w']]) out.push(mk(a, b, k)); };
    side('top', F.x0, F.x1, (a, b, k) => ({ x1: a, y1: F.y0, x2: b, y2: F.y0, k, edge: 1 }));
    side('bottom', F.x0, F.x1, (a, b, k) => ({ x1: a, y1: F.y1, x2: b, y2: F.y1, k, edge: 1 }));
    side('left', F.y0, F.y1, (a, b, k) => ({ x1: F.x0, y1: a, x2: F.x0, y2: b, k, edge: 1 }));
    side('right', F.y0, F.y1, (a, b, k) => ({ x1: F.x1, y1: a, x2: F.x1, y2: b, k, edge: 1 }));
    return out;
  }
  function prep(s) {
    const ex = s.x2 - s.x1, ey = s.y2 - s.y1, len = Math.hypot(ex, ey);
    s.ex = ex; s.ey = ey; s.nx = -ey / len; s.ny = ex / len; return s;
  }
  function compile(L) {
    if (L._c) return L._c;
    const segs = edgeSegs(L.edges);
    for (const w of L.walls || []) segs.push({ x1: w[0], y1: w[1], x2: w[2], y2: w[3], k: w[4] || 'w' });
    for (const [x, y, w, h, k] of L.blocks || []) {
      segs.push({ x1: x, y1: y, x2: x + w, y2: y, k }, { x1: x + w, y1: y, x2: x + w, y2: y + h, k },
        { x1: x + w, y1: y + h, x2: x, y2: y + h, k }, { x1: x, y1: y + h, x2: x, y2: y, k });
    }
    segs.forEach(prep);
    const gates = (L.gates || []).map(g => prep({ ...g, k: 'g' }));
    return (L._c = { segs, gates });
  }

  function hitSeg(s, px, py, dx, dy) {
    const den = dx * s.ey - dy * s.ex;
    if (Math.abs(den) < 1e-12) return -1;
    const ax = s.x1 - px, ay = s.y1 - py;
    const t = (ax * s.ey - ay * s.ex) / den, u = (ax * dy - ay * dx) / den;
    return t > 1e-9 && t <= 1 && u >= -1e-6 && u <= 1 + 1e-6 ? t : -1;
  }
  // gateOpen: 각 문이 열려 있는 마감 시각 배열
  function nearest(C, gateOpen, time, px, py, dx, dy) {
    let best = null, bt = 2;
    for (const s of C.segs) { const t = hitSeg(s, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; best = s; } }
    C.gates.forEach((g, i) => { if (time < gateOpen[i]) return; const t = hitSeg(g, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; best = g; } });
    return best ? { s: best, t: bt } : null;
  }

  function tpos(tg, time) {
    if (!tg.per) return [tg.x, tg.y];
    const k = Math.sin((2 * Math.PI * time) / tg.per);
    return [tg.x + tg.mx * k, tg.y + tg.my * k];
  }

  function newRun(L, shots) {
    const C = compile(L);
    return { L, C, step: 0, shots: shots.map(s => ({ ...s, launched: false })), arrows: [], hit: L.targets.map(() => false),
      gateOpen: C.gates.map(() => -1), swLit: (L.switches || []).map(() => -1), won: false };
  }

  // 화살 이동: 반사/정지 처리. onEvent(type, data)
  function moveArrow(run, a, time, ev) {
    let dx = a.vx * DT, dy = a.vy * DT;
    for (let it = 0; it < 6; it++) {
      const h = nearest(run.C, run.gateOpen, time, a.x, a.y, dx, dy);
      if (!h) { a.x += dx; a.y += dy; return; }
      a.x += dx * h.t; a.y += dy * h.t;
      const s = h.s;
      if (s.k === 'w') {
        let nx = s.nx, ny = s.ny;
        if (nx * dx + ny * dy > 0) { nx = -nx; ny = -ny; }
        const rem = 1 - h.t;
        const vd = a.vx * nx + a.vy * ny;
        a.vx -= 2 * vd * nx; a.vy -= 2 * vd * ny;
        a.x += nx * 0.05; a.y += ny * 0.05;
        dx = a.vx * DT * rem; dy = a.vy * DT * rem;
        a.b++;
        if (ev) ev.push({ type: 'bounce', a, x: a.x, y: a.y, b: a.b });
        if (a.b > MAXB) { a.alive = false; if (ev) ev.push({ type: 'fizzle', a, x: a.x, y: a.y }); return; }
      } else {
        a.alive = false; a.stuck = s.k;
        if (ev) ev.push({ type: 'stick', a, x: a.x, y: a.y, k: s.k, ang: Math.atan2(a.vy, a.vx) });
        return;
      }
    }
  }

  function step(run, ev) {
    const L = run.L, time = run.step * DT;
    for (const s of run.shots) {
      if (!s.launched && s.step <= run.step) {
        s.launched = true;
        const a = { x: L.bow[0], y: L.bow[1], vx: Math.cos(s.ang) * SPEED, vy: Math.sin(s.ang) * SPEED, idx: s.idx, b: 0, age: 0, alive: true, hits: 0 };
        run.arrows.push(a);
        if (ev) ev.push({ type: 'launch', a, echo: s.echo });
      }
    }
    for (const a of run.arrows) {
      if (!a.alive) continue;
      moveArrow(run, a, time, ev);
      if (!a.alive) continue;
      const sws = L.switches || [];
      for (let i = 0; i < sws.length; i++) {
        const sw = sws[i];
        if ((a.x - sw.x) ** 2 + (a.y - sw.y) ** 2 < (SR + 2) ** 2) {
          a.alive = false; a.stuck = 's';
          for (const g of sw.g) run.gateOpen[g] = time + run.C.gates[g].dur;
          run.swLit[i] = time;
          if (ev) ev.push({ type: 'switch', a, i, x: sw.x, y: sw.y });
          break;
        }
      }
      if (!a.alive) continue;
      L.targets.forEach((tg, i) => {
        if (run.hit[i]) return;
        const [tx, ty] = tpos(tg, time);
        if ((a.x - tx) ** 2 + (a.y - ty) ** 2 < (TR + 2) ** 2) {
          run.hit[i] = true; a.hits++;
          if (ev) ev.push({ type: 'hit', a, i, x: tx, y: ty, b: a.b, multi: a.hits });
        }
      });
      a.age += DT;
      if (a.age > LIFE) { a.alive = false; if (ev) ev.push({ type: 'fizzle', a, x: a.x, y: a.y }); }
    }
    run.step++;
    if (!run.won && run.hit.every(Boolean)) { run.won = true; if (ev) ev.push({ type: 'win' }); }
  }

  const done = run => run.shots.every(s => s.launched) && run.arrows.every(a => !a.alive);

  // 조준선: 현재 문 상태 기준으로 반사 경로를 계산
  function ray(run, ang, maxB, maxLen) {
    const L = run.L, time = run.step * DT;
    let x = L.bow[0], y = L.bow[1], vx = Math.cos(ang), vy = Math.sin(ang);
    const pts = [[x, y]];
    let b = 0, total = 0, end = 'open';
    while (b <= maxB) {
      const reach = 900;
      const h = nearest(run.C, run.gateOpen, time, x, y, vx * reach, vy * reach);
      if (!h) { pts.push([x + vx * reach, y + vy * reach]); break; }
      let d = reach * h.t;
      if (b === maxB && maxLen && d > maxLen) { pts.push([x + vx * maxLen, y + vy * maxLen]); end = 'cut'; break; }
      x += vx * d; y += vy * d; total += d; pts.push([x, y]);
      if (h.s.k !== 'w') { end = h.s.k; break; }
      let nx = h.s.nx, ny = h.s.ny;
      if (nx * vx + ny * vy > 0) { nx = -nx; ny = -ny; }
      const vd = vx * nx + vy * ny; vx -= 2 * vd * nx; vy -= 2 * vd * ny;
      x += nx * 0.05; y += ny * 0.05;
      b++;
      if (b > maxB) break;
    }
    return { pts, end };
  }

  // 빠른 판정 (솔버용)
  function simulate(L, shots, maxSteps = 2400) {
    const run = newRun(L, shots);
    while (run.step < maxSteps) {
      step(run, null);
      if (run.won) return run;
      if (done(run)) return run;
    }
    return run;
  }

  return { DT, SPEED, TR, SR, F, LEVELS, compile, newRun, step, done, ray, tpos, simulate };
})();
if (typeof module !== 'undefined') module.exports = SIM;
