// 시계 앱(Timetable.mc)의 파서와 같은 규칙을 구현한다.
// 여기와 시계가 다르게 동작하면 "페이지에선 되는데 시계에선 안 되는" 상황이 생긴다.

const DAYS = [
  { key: 'Mon', ko: '월' }, { key: 'Tue', ko: '화' }, { key: 'Wed', ko: '수' },
  { key: 'Thu', ko: '목' }, { key: 'Fri', ko: '금' }, { key: 'Sat', ko: '토' },
  { key: 'Sun', ko: '일' },
];

const state = {};
DAYS.forEach(d => state[d.key] = []);
let activeDay = 'Mon';

// --- 파싱 (Timetable.mc 와 같은 규칙) --------------------------------------

function normalizeTime(raw) {
  const t = String(raw).trim();
  let h = null, m = null;
  const c = t.indexOf(':');
  if (c >= 0) {
    h = parseInt(t.slice(0, c).trim(), 10);
    m = parseInt(t.slice(c + 1).trim(), 10);
  } else if (/^\d{4}$/.test(t)) {
    h = parseInt(t.slice(0, 2), 10); m = parseInt(t.slice(2), 10);
  } else if (/^\d{3}$/.test(t)) {
    h = parseInt(t.slice(0, 1), 10); m = parseInt(t.slice(1), 10);
  }
  if (!Number.isInteger(h) || !Number.isInteger(m)) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0');
}

const toMin = t => parseInt(t.slice(0, 2), 10) * 60 + parseInt(t.slice(3, 5), 10);

// 한 요일 문자열 -> 항목 배열. 못 읽는 항목은 사유와 함께 따로 모은다.
function parseDay(text) {
  const items = [], bad = [];
  String(text).split(';').forEach(chunk => {
    const raw = chunk.trim();
    if (!raw) return;
    const f = raw.split(',');
    if (f.length < 2) { bad.push([raw, '항목이 부족합니다']); return; }

    let t = f[0].split('-');
    if (t.length !== 2) t = f[0].split('~');
    if (t.length !== 2) { bad.push([raw, '시간 범위를 못 읽었습니다']); return; }

    const start = normalizeTime(t[0]), end = normalizeTime(t[1]);
    if (!start || !end) { bad.push([raw, '시간 형식이 잘못됐습니다']); return; }

    const title = f[1].trim();
    if (!title) { bad.push([raw, '과목명이 비었습니다']); return; }
    if (toMin(end) <= toMin(start)) { bad.push([raw, '종료가 시작보다 빠릅니다']); return; }

    items.push({ start, end, title, place: (f[2] || '').trim() });
  });
  items.sort((a, b) => toMin(a.start) - toMin(b.start));
  return { items, bad };
}

function serializeDay(items) {
  return items.map(b =>
    b.start + '-' + b.end + ',' + b.title + (b.place ? ',' + b.place : '')
  ).join(';');
}

// --- 화면에서 접히는 방식 (TimetableView.mc 와 같은 규칙) --------------------

function foldTitle(title, maxChars) {
  if (visualLen(title) <= maxChars) return [title];
  const len = [...title].length, middle = len / 2;
  let best = null, bestGap = len;
  const chars = [...title];
  for (let i = 1; i < len - 1; i++) {
    if (chars[i] !== ' ') continue;
    const gap = Math.abs(i - middle);
    if (gap < bestGap) { bestGap = gap; best = i; }
  }
  if (best !== null) {
    return [chars.slice(0, best).join(''), chars.slice(best + 1).join('')];
  }
  const half = Math.ceil(len / 2);
  return [chars.slice(0, half).join(''), chars.slice(half).join('')];
}

// 한글은 영문보다 두 배 넓다고 본다 (기기 폰트 근사)
function visualLen(s) {
  let n = 0;
  for (const ch of s) n += /[ᄀ-ᇿ㄰-㆏가-힯一-鿿]/.test(ch) ? 2 : 1;
  return n;
}

// --- 화면 그리기 ------------------------------------------------------------

const $ = id => document.getElementById(id);

function renderTabs() {
  $('tabs').innerHTML = DAYS.map(d =>
    `<button class="tab${d.key === activeDay ? ' on' : ''}" data-day="${d.key}">
       ${d.ko}<span class="cnt">${state[d.key].length || ''}</span>
     </button>`).join('');
}

function renderRows() {
  const items = state[activeDay];
  $('rows').innerHTML = items.length ? items.map((b, i) => `
    <div class="row" data-i="${i}">
      <input class="t" value="${esc(b.start)}" data-f="start" placeholder="09:00">
      <span class="dash">–</span>
      <input class="t" value="${esc(b.end)}" data-f="end" placeholder="09:50">
      <input class="n${b.title.includes('?') ? ' unsure' : ''}" value="${esc(b.title)}" data-f="title" placeholder="과목명">
      <input class="p${b.place.includes('?') ? ' unsure' : ''}" value="${esc(b.place)}" data-f="place" placeholder="강의실">
      <button class="del" title="삭제">×</button>
    </div>`).join('')
    : `<p class="empty">이 요일은 수업이 없습니다.</p>`;
  renderPreview();
  renderOutput();
}

const esc = s => String(s).replace(/[&<>"]/g, c =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// 시계에서 어떻게 보이는지 (근사)
function renderPreview() {
  const items = state[activeDay];
  const b = items[0];
  if (!b) { $('preview').innerHTML = `<div class="pv-done">오늘 일정 없음</div>`; return; }
  const lines = foldTitle(b.title, 9);
  $('preview').innerHTML = `
    <div class="pv-label">NEXT</div>
    <div class="pv-title${lines.length > 1 ? ' two' : ''}">${lines.map(esc).join('<br>')}</div>
    <div class="pv-time">${esc(b.start)} - ${esc(b.end)}</div>
    ${b.place ? `<div class="pv-place">${esc(b.place)}</div>` : ''}`;
}

const WEEK_MAX = 1200;   // settings.xml 의 maxLength 와 맞춘다

// 일주일 전체를 한 칸에 넣는 문자열. "월:...|화:..." 형태.
function serializeWeek() {
  return DAYS.map(d => {
    const v = serializeDay(state[d.key]);
    return v ? d.ko + ':' + v : null;
  }).filter(Boolean).join('|');
}

function renderOutput() {
  const week = serializeWeek();
  const over = week.length > WEEK_MAX;

  $('result').hidden = !week;
  $('week').textContent = week;
  $('len').textContent = week ? week.length + '자' : '';
  $('len').className = 'len' + (over ? ' bad' : '');
  $('copyWeek').dataset.v = week;

  $('out').innerHTML = DAYS.map(d => {
    const v = serializeDay(state[d.key]);
    return `<div class="orow">
      <div class="oday">${d.ko}</div>
      <code class="oval${v ? '' : ' none'}">${v ? esc(v) : '(비움)'}</code>
      <button class="copy" data-v="${esc(v)}" ${v ? '' : 'disabled'}>복사</button>
    </div>`;
  }).join('');

  const total = DAYS.reduce((n, d) => n + state[d.key].length, 0);
  $('editBadge').textContent = total ? `수업 ${total}개` : '';
}

function warn(msg, kind) {
  $('notice').className = 'notice ' + (kind || '');
  $('notice').innerHTML = msg;
}

// --- 붙여넣은 결과 읽기 -----------------------------------------------------

// "월: ..." 형태 7줄, 또는 한 요일 문자열만 들어와도 받는다.
function importText(raw) {
  // 챗봇은 두 가지 형태로 준다 — 줄바꿈으로 나뉜 확인용, 파이프로 이어진 복사용.
  // 어느 쪽을 붙여넣어도 읽혀야 한다. 파이프를 줄바꿈으로 바꾸면 같은 문제가 된다.
  // [확인용] [복사용] 같은 머리말은 요일 표시가 없어서 자연히 무시된다.
  const text = String(raw).replace(/\|/g, '\n');

  const map = {}; DAYS.forEach(d => map[d.ko] = d.key);
  let hit = 0, problems = [], firstBad = null;

  // 요일 표시가 있는 붙여넣기는 주 전체를 교체한다.
  // 있는 요일만 덮어쓰면, 고친 시간표를 다시 넣었을 때 빠진 요일이
  // 옛날 값으로 남는다. 사용자는 지운 줄 알지만 시계엔 그대로 뜬다.
  const parsed = {};
  text.split('\n').forEach(line => {
    const m = line.match(/^\s*([월화수목금토일])\s*(?:요일)?\s*[:：]\s*(.*)$/);
    if (!m) return;
    const key = map[m[1]];
    const { items, bad } = parseDay(m[2]);
    parsed[key] = items; hit++;
    if (bad.length && !firstBad) firstBad = key;
    if (!firstBad && items.some(unsure)) firstBad = key;
    bad.forEach(([raw, why]) => problems.push(`${m[1]}요일 · ${esc(raw)} — ${why}`));
  });
  if (hit) {
    DAYS.forEach(d => state[d.key] = parsed[d.key] || []);
  }
  if (!hit) {
    const { items, bad } = parseDay(text);
    if (items.length) {
      state[activeDay] = items; hit = 1;
      bad.forEach(([raw, why]) => problems.push(`${esc(raw)} — ${why}`));
    }
  }
  if (!hit) {
    warn('읽을 수 있는 시간표를 못 찾았습니다. 형식을 확인해주세요.', 'bad');
    renderTabs(); renderRows(); return;
  }

  const q = countUnsure();
  const trouble = problems.length || q;
  let msg = '';
  if (q) msg += `<b>확인이 필요한 항목 ${q}개</b>가 있습니다 (??? 표시).`;
  if (problems.length) {
    msg += (msg ? '<br>' : '') + `<span class="dim">건너뛴 항목</span><br>` + problems.join('<br>');
  }
  warn(msg, trouble ? 'warn' : '');

  // 문제가 있을 때만 확인 화면을 자동으로 연다.
  // 깨끗하게 읽혔으면 바로 복사해서 끝낼 수 있어야 한다.
  // 열 때는 문제가 있는 요일로 바로 보낸다 — 어디를 봐야 하는지 찾게 만들면 안 된다.
  if (trouble) {
    $('editor').open = true;
    if (firstBad) activeDay = firstBad;
  }

  renderTabs(); renderRows();
}

const unsure = b => b.title.includes('?') || b.place.includes('?');

function countUnsure() {
  let n = 0;
  DAYS.forEach(d => state[d.key].forEach(b => { if (unsure(b)) n++; }));
  return n;
}

// --- 이벤트 -----------------------------------------------------------------

document.addEventListener('click', e => {
  const tab = e.target.closest('.tab');
  if (tab) { activeDay = tab.dataset.day; renderTabs(); renderRows(); return; }

  if (e.target.classList.contains('del')) {
    const i = +e.target.closest('.row').dataset.i;
    state[activeDay].splice(i, 1); renderTabs(); renderRows(); return;
  }

  if (e.target.id === 'add') {
    state[activeDay].push({ start: '', end: '', title: '', place: '' });
    renderRows(); return;
  }

  if (e.target.classList.contains('copy')) { copyFrom(e.target); return; }

  if (e.target.id === 'copyPrompt') {
    navigator.clipboard.writeText($('prompt').textContent).then(() => {
      e.target.textContent = '복사됨';
      setTimeout(() => e.target.textContent = '프롬프트 복사', 1400);
    });
    return;
  }

  if (e.target.id === 'copyWeek') { copyFrom(e.target); return; }

  if (e.target.id === 'showPrompt') {
    e.preventDefault();
    const p = $('prompt');
    p.hidden = !p.hidden;
    e.target.textContent = p.hidden ? '프롬프트 보기' : '프롬프트 숨기기';
    return;
  }

  if (e.target.id === 'clear') {
    if (!confirm('입력한 시간표를 전부 지웁니다.')) return;
    DAYS.forEach(d => state[d.key] = []);
    warn('', ''); renderTabs(); renderRows(); return;
  }

  const step = e.target.closest('.stepbtn');
  if (step) {
    document.querySelectorAll('.stepbtn').forEach(b => b.classList.toggle('on', b === step));
    document.querySelectorAll('.pane').forEach(p =>
      p.classList.toggle('on', p.id === 'pane-' + step.dataset.pane));
  }
});

function copyFrom(btn) {
  navigator.clipboard.writeText(btn.dataset.v).then(() => {
    const old = btn.textContent;
    btn.textContent = '복사됨'; btn.classList.add('done');
    setTimeout(() => { btn.textContent = old; btn.classList.remove('done'); }, 1300);
  });
}

// 붙여넣으면 알아서 읽는다. 버튼을 한 번 더 누르게 할 이유가 없다.
let pasteTimer = null;
$('paste').addEventListener('input', () => {
  clearTimeout(pasteTimer);
  pasteTimer = setTimeout(() => {
    const v = $('paste').value.trim();
    if (v) importText(v);
  }, 350);
});

// 표에서 고치면 바로 반영. 시간은 입력이 끝났을 때만 정규화한다.
document.addEventListener('input', e => {
  const row = e.target.closest('.row');
  if (!row) return;
  const b = state[activeDay][+row.dataset.i];
  b[e.target.dataset.f] = e.target.value;
  renderPreview(); renderOutput();
});

document.addEventListener('change', e => {
  const row = e.target.closest('.row');
  if (!row) return;
  const f = e.target.dataset.f;
  if (f !== 'start' && f !== 'end') return;
  const b = state[activeDay][+row.dataset.i];
  const t = normalizeTime(e.target.value);
  if (t) { b[f] = t; e.target.value = t; e.target.classList.remove('err'); }
  else if (e.target.value.trim()) { e.target.classList.add('err'); }
  state[activeDay].sort((x, y) =>
    (x.start && y.start) ? toMin(x.start) - toMin(y.start) : 0);
  renderRows();
});

fetch('prompt.txt').then(r => r.text()).then(t => $('prompt').textContent = t.trim())
  .catch(() => $('prompt').textContent = '(프롬프트를 불러오지 못했습니다)');

renderTabs(); renderRows();
