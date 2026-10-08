// Tracking API layer - talks to the REAL backend.
//
// There is no client-side guessing here: carrier detection and tracking are
// always answered by the backend (which in turn talks to the real tracking
// provider). If the backend cannot answer, the user sees a real, friendly
// error - never a fabricated result.
//
// Production endpoint (set by the deployment):
//   https://api.kargomnerede.com/api/v1
// For local previews you can override it with ?api=<base url>.

const DEFAULT_API_BASE = 'https://api.kargomnerede.com/api/v1';

function resolveApiBase() {
  if (typeof location !== 'undefined' && location.search) {
    const override = new URLSearchParams(location.search).get('api');
    if (override) return override.replace(/\/+$/, '');
  }
  return DEFAULT_API_BASE;
}

export const API_BASE = resolveApiBase();

// Static fallback mirroring backend/src/services/carrierDetectionService.ts.
// The live list from GET /carriers replaces this as soon as the API answers,
// so the dropdown always reflects the real registry.
export const FALLBACK_CARRIERS = [
  { code: 'yurtici', name: 'Yurtiçi Kargo' },
  { code: 'mng', name: 'MNG Kargo' },
  { code: 'aras', name: 'Aras Kargo' },
  { code: 'surat', name: 'Sürat Kargo' },
  { code: 'ptt', name: 'PTT' },
  { code: 'trendyol_express', name: 'Trendyol Express' },
  { code: 'hepsijet', name: 'HepsiJet' },
  { code: 'hepsiburada', name: 'Hepsiburada Lojistik' },
  { code: 'n11', name: 'n11 Lojistik' },
  { code: 'ups', name: 'UPS' },
  { code: 'fedex', name: 'FedEx' },
  { code: 'dhl', name: 'DHL' },
  { code: 'tnt', name: 'TNT' },
  { code: 'dpd', name: 'DPD' },
  { code: 'gls', name: 'GLS' },
  { code: 'hermes', name: 'Hermes / Evri' },
  { code: 'cargonet', name: 'Cargonet' },
  { code: 'kargomatik', name: 'Kargomatik' },
  { code: 'sendeo', name: 'Sendeo' },
];

async function request(path, options = {}) {
  let response;
  try {
    response = await fetch(`${API_BASE}${path}`, {
      headers: { 'Content-Type': 'application/json' },
      ...options,
    });
  } catch (networkError) {
    // No response at all (offline, DNS not set up yet, CORS blocked, ...)
    const err = new Error('network');
    err.kind = 'network';
    throw err;
  }

  let body = null;
  try {
    body = await response.json();
  } catch {
    // Non-JSON response (e.g. hosting error page)
  }

  if (!response.ok) {
    const err = new Error('api-error');
    err.kind = 'api';
    err.status = response.status;
    err.code = body && body.code ? String(body.code) : `HTTP_${response.status}`;
    err.serverMessage = body && body.message ? String(body.message) : '';
    throw err;
  }

  return body;
}

/** GET /tracking/carriers -> [{code, name}] or null when API is unreachable. */
export async function fetchCarriers() {
  try {
    const body = await request('/tracking/carriers');
    const list = Array.isArray(body?.data) ? body.data : [];
    const valid = list.filter((c) => c && c.code && c.name);
    return valid.length > 0 ? valid : null;
  } catch {
    return null;
  }
}

/**
 * POST /tracking/detect-carrier -> {trackingNumber, carrierCode, detected,
 * source, candidates}. Throws an API error (e.g. 503 when the tracking
 * provider is not configured) - callers decide how to present it.
 */
export async function detectCarrier(trackingNumber) {
  const body = await request('/tracking/detect-carrier', {
    method: 'POST',
    body: JSON.stringify({ trackingNumber }),
  });
  return body?.data ?? null;
}

/** POST /tracking/track -> real TrackingResult from the provider. */
export async function trackShipment(trackingNumber, carrierCode) {
  const payload = { trackingNumber };
  if (carrierCode) payload.carrierCode = carrierCode;
  const body = await request('/tracking/track', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return body?.data ?? null;
}

/**
 * Map an error from this module to a friendly Turkish message.
 * Never exposes stack traces or raw provider payloads to the user.
 */
export function friendlyError(err) {
  if (!err || err.kind === 'network') {
    return 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.';
  }
  switch (err.code) {
    case 'PROVIDER_NOT_CONFIGURED':
    case 'PROVIDER_UNAVAILABLE':
    case 'PROVIDER_AUTH_FAILED':
    case 'PROVIDER_ERROR':
    case 'PROVIDER_UNREACHABLE':
      return 'Kargo takip servisi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
    case 'PROVIDER_RATE_LIMITED':
      return 'Kargo takip servisi yoğunlukta. Birkaç dakika sonra tekrar deneyin.';
    case 'CARRIER_DETECTION_FAILED':
      return 'Kargo firması algılanamadı. Lütfen kargo firmasını seçip tekrar deneyin.';
    case 'VALIDATION_ERROR':
      return 'Geçerli bir takip numarası girin (5-50 karakter).';
    default:
      break;
  }
  if (err.status === 404) {
    return 'Takip servisi bulunamadı. API adresi hatalı olabilir.';
  }
  if (err.status && err.status >= 400 && err.status < 500) {
    return 'Girilen bilgiler geçerli değil. Takip numaranızı kontrol edip tekrar deneyin.';
  }
  return 'Kargo bilgileri alınamadı. Lütfen tekrar deneyin.';
}

/** True when the error means "carrier must be chosen manually". */
export function isCarrierRequiredError(err) {
  return !!err && err.code === 'CARRIER_DETECTION_FAILED';
}

/** True when the backend (tracking provider) itself is unavailable. */
export function isProviderUnavailableError(err) {
  return (
    !!err &&
    typeof err.code === 'string' &&
    err.code.startsWith('PROVIDER_')
  );
}
