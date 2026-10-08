// 메아리 화살 — 결정론적 시뮬레이션 (게임과 솔버가 함께 사용)
const SIM = (() => {
  const DT = 1 / 240, SPEED = 560, MAXB = 12, LIFE = 6, TR = 15, SR = 13, PR = 15, XR = 12, MAXA = 30;
  const RR = 14, RHOLD = 0.5, LR = 12, BR = 74, CHAIN = 0.18; // 되쏘기 고리 반지름·붙잡는 시간, 등불 반지름·폭발 반경·연쇄 지연
  const F = { x0: 12, y0: 84, x1: 348, y1: 624 };
  const D2R = Math.PI / 180;

  // ---- 레벨 정의 도우미 ----
  const B = (x, y, w, h, k = 'w') => [x, y, w, h, k];            // 블록: w 나무(튕김) m 이끼(정지) i 얼음(한 번 튕기고 깨짐)
  const S = (x1, y1, x2, y2, k = 'w') => [x1, y1, x2, y2, k];    // 선분 벽
  const T = (x, y, o = {}) => ({ x, y, mx: 0, my: 0, per: 0, ...o }); // 정령 (mx/my/per: 왕복, shield: 방패 방향°)
  const M = (x, y, s = 0, rot = true, len = 58) => ({ x, y, s, rot, len }); // 거울: s*45° 방향, rot=회전 가능
  const U = (x, y, r = 22) => ({ x, y, r });                      // 버섯 범퍼
  const P = (x1, y1, x2, y2) => ({ a: [x1, y1], b: [x2, y2] });   // 포털 쌍
  const X = (x, y) => ({ x, y });                                 // 프리즘
  const K = (x, y, w, h, soft) => ({ x, y, w, h, soft });         // 유리 마개: soft(l/r/t/b) 면으로 맞을 때만 깨짐(화살은 멈춤), 나머지 면은 튕김
  const R = (x, y, s = 0, rot = true) => ({ x, y, s, rot, relay: true, len: 0 }); // 되쏘기 고리: 화살을 붙잡았다가 s*45° 방향으로 다시 쏨 (mirrors 배열에 들어감)
  const N = (x, y) => ({ x, y });                                 // 등불: 맞으면 폭발, 반경 안 정령을 깨우고(방패 무시) 다른 등불로 번짐
  const SP = (x, y, s, spin, len = 58) => ({ x, y, s, rot: false, len, spin }); // 째깍 거울: spin 초마다 45°씩 저절로 돈다
  const MOSS = { top: [[F.x0, F.x1, 'm']], bottom: [[F.x0, F.x1, 'm']], left: [[F.y0, F.y1, 'm']], right: [[F.y0, F.y1, 'm']] };

  const LEVELS = [
    // ---------------- 월드 1: 숲 ----------------
    { w: 1, name: '첫 발', shots: 3, par: 1, guide: 2, bow: [180, 590], targets: [T(180, 250)],
      hint: '화면 아무 곳이나 누르고 뒤로 당겨 조준, 놓으면 발사!' },
    { w: 1, name: '벽 튕기기', intro: 'moss', shots: 3, par: 1, guide: 2, bow: [180, 590], blocks: [B(110, 300, 140, 40, 'm')], targets: [T(180, 170)],
      hint: '초록 이끼는 화살을 붙잡아요. 나무 벽에 튕겨서 맞혀 보세요.' },
    { w: 1, name: '꿰뚫기', shots: 3, par: 1, guide: 2, bow: [180, 590], blocks: [B(220, 200, 128, 24, 'm')], targets: [T(120, 400), T(60, 210)],
      hint: '화살은 정령을 꿰뚫고 계속 날아가요. 한 발로 둘 다!' },
    { w: 1, name: '두 번 튕기기', shots: 3, par: 1, guide: 2, bow: [180, 590], blocks: [B(12, 300, 250, 26, 'm')], targets: [T(70, 150)] },
    { w: 1, name: '버섯 범퍼', intro: 'bumper', shots: 3, par: 1, guide: 2, bow: [180, 590],
      blocks: [B(100, 300, 160, 30, 'm')], bumpers: [U(90, 440, 30), U(270, 440, 30)], targets: [T(180, 170)],
      hint: '둥근 버섯은 맞는 자리에 따라 튕기는 각도가 달라져요.' },
    { w: 1, name: '흔들리는 정령', intro: 'moving', shots: 3, par: 1, guide: 1, bow: [180, 590], walls: [S(12, 300, 160, 300, 'm'), S(200, 300, 348, 300, 'm')],
      targets: [T(180, 170, { mx: 120, per: 2.6 })], hint: '누르고 있는 동안 시간이 느려져요. 타이밍을 노려 놓으세요.' },
    { w: 1, name: '세 정령', shots: 3, par: 1, guide: 1, bow: [180, 590], blocks: [B(150, 420, 60, 24, 'm')], targets: [T(70, 160), T(290, 160), T(180, 330)],
      hint: '한 발로 셋 다 맞히면 별 3개. 여러 발로 나눠 쏴도 깰 수는 있어요.' },

    // ---------------- 월드 2: 거울 ----------------
    { w: 2, name: '은빛 거울', intro: 'mirror', shots: 3, par: 1, guide: 2, bow: [180, 590], edges: MOSS,
      walls: [S(250, 280, 348, 280, 'm'), S(250, 380, 348, 380, 'm')], mirrors: [M(160, 330, 0, true, 66)], targets: [T(315, 330)],
      hint: '은빛 거울을 톡 누르면 45°씩 돌아가요. 사방이 이끼라 거울만이 길이에요.' },
    { w: 2, name: '잠망경', shots: 3, par: 1, guide: 2, bow: [180, 590], edges: MOSS,
      walls: [S(12, 190, 140, 190, 'm')], mirrors: [M(180, 440, 0, true, 64), M(300, 440, 0, true, 64), M(300, 140, 1, false, 64)], targets: [T(60, 140)],
      hint: '거울 두 개를 이어서 꺾어 보세요.' },
    { w: 2, name: '거울과 버섯', shots: 3, par: 1, guide: 1, bow: [180, 590],
      edges: { left: [[F.y0, 300, 'w'], [300, F.y1, 'm']], right: [[F.y0, 300, 'w'], [300, F.y1, 'm']] },
      blocks: [B(130, 260, 100, 26, 'm')], bumpers: [U(70, 420, 26)], mirrors: [M(280, 400, 0, true, 64)], targets: [T(180, 150)] },
    { w: 2, name: '방패 정령', intro: 'shield', shots: 3, par: 1, guide: 1, bow: [180, 590], targets: [T(180, 260, { shield: 90 })],
      hint: '방패 쪽은 화살을 튕겨내요. 등 뒤로 돌아가 맞히세요.' },
    { w: 2, name: '아기 정령', intro: 'baby', shots: 3, par: 1, guide: 1, bow: [180, 590], mirrors: [M(290, 470, 0)],
      targets: [T(180, 200), T(180, 290, { avoid: true }), T(110, 230, { avoid: true }), T(250, 230, { avoid: true })],
      hint: '분홍 아기 정령은 절대 맞히면 안 돼요! 맞히면 그 판은 실패예요.' },
    { w: 2, name: '갈라지는 화살', intro: 'split', shots: 3, par: 1, guide: 1, bow: [180, 590], skills: { split: 1 },
      walls: [S(120, 84, 120, 230, 'm'), S(240, 84, 240, 230, 'm')], blocks: [B(150, 340, 60, 18)], targets: [T(60, 140), T(180, 130), T(300, 140)],
      hint: '아래 [분열] 화살을 고르면 첫 번째로 튕길 때 세 갈래로 갈라져요.' },
    { w: 2, name: '거울 미로', shots: 3, par: 1, guide: 1, bow: [180, 590], edges: MOSS,
      walls: [S(12, 220, 130, 220, 'm'), S(12, 340, 130, 340, 'm')], mirrors: [M(180, 280, 0, true, 60), M(300, 280, 0, true, 60), M(70, 470, 0, true, 60)], targets: [T(240, 280), T(300, 130)] },

    // ---------------- 월드 3: 수정 ----------------
    { w: 3, name: '얼음문', intro: 'ice', shots: 3, par: 1, guide: 1, bow: [180, 590],
      walls: [S(12, 300, 110, 300, 'm'), S(250, 300, 348, 300, 'm')], blocks: [B(110, 294, 140, 12, 'i')], targets: [T(130, 170)],
      hint: '얼음은 한 번 튕겨내고 깨져요. 깨진 자리로 다시 들어가게 해 보세요.' },
    { w: 3, name: '포털', intro: 'portal', shots: 3, par: 1, guide: 1, bow: [180, 590],
      walls: [S(12, 230, 150, 230, 'm'), S(150, 84, 150, 230, 'm')], portals: [P(290, 430, 50, 200)], targets: [T(100, 130)],
      hint: '주황 포털로 들어가면 파란 포털로 같은 방향 그대로 나와요.' },
    { w: 3, name: '프리즘', intro: 'prism', shots: 3, par: 1, guide: 1, bow: [180, 590], prisms: [X(180, 360)],
      targets: [T(71, 230), T(180, 190), T(289, 230)],
      hint: '프리즘에 맞으면 화살이 세 갈래로 갈라져요.' },
    { w: 3, name: '관통 화살', intro: 'pierce', shots: 3, par: 1, guide: 1, bow: [180, 590], skills: { pierce: 1 },
      walls: [S(130, 150, 230, 150, 'm'), S(230, 150, 230, 250, 'm'), S(230, 250, 130, 250, 'm'), S(130, 250, 130, 150, 'm')],
      targets: [T(180, 200), T(60, 120)], hint: '[관통] 화살은 이끼를 뚫고 지나가요.' },
    { w: 3, name: '수정 정원', shots: 3, par: 1, guide: 1, bow: [180, 590],
      edges: { top: [[F.x0, F.x1, 'm']] }, prisms: [X(110, 380)], portals: [P(290, 470, 290, 150)], mirrors: [M(200, 250, 1)],
      blocks: [B(130, 200, 26, 26, 'i')], targets: [T(60, 140), T(240, 120, { shield: 90 }), T(310, 300)] },

    // ---------------- 월드 4: 메아리 ----------------
    { w: 4, name: '메아리', intro: 'echo', shots: 4, par: 2, guide: 1, bow: [180, 590], echoIntro: true,
      walls: [S(130, 84, 130, 200), S(230, 84, 230, 200)], gates: [{ x1: 130, y1: 200, x2: 230, y2: 200, dur: 2.2 }],
      switches: [{ x: 50, y: 340, g: [0] }], targets: [T(180, 140)],
      hint: '1발: 스위치를 맞혀 문을 열어요. 2발: 지난 화살(메아리)이 다시 스위치를 맞히는 동안 문으로 쏘세요!' },
    { w: 4, name: '쉿!', shots: 4, par: 2, guide: 1, bow: [180, 590],
      walls: [S(130, 84, 130, 200), S(230, 84, 230, 200)], gates: [{ x1: 130, y1: 200, x2: 230, y2: 200, dur: 2.4 }],
      switches: [{ x: 300, y: 330, g: [0] }], targets: [T(180, 140), T(240, 460, { avoid: true }), T(180, 290, { avoid: true })],
      hint: '메아리는 매번 똑같이 날아가요. 아기 정령을 맞히는 메아리를 남기면 계속 실패해요. 그럴 땐 ↻ 다시 시작!' },
    { w: 4, name: '한 문, 두 정령', shots: 4, par: 2, guide: 1, bow: [180, 590],
      walls: [S(110, 84, 110, 200), S(250, 84, 250, 200)],
      gates: [{ x1: 12, y1: 200, x2: 110, y2: 200, dur: 3 }, { x1: 250, y1: 200, x2: 348, y2: 200, dur: 3 }],
      switches: [{ x: 180, y: 300, g: [0, 1] }], targets: [T(60, 140), T(300, 140)] },
    { w: 4, name: '짧은 문', shots: 4, par: 2, guide: 1, bow: [180, 590],
      walls: [S(130, 84, 130, 210), S(230, 84, 230, 210), S(250, 160, 348, 160, 'm')], gates: [{ x1: 130, y1: 210, x2: 230, y2: 210, dur: 0.7 }],
      switches: [{ x: 320, y: 120, g: [0] }], targets: [T(180, 140)], hint: '문이 금방 닫혀요. 메아리가 스위치를 맞히는 순간을 노리세요.' },
    { w: 4, name: '방패의 방', shots: 4, par: 2, guide: 1, bow: [180, 590],
      walls: [S(110, 84, 110, 230), S(250, 84, 250, 230)], gates: [{ x1: 110, y1: 230, x2: 250, y2: 230, dur: 2.4 }],
      switches: [{ x: 320, y: 380, g: [0] }], mirrors: [M(60, 300, 0)], targets: [T(180, 170, { shield: 90 })],
      hint: '방패가 문 쪽을 보고 있어요. 방 안에서 한 번 더 튕겨야 해요.' },
    { w: 4, name: '거울의 역설', shots: 4, par: 2, guide: 1, bow: [180, 590], edges: { top: [[F.x0, F.x1, 'm']], right: [[F.y0, F.y1, 'm']] },
      walls: [S(200, 84, 200, 210), S(300, 84, 300, 210)], gates: [{ x1: 200, y1: 210, x2: 300, y2: 210, dur: 2.0 }],
      switches: [{ x: 40, y: 140, g: [0] }], mirrors: [M(180, 330, 0)], blocks: [B(60, 230, 100, 22, 'm')], targets: [T(250, 140)],
      hint: '거울을 돌리면 메아리의 길도 바뀌어요. 두 화살 모두에게 맞는 각도를 찾으세요.' },
    { w: 4, name: '이중 문', shots: 5, par: 3, guide: 1, bow: [180, 590],
      walls: [S(110, 84, 110, 260), S(250, 84, 250, 260)],
      gates: [{ x1: 110, y1: 260, x2: 250, y2: 260, dur: 2.6 }, { x1: 110, y1: 180, x2: 250, y2: 180, dur: 2.6 }],
      switches: [{ x: 45, y: 420, g: [0] }, { x: 315, y: 420, g: [1] }], targets: [T(180, 130)] },
    { w: 4, name: '빛의 갈림길', shots: 4, par: 1, guide: 1, bow: [180, 590],
      walls: [S(130, 84, 130, 200), S(230, 84, 230, 200)], gates: [{ x1: 130, y1: 200, x2: 230, y2: 200, dur: 2.0 }],
      prisms: [X(180, 420)], switches: [{ x: 60, y: 280, g: [0] }], targets: [T(180, 140)],
      hint: '한 발로? 프리즘이 나눈 화살 하나가 문을 열고, 다른 하나가 들어간다면…' },
    { w: 4, name: '피날레', shots: 5, par: 2, guide: 1, bow: [180, 590],
      walls: [S(110, 84, 110, 220), S(250, 84, 250, 220)], blocks: [B(250, 380, 98, 22, 'm'), B(40, 330, 26, 26, 'i')],
      gates: [{ x1: 110, y1: 220, x2: 250, y2: 220, dur: 1.8 }], mirrors: [M(90, 450, 1)], portals: [P(300, 300, 60, 160)],
      switches: [{ x: 320, y: 470, g: [0] }], targets: [T(180, 140, { mx: 45, per: 1.8 }), T(45, 470), T(60, 250, { shield: 0 })] },

    // ---- 새 장치 소개 판 ----
    { w: 1, name: '등불', intro: 'lantern', shots: 3, par: 1, guide: 2, bow: [180, 590], lanterns: [N(160, 200)], targets: [T(120, 180), T(205, 170), T(110, 232)],
      hint: '등불을 맞히면 펑! 둘레의 정령이 한꺼번에 깨어나요.' },
    { w: 1, name: '연쇄 등불', shots: 3, par: 1, guide: 2, bow: [180, 590], walls: [S(12, 232, 348, 232, 'm')],
      lanterns: [N(90, 330), N(150, 295), N(210, 262)], targets: [T(240, 205), T(185, 200)],
      hint: '이끼 벽 너머는 화살이 못 가요. 등불 불꽃은 옆 등불로 번져요!' },
    { w: 2, name: '째깍 거울', intro: 'spinner', shots: 3, par: 1, guide: 2, bow: [180, 590], edges: MOSS,
      blocks: [B(88, 440, 56, 34, 'm')], mirrors: [SP(180, 330, 0, 1.2, 70)], targets: [T(52, 330)],
      hint: '째깍 거울은 저절로 45°씩 돌아요. 누르고 있으면 시간이 느려지니, 조준선이 정령에 닿는 순간 놓으세요.' },
    { w: 3, name: '되쏘기 고리', intro: 'relay', shots: 3, par: 1, guide: 2, bow: [180, 590], edges: MOSS,
      blocks: [B(222, 410, 46, 46, 'm')], mirrors: [R(180, 400, 6)], targets: [T(300, 270)],
      hint: '초록 고리는 화살을 붙잡았다가 화살표 쪽으로 다시 쏴요. 톡 누르면 방향이 바뀌어요.' },
    { w: 4, name: '유리 마개', intro: 'crystal', shots: 4, par: 2, guide: 2, bow: [180, 590],
      walls: [S(130, 84, 130, 220, 'm'), S(230, 84, 230, 220, 'm')], crystals: [K(130, 220, 100, 26, 'r')], targets: [T(180, 150)],
      hint: '유리는 분홍 금이 간 오른쪽 면으로만 깨져요. 1발로 옆에서 깨고, 2발은 메아리가 깬 다음에 지나가게 쏘세요!' },
  ];

  // ---- 지오메트리 ----
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
    let ice = 0;
    for (const [x, y, w, h, k] of L.blocks || []) {
      const id = k === 'i' ? ice++ : undefined;
      for (const s of [{ x1: x, y1: y, x2: x + w, y2: y }, { x1: x + w, y1: y, x2: x + w, y2: y + h }, { x1: x + w, y1: y + h, x2: x, y2: y + h }, { x1: x, y1: y + h, x2: x, y2: y }])
        segs.push({ ...s, k: k === 'i' ? 'w' : k, ice: id });
    }
    (L.crystals || []).forEach((k, id) => {
      const { x, y, w, h } = k;
      for (const [f, sg] of [['t', { x1: x, y1: y, x2: x + w, y2: y }], ['r', { x1: x + w, y1: y, x2: x + w, y2: y + h }], ['b', { x1: x + w, y1: y + h, x2: x, y2: y + h }], ['l', { x1: x, y1: y + h, x2: x, y2: y }]])
        segs.push({ ...sg, k: 'c', crys: id, soft: f === k.soft });
    });
    segs.forEach(prep);
    const gates = (L.gates || []).map(g => prep({ ...g, k: 'g' }));
    return (L._c = { segs, gates, iceCount: ice });
  }
  // 째깍 거울은 정수 step 으로 계산해 JS/Dart 가 똑같이 끊어지게 한다
  const mirrorAng = (m, s, st) => (s + (m.spin ? Math.floor(st / Math.round(m.spin / DT)) : 0)) * 45 * D2R;
  function mirrorSeg(m, s, st = 0) {
    if (m.relay) return null;
    const a = mirrorAng(m, s, st), hx = Math.cos(a) * m.len / 2, hy = Math.sin(a) * m.len / 2;
    return prep({ x1: m.x - hx, y1: m.y - hy, x2: m.x + hx, y2: m.y + hy, k: 'w', mirror: true });
  }

  function hitSeg(s, px, py, dx, dy) {
    const den = dx * s.ey - dy * s.ex;
    if (Math.abs(den) < 1e-12) return -1;
    const ax = s.x1 - px, ay = s.y1 - py;
    const t = (ax * s.ey - ay * s.ex) / den, u = (ax * dy - ay * dx) / den;
    return t >= 0 && t <= 1 && u >= -1e-6 && u <= 1 + 1e-6 ? t : -1;
  }
  function hitCircle(cx, cy, r, px, py, dx, dy) {
    const fx = px - cx, fy = py - cy, a = dx * dx + dy * dy, b = 2 * (fx * dx + fy * dy), c = fx * fx + fy * fy - r * r;
    if (b >= 0) return -1;
    const disc = b * b - 4 * a * c; if (disc < 0) return -1;
    const t = (-b - Math.sqrt(disc)) / (2 * a);
    return t >= 0 && t <= 1 ? t : -1;
  }
  // 가장 먼저 닿는 면. pierce: 이끼 무시. extra: 레이용(포털/프리즘 원)
  function nearest(run, time, px, py, dx, dy, pierce, extra) {
    let bt = 2, h = null;
    for (const s of run.C.segs) {
      if (s.k === 'm' && pierce) continue;
      if (s.ice !== undefined && run.ice[s.ice]) continue;
      if (s.crys !== undefined && run.crys[s.crys]) continue;
      const t = hitSeg(s, px, py, dx, dy);
      if (t >= 0 && t < bt) { bt = t; h = { nx: s.nx, ny: s.ny, k: s.k, ice: s.ice, crys: s.crys, soft: s.soft }; }
    }
    for (const s of run.mseg) { if (!s) continue; const t = hitSeg(s, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; h = { nx: s.nx, ny: s.ny, k: 'w', mirror: true }; } }
    run.C.gates.forEach((g, i) => { if (time < run.gateOpen[i]) return; const t = hitSeg(g, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; h = { nx: g.nx, ny: g.ny, k: 'g' }; } });
    for (const u of run.L.bumpers || []) {
      const t = hitCircle(u.x, u.y, u.r, px, py, dx, dy);
      if (t >= 0 && t < bt) { bt = t; const hx = px + dx * t - u.x, hy = py + dy * t - u.y, l = Math.hypot(hx, hy); h = { nx: hx / l, ny: hy / l, k: 'w', bumper: true }; }
    }
    if (extra) {
      (run.L.portals || []).forEach((p, i) => { for (const [end, c] of [['a', p.a], ['b', p.b]]) { const t = hitCircle(c[0], c[1], PR, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; h = { k: 'p', i, end }; } } });
      for (const x of run.L.prisms || []) { const t = hitCircle(x.x, x.y, XR, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; h = { k: 'x' }; } }
      (run.L.mirrors || []).forEach((m, i) => { if (!m.relay) return; const t = hitCircle(m.x, m.y, RR, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; h = { k: 'r', i }; } });
      (run.L.lanterns || []).forEach((n, i) => { if (run.lit[i]) return; const t = hitCircle(n.x, n.y, LR, px, py, dx, dy); if (t >= 0 && t < bt) { bt = t; h = { k: 'l', i }; } });
    }
    if (h) h.t = bt;
    return h;
  }

  function tpos(tg, time) {
    if (!tg.per) return [tg.x, tg.y];
    const k = Math.sin((2 * Math.PI * time) / tg.per);
    return [tg.x + tg.mx * k, tg.y + tg.my * k];
  }
  const defaultMirrors = L => (L.mirrors || []).map(m => m.s);

  function newRun(L, shots, mirrors) {
    const C = compile(L);
    const ms = mirrors || defaultMirrors(L);
    return { L, C, step: 0, shots: shots.map(s => ({ ...s, launched: false })), arrows: [], hit: L.targets.map(() => false),
      gateOpen: C.gates.map(() => -1), ice: new Array(C.iceCount).fill(false), mirrors: ms.slice(),
      mseg: (L.mirrors || []).map((m, i) => mirrorSeg(m, ms[i])), won: false, spawned: [],
      crys: (L.crystals || []).map(() => false), lit: (L.lanterns || []).map(() => false), held: [], booms: [] };
  }
  function spawn(run, from, x, y, ang, extra) {
    if (run.arrows.length + run.spawned.length >= MAXA) return null;
    const a = { x, y, vx: Math.cos(ang) * SPEED, vy: Math.sin(ang) * SPEED, idx: from.idx, kind: from.kind === 'split' ? 'n' : from.kind, b: from.b, age: from.age, alive: true, hits: 0, pcd: 0, prisms: from.prisms ? from.prisms.slice() : [], child: true, ...extra };
    run.spawned.push(a);
    return a;
  }

  function moveArrow(run, a, time, ev) {
    let dx = a.vx * DT, dy = a.vy * DT;
    for (let it = 0; it < 6; it++) {
      const h = nearest(run, time, a.x, a.y, dx, dy, a.kind === 'pierce', false);
      if (!h) { a.x += dx; a.y += dy; return; }
      a.x += dx * h.t; a.y += dy * h.t;
      if (h.k === 'c' && h.soft) {
        run.crys[h.crys] = true; a.alive = false; a.stuck = 'c'; a.ang = Math.atan2(a.vy, a.vx);
        if (ev) ev.push({ type: 'crack', a, i: h.crys, x: a.x, y: a.y });
        return;
      }
      if (h.k === 'w' || h.k === 'c') {
        let nx = h.nx, ny = h.ny;
        if (nx * dx + ny * dy > 0) { nx = -nx; ny = -ny; }
        const rem = 1 - h.t, vd = a.vx * nx + a.vy * ny;
        a.vx -= 2 * vd * nx; a.vy -= 2 * vd * ny;
        a.x += nx * 0.05; a.y += ny * 0.05;
        dx = a.vx * DT * rem; dy = a.vy * DT * rem;
        a.b++;
        if (h.ice !== undefined) { run.ice[h.ice] = true; if (ev) ev.push({ type: 'ice', i: h.ice, x: a.x, y: a.y }); }
        if (ev) ev.push({ type: 'bounce', a, x: a.x, y: a.y, b: a.b, mirror: h.mirror, bumper: h.bumper });
        if (a.kind === 'split' && !a.didSplit) {
          a.didSplit = true; a.kind = 'n';
          const ang = Math.atan2(a.vy, a.vx);
          for (const d of [-28, 28]) spawn(run, a, a.x, a.y, ang + d * D2R, { didSplit: true });
          if (ev) ev.push({ type: 'split', a, x: a.x, y: a.y });
        }
        if (a.b > MAXB) { a.alive = false; if (ev) ev.push({ type: 'fizzle', a, x: a.x, y: a.y }); return; }
      } else {
        a.alive = false; a.stuck = h.k; a.ang = Math.atan2(a.vy, a.vx);
        if (ev) ev.push({ type: 'stick', a, x: a.x, y: a.y, k: h.k, ang: a.ang });
        return;
      }
    }
  }

  // 등불 폭발: 반경 안 정령을 깨우고(방패 무시, 아기 정령은 실패), 유리 마개를 깨고, 다른 등불에 불을 옮긴다
  function boom(run, i, time, ev) {
    const L = run.L, n = L.lanterns[i];
    if (ev) ev.push({ type: 'boom', i, x: n.x, y: n.y });
    for (let j = 0; j < L.targets.length; j++) {
      if (run.hit[j]) continue;
      const [tx, ty] = tpos(L.targets[j], time);
      if ((tx - n.x) ** 2 + (ty - n.y) ** 2 >= BR * BR) continue;
      run.hit[j] = true;
      if (L.targets[j].avoid) { run.failed = true; if (ev) ev.push({ type: 'oops', i: j, x: tx, y: ty, boom: true }); }
      else if (ev) ev.push({ type: 'hit', i: j, x: tx, y: ty, b: 0, multi: 1, boom: true });
    }
    (L.crystals || []).forEach((k, j) => {
      if (run.crys[j]) return;
      const cx = k.x + k.w / 2, cy = k.y + k.h / 2;
      if ((cx - n.x) ** 2 + (cy - n.y) ** 2 < BR * BR) { run.crys[j] = true; if (ev) ev.push({ type: 'crack', i: j, x: cx, y: cy }); }
    });
    L.lanterns.forEach((o, j) => {
      if (run.lit[j]) return;
      if ((o.x - n.x) ** 2 + (o.y - n.y) ** 2 < BR * BR) { run.lit[j] = true; run.booms.push({ i: j, at: run.step + Math.round(CHAIN / DT) }); }
    });
  }

  function step(run, ev) {
    const L = run.L, time = run.step * DT;
    (L.mirrors || []).forEach((m, i) => { if (m.spin) run.mseg[i] = mirrorSeg(m, run.mirrors[i], run.step); });
    if (run.booms.length) {
      const due = run.booms.filter(b => b.at <= run.step);
      run.booms = run.booms.filter(b => b.at > run.step);
      for (const b of due) boom(run, b.i, time, ev);
    }
    for (const s of run.shots) {
      if (!s.launched && s.step <= run.step) {
        s.launched = true;
        const a = { x: L.bow[0], y: L.bow[1], vx: Math.cos(s.ang) * SPEED, vy: Math.sin(s.ang) * SPEED, idx: s.idx, kind: s.kind || 'n', b: 0, age: 0, alive: true, hits: 0, pcd: 0, prisms: [] };
        run.arrows.push(a);
        if (ev) ev.push({ type: 'launch', a, echo: s.echo });
      }
    }
    if (run.held.length) {
      const due = run.held.filter(h => h.at <= run.step);
      run.held = run.held.filter(h => h.at > run.step);
      for (const h of due) {
        if (run.arrows.length >= MAXA) continue;
        const m = L.mirrors[h.i], ang = run.mirrors[h.i] * 45 * D2R;
        const a = { x: m.x + Math.cos(ang) * (RR + 4), y: m.y + Math.sin(ang) * (RR + 4), vx: Math.cos(ang) * SPEED, vy: Math.sin(ang) * SPEED, idx: h.idx, kind: h.kind, b: h.b, age: h.age, alive: true, hits: 0, pcd: 0, prisms: h.prisms, child: true };
        run.arrows.push(a);
        if (ev) ev.push({ type: 'relay', a, i: h.i, x: m.x, y: m.y });
      }
    }
    for (const a of run.arrows) {
      if (!a.alive) continue;
      moveArrow(run, a, time, ev);
      if (!a.alive) continue;
      if (a.pcd > 0) a.pcd -= DT;
      // 포털
      const ps = L.portals || [];
      for (let i = 0; i < ps.length && a.pcd <= 0; i++) {
        for (const [from, to] of [[ps[i].a, ps[i].b], [ps[i].b, ps[i].a]]) {
          if ((a.x - from[0]) ** 2 + (a.y - from[1]) ** 2 < PR * PR) {
            const sp = Math.hypot(a.vx, a.vy);
            a.x = to[0] + (a.vx / sp) * (PR + 2); a.y = to[1] + (a.vy / sp) * (PR + 2); a.pcd = 0.15;
            if (ev) ev.push({ type: 'portal', a, x1: from[0], y1: from[1], x2: to[0], y2: to[1] });
            break;
          }
        }
      }
      // 프리즘
      const xs = L.prisms || [];
      for (let i = 0; i < xs.length; i++) {
        const x = xs[i];
        if (a.prisms.includes(i)) continue;
        if ((a.x - x.x) ** 2 + (a.y - x.y) ** 2 < XR * XR) {
          a.alive = false; a.stuck = 'x';
          const ang = Math.atan2(a.vy, a.vx);
          for (const d of [-40, 0, 40]) {
            const na = ang + d * D2R;
            spawn(run, a, x.x + Math.cos(na) * (XR + 3), x.y + Math.sin(na) * (XR + 3), na, { prisms: [...a.prisms, i] });
          }
          if (ev) ev.push({ type: 'prism', a, x: x.x, y: x.y, i });
          break;
        }
      }
      if (!a.alive) continue;
      // 되쏘기 고리
      const ms = L.mirrors || [];
      for (let i = 0; i < ms.length; i++) {
        const m = ms[i];
        if (!m.relay) continue;
        if ((a.x - m.x) ** 2 + (a.y - m.y) ** 2 < RR * RR) {
          a.alive = false; a.stuck = 'r';
          run.held.push({ i, at: run.step + Math.round(RHOLD / DT), idx: a.idx, kind: a.kind, b: a.b, age: a.age, prisms: a.prisms.slice() });
          if (ev) ev.push({ type: 'catch', a, i, x: m.x, y: m.y });
          break;
        }
      }
      if (!a.alive) continue;
      // 스위치
      const sws = L.switches || [];
      for (let i = 0; i < sws.length; i++) {
        const sw = sws[i];
        if ((a.x - sw.x) ** 2 + (a.y - sw.y) ** 2 < (SR + 2) ** 2) {
          a.alive = false; a.stuck = 's';
          for (const g of sw.g) run.gateOpen[g] = time + run.C.gates[g].dur;
          if (ev) ev.push({ type: 'switch', a, i, x: sw.x, y: sw.y });
          break;
        }
      }
      if (!a.alive) continue;
      // 등불
      const ns = L.lanterns || [];
      for (let i = 0; i < ns.length; i++) {
        const n = ns[i];
        if (run.lit[i]) continue;
        if ((a.x - n.x) ** 2 + (a.y - n.y) ** 2 < (LR + 2) ** 2) {
          a.alive = false; a.stuck = 'l'; a.ang = Math.atan2(a.vy, a.vx);
          run.lit[i] = true;
          boom(run, i, time, ev);
          break;
        }
      }
      if (!a.alive) continue;
      // 정령
      for (let i = 0; i < L.targets.length; i++) {
        const tg = L.targets[i];
        if (run.hit[i]) continue;
        const [tx, ty] = tpos(tg, time);
        const ddx = a.x - tx, ddy = a.y - ty;
        if (ddx * ddx + ddy * ddy < (TR + 2) ** 2) {
          if (tg.avoid) {
            run.hit[i] = true; run.failed = true; a.alive = false; a.stuck = 'o'; a.ang = Math.atan2(a.vy, a.vx);
            if (ev) ev.push({ type: 'oops', a, i, x: tx, y: ty });
            break;
          }
          if (tg.shield !== undefined) {
            const phi = Math.atan2(ddy, ddx), diff = Math.abs(((phi - tg.shield * D2R) % (2 * Math.PI) + 3 * Math.PI) % (2 * Math.PI) - Math.PI);
            if (diff < 75 * D2R) {
              const l = Math.hypot(ddx, ddy) || 1, nx = ddx / l, ny = ddy / l, vd = a.vx * nx + a.vy * ny;
              if (vd < 0) { a.vx -= 2 * vd * nx; a.vy -= 2 * vd * ny; a.b++; a.x = tx + nx * (TR + 3); a.y = ty + ny * (TR + 3); if (ev) ev.push({ type: 'shield', a, i, x: a.x, y: a.y, b: a.b }); }
              continue;
            }
          }
          run.hit[i] = true; a.hits++;
          if (ev) ev.push({ type: 'hit', a, i, x: tx, y: ty, b: a.b, multi: a.hits });
        }
      }
      a.age += DT;
      if (a.age > LIFE) { a.alive = false; if (ev) ev.push({ type: 'fizzle', a, x: a.x, y: a.y }); }
    }
    if (run.spawned.length) { for (const a of run.spawned) { run.arrows.push(a); if (ev) ev.push({ type: 'spawn', a }); } run.spawned = []; }
    run.step++;
    if (!run.won && !run.failed && L.targets.every((t, i) => t.avoid || run.hit[i])) { run.won = true; if (ev) ev.push({ type: 'win' }); }
  }

  const done = run => (run.failed && run.arrows.every(a => !a.alive)) || (run.shots.every(s => s.launched) && run.arrows.every(a => !a.alive) && !run.held.length && !run.booms.length);

  // 조준선: 현재 상태 기준 반사 경로 (포털 통과, 프리즘에서 멈춤)
  function ray(run, ang, maxB, maxLen, pierce) {
    const L = run.L, time = run.step * DT;
    let x = L.bow[0], y = L.bow[1], vx = Math.cos(ang), vy = Math.sin(ang);
    const paths = [[[x, y]]];
    let pts = paths[0], b = 0, end = 'open', jumps = 0;
    while (b <= maxB && jumps < 4) {
      const reach = 900;
      const h = nearest(run, time, x, y, vx * reach, vy * reach, pierce, true);
      if (!h) { pts.push([x + vx * reach, y + vy * reach]); break; }
      const d = reach * h.t;
      if (b === maxB && maxLen && d > maxLen && h.k !== 'p') { pts.push([x + vx * maxLen, y + vy * maxLen]); end = 'cut'; break; }
      x += vx * d; y += vy * d; pts.push([x, y]);
      if (h.k === 'p') {
        const p = L.portals[h.i], to = h.end === 'a' ? p.b : p.a;
        x = to[0] + vx * (PR + 2); y = to[1] + vy * (PR + 2); pts = [[x, y]]; paths.push(pts); jumps++; continue;
      }
      if (h.k === 'r') {
        const m = L.mirrors[h.i], a2 = run.mirrors[h.i] * 45 * D2R;
        vx = Math.cos(a2); vy = Math.sin(a2); x = m.x + vx * (RR + 4); y = m.y + vy * (RR + 4); pts = [[x, y]]; paths.push(pts); jumps++; continue;
      }
      if (h.k === 'x') { end = 'x'; break; }
      if (h.k === 'c' && h.soft) { end = 'c'; break; }
      if (h.k !== 'w' && h.k !== 'c') { end = h.k; break; }
      let nx = h.nx, ny = h.ny;
      if (nx * vx + ny * vy > 0) { nx = -nx; ny = -ny; }
      const vd = vx * nx + vy * ny; vx -= 2 * vd * nx; vy -= 2 * vd * ny;
      x += nx * 0.05; y += ny * 0.05;
      b++;
    }
    return { paths, end };
  }

  function simulate(L, shots, mirrors, maxSteps = 2600) {
    const run = newRun(L, shots, mirrors);
    while (run.step < maxSteps) {
      step(run, null);
      if (run.won || done(run)) return run;
    }
    return run;
  }

  return { DT, SPEED, TR, SR, PR, XR, RR, LR, BR, RHOLD, CHAIN, F, D2R, K, R, N, SP, M, T, B, S, U, P, X, MOSS, LEVELS, compile, newRun, step, done, ray, tpos, simulate, defaultMirrors, mirrorSeg };
})();
if (typeof module !== 'undefined') module.exports = SIM;
