import { createSupabaseClient } from './supabase.js';
import { renderApp } from './ui.js';
import { fetchConfig } from './config.js';

export function createApp() {
  let config = null;
  let isLoading = true;
  let error = null;

  async function init() {
    try {
      config = await fetchConfig();
    } catch (err) {
      error = err.message;
      console.error('Failed to fetch config:', err);
    } finally {
      isLoading = false;
      render();
    }
  }

  function render() {
    renderApp({
      config,
      isLoading,
      error,
      onRetry: () => {
        isLoading = true;
        error = null;
        render();
        init();
      },
    });
  }

  init();

  return {
    mount: (selector) => {
      // Already mounted via renderApp
    },
  };
}