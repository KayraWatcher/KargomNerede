import { fetchConfig } from './config.js';
import {
  FALLBACK_CARRIERS,
  fetchCarriers,
  detectCarrier,
  trackShipment,
  friendlyError,
  isCarrierRequiredError,
  isProviderUnavailableError,
} from './tracking.js';
import {
  renderApp,
  updateTrackingResult,
  trackingLoadingHTML,
  trackingErrorHTML,
  trackingCarrierRequiredHTML,
  trackingSuccessHTML,
  setBusy,
} from './ui.js';

export function createApp() {
  let config = null;
  let isLoading = true;
  let error = null;
  let carriers = FALLBACK_CARRIERS;
  let lastQuery = { number: '', carrierCode: null };

  async function init() {
    const [configResult, carriersResult] = await Promise.allSettled([
      fetchConfig(),
      fetchCarriers(),
    ]);

    if (configResult.status === 'fulfilled') {
      config = configResult.value;
    } else {
      // Config failure is fatal only if we have nothing sensible to show.
      error = configResult.reason?.message || 'Sayfa yüklenemedi.';
    }

    if (carriersResult.status === 'fulfilled' && carriersResult.value) {
      carriers = carriersResult.value;
    } // else: static fallback mirroring the backend registry

    isLoading = false;
    render();
  }

  function render() {
    renderApp({
      config,
      isLoading,
      error,
      carriers,
      onRetry: () => {
        isLoading = true;
        error = null;
        render();
        init();
      },
      onTrack: runTracking,
    });
  }

  /**
   * Real tracking flow:
   *   number -> (detect carrier via backend, unless chosen manually)
   *          -> track via backend -> render real result (or a real error).
   * Nothing is ever fabricated client-side.
   */
  async function runTracking(number, carrierCode) {
    lastQuery = { number, carrierCode: carrierCode || null };
    updateTrackingResult(trackingLoadingHTML());
    setBusy(true);

    try {
      let carrier = carrierCode;

      if (!carrier) {
        let detection;
        try {
          detection = await detectCarrier(number);
        } catch (detectError) {
          if (isProviderUnavailableError(detectError)) {
            // The backend could not verify the carrier (provider not
            // configured yet). Be honest and ask the user to choose.
            updateTrackingResult(
              trackingCarrierRequiredHTML({
                carriers,
                notice: 'Kargo firması otomatik olarak belirlenemedi. Lütfen kargo firmasını seçin.',
              }),
              { pick: pickCarrierAndTrack }
            );
            return;
          }
          throw detectError;
        }

        if (detection?.detected && detection.carrierCode) {
          carrier = detection.carrierCode;
        } else {
          updateTrackingResult(
            trackingCarrierRequiredHTML({
              carriers,
              candidates: Array.isArray(detection?.candidates) ? detection.candidates : [],
              notice: 'Bu takip numarası için kargo firması belirlenemedi. Lütfen seçin.',
            }),
            { pick: pickCarrierAndTrack }
          );
          return;
        }
      }

      const result = await trackShipment(number, carrier);
      updateTrackingResult(trackingSuccessHTML(result));
    } catch (err) {
      if (isCarrierRequiredError(err)) {
        updateTrackingResult(
          trackingCarrierRequiredHTML({
            carriers,
            notice: friendlyError(err),
          }),
          { pick: pickCarrierAndTrack }
        );
      } else {
        updateTrackingResult(
          trackingErrorHTML(friendlyError(err)),
          { retry: retryLastQuery }
        );
      }
    } finally {
      setBusy(false);
    }
  }

  function pickCarrierAndTrack(code) {
    runTracking(lastQuery.number, code);
  }

  function retryLastQuery() {
    const select = document.getElementById('carrier-select');
    const manual = select ? select.value : '';
    runTracking(lastQuery.number, manual || lastQuery.carrierCode || null);
  }

  init();

  return {
    mount: () => {
      // Already mounted via renderApp
    },
  };
}
