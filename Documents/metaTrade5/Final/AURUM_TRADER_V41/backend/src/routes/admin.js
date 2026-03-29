'use strict';

const express = require('express');
const { store, priceState, calcPnl, setSimConfig, getSimConfig, addTransaction, deleteUser } = require('../models/store');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();

// ── Admin secret key guard ────────────────────────────────────────────────────
// In production use a role field on the user. Here we check a static admin key
// sent as X-Admin-Key header, falling back to JWT auth for the admin login route.
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'mt5_admin_secret_2024';

function adminAuth(req, res, next) {
  const key = req.headers['x-admin-key'];
  if (key && key === ADMIN_SECRET) return next();
  // Also allow JWT admin tokens (from /admin/login endpoint)
  return authenticate(req, res, () => {
    const user = store.users.get(req.userId);
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required.' });
    }
    next();
  });
}

// ── POST /api/v1/admin/login ─────────────────────────────────────────────────
// Admin login with master password (returns admin token)
router.post('/login', asyncWrap(async (req, res) => {
  const { password } = req.body;
  if (!password) return res.status(400).json({ error: 'password required.' });
  if (password !== ADMIN_SECRET) {
    return res.status(401).json({ error: 'Invalid admin credentials.' });
  }
  // Return the admin key directly (used as X-Admin-Key in subsequent requests)
  res.json({
    token: ADMIN_SECRET,
    message: 'Admin authenticated.',
  });
}));

// All routes below require admin auth
router.use(adminAuth);

// ── GET /api/v1/admin/stats ──────────────────────────────────────────────────
// Platform-wide overview statistics
router.get('/stats', asyncWrap(async (req, res) => {
  const state = priceState();
  let totalUsers = 0;
  let totalBalance = 0;
  let totalOpenTrades = 0;
  let totalClosedTrades = 0;
  let totalPnl = 0;
  let totalVolume = 0;
  let activeToday = 0;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayTs = today.getTime();

  for (const user of store.users.values()) {
    if (user.role === 'admin') continue;
    totalUsers++;
    totalBalance += user.balance;
    if (user.createdAt >= todayTs) activeToday++;
  }

  for (const trade of store.trades.values()) {
    const user = store.users.get(trade.userId);
    if (!user || user.role === 'admin') continue;
    if (trade.status === 'open') {
      totalOpenTrades++;
      const closePrice = trade.type === 'buy' ? state.bid : state.ask;
      totalPnl += calcPnl(trade, closePrice);
      totalVolume += trade.lotSize;
    } else {
      totalClosedTrades++;
      totalPnl += (trade.pnl || 0);
      totalVolume += trade.lotSize;
    }
  }

  res.json({
    stats: {
      totalUsers,
      totalBalance: parseFloat(totalBalance.toFixed(2)),
      totalOpenTrades,
      totalClosedTrades,
      totalTrades: totalOpenTrades + totalClosedTrades,
      totalPnl: parseFloat(totalPnl.toFixed(2)),
      totalVolume: parseFloat(totalVolume.toFixed(2)),
      newUsersToday: activeToday,
      currentBid: state.bid,
      currentAsk: state.ask,
      spread: state.spread,
      high24h: state.high24h,
      low24h: state.low24h,
      change: state.change,
      changePercent: state.changePercent,
    },
  });
}));

// ── GET /api/v1/admin/users ──────────────────────────────────────────────────
// List all users with their stats
router.get('/users', asyncWrap(async (req, res) => {
  const state = priceState();
  const search = (req.query.search || '').toLowerCase();
  const page = parseInt(req.query.page) || 1;
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);
  const sortBy = req.query.sortBy || 'createdAt'; // createdAt | balance | fullName | trades
  const order = req.query.order === 'asc' ? 1 : -1;

  const users = [];

  for (const user of store.users.values()) {
    if (user.role === 'admin') continue;
    if (search && !user.fullName.toLowerCase().includes(search) &&
        !user.email.toLowerCase().includes(search)) continue;

    // Compute live stats per user
    let openTrades = 0;
    let closedTrades = 0;
    let totalPnl = 0;
    let livePnl = 0;
    let totalLots = 0;
    let wins = 0;

    for (const t of store.trades.values()) {
      if (t.userId !== user.id) continue;
      if (t.status === 'open') {
        openTrades++;
        const cp = t.type === 'buy' ? state.bid : state.ask;
        livePnl += calcPnl(t, cp);
        totalLots += t.lotSize;
      } else {
        closedTrades++;
        totalPnl += (t.pnl || 0);
        totalLots += t.lotSize;
        if ((t.pnl || 0) >= 0) wins++;
      }
    }

    users.push({
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      accountType: user.accountType,
      balance: user.balance,
      equity: parseFloat((user.balance + livePnl).toFixed(2)),
      livePnl: parseFloat(livePnl.toFixed(2)),
      openTrades,
      closedTrades,
      totalTrades: openTrades + closedTrades,
      totalPnl: parseFloat(totalPnl.toFixed(2)),
      totalLots: parseFloat(totalLots.toFixed(2)),
      winRate: closedTrades > 0 ? parseFloat(((wins / closedTrades) * 100).toFixed(1)) : 0,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    });
  }

  // Sort
  users.sort((a, b) => {
    let av = a[sortBy], bv = b[sortBy];
    if (typeof av === 'string') av = av.toLowerCase();
    if (typeof bv === 'string') bv = bv.toLowerCase();
    return av < bv ? -order : av > bv ? order : 0;
  });

  const total = users.length;
  const start = (page - 1) * limit;
  const paged = users.slice(start, start + limit);

  res.json({ users: paged, total, page, pages: Math.ceil(total / limit) });
}));

// ── GET /api/v1/admin/users/:id ──────────────────────────────────────────────
// Single user detail with all trades
router.get('/users/:id', asyncWrap(async (req, res) => {
  const user = store.users.get(req.params.id);
  if (!user || user.role === 'admin') {
    return res.status(404).json({ error: 'User not found.' });
  }

  const state = priceState();
  const openTrades = [];
  const closedTrades = [];
  let livePnl = 0;
  let totalPnl = 0;
  let wins = 0;

  for (const t of store.trades.values()) {
    if (t.userId !== user.id) continue;
    if (t.status === 'open') {
      const cp = t.type === 'buy' ? state.bid : state.ask;
      const pnl = calcPnl(t, cp);
      livePnl += pnl;
      openTrades.push({ ...t, livePnl: parseFloat(pnl.toFixed(2)), currentPrice: cp });
    } else {
      closedTrades.push(t);
      totalPnl += (t.pnl || 0);
      if ((t.pnl || 0) >= 0) wins++;
    }
  }

  closedTrades.sort((a, b) => (b.closeTime || 0) - (a.closeTime || 0));

  const { passwordHash, ...safeUser } = user;
  res.json({
    user: {
      ...safeUser,
      equity: parseFloat((user.balance + livePnl).toFixed(2)),
      livePnl: parseFloat(livePnl.toFixed(2)),
    },
    openTrades,
    closedTrades: closedTrades.slice(0, 50),
    stats: {
      totalPnl: parseFloat(totalPnl.toFixed(2)),
      closedTrades: closedTrades.length,
      openTrades: openTrades.length,
      winRate: closedTrades.length > 0
        ? parseFloat(((wins / closedTrades.length) * 100).toFixed(1)) : 0,
      wins,
      losses: closedTrades.length - wins,
    },
  });
}));

// ── PATCH /api/v1/admin/users/:id/balance ───────────────────────────────────
// Adjust a user's balance
router.patch('/users/:id/balance', asyncWrap(async (req, res) => {
  const user = store.users.get(req.params.id);
  if (!user || user.role === 'admin') {
    return res.status(404).json({ error: 'User not found.' });
  }

  const { balance } = req.body;
  const newBal = parseFloat(balance);
  if (isNaN(newBal) || newBal < 0 || newBal > 10000000) {
    return res.status(400).json({ error: 'balance must be between 0 and 10,000,000.' });
  }

  const prevBal = user.balance;
  const diff    = parseFloat((newBal - prevBal).toFixed(2));
  store.users.set(user.id, { ...user, balance: newBal, updatedAt: Date.now() });

  // Record transaction so it appears in app history
  const txType = diff >= 0 ? 'deposit' : 'withdrawal';
  const label  = diff >= 0 ? 'Admin credit' : 'Admin debit';
  addTransaction(user.id, txType, Math.abs(diff),
    `${label}: $${Math.abs(diff).toFixed(2)} (balance set to $${newBal.toFixed(2)})`);

  res.json({ message: `Balance updated to $${newBal.toFixed(2)}`, balance: newBal, prev: prevBal });
}));

// ── DELETE /api/v1/admin/users/:id ──────────────────────────────────────────
// Delete a user and all their trades
router.delete('/users/:id', asyncWrap(async (req, res) => {
  const user = store.users.get(req.params.id);
  if (!user || user.role === 'admin') {
    return res.status(404).json({ error: 'User not found.' });
  }

  await deleteUser(user.id);
  res.json({ message: `User ${user.email} deleted.` });
}));

// ── GET /api/v1/admin/trades ─────────────────────────────────────────────────
// All trades across all users
router.get('/trades', asyncWrap(async (req, res) => {
  const state = priceState();
  const status = req.query.status || 'all';
  const page = parseInt(req.query.page) || 1;
  const limit = Math.min(parseInt(req.query.limit) || 50, 200);

  const trades = [];

  for (const t of store.trades.values()) {
    if (status !== 'all' && t.status !== status) continue;
    const user = store.users.get(t.userId);
    let livePnl = null;
    if (t.status === 'open') {
      const cp = t.type === 'buy' ? state.bid : state.ask;
      livePnl = parseFloat(calcPnl(t, cp).toFixed(2));
    }
    trades.push({
      ...t,
      livePnl,
      userName: user ? user.fullName : 'Unknown',
      userEmail: user ? user.email : '',
    });
  }

  trades.sort((a, b) => {
    if (a.status !== b.status) return a.status === 'open' ? -1 : 1;
    return (b.openTime || 0) - (a.openTime || 0);
  });

  const total = trades.length;
  const start = (page - 1) * limit;
  const paged = trades.slice(start, start + limit);

  res.json({ trades: paged, total, page, pages: Math.ceil(total / limit) });
}));

// ── POST /api/v1/admin/users/:id/close-all ──────────────────────────────────
// Force close all open trades for a user
router.post('/users/:id/close-all', asyncWrap(async (req, res) => {
  const user = store.users.get(req.params.id);
  if (!user) return res.status(404).json({ error: 'User not found.' });

  const state = priceState();
  let closed = 0;
  let totalPnl = 0;
  const now = Date.now();

  for (const [tid, t] of store.trades.entries()) {
    if (t.userId !== user.id || t.status !== 'open') continue;
    const cp = t.type === 'buy' ? state.bid : state.ask;
    const pnl = parseFloat(calcPnl(t, cp).toFixed(2));
    totalPnl += pnl;
    store.trades.set(tid, {
      ...t, status: 'closed', closePrice: cp, closeTime: now,
      pnl, closeReason: 'admin_close', updatedAt: now,
    });
    closed++;
  }

  const newBalance = parseFloat((user.balance + totalPnl).toFixed(2));
  store.users.set(user.id, { ...user, balance: newBalance, updatedAt: now });

  res.json({ closed, totalPnl: parseFloat(totalPnl.toFixed(2)), newBalance, message: `${closed} trades closed.` });
}));


// ── GET /api/v1/admin/simulation ──────────────────────────────────────────────
// Get current simulation speed / volatility / drift config
router.get('/simulation', asyncWrap(async (req, res) => {
  const config = getSimConfig();
  const speedLabel = _speedLabel(config.tickIntervalMs);
  const progress = config.simStartMs < config.simEndMs
    ? ((config.simDateMs - config.simStartMs) / (config.simEndMs - config.simStartMs) * 100).toFixed(1)
    : '0.0';
  res.json({
    ...config, speedLabel,
    simDateStr:  new Date(config.simDateMs).toISOString().slice(0,10),
    simStartStr: new Date(config.simStartMs).toISOString().slice(0,10),
    simEndStr:   new Date(config.simEndMs).toISOString().slice(0,10),
    progressPct: parseFloat(progress),
  });
}));

// ── PATCH /api/v1/admin/simulation ────────────────────────────────────────────
// Update simulation parameters at runtime
// Body (all optional):
//   tickIntervalMs : 20–30000  (ms between price ticks)
//   volatility     : 0.1–50     (price movement per tick)
//   drift          : -0.5–0.5   (directional bias)
//   simStatus      : 'running' | 'paused'
//   simStartMs     : timestamp (epoch ms)
//   simEndMs       : timestamp (epoch ms)
router.patch('/simulation', asyncWrap(async (req, res) => {
  const { tickIntervalMs, volatility, drift, simStatus, simStartMs, simEndMs } = req.body;
  const updates = {};
  if (tickIntervalMs !== undefined) updates.tickIntervalMs = tickIntervalMs;
  if (volatility     !== undefined) updates.volatility     = volatility;
  if (drift          !== undefined) updates.drift          = drift;
  if (simStartMs     !== undefined) updates.simStartMs     = simStartMs;
  if (simEndMs       !== undefined) updates.simEndMs       = simEndMs;

  if (simStatus !== undefined) {
    const allowed = ['idle', 'running', 'paused', 'stopped'];
    if (!allowed.includes(simStatus)) {
      return res.status(400).json({ error: `simStatus must be one of: ${allowed.join(', ')}` });
    }
    updates.simStatus = simStatus;
  }

  if (Object.keys(updates).length === 0) {
    return res.status(400).json({ error: 'Provide at least one field to update.' });
  }

  const config = setSimConfig(updates);
  res.json({
    message:    'Simulation config updated.',
    config,
    speedLabel: _speedLabel(config.tickIntervalMs),
  });
}));

// ── POST /api/v1/admin/simulation/reset ───────────────────────────────────────
// Reset the replay to Jan 1 2025 and set status to idle (stopped)
router.post('/simulation/reset', asyncWrap(async (_req, res) => {
  const current = getSimConfig();
  const config  = setSimConfig({
    simStatus:  'idle',
    simDateMs:  current.simStartMs,   // rewind to start date
  });
  res.json({
    message:     'Replay reset to start.',
    config,
    speedLabel:  _speedLabel(config.tickIntervalMs),
    simDateStr:  new Date(config.simDateMs).toISOString().slice(0, 10),
    simStartStr: new Date(config.simStartMs).toISOString().slice(0, 10),
    simEndStr:   new Date(config.simEndMs).toISOString().slice(0, 10),
    progressPct: 0,
  });
}));

// ── Helpers ────────────────────────────────────────────────────────────────────
function _speedLabel(ms) {
  if (ms <= 30)   return 'TURBO (~35/sec)';
  if (ms <= 100)  return 'ULTRA FAST';
  if (ms <= 200)  return 'ULTRA FAST';
  if (ms <= 500)  return 'FAST';
  if (ms <= 1000) return 'NORMAL';
  if (ms <= 3000) return 'SLOW';
  if (ms <= 8000) return 'VERY SLOW';
  return 'PAUSED-LIKE';
}

module.exports = router;
