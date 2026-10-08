(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const r of document.querySelectorAll('link[rel="modulepreload"]'))a(r);new MutationObserver(r=>{for(const i of r)if(i.type==="childList")for(const l of i.addedNodes)l.tagName==="LINK"&&l.rel==="modulepreload"&&a(l)}).observe(document,{childList:!0,subtree:!0});function n(r){const i={};return r.integrity&&(i.integrity=r.integrity),r.referrerPolicy&&(i.referrerPolicy=r.referrerPolicy),r.crossOrigin==="use-credentials"?i.credentials="include":r.crossOrigin==="anonymous"?i.credentials="omit":i.credentials="same-origin",i}function a(r){if(r.ep)return;r.ep=!0;const i=n(r);fetch(r.href,i)}})();const C="modulepreload",_=function(e,t){return new URL(e,t).href},R={},N=function(t,n,a){let r=Promise.resolve();if(n&&n.length>0){const l=document.getElementsByTagName("link"),o=document.querySelector("meta[property=csp-nonce]"),d=(o==null?void 0:o.nonce)||(o==null?void 0:o.getAttribute("nonce"));r=Promise.allSettled(n.map(p=>{if(p=_(p,a),p in R)return;R[p]=!0;const s=p.endsWith(".css"),u=s?'[rel="stylesheet"]':"";if(!!a)for(let m=l.length-1;m>=0;m--){const v=l[m];if(v.href===p&&(!s||v.rel==="stylesheet"))return}else if(document.querySelector(`link[href="${p}"]${u}`))return;const g=document.createElement("link");if(g.rel=s?"stylesheet":C,s||(g.as="script"),g.crossOrigin="",g.href=p,d&&g.setAttribute("nonce",d),document.head.appendChild(g),s)return new Promise((m,v)=>{g.addEventListener("load",m),g.addEventListener("error",()=>v(new Error(`Unable to preload CSS for ${p}`)))})}))}function i(l){const o=new Event("vite:preloadError",{cancelable:!0});if(o.payload=l,window.dispatchEvent(o),!o.defaultPrevented)throw l}return r.then(l=>{for(const o of l||[])o.status==="rejected"&&i(o.reason);return t().catch(i)})};let y=null;async function $(){if(y)return y;const e="https://lfrrluxtrxhddznjuidx.supabase.co",t="sb_publishable_v4QG9BoSHK5EMv_5NF9TUw_at8SNPtF";if(e.includes("placeholder")||t.includes("placeholder"))return console.warn("[Supabase] Configuration missing or using placeholder. Running in offline mode."),null;try{const{createClient:a}=await N(async()=>{const{createClient:r}=await import("./index.B5W6PeoS.js");return{createClient:r}},[],import.meta.url);return y=a(e,t,{auth:{persistSession:!1}}),y}catch(a){return console.warn("[Supabase] Failed to initialize client:",a),null}}async function B(){const e=await $();if(!e)return console.warn("[Config] Supabase client unavailable, using default config"),h();try{const{data:t,error:n}=await e.from("app_config").select("*").eq("id","main").single();return n?(console.warn("[Config] Supabase query error:",n.message),h()):t?{minimumVersion:t.minimum_version,latestVersion:t.latest_version,downloadUrl:t.download_url,forceUpdate:t.force_update,updateMessage:t.update_message,updatedAt:t.updated_at}:(console.warn("[Config] App config not found in Supabase"),h())}catch(t){return console.warn("[Config] Fetch failed:",t),h()}}function h(){return{minimumVersion:"1.0.0",latestVersion:"1.0.0",downloadUrl:"downloads/KargomNerede.apk",forceUpdate:!1,updateMessage:"Yeni bir sürüm mevcut. Lütfen güncelleyin.",updatedAt:new Date().toISOString()}}function P(e){const t="./";return!e||!e.downloadUrl?`${t}downloads/KargomNerede.apk`:e.downloadUrl.startsWith("http")?e.downloadUrl:`${t}${e.downloadUrl.replace(/^\.?\/+/,"")}`}const O="https://api.kargomnerede.com/api/v1";function x(){if(typeof location<"u"&&location.search){const e=new URLSearchParams(location.search).get("api");if(e)return e.replace(/\/+$/,"")}return O}const K=x(),U=[{code:"yurtici",name:"Yurtiçi Kargo"},{code:"mng",name:"MNG Kargo"},{code:"aras",name:"Aras Kargo"},{code:"surat",name:"Sürat Kargo"},{code:"ptt",name:"PTT"},{code:"trendyol_express",name:"Trendyol Express"},{code:"hepsijet",name:"HepsiJet"},{code:"hepsiburada",name:"Hepsiburada Lojistik"},{code:"n11",name:"n11 Lojistik"},{code:"ups",name:"UPS"},{code:"fedex",name:"FedEx"},{code:"dhl",name:"DHL"},{code:"tnt",name:"TNT"},{code:"dpd",name:"DPD"},{code:"gls",name:"GLS"},{code:"hermes",name:"Hermes / Evri"},{code:"cargonet",name:"Cargonet"},{code:"kargomatik",name:"Kargomatik"},{code:"sendeo",name:"Sendeo"}];async function A(e,t={}){let n;try{n=await fetch(`${K}${e}`,{headers:{"Content-Type":"application/json"},...t})}catch{const i=new Error("network");throw i.kind="network",i}let a=null;try{a=await n.json()}catch{}if(!n.ok){const r=new Error("api-error");throw r.kind="api",r.status=n.status,r.code=a&&a.code?String(a.code):`HTTP_${n.status}`,r.serverMessage=a&&a.message?String(a.message):"",r}return a}async function z(){try{const e=await A("/tracking/carriers"),n=(Array.isArray(e==null?void 0:e.data)?e.data:[]).filter(a=>a&&a.code&&a.name);return n.length>0?n:null}catch{return null}}async function H(e){const t=await A("/tracking/detect-carrier",{method:"POST",body:JSON.stringify({trackingNumber:e})});return(t==null?void 0:t.data)??null}async function V(e,t){const n={trackingNumber:e};t&&(n.carrierCode=t);const a=await A("/tracking/track",{method:"POST",body:JSON.stringify(n)});return(a==null?void 0:a.data)??null}function L(e){if(!e||e.kind==="network")return"Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.";switch(e.code){case"PROVIDER_NOT_CONFIGURED":case"PROVIDER_UNAVAILABLE":case"PROVIDER_AUTH_FAILED":case"PROVIDER_ERROR":case"PROVIDER_UNREACHABLE":return"Kargo takip servisi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.";case"PROVIDER_RATE_LIMITED":return"Kargo takip servisi yoğunlukta. Birkaç dakika sonra tekrar deneyin.";case"CARRIER_DETECTION_FAILED":return"Kargo firması algılanamadı. Lütfen kargo firmasını seçip tekrar deneyin.";case"VALIDATION_ERROR":return"Geçerli bir takip numarası girin (5-50 karakter)."}return e.status===404?"Takip servisi bulunamadı. API adresi hatalı olabilir.":e.status&&e.status>=400&&e.status<500?"Girilen bilgiler geçerli değil. Takip numaranızı kontrol edip tekrar deneyin.":"Kargo bilgileri alınamadı. Lütfen tekrar deneyin."}function M(e){return!!e&&e.code==="CARRIER_DETECTION_FAILED"}function F(e){return!!e&&typeof e.code=="string"&&e.code.startsWith("PROVIDER_")}const j={CREATED:"Oluşturuldu",PENDING:"Bilgi Alındı",INFO_RECEIVED:"Bilgi Alındı",IN_TRANSIT:"Yolda",ARRIVED_AT_FACILITY:"İşleme Merkezinde",OUT_FOR_DELIVERY:"Dağıtıma Çıktı",DELIVERED:"Teslim Edildi",EXCEPTION:"Sorun Yaşandı",RETURNED:"İade Edildi",EXPIRED:"Süresi Doldu"},q={DELIVERED:"status-ok",OUT_FOR_DELIVERY:"status-warn",IN_TRANSIT:"status-info",ARRIVED_AT_FACILITY:"status-info",CREATED:"status-neutral",PENDING:"status-neutral",INFO_RECEIVED:"status-neutral",EXCEPTION:"status-err",RETURNED:"status-err",EXPIRED:"status-err"};function c(e){if(e==null)return"";const t=document.createElement("div");return t.textContent=String(e),t.innerHTML}function w(e,t=!1){if(!e)return"—";try{const n=new Date(e);return Number.isNaN(n.getTime())?String(e):t?n.toLocaleString("tr-TR",{day:"2-digit",month:"2-digit",year:"numeric",hour:"2-digit",minute:"2-digit"}):n.toLocaleDateString("tr-TR",{day:"numeric",month:"long",year:"numeric"})}catch{return String(e)}}function b(e){return j[e]||e||"Bilinmiyor"}function I(e){return q[e]||"status-neutral"}function G({config:e,isLoading:t,error:n,carriers:a,onRetry:r,onTrack:i}){var o,d,p;const l=document.getElementById("app");if(t){l.innerHTML=`
      <div class="loading-screen">
        <div class="loading-spinner"></div>
        <p>Yükleniyor...</p>
      </div>`;return}if(n){l.innerHTML=`
      <div class="error-screen">
        <div class="error-icon">⚠️</div>
        <h2>Bir Hata Oluştu</h2>
        <p>${c(n)}</p>
        <button id="retry-btn" class="btn btn-primary">Tekrar Dene</button>
      </div>`,(o=document.getElementById("retry-btn"))==null||o.addEventListener("click",r);return}l.innerHTML=W(e,a),(d=document.getElementById("download-btn"))==null||d.addEventListener("click",Z),(p=document.getElementById("tracking-form"))==null||p.addEventListener("submit",s=>{s.preventDefault();const u=document.getElementById("tracking-number").value.trim(),f=document.getElementById("carrier-select").value;if(u.length<5){k(T("Takip numarası en az 5 karakter olmalı."));return}if(u.length>50){k(T("Takip numarası en fazla 50 karakter olabilir."));return}i(u,f||null)})}function Y(e,t=""){return(Array.isArray(e)&&e.length>0?e:[]).map(a=>{const r=a.code===t?" selected":"";return`<option value="${c(a.code)}"${r}>${c(a.name)}</option>`}).join("")}function W(e,t){const n=P(e),a=(e==null?void 0:e.latestVersion)||"1.0.0",r=e!=null&&e.updatedAt?w(e.updatedAt):"—",i=new Date().getFullYear();return`
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
                  ${Y(t)}
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
                  <span>Son sürüm: <strong>${c(a)}</strong></span>
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
                  <span>Güncelleme: <strong>${c(r)}</strong></span>
                </span>
              </div>

              <button id="download-btn" class="btn btn-primary btn-large" data-url="${c(n)}">
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
        <p>&copy; ${i} Kargom Nerede. Tüm hakları saklıdır.</p>
        <div class="footer-links">
          <a href="#takip">Takip</a>
          <a href="#indir">İndir</a>
          <a href="#ozellikler">Özellikler</a>
        </div>
      </div>
    </footer>`}function k(e,t={}){const n=document.getElementById("tracking-result");if(!n)return;n.innerHTML=e;const a=document.getElementById("retry-btn");a&&t.retry&&a.addEventListener("click",t.retry);const r=document.getElementById("carrier-pick-btn");r&&t.pick&&r.addEventListener("click",()=>{const i=document.getElementById("carrier-pick");i&&i.value&&t.pick(i.value)})}function X(){return`
    <div class="track-loading">
      <div class="spinner-small" aria-hidden="true"></div>
      <p>Kargo bilgileri alınıyor...</p>
    </div>`}function T(e){return`
    <div class="track-error" role="alert">
      <p>${c(e)}</p>
      <button id="retry-btn" class="btn btn-primary btn-sm" type="button">Tekrar Dene</button>
    </div>`}function E({carriers:e,candidates:t=[],notice:n}){const a=new Set(t),r=[],i=[];for(const d of e)(a.has(d.code)?r:i).push(d);const l=r.map(d=>`<option value="${c(d.code)}">${c(d.name)} (önerilen)</option>`).join(""),o=i.map(d=>`<option value="${c(d.code)}">${c(d.name)}</option>`).join("");return`
    <div class="track-notice" role="status">
      <p>${c(n)}</p>
      <div class="carrier-pick">
        <select id="carrier-pick" class="track-select" aria-label="Kargo firması seçin">
          <option value="" disabled selected>Kargo firması seçin</option>
          ${l}
          ${o}
        </select>
        <button id="carrier-pick-btn" class="btn btn-primary btn-sm" type="button">Seç ve Takip Et</button>
      </div>
    </div>`}function J(e){const t=(e==null?void 0:e.carrierName)||(e==null?void 0:e.carrierCode)||"Kargo firması",n=(e==null?void 0:e.trackingNumber)||"",a=(e==null?void 0:e.status)||"",r=(e==null?void 0:e.statusDescription)||"",i=(e==null?void 0:e.lastUpdate)||"",l=(e==null?void 0:e.currentLocation)||"",o=Array.isArray(e==null?void 0:e.events)?e.events:[],d=r&&r!==b(a)?`<p class="result-desc">${c(r)}</p>`:"",p=o.length>0?`<h4 class="timeline-title">Hareketler</h4>
         <ol class="timeline">
           ${Q(o).map(s=>{const u=(s==null?void 0:s.status)||"";return`
             <li class="timeline-item">
               <span class="timeline-dot ${I(u)}" aria-hidden="true"></span>
               <div class="timeline-body">
                 <div class="timeline-meta">
                   <time>${c(w(s==null?void 0:s.timestamp,!0))}</time>
                   <span class="timeline-status">${c(b(u))}</span>
                 </div>
                 ${s!=null&&s.description?`<p class="timeline-desc">${c(s.description)}</p>`:""}
                 ${s!=null&&s.location?`<span class="timeline-location">${c(s.location)}</span>`:""}
               </div>
             </li>`}).join("")}
         </ol>`:`<div class="empty-state">
           <p>Henüz hareket bilgisi bulunmuyor. Kargo şubeye ulaştığında burada görünecek.</p>
         </div>`;return`
    <div class="result-card">
      <div class="result-top">
        <div class="result-id">
          <span class="result-carrier">${c(t)}</span>
          <span class="result-number">${c(n)}</span>
        </div>
        <span class="status-badge ${I(a)}">${c(b(a))}</span>
      </div>
      <div class="result-meta">
        <span>Son güncelleme: ${c(w(i,!0))}</span>
        ${l?`<span class="result-location">${c(l)}</span>`:""}
      </div>
      ${d}
      ${p}
    </div>`}function Q(e){var r,i;const t=[...e],n=Date.parse((r=t[0])==null?void 0:r.timestamp),a=Date.parse((i=t[t.length-1])==null?void 0:i.timestamp);return!Number.isNaN(n)&&!Number.isNaN(a)&&n<a&&t.reverse(),t}function S(e){const t=document.getElementById("track-submit"),n=t==null?void 0:t.querySelector(".track-submit-label");!t||!n||(t.disabled=e,t.classList.toggle("is-busy",e),n.textContent=e?"Lütfen bekleyin...":"Kargoyu Bul")}function Z(e){const n=e.currentTarget.dataset.url;if(!n){alert("İndirme bağlantısı bulunamadı.");return}n.startsWith("http")?D(n):fetch(n,{method:"HEAD"}).then(a=>{a.ok?D(n):alert("APK dosyası henüz yayınlanmadı. Lütfen daha sonra tekrar deneyin.")}).catch(()=>{alert("APK dosyası kontrol edilemedi. Lütfen daha sonra tekrar deneyin.")})}function D(e){const t=document.createElement("a");t.href=e,t.download="KargomNerede.apk",document.body.appendChild(t),t.click(),document.body.removeChild(t)}function ee(){let e=null,t=!0,n=null,a=U,r={number:"",carrierCode:null};async function i(){var f;const[s,u]=await Promise.allSettled([B(),z()]);s.status==="fulfilled"?e=s.value:n=((f=s.reason)==null?void 0:f.message)||"Sayfa yüklenemedi.",u.status==="fulfilled"&&u.value&&(a=u.value),t=!1,l()}function l(){G({config:e,isLoading:t,error:n,carriers:a,onRetry:()=>{t=!0,n=null,l(),i()},onTrack:o})}async function o(s,u){r={number:s,carrierCode:u||null},k(X()),S(!0);try{let f=u;if(!f){let m;try{m=await H(s)}catch(v){if(F(v)){k(E({carriers:a,notice:"Kargo firması otomatik olarak belirlenemedi. Lütfen kargo firmasını seçin."}),{pick:d});return}throw v}if(m!=null&&m.detected&&m.carrierCode)f=m.carrierCode;else{k(E({carriers:a,candidates:Array.isArray(m==null?void 0:m.candidates)?m.candidates:[],notice:"Bu takip numarası için kargo firması belirlenemedi. Lütfen seçin."}),{pick:d});return}}const g=await V(s,f);k(J(g))}catch(f){M(f)?k(E({carriers:a,notice:L(f)}),{pick:d}):k(T(L(f)),{retry:p})}finally{S(!1)}}function d(s){o(r.number,s)}function p(){const s=document.getElementById("carrier-select"),u=s?s.value:"";o(r.number,u||r.carrierCode||null)}return i(),{mount:()=>{}}}document.addEventListener("DOMContentLoaded",()=>{ee()});
