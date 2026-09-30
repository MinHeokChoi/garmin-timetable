const langSelect = document.getElementById('langSelect');
const copyButton = document.getElementById('copyPrompt');
const status = document.getElementById('status');
const fallback = document.getElementById('promptFallback');

let promptText = '';
let promptRequest = 0;

async function applyLang(code) {
  const t = I18N[code] || I18N.en;
  const request = ++promptRequest;
  document.documentElement.lang = t.html;
  document.title = `Next Class — ${t.title}`;
  langSelect.value = code;
  document.querySelectorAll('[data-t]').forEach(el => {
    el.textContent = t[el.dataset.t];
  });
  status.textContent = '';
  fallback.hidden = true;
  promptText = '';
  copyButton.disabled = true;
  try { localStorage.setItem('lang', code); } catch (_) { /* Optional preference. */ }

  try {
    const response = await fetch(t.prompt);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const loaded = (await response.text()).trim();
    if (!loaded) throw new Error('Empty prompt');
    if (request !== promptRequest) return;
    promptText = loaded;
    copyButton.disabled = false;
  } catch (_) {
    if (request === promptRequest) status.textContent = t.loadError;
  }
}

langSelect.addEventListener('change', () => applyLang(langSelect.value));
copyButton.addEventListener('click', async () => {
  if (!promptText) return;
  const t = I18N[langSelect.value];
  try {
    await navigator.clipboard.writeText(promptText);
    status.textContent = t.copied;
    fallback.hidden = true;
  } catch (_) {
    status.textContent = t.copyError;
    fallback.value = promptText;
    fallback.hidden = false;
    fallback.focus();
    fallback.select();
  }
});

applyLang(pickLang());
