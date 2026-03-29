// ── /api/v1/watchlist ─────────────────────────────────────────────────────────
'use strict';
const express = require('express');
const { store, priceState } = require('../models/store');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');
const router = express.Router();
router.use(authenticate);

const DEFAULT_WATCHLIST = ['XAU/USD','XAG/USD','EUR/USD','GBP/USD','USD/JPY','BTC/USD','OIL/USD'];

function _getWatchlist(userId) {
  return store.watchlists.get(userId) || [...DEFAULT_WATCHLIST];
}

// GET /api/v1/watchlist
router.get('/', asyncWrap(async (req, res) => {
  const symbols = _getWatchlist(req.userId);
  const state = priceState();
  // Annotate XAU/USD with live price; others show placeholder
  const items = symbols.map(s => ({
    symbol: s,
    description: _desc(s),
    bid:    s === 'XAU/USD' ? state.bid : null,
    ask:    s === 'XAU/USD' ? state.ask : null,
    change: s === 'XAU/USD' ? state.change : null,
    changePercent: s === 'XAU/USD' ? state.changePercent : null,
  }));
  res.json({ watchlist: items });
}));

// POST /api/v1/watchlist   { symbol }
router.post('/', asyncWrap(async (req, res) => {
  const { symbol } = req.body;
  if (!symbol || typeof symbol !== 'string') return res.status(400).json({ error: 'symbol required' });
  const sym = symbol.toUpperCase().trim();
  const list = _getWatchlist(req.userId);
  if (!list.includes(sym)) list.push(sym);
  store.watchlists.set(req.userId, list);
  res.json({ watchlist: list });
}));

// DELETE /api/v1/watchlist/:symbol
router.delete('/:symbol', asyncWrap(async (req, res) => {
  const sym = req.params.symbol.toUpperCase();
  const list = _getWatchlist(req.userId).filter(s => s !== sym);
  store.watchlists.set(req.userId, list);
  res.json({ watchlist: list });
}));

// PUT /api/v1/watchlist  { symbols: [...] }   — reorder
router.put('/', asyncWrap(async (req, res) => {
  const { symbols } = req.body;
  if (!Array.isArray(symbols)) return res.status(400).json({ error: 'symbols array required' });
  store.watchlists.set(req.userId, symbols.map(s => String(s).toUpperCase()));
  res.json({ watchlist: symbols });
}));

function _desc(s) {
  const map = {
    'XAU/USD':'Gold vs US Dollar','XAG/USD':'Silver vs US Dollar',
    'EUR/USD':'Euro vs US Dollar','GBP/USD':'British Pound vs US Dollar',
    'USD/JPY':'US Dollar vs Japanese Yen','BTC/USD':'Bitcoin vs US Dollar',
    'OIL/USD':'Crude Oil vs US Dollar',
  };
  return map[s] || s;
}

module.exports = router;
