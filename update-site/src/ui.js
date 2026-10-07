export function renderApp({ config, isLoading, error, onRetry }) {
  const app = document.getElementById('app');
  
  if (isLoading) {
    app.innerHTML = getLoadingHTML();
    return;
  }
  
  if (error) {
    app.innerHTML = getErrorHTML(error, onRetry);
    return;
  }
  
  app.innerHTML = getAppHTML(config);
  
  // Add event listeners
  const downloadBtn = document.getElementById('download-btn');
  if (downloadBtn) {
    downloadBtn.addEventListener('click', handleDownload);
  }
  
  const retryBtn = document.getElementById('retry-btn');
  if (retryBtn) {
    retryBtn.addEventListener('click', onRetry);
  }
}

function getLoadingHTML() {
  return `
    <div class="loading-screen">
      <div class="loading-spinner"></div>
      <p>Yükleniyor...</p>
    </div>
  `;
}

function getErrorHTML(error, onRetry) {
  return `
    <div class="error-screen">
      <div class="error-icon">⚠️</div>
      <h2>Bir Hata Oluştu</h2>
      <p>${escapeHtml(error)}</p>
      <button id="retry-btn" class="btn btn-primary">Tekrar Dene</button>
    </div>
  `;
}

function getAppHTML(config) {
  const downloadUrl = config?.downloadUrl || 'downloads/KargomNerede.apk';
  const latestVersion = config?.latestVersion || '1.0.0';
  const updatedAt = config?.updatedAt ? formatDate(config.updatedAt) : '—';
  
  return `
      <header class="header">
        <div class="container">
          <div class="logo">
            <svg class="logo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
              <polyline points="17 8 12 3 7 8"/>
              <line x1="12" y1="3" x2="12" y2="15"/>
            </svg>
            <span class="logo-text">Kargom Nerede</span>
          </div>
        </div>
      </header>

      <main class="main">
        <div class="container">
          <section class="hero">
            <h1 class="hero-title">Kargom Nerede</h1>
            <p class="hero-subtitle">Kargolarınızı tek bir yerden kolayca takip edin.</p>
            
            <div class="app-showcase">
              <div class="phone-mockup">
                <div class="phone-screen">
                  <div class="mockup-content">
                    <div class="mockup-header">
                      <div class="mockup-dots">
                        <span></span><span></span><span></span>
                      </div>
                    </div>
                    <div class="mockup-shipments">
                      <div class="mockup-shipment">
                        <div class="mockup-shipment-info">
                          <span class="mockup-carrier">Yurtiçi Kargo</span>
                          <span class="mockup-tracking">1234567890123</span>
                        </div>
                        <span class="mockup-status delivered">Teslim Edildi</span>
                      </div>
                      <div class="mockup-shipment">
                        <div class="mockup-shipment-info">
                          <span class="mockup-carrier">MNG Kargo</span>
                          <span class="mockup-tracking">9876543210</span>
                        </div>
                        <span class="mockup-status transit">Yolda</span>
                      </div>
                      <div class="mockup-shipment">
                        <div class="mockup-shipment-info">
                          <span class="mockup-carrier">Aras Kargo</span>
                          <span class="mockup-tracking">AR1234567890</span>
                        </div>
                        <span class="mockup-status out-for-delivery">Dağıtıma Çıktı</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <section class="download-section">
            <div class="download-card">
              <div class="download-info">
                <h2 class="download-title">Android Uygulaması</h2>
                <p class="download-description">En güncel sürümü indir</p>
                
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
                      <rect x="2" y="2" width="20" height="20" rx="2"/>
                      <line x1="6" y1="9" x2="18" y2="9"/>
                      <line x1="6" y1="15" x2="18" y2="15"/>
                    </svg>
                    <span>Android</span>
                  </span>
                  <span class="version-badge">
                    <svg class="badge-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
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
                
                <p class="download-note">Dosya boyutu: ~15 MB • Android 5.0+ gerektirir</p>
              </div>
            </div>
          </section>

          <section class="features-section">
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
                <h3>Otomatik Taşıyıcı Algılama</h3>
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
                <h3>Detaylı Geçmiş</h3>
                <p>Kargonuzun tüm hareketlerini zaman çizelgesi olarak görüntüleyin.</p>
              </div>
            </div>
          </section>
        </div>
      </main>

      <footer class="footer">
        <div class="container">
          <p>&copy; 2025 Kargom Nerede. Tüm hakları saklıdır.</p>
          <div class="footer-links">
            <a href="#" aria-label="Gizlilik Politikası">Gizlilik</a>
            <a href="#" aria-label="Kullanım Şartları">Şartlar</a>
            <a href="#" aria-label="İletişim">İletişim</a>
          </div>
        </div>
      </footer>
  `;
}

function handleDownload(event) {
  const btn = event.currentTarget;
  const url = btn.dataset.url;
  
  if (!url) {
    alert('İndirme bağlantısı bulunamadı.');
    return;
  }

  // If URL is relative, check if file exists before downloading
  if (!url.startsWith('http')) {
    fetch(url, { method: 'HEAD' })
      .then(res => {
        if (res.ok) {
          triggerDownload(url);
        } else {
          alert('APK dosyası henüz yayınlanmadı. Lütfen daha sonra tekrar deneyin.');
        }
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

function formatDate(dateString) {
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('tr-TR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  } catch {
    return '—';
  }
}

function escapeHtml(text) {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
