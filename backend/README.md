# KargomNerede Backend

Bu klasör backend API servisini içerir.

## Yapı
```
backend/
├── src/
│   ├── index.ts          # Entry point
│   ├── config/           # Configuration
│   ├── routes/           # API routes
│   ├── services/         # Business logic
│   ├── middleware/       # Express middleware
│   ├── utils/            # Utilities
│   └── types/            # TypeScript types
├── package.json
├── tsconfig.json
└── .env.example
```

## Kurulum
```bash
cd backend
npm install
cp .env.example .env
# .env dosyasını düzenleyin
npm run dev
```

## Environment Variables
- `PORT` - Server port (default: 3000; Render injects its own `PORT`)
- `NODE_ENV` - `development` | `production`
- `CORS_ORIGIN` - Comma separated browser allowlist (Flutter needs no CORS)
- `TRACKING_PROVIDER` - Default tracking provider (ship24, 17track, aftership)
- `TRACKING_SHIP24_API_KEY` - Ship24 API key (only when `TRACKING_PROVIDER=ship24`)
- `TRACKING_17TRACK_API_KEY` - 17TRACK API key (only when `TRACKING_PROVIDER=17track`)
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Firebase private key
- `FIREBASE_CLIENT_EMAIL` - Firebase client email
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string (for caching)
- `JWT_SECRET` - JWT signing secret

> API keys are set in the environment (Render dashboard / `.env`), never in
> source code. `.env` is gitignored.

## Production / Render
```bash
cd backend
npm install --include=dev   # tsc lives in devDependencies
npm run build               # tsc -> dist/
NODE_ENV=production npm start   # node dist/index.js
GET /health                 # {"ok":true,"service":"kargomnerede-backend",...}
```
The repo root contains `render.yaml` (Node web service, no Docker needed).
Without `TRACKING_SHIP24_API_KEY`, tracking endpoints answer
`503 PROVIDER_NOT_CONFIGURED` / `PROVIDER_UNAVAILABLE` - they never fall
back to mock data.