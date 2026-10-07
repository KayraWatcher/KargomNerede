// Supabase client for public read access
// Uses anon key only - safe for client-side

let supabaseClient = null;

export async function createSupabaseClient() {
  if (supabaseClient) return supabaseClient;

  const url = import.meta.env.VITE_SUPABASE_URL || '';
  const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

  if (!url || !anonKey) {
    throw new Error('Supabase configuration missing. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.');
  }

  // Dynamic import to avoid bundling issues
  const { createClient } = await import('@supabase/supabase-js');
  supabaseClient = createClient(url, anonKey, {
    auth: {
      persistSession: false,
    },
  });

  return supabaseClient;
}