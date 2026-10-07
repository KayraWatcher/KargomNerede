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
- `PORT` - Server port (default: 3000)
- `FIREBASE_PROJECT_ID` - Firebase project ID
- `FIREBASE_PRIVATE_KEY` - Firebase private key
- `FIREBASE_CLIENT_EMAIL` - Firebase client email
- `TRACKING_PROVIDER` - Default tracking provider (17track, aftership, ship24)
- `TRACKING_API_KEY` - Tracking provider API key
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string (for caching)
- `JWT_SECRET` - JWT signing secret
- `CORS_ORIGIN` - Allowed CORS origin