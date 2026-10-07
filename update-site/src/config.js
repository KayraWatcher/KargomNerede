import { createSupabaseClient } from './supabase.js';

export async function fetchConfig() {
  const supabase = createSupabaseClient();
  
  const { data, error } = await supabase
    .from('app_config')
    .select('*')
    .eq('id', 'main')
    .single();

  if (error) {
    throw new Error(`Config fetch failed: ${error.message}`);
  }

  if (!data) {
    throw new Error('App config not found');
  }

  return {
    minimumVersion: data.minimum_version,
    latestVersion: data.latest_version,
    downloadUrl: data.download_url,
    forceUpdate: data.force_update,
    updateMessage: data.update_message,
    updatedAt: data.updated_at,
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