import { createSupabaseClient } from './supabase.js';

export async function fetchConfig() {
  const supabase = await createSupabaseClient();
  
  // Fail-open: if supabase client not available, return default config
  if (!supabase) {
    console.warn('[Config] Supabase client unavailable, using default config');
    return getDefaultConfig();
  }
  
  try {
    const { data, error } = await supabase
      .from('app_config')
      .select('*')
      .eq('id', 'main')
      .single();

    if (error) {
      console.warn('[Config] Supabase query error:', error.message);
      return getDefaultConfig();
    }

    if (!data) {
      console.warn('[Config] App config not found in Supabase');
      return getDefaultConfig();
    }

    return {
      minimumVersion: data.minimum_version,
      latestVersion: data.latest_version,
      downloadUrl: data.download_url,
      forceUpdate: data.force_update,
      updateMessage: data.update_message,
      updatedAt: data.updated_at,
    };
  } catch (err) {
    console.warn('[Config] Fetch failed:', err);
    return getDefaultConfig();
  }
}

function getDefaultConfig() {
  return {
    minimumVersion: '1.0.0',
    latestVersion: '1.0.0',
    downloadUrl: 'downloads/KargomNerede.apk',
    forceUpdate: false,
    updateMessage: 'Yeni bir sürüm mevcut. Lütfen güncelleyin.',
    updatedAt: new Date().toISOString(),
  };
}

export function getDownloadUrl(config) {
  if (!config || !config.downloadUrl) {
    return '/downloads/KargomNerede.apk';
  }
  
  // If it's already a full URL, return as-is
  if (config.downloadUrl.startsWith('http')) {
    return config.downloadUrl;
  }
  
  // Otherwise prepend the site origin
  return `${window.location.origin}${config.downloadUrl}`;
}