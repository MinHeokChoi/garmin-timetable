// 화면 문구. 앱(resources/, resources-eng/, resources-zhs/)과 같은 세 언어를 맞춘다.
//
// 요일은 두 가지가 따로 있다.
//   labels  화면에 보여줄 이름 — 그 언어로
//   days    출력 문자열에 넣을 표시 — 앱이 읽을 수 있는 것으로만
// 앱이 인식하는 건 한글 한 글자(월)와 영문 세 글자(Mon) 두 가지다.
// 중국어 "周一" 는 앱이 못 읽으므로 화면에만 쓰고 출력에는 영문을 쓴다.

const I18N = {
  ko: {
    html: 'ko', prompt: 'prompt.txt', marker: 'ko',
    days: ['월','화','수','목','금','토','일'],
    labels: ['월','화','수','목','금','토','일'],
    title: '시간표를 시계에 넣기',
    copyPrompt: '프롬프트 복사',
    lead1: '챗봇에 <b>시간표 사진과 함께</b> 붙여넣으면 한 줄이 나옵니다. ' +
           '그대로 Garmin Connect 에 넣어도 되고, 고칠 게 있으면 아래에 붙여넣으세요.',
    showPrompt: '프롬프트 보기', hidePrompt: '프롬프트 숨기기',
    placeholder: '월:09:00-09:50,운영체제,T0503|화:11:00-12:50,생물학,K502',
    where: 'Garmin Connect → Next Class → 설정 → 한 번에 입력',
    copy: '복사', copied: '복사됨',
    edit: '확인하고 고치기', add: '+ 수업 추가',
    cap: '시계에서 보이는 모습 (근사)',
    byday: '요일별로 나눠 넣기',
    bydayHint: '전체 칸이 길어서 안 들어갈 때만.',
    clear: '전부 지우기', clearAsk: '입력한 시간표를 전부 지웁니다.',
    foot1: '<b>과목명이 한글이면 시계 언어도 한국어여야 합니다.</b> 시계 → 설정 → 시스템 → 언어',
    foot2: '입력한 내용은 어디에도 전송되지 않습니다.',
    empty: '이 요일은 수업이 없습니다.',
    none: '(비움)', classes: n => `수업 ${n}개`, chars: n => `${n}자`,
    noRead: '읽을 수 있는 시간표를 못 찾았습니다. 형식을 확인해주세요.',
    unsure: n => `<b>확인이 필요한 항목 ${n}개</b>가 있습니다 (??? 표시).`,
    skipped: '건너뛴 항목',
    why: { few: '항목이 부족합니다', range: '시간 범위를 못 읽었습니다',
           time: '시간 형식이 잘못됐습니다', name: '과목명이 비었습니다',
           order: '종료가 시작보다 빠릅니다' },
    ph: { start: '09:00', end: '09:50', name: '과목명', place: '강의실' },
  },
  en: {
    html: 'en', prompt: 'prompt-en.txt', marker: 'en',
    days: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    labels: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    title: 'Put your timetable on your watch',
    copyPrompt: 'Copy prompt',
    lead1: 'Paste it into a chatbot <b>together with a photo of your timetable</b>. ' +
           'You get one line — paste it straight into Garmin Connect, or paste it below to edit.',
    showPrompt: 'Show prompt', hidePrompt: 'Hide prompt',
    placeholder: 'Mon:09:00-09:50,Calculus,A101|Tue:11:00-12:50,Biology,K502',
    where: 'Garmin Connect → Next Class → Settings → All week at once',
    copy: 'Copy', copied: 'Copied',
    edit: 'Check and edit', add: '+ Add class',
    cap: 'How it looks on the watch (approx.)',
    byday: 'Enter day by day',
    bydayHint: 'Only if the single field is too long.',
    clear: 'Clear all', clearAsk: 'This clears the whole timetable.',
    foot1: '<b>Class names show only if the watch language matches.</b> Watch → Settings → System → Language',
    foot2: 'Nothing you type is sent anywhere.',
    empty: 'No classes on this day.',
    none: '(empty)', classes: n => `${n} classes`, chars: n => `${n} chars`,
    noRead: 'Could not find a timetable here. Check the format.',
    unsure: n => `<b>${n} item(s) need checking</b> (marked ???).`,
    skipped: 'Skipped',
    why: { few: 'too few fields', range: 'could not read the time range',
           time: 'bad time format', name: 'class name is empty',
           order: 'end is before start' },
    ph: { start: '09:00', end: '09:50', name: 'Class name', place: 'Room' },
  },
  zh: {
    html: 'zh-Hans', prompt: 'prompt-zh.txt', marker: 'en',
    days: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
    labels: ['周一','周二','周三','周四','周五','周六','周日'],
    title: '把课表放到手表上',
    copyPrompt: '复制提示词',
    lead1: '把它和<b>课表照片一起</b>发给 AI 聊天机器人，会得到一行文字。' +
           '可以直接粘贴到 Garmin Connect，需要修改就粘贴到下面。',
    showPrompt: '查看提示词', hidePrompt: '隐藏提示词',
    placeholder: 'Mon:09:00-09:50,高等数学,A101|Tue:11:00-12:50,生物学,K502',
    where: 'Garmin Connect → Next Class → 设置 → 一次性输入（整周）',
    copy: '复制', copied: '已复制',
    edit: '检查和修改', add: '+ 添加课程',
    cap: '手表上的显示效果（近似）',
    byday: '按星期分别输入',
    bydayHint: '仅当整周那一栏太长放不下时使用。',
    clear: '全部清除', clearAsk: '将清除已输入的全部课表。',
    foot1: '<b>课程名要显示中文，手表语言也需设为中文。</b> 手表 → 设置 → 系统 → 语言',
    foot2: '输入的内容不会发送到任何地方。',
    empty: '这一天没有课。',
    none: '(空)', classes: n => `${n} 节课`, chars: n => `${n} 字`,
    noRead: '没有找到可以识别的课表，请检查格式。',
    unsure: n => `<b>有 ${n} 项需要确认</b>（标记为 ???）。`,
    skipped: '已跳过',
    why: { few: '字段不足', range: '无法识别时间范围',
           time: '时间格式有误', name: '课程名为空',
           order: '结束时间早于开始时间' },
    ph: { start: '09:00', end: '09:50', name: '课程名', place: '教室' },
  },
};

// 저장된 선택 > 브라우저 언어 > 영어
function pickLang() {
  try {
    const saved = localStorage.getItem('lang');
    if (saved && I18N[saved]) return saved;
  } catch (e) { /* 사생활 보호 모드 등 */ }
  const n = (navigator.language || '').toLowerCase();
  if (n.startsWith('ko')) return 'ko';
  if (n.startsWith('zh')) return 'zh';
  return 'en';
}
