// UI rendering for the Kargom Nerede landing/tracking site.
// All dynamic content is escaped before insertion (XSS safe).

import { getDownloadUrl } from './config.js';

const STATUS_LABELS = {
  CREATED: 'Oluşturuldu',
  PENDING: 'Bilgi Alındı',
  INFO_RECEIVED: 'Bilgi Alındı',
  IN_TRANSIT: 'Yolda',
  ARRIVED_AT_FACILITY: 'İşleme Merkezinde',
  OUT_FOR_DELIVERY: 'Dağıtıma Çıktı',
  DELIVERED: 'Teslim Edildi',
  EXCEPTION: 'Sorun Yaşandı',
  RETURNED: 'İade Edildi',
  EXPIRED: 'Süresi Doldu',
};

const STATUS_CLASSES = {
  DELIVERED: 'status-ok',
  OUT_FOR_DELIVERY: 'status-warn',
  IN_TRANSIT: 'status-info',
  ARRIVED_AT_FACILITY: 'status-info',
  CREATED: 'status-neutral',
  PENDING: 'status-neutral',
  INFO_RECEIVED: 'status-neutral',
  EXCEPTION: 'status-err',
  RETURNED: 'status-err',
  EXPIRED: 'status-err',
};

export function escapeHtml(value) {
  if (value === null || value === undefined) return '';
  const div = document.createElement('div');
  div.textContent = String(value);
  return div.innerHTML;
}

function formatDate(value, withTime = false) {
  if (!value) return '—';
  try {
    const date = new Date(value);
      if (Number.isNaN(date.getTime())) return String(value);
    return withTime
      ? date.toLocaleString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
      : date.toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' });
  } catch {
    return String(value);
  }
}

function statusLabel(status) {
  return STATUS_LABELS[status] || status || 'Bilinmiyor';
}

function statusClass(status) {
  return STATUS_CLASSES[status] || 'status-neutral';
}

/* ------------------------------- page ------------------------------- */

export function renderApp({ config, isLoading, error, carriers, onRetry, onTrack }) {
  const app = document.getElementById('app');

  if (isLoading) {
    app.innerHTML = `
      <div class="loading-screen">
        <div class="loading-spinner"></div>
        <p>Yükleniyor...</p>
      </div>`;
    return;
  }

  if (error) {
    app.innerHTML = `
      <div class="error-screen">
        <div class="error-icon">⚠️</div>
        <h2>Bir Hata Oluştu</h2>
        <p>${escapeHtml(error)}</p>
        <button id="retry-btn" class="btn btn-primary">Tekrar Dene</button>
      </div>`;
    document.getElementById('retry-btn')?.addEventListener('click', onRetry);
    return;
  }

  app.innerHTML = getAppHTML(config, carriers);

  document.getElementById('download-btn')?.addEventListener('click', handleDownload);
  document.getElementById('tracking-form')?.addEventListener('submit', (event) => {
    event.preventDefault();
    const number = document.getElementById('tracking-number').value.trim();
    const carrierCode = document.getElementById('carrier-select').value;
    if (number.length < 5) {
      updateTrackingResult(trackingErrorHTML('Takip numarası en az 5 karakter olmalı.'));
      return;
    }
    if (number.length > 50) {
      updateTrackingResult(trackingErrorHTML('Takip numarası en fazla 50 karakter olabilir.'));
      return;
    }
    onTrack(number, carrierCode || null);
  });
}

function carrierOptions(carriers, selected = '') {
  const list = Array.isArray(carriers) && carriers.length > 0 ? carriers : [];
  return list
    .map((c) => {
      const isSelected = c.code === selected ? ' selected' : '';
      return `<option value="${escapeHtml(c.code)}"${isSelected}>${escapeHtml(c.name)}</option>`;
    })
    .join('');
}

function getAppHTML(config, carriers) {
  const downloadUrl = getDownloadUrl(config);
  const latestVersion = config?.latestVersion || '1.0.0';
  const updatedAt = config?.updatedAt ? formatDate(config.updatedAt) : '—';
  const year = new Date().getFullYear();

  return `
    <header class="header">
      <div class="container header-inner">
        <div class="logo">
          <svg class="logo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
            <polyline points="17 8 12 3 7 8"/>
            <line x1="12" y1="3" x2="12" y2="15"/>
          </svg>
          <span class="logo-text">Kargom Nerede</span>
        </div>
        <nav class="nav" aria-label="Ana menü">
          <a href="#takip">Takip</a>
          <a href="#indir">İndir</a>
          <a href="#ozellikler">Özellikler</a>
        </nav>
      </div>
    </header>

    <main class="main">
      <div class="container">
        <section class="hero" id="takip">
          <h1 class="hero-title">Kargon nerede?</h1>
          <p class="hero-subtitle">Takip numaranızı girin, kargonuzun anlık durumunu gerçek zamanlı görün.</p>

          <div class="track-card">
            <form id="tracking-form" class="track-form" autocomplete="off" novalidate>
              <div class="track-row">
                <input
                  id="tracking-number"
                  class="track-input"
                  type="text"
                  inputmode="latin"
                  maxlength="50"
                  minlength="5"
                  placeholder="Takip numarası (örn. AR12345678901)"
                  aria-label="Takip numarası"
                  required
                >
                <button id="track-submit" class="btn btn-primary track-submit" type="submit">
                  <span class="track-submit-label">Kargoyu Bul</span>
                </button>
              </div>
              <div class="track-row">
                <select id="carrier-select" class="track-select" aria-label="Kargo firması seçimi">
                  <option value="">Kargo firması — Otomatik algıla</option>
                  ${carrierOptions(carriers)}
                </select>
              </div>
              <p class="track-hint">Kargo firması otomatik algılanır; algılanamazsa elle seçebilirsiniz.</p>
            </form>

            <div id="tracking-result" class="tracking-result" aria-live="polite"></div>
          </div>
        </section>

        <section class="download-section" id="indir">
          <div class="download-card">
            <div class="download-info">
              <h2 class="download-title">Kargom Nerede'yi İndir</h2>
              <p class="download-description">Android uygulamasıyla kargolarınızı her yerden takip edin.</p>

              <div class="version-badges">
                <span class="version-badge">
                  <svg class="badge-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="16 18 22 12 16 6"/>
                    <polyline points="8 6 2 12 8 18"/>
                  </svg>
                  <span>Son sürüm: <strong>${escapeHtml(latestVersion)}</strong></span>
                </span>
                <span class="version-badge">
                  <svg class="badge-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="5" y="2" width="14" height="20" rx="2"/>
                    <line x1="10" y1="18" x2="14" y2="18"/>
                  </svg>
                  <span>Android APK</span>
                </span>
                <span class="version-badge">
                  <svg class="badge-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2"/>
                    <line x1="16" y1="2" x2="16" y2="6"/>
                    <line x1="8" y1="2" x2="8" y2="6"/>
                    <line x1="3" y1="10" x2="21" y2="10"/>
                  </svg>
                  <span>Güncelleme: <strong>${escapeHtml(updatedAt)}</strong></span>
                </span>
              </div>

              <button id="download-btn" class="btn btn-primary btn-large" data-url="${escapeHtml(downloadUrl)}">
                <svg class="btn-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                  <polyline points="7 10 12 15 17 10"/>
                  <line x1="12" y1="15" x2="12" y2="3"/>
                </svg>
                <span>APK'yı İndir</span>
              </button>

              <p class="download-note">Dosya boyutu: ~59 MB • Android 5.0+ gerektirir</p>
            </div>
          </div>
        </section>

        <section class="features-section" id="ozellikler">
          <h2 class="section-title">Neden Kargom Nerede?</h2>
          <div class="features-grid">
            <div class="feature-card">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"/>
                  <polyline points="12 6 12 12 16 14"/>
                </svg>
              </div>
              <h3>Anlık Takip</h3>
              <p>Tüm kargolarınızı tek ekrandan, gerçek zamanlı olarak takip edin.</p>
            </div>
            <div class="feature-card">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                  <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
              </div>
              <h3>Akıllı Bildirimler</h3>
              <p>Kargonuz hareket ettiğinde, dağıtıma çıktığında veya teslim edildiğinde anında haberdar olun.</p>
            </div>
            <div class="feature-card">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
                </svg>
              </div>
              <h3>Otomatik Kargo Firması Algılama</h3>
              <p>Takip numarasını girin, hangi kargo firmasına ait olduğunu otomatik algılayalım.</p>
            </div>
            <div class="feature-card">
              <div class="feature-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="2" y="3" width="20" height="14" rx="2"/>
                  <path d="M8 21h8"/>
                  <path d="M12 17v4"/>
                </svg>
              </div>
              <h3>Detaylı Hareket Geçmişi</h3>
              <p>Kargonuzun tüm hareketlerini zaman çizelgesi olarak görüntüleyin.</p>
            </div>
          </div>
        </section>
      </div>
    </main>

    <footer class="footer">
      <div class="container">
        <p>&copy; ${year} Kargom Nerede. Tüm hakları saklıdır.</p>
        <div class="footer-links">
          <a href="#takip">Takip</a>
          <a href="#indir">İndir</a>
          <a href="#ozellikler">Özellikler</a>
        </div>
      </div>
    </footer>`;
}

/* --------------------------- tracking states --------------------------- */

export function updateTrackingResult(html, actions = {}) {
  const el = document.getElementById('tracking-result');
  if (!el) return;
  el.innerHTML = html;

  const retry = document.getElementById('retry-btn');
  if (retry && actions.retry) retry.addEventListener('click', actions.retry);

  const pick = document.getElementById('carrier-pick-btn');
  if (pick && actions.pick) {
    pick.addEventListener('click', () => {
      const select = document.getElementById('carrier-pick');
      if (select && select.value) actions.pick(select.value);
    });
  }
}

export function trackingLoadingHTML() {
  return `
    <div class="track-loading">
      <div class="spinner-small" aria-hidden="true"></div>
      <p>Kargo bilgileri alınıyor...</p>
    </div>`;
}

export function trackingErrorHTML(message) {
  return `
    <div class="track-error" role="alert">
      <p>${escapeHtml(message)}</p>
      <button id="retry-btn" class="btn btn-primary btn-sm" type="button">Tekrar Dene</button>
    </div>`;
}

export function trackingCarrierRequiredHTML({ carriers, candidates = [], notice }) {
  const candidateSet = new Set(candidates);
  const ordered = [];
  const rest = [];
  for (const c of carriers) {
    (candidateSet.has(c.code) ? ordered : rest).push(c);
  }
  const options = ordered
    .map((c) => `<option value="${escapeHtml(c.code)}">${escapeHtml(c.name)} (önerilen)</option>`)
    .join('');
  const restOptions = rest
    .map((c) => `<option value="${escapeHtml(c.code)}">${escapeHtml(c.name)}</option>`)
    .join('');

  return `
    <div class="track-notice" role="status">
      <p>${escapeHtml(notice)}</p>
      <div class="carrier-pick">
        <select id="carrier-pick" class="track-select" aria-label="Kargo firması seçin">
          <option value="" disabled selected>Kargo firması seçin</option>
          ${options}
          ${restOptions}
        </select>
        <button id="carrier-pick-btn" class="btn btn-primary btn-sm" type="button">Seç ve Takip Et</button>
      </div>
    </div>`;
}

export function trackingSuccessHTML(result) {
  const carrierName = result?.carrierName || result?.carrierCode || 'Kargo firması';
  const number = result?.trackingNumber || '';
  const status = result?.status || '';
  const statusDesc = result?.statusDescription || '';
  const lastUpdate = result?.lastUpdate || '';
  const location = result?.currentLocation || '';
  const events = Array.isArray(result?.events) ? result.events : [];

  const descLine =
    statusDesc && statusDesc !== statusLabel(status)
      ? `<p class="result-desc">${escapeHtml(statusDesc)}</p>`
      : '';

  const timeline =
    events.length > 0
      ? `<h4 class="timeline-title">Hareketler</h4>
         <ol class="timeline">
           ${sortEventsNewestFirst(events)
             .map((e) => {
               const evStatus = e?.status || '';
               return `
             <li class="timeline-item">
               <span class="timeline-dot ${statusClass(evStatus)}" aria-hidden="true"></span>
               <div class="timeline-body">
                 <div class="timeline-meta">
                   <time>${escapeHtml(formatDate(e?.timestamp, true))}</time>
                   <span class="timeline-status">${escapeHtml(statusLabel(evStatus))}</span>
                 </div>
                 ${e?.description ? `<p class="timeline-desc">${escapeHtml(e.description)}</p>` : ''}
                 ${e?.location ? `<span class="timeline-location">${escapeHtml(e.location)}</span>` : ''}
               </div>
             </li>`;
             })
             .join('')}
         </ol>`
      : `<div class="empty-state">
           <p>Henüz hareket bilgisi bulunmuyor. Kargo şubeye ulaştığında burada görünecek.</p>
         </div>`;

  return `
    <div class="result-card">
      <div class="result-top">
        <div class="result-id">
          <span class="result-carrier">${escapeHtml(carrierName)}</span>
          <span class="result-number">${escapeHtml(number)}</span>
        </div>
        <span class="status-badge ${statusClass(status)}">${escapeHtml(statusLabel(status))}</span>
      </div>
      <div class="result-meta">
        <span>Son güncelleme: ${escapeHtml(formatDate(lastUpdate, true))}</span>
        ${location ? `<span class="result-location">${escapeHtml(location)}</span>` : ''}
      </div>
      ${descLine}
      ${timeline}
    </div>`;
}

function sortEventsNewestFirst(events) {
  const copy = [...events];
  const first = Date.parse(copy[0]?.timestamp);
  const last = Date.parse(copy[copy.length - 1]?.timestamp);
  if (!Number.isNaN(first) && !Number.isNaN(last) && first < last) {
    copy.reverse();
  }
  return copy;
}

export function setBusy(busy) {
  const btn = document.getElementById('track-submit');
  const label = btn?.querySelector('.track-submit-label');
  if (!btn || !label) return;
  btn.disabled = busy;
  btn.classList.toggle('is-busy', busy);
  label.textContent = busy ? 'Lütfen bekleyin...' : 'Kargoyu Bul';
}

/* ------------------------------ download ------------------------------ */

function handleDownload(event) {
  const btn = event.currentTarget;
  const url = btn.dataset.url;
  if (!url) {
    alert('İndirme bağlantısı bulunamadı.');
    return;
  }

  if (!url.startsWith('http')) {
    fetch(url, { method: 'HEAD' })
      .then((res) => {
        if (res.ok) triggerDownload(url);
        else alert('APK dosyası henüz yayınlanmadı. Lütfen daha sonra tekrar deneyin.');
      })
      .catch(() => {
        alert('APK dosyası kontrol edilemedi. Lütfen daha sonra tekrar deneyin.');
      });
  } else {
    triggerDownload(url);
  }
}

function triggerDownload(url) {
  const a = document.createElement('a');
  a.href = url;
  a.download = 'KargomNerede.apk';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}
