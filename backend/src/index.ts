import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { errorHandler } from './middleware/errorHandler';
import { requestLogger } from './middleware/requestLogger';
import { trackingRoutes } from './routes/tracking';
import { shipmentRoutes } from './routes/shipments';
import { notificationRoutes } from './routes/notifications';
import { webhookRoutes } from './routes/webhooks';
import { healthRoutes } from './routes/health';

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable for API
}));

// CORS
//
// The Flutter app is not a browser and does not enforce CORS, so this
// configuration can never break it: clients without an Origin header
// (Flutter, curl, server-to-server) are always accepted. Browser access is
// limited to an explicit allowlist - set CORS_ORIGIN (comma separated, e.g.
// "https://kargomnerede.com") for a future web client; with an empty list
// no browser origin gets CORS headers. The API uses no cookies, so
// credentials stay disabled (no wildcard+credentials mix).
const allowedOrigins = (process.env.CORS_ORIGIN ?? '')
  .split(',')
  .map((origin) => origin.trim())
  .filter((origin) => origin.length > 0);

app.use(cors({
  origin: (origin, callback) => {
    if (!origin) {
      callback(null, true); // non-browser client
      return;
    }
    callback(null, allowedOrigins.includes(origin));
  },
  credentials: false,
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging
app.use(morgan('combined'));
app.use(requestLogger);

// Health check
app.use('/health', healthRoutes);

// API Routes
app.use('/api/v1/tracking', trackingRoutes);
app.use('/api/v1/shipments', shipmentRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/webhooks', webhookRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
  });
});

// Error handler
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

export { app };