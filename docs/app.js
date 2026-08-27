(() => {
  'use strict';

  const LS = {
    history: 'st_history',
    dayNumber: 'st_dayNumber',
    person: 'st_person',
    baseURL: 'st_baseURL',
    roomId: 'st_roomId',
  };

  function todayKey(d = new Date()) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  function loadHistory() {
    try {
      return JSON.parse(localStorage.getItem(LS.history)) || {};
    } catch {
      return {};
    }
  }

  const state = {
    history: loadHistory(),
    dayNumber: parseInt(localStorage.getItem(LS.dayNumber) || '0', 10),
    today: null,
    person: localStorage.getItem(LS.person) || 'husband',
    partner: null,
    partnerUpdatedAt: null,
    partnerError: null,
    myPushError: null,
  };

  function initToday() {
    const key = todayKey();
    if (state.history[key]) {
      state.today = state.history[key];
      if (state.dayNumber === 0) state.dayNumber = 1;
    } else {
      const keys = Object.keys(state.history).sort();
      const prevKey = keys[keys.length - 1];
      const prev = prevKey ? state.history[prevKey] : null;
      const newTarget = (prev ? prev.targetReps : 0) + 1;
      state.today = {
        targetReps: Math.max(newTarget, 1),
        completedReps: 0,
        targetCindySets: prev ? prev.targetCindySets : 4,
        completedCindySets: 0,
      };
      state.dayNumber = prev ? state.dayNumber + 1 : Math.max(state.dayNumber, 1);
      state.history[key] = state.today;
      localStorage.setItem(LS.dayNumber, String(state.dayNumber));
    }
    persistToday();
  }

  function persistToday() {
    state.history[todayKey()] = state.today;
    localStorage.setItem(LS.history, JSON.stringify(state.history));
  }

  function partnerOf(person) {
    return person === 'husband' ? 'wife' : 'husband';
  }

  function personLabel(person) {
    return person === 'husband' ? '老公' : '老婆';
  }

  function firebaseConfigured() {
    return !!localStorage.getItem(LS.baseURL) && !!localStorage.getItem(LS.roomId);
  }

  function personUrl(person) {
    const base = (localStorage.getItem(LS.baseURL) || '').trim().replace(/\/+$/, '');
    const room = encodeURIComponent((localStorage.getItem(LS.roomId) || '').trim());
    return `${base}/couples/${room}/${person}.json`;
  }

  async function pushMyProgress() {
    if (!firebaseConfigured()) return;
    const payload = {
      dayNumber: state.dayNumber,
      targetReps: state.today.targetReps,
      completedReps: state.today.completedReps,
      targetCindySets: state.today.targetCindySets,
      completedCindySets: state.today.completedCindySets,
      updatedAt: Date.now() / 1000,
    };
    try {
      const res = await fetch(personUrl(state.person), {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);
      state.myPushError = null;
    } catch (e) {
      state.myPushError = e.message || String(e);
    }
    render();
  }

  async function refreshPartner() {
    if (!firebaseConfigured()) return;
    try {
      const res = await fetch(personUrl(partnerOf(state.person)));
      if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);
      const data = await res.json();
      state.partner = data;
      state.partnerUpdatedAt = new Date();
      state.partnerError = null;
    } catch (e) {
      state.partnerError = e.message || String(e);
    }
    render();
  }

  function incrementStair() {
    state.today.completedReps += 1;
    persistToday();
    pushMyProgress();
    render();
  }
  function decrementStair() {
    if (state.today.completedReps <= 0) return;
    state.today.completedReps -= 1;
    persistToday();
    pushMyProgress();
    render();
  }
  function incrementCindy() {
    state.today.completedCindySets += 1;
    persistToday();
    pushMyProgress();
    render();
  }
  function decrementCindy() {
    if (state.today.completedCindySets <= 0) return;
    state.today.completedCindySets -= 1;
    persistToday();
    pushMyProgress();
    render();
  }

  function relativeTime(date) {
    if (!date) return '-';
    const seconds = Math.round((Date.now() - date.getTime()) / 1000);
    if (seconds < 10) return '剛剛';
    if (seconds < 60) return `${seconds} 秒前`;
    const minutes = Math.round(seconds / 60);
    if (minutes < 60) return `${minutes} 分鐘前`;
    const hours = Math.round(minutes / 60);
    return `${hours} 小時前`;
  }

  function render() {
    document.getElementById('dayTitle').textContent = `第 ${state.dayNumber} 天訓練`;
    document.getElementById('dateLine').textContent = new Date().toLocaleDateString('zh-TW', {
      year: 'numeric', month: 'long', day: 'numeric', weekday: 'short',
    });
    document.getElementById('configWarning').hidden = firebaseConfigured();
    document.getElementById('meLabel').textContent = personLabel(state.person);

    document.getElementById('stairCount').textContent = `${state.today.completedReps} / ${state.today.targetReps}`;
    document.getElementById('stairFill').style.width =
      `${state.today.targetReps > 0 ? Math.min(100, (state.today.completedReps / state.today.targetReps) * 100) : 0}%`;
    document.getElementById('stairMinus').disabled = state.today.completedReps <= 0;

    document.getElementById('cindyCount').textContent = `${state.today.completedCindySets} / ${state.today.targetCindySets}`;
    document.getElementById('cindyFill').style.width =
      `${state.today.targetCindySets > 0 ? Math.min(100, (state.today.completedCindySets / state.today.targetCindySets) * 100) : 0}%`;
    document.getElementById('cindyMinus').disabled = state.today.completedCindySets <= 0;

    const pushErrEl = document.getElementById('myPushError');
    if (state.myPushError) {
      pushErrEl.hidden = false;
      pushErrEl.textContent = `⚠️ 上傳失敗:${state.myPushError}`;
    } else {
      pushErrEl.hidden = true;
    }

    document.getElementById('partnerLabel').textContent = `${personLabel(partnerOf(state.person))}的進度`;

    const partnerContent = document.getElementById('partnerContent');
    if (state.partner) {
      const p = state.partner;
      const stairPct = p.targetReps > 0 ? Math.min(100, (p.completedReps / p.targetReps) * 100) : 0;
      const cindyPct = p.targetCindySets > 0 ? Math.min(100, (p.completedCindySets / p.targetCindySets) * 100) : 0;
      partnerContent.innerHTML = `
        <div class="partner-row">
          <div class="label-line"><span>爬樓梯</span><b>${p.completedReps} / ${p.targetReps}</b></div>
          <div class="bar"><div class="fill" style="width:${stairPct}%;background:var(--orange)"></div></div>
        </div>
        <div class="partner-row">
          <div class="label-line"><span>Cindy</span><b>${p.completedCindySets} / ${p.targetCindySets}</b></div>
          <div class="bar"><div class="fill" style="width:${cindyPct}%;background:var(--blue)"></div></div>
        </div>
        <div class="muted">第 ${p.dayNumber} 天 · 最後更新:${relativeTime(state.partnerUpdatedAt)}</div>
      `;
    } else if (firebaseConfigured()) {
      partnerContent.innerHTML = `<div class="muted">尚未取得對方的資料,下拉或稍後重新整理</div>`;
    } else {
      partnerContent.innerHTML = `<div class="muted">設定好 Firebase 同步後,這裡會顯示對方的進度</div>`;
    }

    const partnerErrEl = document.getElementById('partnerError');
    if (state.partnerError) {
      partnerErrEl.hidden = false;
      partnerErrEl.textContent = `⚠️ ${state.partnerError}`;
    } else {
      partnerErrEl.hidden = true;
    }
  }

  // ---- Settings sheet ----
  const settingsOverlay = document.getElementById('settingsOverlay');
  const baseURLInput = document.getElementById('baseURLInput');
  const roomIdInput = document.getElementById('roomIdInput');
  let settingsPersonDraft = state.person;

  function paintPersonButtons() {
    document.getElementById('personHusbandBtn').classList.toggle('active', settingsPersonDraft === 'husband');
    document.getElementById('personWifeBtn').classList.toggle('active', settingsPersonDraft === 'wife');
  }

  function openSettings() {
    baseURLInput.value = localStorage.getItem(LS.baseURL) || '';
    roomIdInput.value = localStorage.getItem(LS.roomId) || '';
    settingsPersonDraft = state.person;
    paintPersonButtons();
    document.getElementById('testResult').textContent = '';
    settingsOverlay.hidden = false;
  }

  document.getElementById('settingsBtn').addEventListener('click', openSettings);
  document.getElementById('settingsCancel').addEventListener('click', () => { settingsOverlay.hidden = true; });
  document.getElementById('personHusbandBtn').addEventListener('click', () => { settingsPersonDraft = 'husband'; paintPersonButtons(); });
  document.getElementById('personWifeBtn').addEventListener('click', () => { settingsPersonDraft = 'wife'; paintPersonButtons(); });

  function saveSettings() {
    localStorage.setItem(LS.baseURL, baseURLInput.value.trim());
    localStorage.setItem(LS.roomId, roomIdInput.value.trim());
    localStorage.setItem(LS.person, settingsPersonDraft);
    state.person = settingsPersonDraft;
  }

  document.getElementById('settingsSave').addEventListener('click', async () => {
    saveSettings();
    settingsOverlay.hidden = true;
    await pushMyProgress();
    await refreshPartner();
  });

  document.getElementById('testConnBtn').addEventListener('click', async () => {
    saveSettings();
    const resultEl = document.getElementById('testResult');
    resultEl.textContent = '測試中…';
    await pushMyProgress();
    if (state.myPushError) {
      resultEl.textContent = `❌ 上傳失敗:${state.myPushError}`;
    } else {
      resultEl.textContent = '✅ 已成功上傳我的進度到 Firebase';
    }
    await refreshPartner();
  });

  // ---- Edit today sheet ----
  const editOverlay = document.getElementById('editOverlay');
  let editDraft = null;

  const editFieldConfig = {
    dayNumber: { min: 1, max: 9999, labelId: 'dayNumberLabel', format: v => `第 ${v} 天` },
    targetReps: { min: 0, max: 200, labelId: 'targetRepsLabel', format: v => `${v} 趟` },
    completedReps: { min: 0, max: 200, labelId: 'completedRepsLabel', format: v => `${v} 趟` },
    targetCindySets: { min: 0, max: 50, labelId: 'targetCindyLabel', format: v => `${v} 組` },
    completedCindySets: { min: 0, max: 50, labelId: 'completedCindyLabel', format: v => `${v} 組` },
  };

  function paintEditDraft() {
    for (const [field, cfg] of Object.entries(editFieldConfig)) {
      document.getElementById(cfg.labelId).textContent = cfg.format(editDraft[field]);
    }
  }

  function openEdit() {
    editDraft = {
      dayNumber: state.dayNumber,
      targetReps: state.today.targetReps,
      completedReps: state.today.completedReps,
      targetCindySets: state.today.targetCindySets,
      completedCindySets: state.today.completedCindySets,
    };
    paintEditDraft();
    editOverlay.hidden = false;
  }

  document.getElementById('editBtn').addEventListener('click', openEdit);
  document.getElementById('editCancel').addEventListener('click', () => { editOverlay.hidden = true; });

  editOverlay.querySelectorAll('button[data-field]').forEach(btn => {
    btn.addEventListener('click', () => {
      const field = btn.dataset.field;
      const delta = parseInt(btn.dataset.delta, 10);
      const cfg = editFieldConfig[field];
      editDraft[field] = Math.min(cfg.max, Math.max(cfg.min, editDraft[field] + delta));
      paintEditDraft();
    });
  });

  document.getElementById('editSave').addEventListener('click', async () => {
    state.dayNumber = editDraft.dayNumber;
    state.today = {
      targetReps: editDraft.targetReps,
      completedReps: editDraft.completedReps,
      targetCindySets: editDraft.targetCindySets,
      completedCindySets: editDraft.completedCindySets,
    };
    localStorage.setItem(LS.dayNumber, String(state.dayNumber));
    persistToday();
    editOverlay.hidden = true;
    render();
    await pushMyProgress();
  });

  // ---- Increment / decrement buttons ----
  document.getElementById('stairPlus').addEventListener('click', incrementStair);
  document.getElementById('stairMinus').addEventListener('click', decrementStair);
  document.getElementById('cindyPlus').addEventListener('click', incrementCindy);
  document.getElementById('cindyMinus').addEventListener('click', decrementCindy);

  // ---- Boot ----
  initToday();
  render();
  pushMyProgress();
  refreshPartner();

  setInterval(refreshPartner, 15000);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      initToday();
      render();
      refreshPartner();
    }
  });
})();
