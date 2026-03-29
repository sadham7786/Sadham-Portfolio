'use strict';

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');

const { connectDB } = require('./models/store');

const authRoutes = require('./routes/auth');
const priceRoutes = require('./routes/price');
const tradeRoutes = require('./routes/trades');
const accountRoutes = require('./routes/account');
const adminRoutes = require('./routes/admin');
const calendarRoutes      = require('./routes/calendar');
const analyticsRoutes     = require('./routes/analytics');
const watchlistRoutes     = require('./routes/watchlist');
const alertsRoutes        = require('./routes/alerts');
const notificationsRoutes = require('./routes/notifications');
const transactionsRoutes  = require('./routes/transactions');
const marketRoutes        = require('./routes/market');
const newsRoutes          = require('./routes/news');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 8080;

// ── Security ─────────────────────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false })); // CSP off — admin panel uses inline scripts
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Admin-Key'],
}));

// ── Rate Limiting ─────────────────────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  message: { error: 'Too many requests.' },
});
app.use(limiter);

// ── Body Parsing ──────────────────────────────────────────────────────────────
app.use(express.json());

// ── Health Check ──────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    app: 'AURUM TRADER API',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// ── Admin Panel (static HTML) — no-cache so JS fixes always reach browser ──────
const NO_CACHE = { 'Cache-Control': 'no-cache, no-store, must-revalidate', 'Pragma': 'no-cache', 'Expires': '0' };
app.get('/admin', (req, res) => {
  res.set(NO_CACHE).sendFile(path.join(__dirname, '../../admin_panel/index.html'));
});
app.use('/admin', (req, res, next) => { res.set(NO_CACHE); next(); },
  express.static(path.join(__dirname, '../../admin_panel')));

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/price', priceRoutes);
app.use('/api/v1/trades', tradeRoutes);
app.use('/api/v1/account', accountRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/calendar',      calendarRoutes);
app.use('/api/v1/analytics',     analyticsRoutes);
app.use('/api/v1/watchlist',     watchlistRoutes);
app.use('/api/v1/alerts',        alertsRoutes);
app.use('/api/v1/notifications', notificationsRoutes);
app.use('/api/v1/transactions',  transactionsRoutes);
app.use('/api/v1/market',        marketRoutes);
app.use('/api/v1/news',          newsRoutes);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Cannot ${req.method} ${req.path}` });
});

// ── Global Error Handler ──────────────────────────────────────────────────────
app.use(errorHandler);

// ── Start ─────────────────────────────────────────────────────────────────────
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`\n🥇 AURUM TRADER API`);
    console.log(`   Running on  → http://localhost:${PORT}`);
    console.log(`   Admin panel → http://localhost:${PORT}/admin`);
    console.log(`   Health      → http://localhost:${PORT}/health`);
    console.log(`   Endpoints   → /api/v1/{auth,price,trades,account,admin}\n`);
  });
});

module.exports = app;
