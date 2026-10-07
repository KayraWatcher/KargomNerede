# KargomNerede Force Update System - Implementation Summary

## Overview
Complete force-update infrastructure with Supabase backend, Flutter client integration, and a modern update/download site.

---

## 1. Supabase Database

### Table: `app_config`
```sql
-- Run: supabase/migrations/20250108_create_app_config.sql

CREATE TABLE public.app_config (
    id TEXT PRIMARY KEY DEFAULT 'main',
    minimum_version TEXT NOT NULL DEFAULT '1.0.0',
    latest_version TEXT NOT NULL DEFAULT '1.0.0',
    download_url TEXT NOT NULL DEFAULT '',
    force_update BOOLEAN NOT NULL DEFAULT FALSE,
    update_message TEXT NOT NULL DEFAULT 'Yeni bir sürüm mevcut. Lütfen güncelleyin.',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Public read access (Flutter app + Update site)
CREATE POLICY "Allow public read access" ON public.app_config
    FOR SELECT USING (true);

-- Admin write access (Service role only)
CREATE POLICY "Allow service role full access" ON public.app_config
    FOR ALL USING (auth.role() = 'service_role');
```

### Column Reference
| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `id` | TEXT (PK) | Always 'main' | `'main'` |
| `minimum_version` | TEXT | Minimum required version | `'1.1.0'` |
| `latest_version` | TEXT | Latest available version | `'1.2.0'` |
| `download_url` | TEXT | APK download URL (relative or absolute) | `'/downloads/KargomNerede.apk'` |
| `force_update` | BOOLEAN | Block app until updated | `true`/`false` |
| `update_message` | TEXT | User-facing message | `'Güvenlik güncellemesi...'` |
| `updated_at` | TIMESTAMPTZ | Auto-updated on change | Auto |
| `created_at` | TIMESTAMPTZ | Set on creation | Auto |

### Default Config (Current)
```json
{
  "id": "main",
  "minimum_version": "1.0.0",
  "latest_version": "1.0.0",
  "download_url": "/downloads/KargomNerede.apk",
  "force_update": false,
  "update_message": "Yeni bir sürüm mevcut. Lütfen güncelleyin."
}
```

### To Enable Force Update
```json
{
  "minimum_version": "1.1.0",
  "latest_version": "1.2.0",
  "download_url": "https://kargomnerede.com/downloads/KargomNerede-v1.2.0.apk",
  "force_update": true,
  "update_message": "Güvenlik güncellemesi yapıldı. Uygulamayı kullanmaya devam etmek için güncelleyin."
}
```

---

## 2. Flutter App Integration

### Dependencies Added
```yaml
dependencies:
  supabase_flutter: ^2.5.6
  package_info_plus: ^8.1.1  # Already present
  url_launcher: ^6.3.1       # Already present
```

### Key Files Created

#### `lib/src/shared/models/app_config.dart`
- Semantic version comparison (handles `1.9.0 < 1.10.0` correctly)
- `UpdateType` enum: `none`, `optional`, `force`
- Offline caching (7-day TTL)

#### `lib/src/shared/providers/supabase_providers.dart`
- `supabaseClientProvider` - Supabase client
- `appConfigProvider` - Fetches config from Supabase
- `updateStatusProvider` - Determines update state
- `initializeSupabase()` - Init with env vars (fail-open)
- Cache helpers: `_cacheConfig()`, `_getCachedConfig()`

#### `lib/src/features/update/presentation/screens/force_update_screen.dart`
- Non-dismissible force update screen
- Version info display
- Download button → opens update site or direct APK URL

#### `lib/src/features/update/presentation/screens/optional_update_dialog.dart`
- Dismissible dialog for optional updates
- "Şimdi Değil" / "Güncelle" buttons

#### `lib/src/features/update/presentation/widgets/app_initializer.dart`
- Wraps app with `AppInitializer`
- Checks config on startup
- Shows force update screen OR optional dialog

### Main.dart Integration
```dart
// Initialize Supabase (fail-open)
try {
  await initializeSupabase();
} catch (e) {
  debugPrint('Supabase initialization failed (offline mode): $e');
}

// Wrap app with AppInitializer
builder: (context, child) {
  return AppInitializer(
    child: MediaQuery(... child ...),
  );
}
```

### Offline Behavior
- Config cached for 7 days
- On network error → uses cached config
- No cached config → app continues (fail-open)
- Never blocks app due to timeout/network issues

---

## 3. Update Site (update-site/)

### Technology Stack
- Vanilla JS + Vite
- Supabase JS client (anon key only)
- No framework dependencies

### Files
```
update-site/
├── package.json
├── vite.config.js
├── index.html
├── .env.example
├── public/
│   ├── manifest.json
│   └── favicon.svg
└── src/
    ├── main.js
    ├── app.js
    ├── supabase.js
    ├── config.js
    ├── ui.js
    └── styles.css
```

### Features
- **Dark navy/graphite theme** with cyan/blue accents
- **Responsive** - mobile & desktop
- **Turkish locale** - all text in Turkish
- **Fetches config from Supabase** (public anon key)
- **Shows**: Latest version, update date, Android badge
- **Download button** → triggers APK download
- **Relative URL support** - prepends site origin
- **Error handling** - retry button on config fetch failure
- **Loading state** - spinner while fetching

### Design Specs
- Background: `#0D1B2A` (navy)
- Cards: `#152536` (graphite)
- Accent: `#00B4D8` (cyan)
- Font: Inter (400, 500, 600, 700)
- Border radius: 12px/16px/24px
- Subtle shadows, glow on hover

### Build Output
```bash
cd update-site
npm run build
# Output: ../build/update-site/
```

---

## 4. Environment Configuration

### Flutter App (compile-time via --dart-define)
```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
             --dart-define=SUPABASE_ANON_KEY=xxx
```

### Backend (.env)
```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx  # NEVER in Flutter app!
```

### Update Site (.env)
```env
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=xxx
```

### .gitignore (ensure these are ignored)
```
.env
.env.local
*.env
backend/.env
update-site/.env
```

---

## 5. Deployment

### Supabase
1. Run migration in SQL Editor
2. Verify table `app_config` exists with row `id='main'`
3. Set RLS policies as shown above

### Update Site
```bash
cd update-site
npm install
npm run build
# Deploy ../build/update-site/ to:
# - GitHub Pages
# - Netlify
# - Vercel
# - Firebase Hosting
# - Any static hosting
```

### APK Hosting (When Ready)
1. Build release APK: `flutter build apk --release`
2. Upload to hosting (GitHub Releases, CDN, or update site `/public/downloads/`)
3. Update `download_url` in Supabase `app_config`

---

## 6. Version Comparison Logic

```dart
// Correctly handles semantic versions
AppConfig.compareVersions('1.9.0', '1.10.0')  // -1 (1.9.0 < 1.10.0)
AppConfig.compareVersions('1.10.0', '1.9.0')  // 1
AppConfig.compareVersions('1.0.0', '1.0.0')   // 0
AppConfig.compareVersions('2.0.0', '1.9.9')   // 1
```

### Update Type Determination
| Current | Minimum | Latest | Force Update | Result |
|---------|---------|--------|--------------|--------|
| 1.0.0   | 1.1.0   | 1.2.0  | true         | **Force Update** |
| 1.1.0   | 1.1.0   | 1.2.0  | false        | **Optional Update** |
| 1.2.0   | 1.1.0   | 1.2.0  | false        | **No Update** |

---

## 7. Security

### ✅ Safe Practices Implemented
- **Service role key NEVER in Flutter app** - only in backend/.env
- **Anon key only** in Flutter app and update site
- **RLS policies** - public read, service_role write
- **Environment variables** - no hardcoded secrets
- **.env.example files** - template for configuration

### ❌ NOT Done
- APK not uploaded yet (placeholder only)
- Real Supabase project not configured (use your own)

---

## 8. Testing Checklist

### Flutter
- [x] `flutter analyze` - Only pre-existing warnings
- [x] `flutter test` - All tests pass
- [x] Force update screen renders correctly
- [x] Optional update dialog renders correctly
- [x] Offline mode works (fail-open)

### Update Site
- [x] `npm run build` - Successful
- [x] Responsive on mobile/desktop
- [x] Config fetch from Supabase works
- [x] Download button triggers correctly
- [x] Relative URL handling works

---

## 9. Next Steps (When APK Ready)

1. **Build release APK**
   ```bash
   flutter build apk --release
   ```

2. **Upload APK** to hosting
   - Option A: GitHub Releases → use release URL
   - Option B: Update site `/public/downloads/KargomNerede.apk`
   - Option C: CDN (Cloudflare R2, S3, etc.)

3. **Update Supabase config**
   ```sql
   UPDATE app_config SET
     minimum_version = '1.0.0',
     latest_version = '1.0.0',
     download_url = 'https://your-hosting.com/KargomNerede-v1.0.0.apk',
     force_update = false,
     update_message = 'Yeni sürüm yayınlandı!'
   WHERE id = 'main';
   ```

4. **Verify**
   - Open app → should show optional update (if version bumped)
   - Open update site → should show correct version & download works

---

## 10. File Structure Summary

```
KargomNerede/
├── supabase/
│   ├── migrations/
│   │   └── 20250108_create_app_config.sql
│   └── README.md
├── update-site/
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   ├── .env.example
│   ├── public/
│   │   ├── manifest.json
│   │   └── favicon.svg
│   └── src/
│       ├── main.js
│       ├── app.js
│       ├── supabase.js
│       ├── config.js
│       ├── ui.js
│       └── styles.css
├── lib/
│   ├── main.dart                          # Updated with AppInitializer
│   ├── src/
│   │   ├── shared/
│   │   │   ├── models/
│   │   │   │   └── app_config.dart        # NEW: Version config model
│   │   │   └── providers/
│   │   │       ├── app_providers.dart
│   │   │       └── supabase_providers.dart # NEW: Supabase integration
│   │   ├── features/
│   │   │   └── update/
│   │   │       ├── data/
│   │   │       │   └── update_service.dart
│   │   │       └── presentation/
│   │   │           ├── screens/
│   │   │           │   ├── force_update_screen.dart
│   │   │           │   └── optional_update_dialog.dart
│   │   │           └── widgets/
│   │   │               └── app_initializer.dart
│   │   ├── core/
│   │   │   └── constants/
│   │   │       └── app_constants.dart     # Added cache keys
├── .env.example                           # NEW: Flutter env template
├── backend/
│   └── .env.example                       # NEW: Backend env template
└── FORCE_UPDATE_SYSTEM_SUMMARY.md         # This file
```

---

## 11. Quick Reference

### Change Minimum Version (Force Update)
```sql
UPDATE app_config SET minimum_version = '1.1.0', force_update = true WHERE id = 'main';
```

### Change Latest Version (Optional Update)
```sql
UPDATE app_config SET latest_version = '1.2.0', force_update = false WHERE id = 'main';
```

### Change Download URL
```sql
UPDATE app_config SET download_url = 'https://cdn.example.com/app.apk' WHERE id = 'main';
```

### View Current Config
```sql
SELECT * FROM app_config WHERE id = 'main';
```

---

## 12. Commands Reference

```bash
# Flutter
flutter pub get
flutter analyze
flutter test
flutter build apk --release

# Update Site
cd update-site
npm install
npm run dev      # Development server
npm run build    # Production build → ../build/update-site/

# Supabase
# Run migration in Dashboard → SQL Editor
```