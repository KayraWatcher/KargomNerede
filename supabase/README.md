# Supabase Setup for KargomNerede

## 1. Run Migration

Go to Supabase Dashboard → SQL Editor and run the migration:

```sql
-- Copy contents of supabase/migrations/20250108_create_app_config.sql
```

## 2. Configure Environment Variables

### Flutter App (.env)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### Backend (.env) - for admin operations
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### Update Site (.env)
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

## 3. App Config Table Structure

| Column | Type | Description |
|--------|------|-------------|
| id | TEXT (PK) | Always 'main' |
| minimum_version | TEXT | Minimum required version (e.g., '1.1.0') |
| latest_version | TEXT | Latest available version (e.g., '1.2.0') |
| download_url | TEXT | APK download URL (relative or absolute) |
| force_update | BOOLEAN | If true, blocks app usage until update |
| update_message | TEXT | Message shown to user |
| updated_at | TIMESTAMPTZ | Auto-updated on change |
| created_at | TIMESTAMPTZ | Set on creation |

## 4. Version Comparison Logic

The app uses semantic version comparison:
- `1.9.0 < 1.10.0` ✓ (correct)
- `1.0.0 < 1.0.1` ✓
- `2.0.0 > 1.9.9` ✓

## 5. Force Update Flow

1. App starts → `initializeSupabase()`
2. `AppInitializer` wraps the app
3. `forceUpdateCheckProvider` fetches config from Supabase
4. If `force_update = true` AND `current < minimum_version`:
   - Shows `ForceUpdateScreen` (non-dismissible)
   - User must tap "Güncelle" to proceed
5. If `force_update = false` AND `current < latest_version`:
   - Shows `OptionalUpdateDialog` (dismissible)
   - User can choose "Şimdi Değil" or "Güncelle"

## 6. Offline Behavior

- Config is cached locally (7 days TTL)
- On network error, cached config is used
- If no cached config, app continues (fail-open)
- No force update shown on timeout/errors

## 7. Admin: Update Config via Supabase Dashboard

Go to Table Editor → `app_config` → Edit the `main` row:

| Field | Example Value |
|-------|---------------|
| minimum_version | `1.1.0` |
| latest_version | `1.2.0` |
| download_url | `https://kargomnerede.com/downloads/KargomNerede-v1.2.0.apk` |
| force_update | `true` |
| update_message | `Güvenlik güncellemesi yapıldı. Uygulamayı kullanmaya devam etmek için güncelleyin.` |

## 8. Download URL Format

The download URL can be:
- Relative: `/downloads/KargomNerede.apk` (served from update site)
- Absolute: `https://cdn.example.com/KargomNerede.apk`
- GitHub Release: `https://github.com/user/repo/releases/download/v1.2.0/KargomNerede.apk`

The update site will prepend its origin for relative URLs.

## 9. Testing

### Test Force Update
1. Set `minimum_version = 99.0.0`
2. Set `force_update = true`
3. Open app → Should show force update screen

### Test Optional Update
1. Set `minimum_version = 1.0.0`
2. Set `latest_version = 2.0.0`
3. Set `force_update = false`
4. Open app → Should show optional update dialog

### Test No Update
1. Set `minimum_version = 1.0.0`
2. Set `latest_version = 1.0.0`
3. Open app → Normal flow

## 10. Deploying APK

When you have a real APK:
1. Build release APK: `flutter build apk --release`
2. Upload to your hosting (GitHub Releases, CDN, or update site)
3. Update `download_url` in Supabase `app_config`
4. Update `latest_version` and `minimum_version` as needed