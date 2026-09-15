// 시계 앱(Timetable.mc)의 파서와 같은 규칙을 구현한다.
// 여기와 시계가 다르게 동작하면 "페이지에선 되는데 시계에선 안 되는" 상황이 생긴다.

const DAY_KEYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const WEEK_MAX = 1200;                 // settings.xml 의 maxLength 와 맞춘다

let T = I18N[pickLang()];
const state = {};
DAY_KEYS.forEach(k => state[k] = []);
let activeDay = 'Mon';

// 붙여넣기에서 요일을 알아보는 표. 표시 언어와 무관하게 전부 받는다 —
// 사용자가 어떤 챗봇을 쓰든 어느 언어로 답하든 읽혀야 한다.
// Timetable.mc 의 MARKERS 와 같은 내용을 DAY_KEYS 순서(월요일부터)로 둔다.
const MARKERS = [
  ['월', 'mon', '月', '周一', '週一', '星期一', 'lun', 'mo', 'pon'],
  ['화', 'tue', '火', '周二', '週二', '星期二', 'mar', 'die', 'di', 'wto', 'wt'],
  ['수', 'wed', '水', '周三', '週三', '星期三', 'mer', 'mié', 'mie', 'mit', 'mi', 'śro', 'Śro', 'sro', 'śr', 'Śr', 'sr'],
  ['목', 'thu', '木', '周四', '週四', '星期四', 'jeu', 'jue', 'don', 'do', 'gio', 'czw'],
  ['금', 'fri', '金', '周五', '週五', '星期五', 'ven', 'vie', 'fre', 'fr', 'pią', 'pia', 'pt'],
  ['토', 'sat', '土', '周六', '週六', '星期六', 'sam', 'sáb', 'sab', 'sa', 'sob'],
  ['일', 'sun', '日', '周日', '週日', '星期日', '周天', '星期天', '週天', 'dim', 'dom', 'son', 'so', 'nie', 'nd'],
];

// 세 글자 이상은 앞부분만 맞아도 받는다 — "lun" 하나로 lundi 와 lunes 를 읽는다.
// 두 글자(독일어 Mo/Di)는 흔한 낱말과 부딪혀서 정확히 맞을 때만.
function dayIndexOf(token) {
  const t = String(token).trim().toLowerCase().replace(/(요일|曜日|曜)$/, '');
  for (let i = 0; i < MARKERS.length; i++) {
    for (const m of MARKERS[i]) {
      if (t === m) return i;
      if (m.length >= 3 && t.startsWith(m)) return i;
    }
  }
  return undefined;
}

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

function parseDay(text) {
  const items = [], bad = [];
  String(text).split(';').forEach(chunk => {
    const raw = chunk.trim();
    if (!raw) return;
    const f = raw.split(',');
    if (f.length < 2) { bad.push([raw, T.why.few]); return; }

    let t = f[0].split('-');
    if (t.length !== 2) t = f[0].split('~');
    if (t.length !== 2) { bad.push([raw, T.why.range]); return; }

    const start = normalizeTime(t[0]), end = normalizeTime(t[1]);
    if (!start || !end) { bad.push([raw, T.why.time]); return; }

    const title = f[1].trim();
    if (!title) { bad.push([raw, T.why.name]); return; }
    if (toMin(end) <= toMin(start)) { bad.push([raw, T.why.order]); return; }

    items.push({ start, end, title, place: (f[2] || '').trim() });
  });
  items.sort((a, b) => toMin(a.start) - toMin(b.start));
  return { items, bad };
}

const serializeDay = items => items.map(b =>
  b.start + '-' + b.end + ',' + b.title + (b.place ? ',' + b.place : '')).join(';');

// 출력 요일 표시는 표시 언어를 따른다. 앱이 읽는 건 한글 한 글자와 영문 세 글자다.
const serializeWeek = () => DAY_KEYS.map((k, i) => {
  const v = serializeDay(state[k]);
  return v ? T.days[i] + ':' + v : null;
}).filter(Boolean).join('|');

// --- 화면에서 접히는 방식 (TimetableView.mc 와 같은 규칙) --------------------

function visualLen(s) {
  let n = 0;
  for (const ch of s) n += /[ᄀ-ᇿ㄰-㆏가-힯一-鿿]/.test(ch) ? 2 : 1;
  return n;
}

function foldTitle(title, maxChars) {
  if (visualLen(title) <= maxChars) return [title];
  const chars = [...title], len = chars.length, middle = len / 2;
  let best = null, bestGap = len;
  for (let i = 1; i < len - 1; i++) {
    if (chars[i] !== ' ') continue;
    const gap = Math.abs(i - middle);
    if (gap < bestGap) { bestGap = gap; best = i; }
  }
  if (best !== null) return [chars.slice(0, best).join(''), chars.slice(best + 1).join('')];
  const half = Math.ceil(len / 2);
  return [chars.slice(0, half).join(''), chars.slice(half).join('')];
}

// --- 화면 그리기 ------------------------------------------------------------

const $ = id => document.getElementById(id);
const esc = s => String(s).replace(/[&<>"]/g, c =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const unsure = b => b.title.includes('?') || b.place.includes('?');

function renderTabs() {
  $('tabs').innerHTML = DAY_KEYS.map((k, i) =>
    `<button class="tab${k === activeDay ? ' on' : ''}" data-day="${k}">
       ${esc(T.labels[i])}<span class="cnt">${state[k].length || ''}</span>
     </button>`).join('');
}

function renderRows() {
  const items = state[activeDay];
  $('rows').innerHTML = items.length ? items.map((b, i) => `
    <div class="row" data-i="${i}">
      <input class="t" value="${esc(b.start)}" data-f="start" placeholder="${esc(T.ph.start)}">
      <span class="dash">–</span>
      <input class="t" value="${esc(b.end)}" data-f="end" placeholder="${esc(T.ph.end)}">
      <input class="n${b.title.includes('?') ? ' unsure' : ''}" value="${esc(b.title)}"
             data-f="title" placeholder="${esc(T.ph.name)}">
      <input class="p${b.place.includes('?') ? ' unsure' : ''}" value="${esc(b.place)}"
             data-f="place" placeholder="${esc(T.ph.place)}">
      <button class="del" title="×">×</button>
    </div>`).join('')
    : `<p class="empty">${esc(T.empty)}</p>`;
  renderPreview();
  renderOutput();
}

function renderPreview() {
  const b = state[activeDay][0];
  if (!b) { $('preview').innerHTML = `<div class="pv-done">${esc(T.empty)}</div>`; return; }
  const lines = foldTitle(b.title, 9);
  $('preview').innerHTML = `
    <div class="pv-label">NEXT</div>
    <div class="pv-title${lines.length > 1 ? ' two' : ''}">${lines.map(esc).join('<br>')}</div>
    <div class="pv-time">${esc(b.start)} - ${esc(b.end)}</div>
    ${b.place ? `<div class="pv-place">${esc(b.place)}</div>` : ''}`;
}

function renderOutput() {
  const week = serializeWeek();
  $('result').hidden = !week;
  $('week').textContent = week;
  $('len').textContent = week ? T.chars(week.length) : '';
  $('len').className = 'len' + (week.length > WEEK_MAX ? ' bad' : '');
  $('copyWeek').dataset.v = week;

  $('out').innerHTML = DAY_KEYS.map((k, i) => {
    const v = serializeDay(state[k]);
    return `<div class="orow">
      <div class="oday">${esc(T.labels[i])}</div>
      <code class="oval${v ? '' : ' none'}">${v ? esc(v) : esc(T.none)}</code>
      <button class="copy" data-v="${esc(v)}" ${v ? '' : 'disabled'}>${esc(T.copy)}</button>
    </div>`;
  }).join('');

  const total = DAY_KEYS.reduce((n, k) => n + state[k].length, 0);
  $('editBadge').textContent = total ? T.classes(total) : '';
}

function warn(msg, kind) {
  $('notice').className = 'notice ' + (kind || '');
  $('notice').innerHTML = msg;
}

// --- 붙여넣은 결과 읽기 -----------------------------------------------------

function importText(raw) {
  // 챗봇은 파이프로 이은 한 줄을 주지만, 사람이 줄바꿈 형태를 붙여넣기도 한다.
  // 파이프를 줄바꿈으로 바꾸면 한 가지 경로로 처리된다.
  const text = String(raw).replace(/\|/g, '\n');
  let hit = 0, problems = [], firstBad = null;

  // 요일 표시가 있는 붙여넣기는 주 전체를 교체한다. 있는 요일만 덮어쓰면
  // 고친 시간표를 다시 넣었을 때 빠진 요일이 옛날 값으로 남는다.
  const parsed = {};
  text.split('\n').forEach(line => {
    // 요일 표시 자리는 넉넉히 본다 — "Donnerstag" "Miércoles" 처럼 긴 이름이 온다.
    const m = line.match(/^\s*([^:：]{1,12})\s*[:：]\s*(.*)$/);
    if (!m) return;
    const idx = dayIndexOf(m[1]);
    if (idx === undefined) return;
    const key = DAY_KEYS[idx];
    const { items, bad } = parseDay(m[2]);
    parsed[key] = items; hit++;
    if (bad.length && !firstBad) firstBad = key;
    if (!firstBad && items.some(unsure)) firstBad = key;
    bad.forEach(([r, why]) => problems.push(`${esc(T.labels[idx])} · ${esc(r)} — ${why}`));
  });
  if (hit) DAY_KEYS.forEach(k => state[k] = parsed[k] || []);

  if (!hit) {
    // 요일 표시가 없으면 지금 보고 있는 요일 하나로 본다
    const { items, bad } = parseDay(text);
    if (items.length) {
      state[activeDay] = items; hit = 1;
      bad.forEach(([r, why]) => problems.push(`${esc(r)} — ${why}`));
    }
  }
  if (!hit) { warn(T.noRead, 'bad'); renderTabs(); renderRows(); return; }

  const q = DAY_KEYS.reduce((n, k) => n + state[k].filter(unsure).length, 0);
  const trouble = problems.length || q;
  let msg = q ? T.unsure(q) : '';
  if (problems.length) {
    msg += (msg ? '<br>' : '') + `<span class="dim">${esc(T.skipped)}</span><br>` + problems.join('<br>');
  }
  warn(msg, trouble ? 'warn' : '');

  // 문제가 있을 때만 확인 화면을 열고, 문제가 있는 요일로 바로 보낸다.
  if (trouble) { $('editor').open = true; if (firstBad) activeDay = firstBad; }

  renderTabs(); renderRows();
}

// --- 언어 ------------------------------------------------------------------

function applyLang(code) {
  T = I18N[code];
  try { localStorage.setItem('lang', code); } catch (e) { /* 무시 */ }
  document.documentElement.lang = T.html;

  document.querySelectorAll('[data-t]').forEach(el => {
    const v = T[el.dataset.t];
    if (v !== undefined) el.innerHTML = v;
  });
  document.querySelectorAll('.lang').forEach(b =>
    b.classList.toggle('on', b.dataset.lang === code));
  $('paste').placeholder = T.placeholder;
  $('showPrompt').textContent = $('prompt').hidden ? T.showPrompt : T.hidePrompt;

  fetch(T.prompt).then(r => r.text()).then(t => $('prompt').textContent = t.trim())
    .catch(() => $('prompt').textContent = '');

  renderTabs(); renderRows();
}

// --- 이벤트 -----------------------------------------------------------------

function copyFrom(btn) {
  navigator.clipboard.writeText(btn.dataset.v || $('prompt').textContent).then(() => {
    const old = btn.textContent;
    btn.textContent = T.copied; btn.classList.add('done');
    setTimeout(() => { btn.textContent = old; btn.classList.remove('done'); }, 1300);
  });
}

document.addEventListener('click', e => {
  const lang = e.target.closest('.lang');
  if (lang) { applyLang(lang.dataset.lang); return; }

  const tab = e.target.closest('.tab');
  if (tab) { activeDay = tab.dataset.day; renderTabs(); renderRows(); return; }

  if (e.target.classList.contains('del')) {
    state[activeDay].splice(+e.target.closest('.row').dataset.i, 1);
    renderTabs(); renderRows(); return;
  }
  if (e.target.id === 'add') {
    state[activeDay].push({ start: '', end: '', title: '', place: '' });
    renderRows(); return;
  }
  if (e.target.classList.contains('copy') || e.target.id === 'copyWeek') { copyFrom(e.target); return; }
  if (e.target.id === 'copyPrompt') {
    navigator.clipboard.writeText($('prompt').textContent).then(() => {
      e.target.textContent = T.copied;
      setTimeout(() => e.target.textContent = T.copyPrompt, 1400);
    });
    return;
  }
  if (e.target.id === 'showPrompt') {
    e.preventDefault();
    const p = $('prompt');
    p.hidden = !p.hidden;
    e.target.textContent = p.hidden ? T.showPrompt : T.hidePrompt;
    return;
  }
  if (e.target.id === 'clear') {
    if (!confirm(T.clearAsk)) return;
    DAY_KEYS.forEach(k => state[k] = []);
    warn('', ''); renderTabs(); renderRows(); return;
  }
});

// 붙여넣으면 알아서 읽는다. 버튼을 한 번 더 누르게 할 이유가 없다.
let pasteTimer = null;
$('paste').addEventListener('input', () => {
  clearTimeout(pasteTimer);
  pasteTimer = setTimeout(() => {
    const v = $('paste').value.trim();
    if (v) importText(v);
  }, 350);
});

document.addEventListener('input', e => {
  const row = e.target.closest('.row');
  if (!row) return;
  state[activeDay][+row.dataset.i][e.target.dataset.f] = e.target.value;
  renderPreview(); renderOutput();
});

document.addEventListener('change', e => {
  const row = e.target.closest('.row');
  if (!row) return;
  const f = e.target.dataset.f;
  if (f !== 'start' && f !== 'end') return;
  const b = state[activeDay][+row.dataset.i];
  const t = normalizeTime(e.target.value);
  if (t) { b[f] = t; e.target.classList.remove('err'); }
  else if (e.target.value.trim()) { e.target.classList.add('err'); }
  state[activeDay].sort((x, y) => (x.start && y.start) ? toMin(x.start) - toMin(y.start) : 0);
  renderRows();
});

applyLang(pickLang());
