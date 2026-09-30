// Keep the prompt filename and the three visible steps together for each language.
const I18N = {
  ko: {
    html: 'ko', prompt: 'prompt.txt', title: '시간표를 시계에 넣기',
    step1: 'ChatGPT 또는 Claude 무료 버전이 필요합니다.',
    step2: '프롬프트를 복사해 AI 채팅방에 시간표 사진과 함께 보내세요.',
    step3: '받은 답변을 Connect IQ 앱 → Next Class → 설정의 시간표 입력칸에 붙여넣고 저장하세요.',
    copyPrompt: '프롬프트 복사', copied: '프롬프트를 복사했습니다.',
    loadError: '프롬프트를 불러오지 못했습니다. 페이지를 새로고침하세요.',
    copyError: '자동 복사가 안 됩니다. 아래 내용을 직접 복사하세요.',
  },
  en: {
    html: 'en', prompt: 'prompt-en.txt', title: 'Put your timetable on your watch',
    step1: 'You need the free version of ChatGPT or Claude.',
    step2: 'Copy the prompt and send it with a photo of your timetable in an AI chat.',
    step3: 'Paste the reply into the timetable field in Connect IQ → Next Class → Settings, then save.',
    copyPrompt: 'Copy prompt', copied: 'Prompt copied.',
    loadError: 'Could not load the prompt. Refresh the page.',
    copyError: 'Automatic copy failed. Copy the text below instead.',
  },
  zh: {
    html: 'zh-Hans', prompt: 'prompt-zh.txt', title: '把课表放到手表上',
    step1: '需要免费版 ChatGPT 或 Claude。',
    step2: '复制提示词，连同课表照片一起发送到 AI 聊天中。',
    step3: '将回复粘贴到 Connect IQ → Next Class → 设置中的课表输入框，然后保存。',
    copyPrompt: '复制提示词', copied: '提示词已复制。',
    loadError: '无法加载提示词，请刷新页面。',
    copyError: '自动复制失败，请手动复制下方内容。',
  },
  ja: {
    html: 'ja', prompt: 'prompt-ja.txt', title: '時間割をウォッチに入れる',
    step1: '無料版の ChatGPT または Claude が必要です。',
    step2: 'プロンプトをコピーし、時間割の写真と一緒に AI チャットへ送ってください。',
    step3: '返答を Connect IQ → Next Class → 設定の時間割入力欄に貼り付けて保存してください。',
    copyPrompt: 'プロンプトをコピー', copied: 'プロンプトをコピーしました。',
    loadError: 'プロンプトを読み込めません。ページを再読み込みしてください。',
    copyError: '自動コピーできません。下の文章を直接コピーしてください。',
  },
  fr: {
    html: 'fr', prompt: 'prompt-fr.txt', title: 'Mettre votre emploi du temps sur la montre',
    step1: 'Il vous faut la version gratuite de ChatGPT ou Claude.',
    step2: 'Copiez le prompt et envoyez-le avec une photo de votre emploi du temps dans une conversation IA.',
    step3: 'Collez la réponse dans le champ d’emploi du temps de Connect IQ → Next Class → Paramètres, puis enregistrez.',
    copyPrompt: 'Copier le prompt', copied: 'Prompt copié.',
    loadError: 'Impossible de charger le prompt. Actualisez la page.',
    copyError: 'Copie automatique impossible. Copiez le texte ci-dessous.',
  },
  de: {
    html: 'de', prompt: 'prompt-de.txt', title: 'Stundenplan auf die Uhr übertragen',
    step1: 'Du brauchst die kostenlose Version von ChatGPT oder Claude.',
    step2: 'Kopiere den Prompt und sende ihn zusammen mit einem Foto deines Stundenplans in einem KI-Chat.',
    step3: 'Füge die Antwort in das Stundenplanfeld unter Connect IQ → Next Class → Einstellungen ein und speichere.',
    copyPrompt: 'Prompt kopieren', copied: 'Prompt kopiert.',
    loadError: 'Prompt konnte nicht geladen werden. Lade die Seite neu.',
    copyError: 'Automatisches Kopieren fehlgeschlagen. Kopiere den Text unten.',
  },
  es: {
    html: 'es', prompt: 'prompt-es.txt', title: 'Pon tu horario en el reloj',
    step1: 'Necesitas la versión gratuita de ChatGPT o Claude.',
    step2: 'Copia el prompt y envíalo con una foto de tu horario en un chat de IA.',
    step3: 'Pega la respuesta en el campo de horario de Connect IQ → Next Class → Configuración y guarda.',
    copyPrompt: 'Copiar prompt', copied: 'Prompt copiado.',
    loadError: 'No se pudo cargar el prompt. Actualiza la página.',
    copyError: 'No se pudo copiar automáticamente. Copia el texto de abajo.',
  },
  it: {
    html: 'it', prompt: 'prompt-it.txt', title: 'Metti l’orario sull’orologio',
    step1: 'Ti serve la versione gratuita di ChatGPT o Claude.',
    step2: 'Copia il prompt e invialo con una foto dell’orario in una chat AI.',
    step3: 'Incolla la risposta nel campo dell’orario in Connect IQ → Next Class → Impostazioni e salva.',
    copyPrompt: 'Copia prompt', copied: 'Prompt copiato.',
    loadError: 'Impossibile caricare il prompt. Ricarica la pagina.',
    copyError: 'Copia automatica non riuscita. Copia il testo qui sotto.',
  },
  pl: {
    html: 'pl', prompt: 'prompt-pl.txt', title: 'Przenieś plan zajęć na zegarek',
    step1: 'Potrzebujesz darmowej wersji ChatGPT lub Claude.',
    step2: 'Skopiuj instrukcję i wyślij ją ze zdjęciem planu zajęć na czacie AI.',
    step3: 'Wklej odpowiedź w polu planu zajęć w Connect IQ → Next Class → Ustawienia i zapisz.',
    copyPrompt: 'Kopiuj instrukcję', copied: 'Instrukcja skopiowana.',
    loadError: 'Nie udało się wczytać instrukcji. Odśwież stronę.',
    copyError: 'Automatyczne kopiowanie nie działa. Skopiuj tekst poniżej.',
  },
};

function pickLang() {
  try {
    const saved = localStorage.getItem('lang');
    if (saved && I18N[saved]) return saved;
  } catch (_) { /* Storage can be unavailable in private mode. */ }
  const browserLang = (navigator.language || '').toLowerCase().slice(0, 2);
  return I18N[browserLang] ? browserLang : 'en';
}
