'use strict';

const express = require('express');
const { priceState, getSimConfig, setSimConfig } = require('../models/store');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();

// ── GET /api/v1/price/ticker ──────────────────────────────────────────────────
router.get('/ticker', asyncWrap(async (req, res) => {
  const s = priceState();
  res.json({
    bid:           s.bid,
    ask:           s.ask,
    spread:        s.spread,
    high24h:       s.high24h,
    low24h:        s.low24h,
    open24h:       s.open24h,
    change:        s.change,
    changePercent: s.changePercent,
    timestamp:     s.timestamp,
  });
}));

// ── GET /api/v1/price/candles ─────────────────────────────────────────────────
// Query: limit (max 2880), from (unix ms), tf (1m | 1d | 1w)
router.get('/candles', asyncWrap(async (req, res) => {
  const s  = priceState();
  const tf = req.query.tf || '1m';

  let source;
  let maxLimit;
  if (tf === '1d') {
    source   = s.dailyCandles;
    maxLimit = 400;
  } else if (tf === '1w') {
    source   = s.weeklyCandles;
    maxLimit = 270;
  } else {
    source   = s.candles;
    maxLimit = 2880;
  }

  let limit = Math.min(parseInt(req.query.limit) || 120, maxLimit);
  const from = req.query.from ? parseInt(req.query.from) : null;

  let candles = source;
  if (from) candles = candles.filter(c => c.time >= from);
  candles = candles.slice(-limit);

  res.json({
    symbol:    'XAU/USD',
    timeframe: tf,
    candles,
    count:     candles.length,
  });
}));

// ── GET /api/v1/price/snapshot ────────────────────────────────────────────────
// Full snapshot: ticker + candles (multi-timeframe)
router.get('/snapshot', asyncWrap(async (req, res) => {
  const s     = priceState();
  const tf    = req.query.tf    || '1m';
  const limit = Math.min(parseInt(req.query.limit) || 120, 2880);

  let candles;
  if (tf === '1d')       candles = s.dailyCandles.slice(-limit);
  else if (tf === '1w')  candles = s.weeklyCandles.slice(-limit);
  else                   candles = s.candles.slice(-limit);

  res.json({
    ticker: {
      bid:           s.bid,
      ask:           s.ask,
      spread:        s.spread,
      high24h:       s.high24h,
      low24h:        s.low24h,
      open24h:       s.open24h,
      change:        s.change,
      changePercent: s.changePercent,
      timestamp:     s.timestamp,
    },
    candles,
    timeframe: tf,
  });
}));

// ── GET /api/v1/price/history ─────────────────────────────────────────────────
// Returns multi-timeframe history for charting widgets
// Query: tf=1m|1d|1w  from=<unix ms>  limit=<n>
router.get('/history', asyncWrap(async (req, res) => {
  const s   = priceState();
  const tf  = req.query.tf || '1d';
  const from = req.query.from ? parseInt(req.query.from) : null;

  let source, maxLimit;
  if (tf === '1d')       { source = s.dailyCandles;  maxLimit = 400; }
  else if (tf === '1w')  { source = s.weeklyCandles; maxLimit = 270; }
  else                   { source = s.candles;        maxLimit = 2880; }

  const limit = Math.min(parseInt(req.query.limit) || maxLimit, maxLimit);
  let candles = from ? source.filter(c => c.time >= from) : source;
  candles = candles.slice(-limit);

  res.json({
    symbol:    'XAU/USD',
    timeframe: tf,
    from:      candles[0]?.time || null,
    to:        candles[candles.length - 1]?.time || null,
    count:     candles.length,
    candles,
  });
}));

// ── GET /api/v1/price/config ──────────────────────────────────────────────────
// Get current simulation config (public — Flutter app shows the speed)
router.get('/config', asyncWrap(async (req, res) => {
  res.json(getSimConfig());
}));

// ── PATCH /api/v1/price/config ────────────────────────────────────────────────
// Update simulation speed/volatility/drift (requires auth)
// Body: { tickIntervalMs, volatility, drift, running }
router.patch('/config', authenticate, asyncWrap(async (req, res) => {
  const allowed = ['tickIntervalMs', 'volatility', 'drift', 'running'];
  const updates = {};
  for (const k of allowed) {
    if (req.body[k] !== undefined) updates[k] = req.body[k];
  }
  if (Object.keys(updates).length === 0) {
    return res.status(400).json({ error: 'No valid config fields provided.' });
  }
  const config = setSimConfig(updates);
  res.json({ message: 'Simulation config updated.', config });
}));

module.exports = router;
