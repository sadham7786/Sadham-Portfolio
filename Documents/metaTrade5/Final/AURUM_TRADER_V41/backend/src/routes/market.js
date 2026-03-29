'use strict';
// ─────────────────────────────────────────────────────────────────────────────
// Market Info API  —  /api/v1/market
// Session status, spread history, market depth simulation
// ─────────────────────────────────────────────────────────────────────────────
const router = require('express').Router();
const { priceState } = require('../models/store');
const { asyncWrap } = require('../middleware/errorHandler');

// ── GET /api/v1/market/status ─────────────────────────────────────────────────
router.get('/status', asyncWrap(async (req, res) => {
  const now = new Date();
  const utcHour = now.getUTCHours();
  const utcDay  = now.getUTCDay(); // 0=Sun 6=Sat
  const isWeekend = utcDay === 0 || utcDay === 6;

  const sessions = [
    { name: 'Sydney',    open: 21, close: 6,  tz: 'AEDT (UTC+11)' },
    { name: 'Tokyo',     open: 23, close: 8,  tz: 'JST (UTC+9)'   },
    { name: 'London',    open: 7,  close: 16, tz: 'GMT (UTC+0)'   },
    { name: 'New York',  open: 12, close: 21, tz: 'EST (UTC-5)'   },
  ];

  const activeSessions = sessions.filter(s => {
    if (isWeekend) return false;
    if (s.open < s.close) return utcHour >= s.open && utcHour < s.close;
    return utcHour >= s.open || utcHour < s.close;
  });

  const state = priceState();
  res.json({
    status: {
      isOpen:    !isWeekend && activeSessions.length > 0,
      isWeekend,
      utcTime:   now.toISOString(),
      sessions:  sessions.map(s => ({
        ...s,
        active: activeSessions.some(a => a.name === s.name),
      })),
      activeSessions: activeSessions.map(s => s.name),
      spread:    state.spread,
      bid:       state.bid,
      ask:       state.ask,
    },
  });
}));

// ── GET /api/v1/market/depth ──────────────────────────────────────────────────
// Simulated order book depth
router.get('/depth', asyncWrap(async (req, res) => {
  const state = priceState();
  const mid = (state.bid + state.ask) / 2;
  const bids = [], asks = [];
  let bidVol = 0, askVol = 0;
  for (let i = 1; i <= 10; i++) {
    const bPrice = parseFloat((mid - i * 0.35).toFixed(2));
    const aPrice = parseFloat((mid + i * 0.35).toFixed(2));
    const bVol = parseFloat((Math.random() * 5 + 0.5).toFixed(2));
    const aVol = parseFloat((Math.random() * 5 + 0.5).toFixed(2));
    bidVol += bVol; askVol += aVol;
    bids.push({ price: bPrice, volume: bVol, total: parseFloat(bidVol.toFixed(2)) });
    asks.push({ price: aPrice, volume: aVol, total: parseFloat(askVol.toFixed(2)) });
  }
  res.json({ symbol: 'XAU/USD', bid: state.bid, ask: state.ask, bids, asks, timestamp: Date.now() });
}));

// ── GET /api/v1/market/sentiment ──────────────────────────────────────────────
router.get('/sentiment', asyncWrap(async (req, res) => {
  // Simulated sentiment (real impl would use news/options data)
  const { store } = require('../models/store');
  let buyCount = 0, sellCount = 0, buyLots = 0, sellLots = 0;
  for (const t of store.trades.values()) {
    if (t.status !== 'open') continue;
    if (t.type === 'buy')  { buyCount++;  buyLots  += t.lotSize; }
    else                   { sellCount++; sellLots += t.lotSize; }
  }
  const total = buyCount + sellCount || 1;
  const totalLots = buyLots + sellLots || 1;
  res.json({
    sentiment: {
      buyPercent:  parseFloat(((buyCount  / total)     * 100).toFixed(1)),
      sellPercent: parseFloat(((sellCount / total)     * 100).toFixed(1)),
      buyLotShare: parseFloat(((buyLots   / totalLots) * 100).toFixed(1)),
      sellLotShare:parseFloat(((sellLots  / totalLots) * 100).toFixed(1)),
      openPositions: buyCount + sellCount,
    },
  });
}));

module.exports = router;
