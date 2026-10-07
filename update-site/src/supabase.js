// Supabase client for public read access
// Uses anon key only - safe for client-side

let supabaseClient = null;

export async function createSupabaseClient() {
  if (supabaseClient) return supabaseClient;

  const url = import.meta.env.VITE_SUPABASE_URL || '';
  const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

  // Fail-open: if config missing or placeholder, return null instead of throwing
  const isPlaceholder = url.includes('placeholder') || anonKey.includes('placeholder');
  if (!url || !anonKey || isPlaceholder) {
    console.warn('[Supabase] Configuration missing or using placeholder. Running in offline mode.');
    return null;
  }

  try {
    // Dynamic import to avoid bundling issues
    const { createClient } = await import('@supabase/supabase-js');
    supabaseClient = createClient(url, anonKey, {
      auth: {
        persistSession: false,
      },
    });
    return supabaseClient;
  } catch (err) {
    console.warn('[Supabase] Failed to initialize client:', err);
    return null;
  }
}