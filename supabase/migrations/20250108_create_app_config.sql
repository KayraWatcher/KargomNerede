-- KargomNerede App Config Table
-- Run this in Supabase SQL Editor

-- Create the app_config table
CREATE TABLE IF NOT EXISTS public.app_config (
    id TEXT PRIMARY KEY,
    minimum_version TEXT NOT NULL DEFAULT '1.0.0',
    latest_version TEXT NOT NULL DEFAULT '1.0.0',
    download_url TEXT NOT NULL DEFAULT '',
    force_update BOOLEAN NOT NULL DEFAULT FALSE,
    update_message TEXT NOT NULL DEFAULT 'Yeni bir sürüm mevcut. Lütfen güncelleyin.',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access (for Flutter app and update site)
CREATE POLICY "Allow public read access" ON public.app_config
    FOR SELECT USING (true);

-- Policy: Only service role can modify (admin operations)
CREATE POLICY "Allow service role full access" ON public.app_config
    FOR ALL USING (auth.role() = 'service_role');

-- Insert default config
INSERT INTO public.app_config (id, minimum_version, latest_version, download_url, force_update, update_message)
VALUES (
    'main',
    '1.0.0',
    '1.0.0',
    '/downloads/KargomNerede.apk',
    FALSE,
    'Yeni bir sürüm mevcut. Lütfen güncelleyin.'
) ON CONFLICT (id) DO NOTHING;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_app_config_updated_at ON public.app_config;
CREATE TRIGGER update_app_config_updated_at
    BEFORE UPDATE ON public.app_config
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Grant permissions
GRANT SELECT ON public.app_config TO anon;
GRANT ALL ON public.app_config TO service_role;