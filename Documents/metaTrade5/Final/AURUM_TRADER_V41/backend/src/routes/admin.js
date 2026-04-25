'use strict';

const express = require('express');
const { v4: uuidv4 } = require('uuid');

const { priceState, calcPnl, deleteUser, getSimConfig, setSimConfig } = require('../models/store');
const User        = require('../models/User');
const Trade       = require('../models/Trade');
const PendingOrder = require('../models/PendingOrder');
const Transaction = require('../models/Transaction');

const { authenticate } = require('../middleware/auth');
const { asyncWrap }    = require('../middleware/errorHandler');

const router = express.Router();

// ── Admin secret key guard ───────────────────────────────────────────────────
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'mt5_admin_secret_2024';

function adminAuth(req, res, next) {
  const key = req.headers['x-admin-key'];
  if (key && key === ADMIN_SECRET) return next();
  return authenticate(req, res, async () => {
    try {
      const user = await User.findById(req.userId).lean();
      if (!user || user.role !== 'admin') {
        return res.status(403).json({ error: 'Admin access required.' });
      }
      next();
    } catch (e) {
      return res.status(403).json({ error: 'Admin access required.' });
    }
  });
}

// ── POST /api/v1/admin/login ─────────────────────────────────────────────────
router.post('/login', asyncWrap(async (req, res) => {
  const { password } = req.body;
  if (!password) return res.status(400).json({ error: 'password required.' });
  if (password !== ADMIN_SECRET) {
    return res.status(401).json({ error: 'Invalid admin credentials.' });
  }
  res.json({ token: ADMIN_SECRET, message: 'Admin authenticated.' });
}));

// All routes below require admin auth
router.use(adminAuth);

// ── GET /api/v1/admin/stats ──────────────────────────────────────────────────
router.get('/stats', asyncWrap(async (req, res) => {
  const state = priceState();

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayTs = today.getTime();

  const users  = await User.find({ role: { $ne: 'admin' } }).lean();
  const trades = await Trade.find({}).lean();

  // Build userId → user map for quick lookups
  const userMap = new Map(users.map(u => [String(u._id), u]));

  let totalBalance = 0, activeToday = 0;
  for (const u of users) {
    totalBalance += u.balance;
    if ((u.createdAt || 0) >= todayTs) activeToday++;
  }

  let totalOpenTrades = 0, totalClosedTrades = 0, totalPnl = 0, totalVolume = 0;
  for (const t of trades) {
    const u = userMap.get(String(t.userId));
    if (!u || u.role === 'admin') continue;
    if (t.status === 'open') {
      totalOpenTrades++;
      const cp = t.type === 'buy' ? state.bid : state.ask;
      totalPnl += calcPnl(t, cp);
      totalVolume += t.lotSize;
    } else {
      totalClosedTrades++;
      totalPnl += (t.pnl || 0);
      totalVolume += t.lotSize;
    }
  }

  res.json({
    stats: {
      totalUsers:        users.length,
      totalBalance:      parseFloat(totalBalance.toFixed(2)),
      totalOpenTrades,
      totalClosedTrades,
      totalTrades:       totalOpenTrades + totalClosedTrades,
      totalPnl:          parseFloat(totalPnl.toFixed(2)),
      totalVolume:       parseFloat(totalVolume.toFixed(2)),
      newUsersToday:     activeToday,
      currentBid:        state.bid,
      currentAsk:        state.ask,
      spread:            state.spread,
    },
  });
}));

// ── GET /api/v1/admin/users ──────────────────────────────────────────────────
router.get('/users', asyncWrap(async (req, res) => {
  const state   = priceState();
  const search  = (req.query.search || '').toLowerCase();
  const page    = parseInt(req.query.page)  || 1;
  const limit   = Math.min(parseInt(req.query.limit) || 20, 100);
  const sortBy  = req.query.sortBy || 'createdAt';
  const order   = req.query.order === 'asc' ? 1 : -1;

  const query = { role: { $ne: 'admin' } };
  if (search) {
    query.$or = [
      { fullName: { $regex: search, $options: 'i' } },
      { email:    { $regex: search, $options: 'i' } },
    ];
  }

  const rawUsers = await User.find(query).lean();
  const allTrades = await Trade.find({}).lean();

  // Group trades by userId
  const tradesByUser = new Map();
  for (const t of allTrades) {
    const uid = String(t.userId);
    if (!tradesByUser.has(uid)) tradesByUser.set(uid, []);
    tradesByUser.get(uid).push(t);
  }

  const users = rawUsers.map(u => {
    const uid = String(u._id);
    const userTrades = tradesByUser.get(uid) || [];
    let openTrades = 0, closedTrades = 0, totalPnl = 0, livePnl = 0, totalLots = 0, wins = 0;

    for (const t of userTrades) {
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

    return {
      id:           uid,
      fullName:     u.fullName,
      email:        u.email,
      accountType:  u.accountType,
      balance:      u.balance,
      equity:       parseFloat((u.balance + livePnl).toFixed(2)),
      livePnl:      parseFloat(livePnl.toFixed(2)),
      openTrades,
      closedTrades,
      totalTrades:  openTrades + closedTrades,
      totalPnl:     parseFloat(totalPnl.toFixed(2)),
      totalLots:    parseFloat(totalLots.toFixed(2)),
      winRate:      closedTrades > 0 ? parseFloat(((wins / closedTrades) * 100).toFixed(1)) : 0,
      createdAt:    u.createdAt,
      updatedAt:    u.updatedAt,
    };
  });

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
router.get('/users/:id', asyncWrap(async (req, res) => {
  const user = await User.findById(req.params.id).lean();
  if (!user || user.role === 'admin') {
    return res.status(404).json({ error: 'User not found.' });
  }

  const state = priceState();
  const trades = await Trade.find({ userId: req.params.id }).lean();

  const openTrades   = [];
  const closedTrades = [];
  let livePnl = 0, totalPnl = 0, wins = 0;

  for (const t of trades) {
    if (t.status === 'open') {
      const cp  = t.type === 'buy' ? state.bid : state.ask;
      const pnl = calcPnl(t, cp);
      livePnl += pnl;
      openTrades.push({ ...t, id: String(t._id), livePnl: parseFloat(pnl.toFixed(2)), currentPrice: cp });
    } else {
      closedTrades.push({ ...t, id: String(t._id) });
      totalPnl += (t.pnl || 0);
      if ((t.pnl || 0) >= 0) wins++;
    }
  }

  closedTrades.sort((a, b) => (b.closeTime || 0) - (a.closeTime || 0));

  const { passwordHash, _id, ...rest } = user;
  res.json({
    user: {
      ...rest,
      id:      String(_id),
      equity:  parseFloat((user.balance + livePnl).toFixed(2)),
      livePnl: parseFloat(livePnl.toFixed(2)),
    },
    openTrades,
    closedTrades: closedTrades.slice(0, 50),
    stats: {
      totalPnl:     parseFloat(totalPnl.toFixed(2)),
      closedTrades: closedTrades.length,
      openTrades:   openTrades.length,
      winRate:      closedTrades.length > 0
        ? parseFloat(((wins / closedTrades.length) * 100).toFixed(1)) : 0,
      wins,
      losses: closedTrades.length - wins,
    },
  });
}));

// ── PATCH /api/v1/admin/users/:id/balance ───────────────────────────────────
router.patch('/users/:id/balance', asyncWrap(async (req, res) => {
  const user = await User.findById(req.params.id).lean();
  if (!user || user.role === 'admin') {
    return res.status(404).json({ error: 'User not found.' });
  }

  const newBal = parseFloat(req.body.balance);
  if (isNaN(newBal) || newBal < 0 || newBal > 10000000) {
    return res.status(400).json({ error: 'balance must be between 0 and 10,000,000.' });
  }

  const prevBal = user.balance;
  const diff    = parseFloat((newBal - prevBal).toFixed(2));

  await User.findByIdAndUpdate(req.params.id, { $set: { balance: newBal, updatedAt: Date.now() } });

  const txType = diff >= 0 ? 'deposit' : 'withdrawal';
  const label  = diff >= 0 ? 'Admin credit' : 'Admin debit';
  await Transaction.create({
    _id:         uuidv4(),
    userId:      String(user._id),
    type:        txType,
    amount:      Math.abs(diff),
    description: `${label}: $${Math.abs(diff).toFixed(2)} (balance set to $${newBal.toFixed(2)})`,
    createdAt:   Date.now(),
  });

  res.json({ message: `Balance updated to $${newBal.toFixed(2)}`, balance: newBal, prev: prevBal });
}));

// ── DELETE /api/v1/admin/users/:id ──────────────────────────────────────────
router.delete('/users/:id', asyncWrap(async (req, res) => {
  const user = await User.findById(req.params.id).lean();
  if (!user || user.role === 'admin') {
    return res.status(404).json({ error: 'User not found.' });
  }

  await deleteUser(req.params.id);
  res.json({ message: `User ${user.email} deleted.` });
}));

// ── GET /api/v1/admin/trades ─────────────────────────────────────────────────
router.get('/trades', asyncWrap(async (req, res) => {
  const state   = priceState();
  const status  = req.query.status || 'all';
  const page    = parseInt(req.query.page)  || 1;
  const limit   = Math.min(parseInt(req.query.limit) || 50, 200);

  const query = status !== 'all' ? { status } : {};
  const rawTrades = await Trade.find(query).lean();

  // Fetch user info for all unique userIds
  const userIds = [...new Set(rawTrades.map(t => String(t.userId)))];
  const users   = await User.find({ _id: { $in: userIds } }).lean();
  const userMap = new Map(users.map(u => [String(u._id), u]));

  const trades = rawTrades.map(t => {
    const u = userMap.get(String(t.userId));
    let livePnl = null;
    if (t.status === 'open') {
      const cp = t.type === 'buy' ? state.bid : state.ask;
      livePnl  = parseFloat(calcPnl(t, cp).toFixed(2));
    }
    return {
      ...t,
      id:        String(t._id),
      livePnl,
      userName:  u ? u.fullName : 'Unknown',
      userEmail: u ? u.email    : '',
    };
  });

  trades.sort((a, b) => {
    if (a.status !== b.status) return a.status === 'open' ? -1 : 1;
    return (b.openTime || 0) - (a.openTime || 0);
  });

  const total = trades.length;
  const start = (page - 1) * limit;
  res.json({ trades: trades.slice(start, start + limit), total, page, pages: Math.ceil(total / limit) });
}));

// ── POST /api/v1/admin/users/:id/close-all ──────────────────────────────────
router.post('/users/:id/close-all', asyncWrap(async (req, res) => {
  const user = await User.findById(req.params.id).lean();
  if (!user) return res.status(404).json({ error: 'User not found.' });

  const state = priceState();
  const openTrades = await Trade.find({ userId: req.params.id, status: 'open' }).lean();

  let closed = 0, totalPnl = 0;
  const now = Date.now();

  for (const t of openTrades) {
    const cp  = t.type === 'buy' ? state.bid : state.ask;
    const pnl = parseFloat(calcPnl(t, cp).toFixed(2));
    totalPnl += pnl;

    await Trade.findByIdAndUpdate(t._id, {
      $set: { status: 'closed', closePrice: cp, closeTime: now, pnl, closeReason: 'admin_close' }
    });
    closed++;
  }

  const newBalance = parseFloat((user.balance + totalPnl).toFixed(2));
  await User.findByIdAndUpdate(req.params.id, { $set: { balance: newBalance, updatedAt: now } });

  res.json({ closed, totalPnl: parseFloat(totalPnl.toFixed(2)), newBalance, message: `${closed} trades closed.` });
}));

// ── GET /api/v1/admin/simulation ─────────────────────────────────────────────
router.get('/simulation', asyncWrap(async (req, res) => {
  res.json(getSimConfig());
}));

// ── PATCH /api/v1/admin/simulation ───────────────────────────────────────────
router.patch('/simulation', asyncWrap(async (req, res) => {
  const { tickIntervalMs, volatility, drift, simStatus, simStartMs, simEndMs, simDateMs } = req.body;
  const updates = {};
  if (tickIntervalMs !== undefined) updates.tickIntervalMs = tickIntervalMs;
  if (volatility     !== undefined) updates.volatility     = volatility;
  if (drift          !== undefined) updates.drift          = drift;
  if (simStartMs     !== undefined) updates.simStartMs     = simStartMs;
  if (simEndMs       !== undefined) updates.simEndMs       = simEndMs;
  if (simDateMs      !== undefined) updates.simDateMs      = simDateMs;

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
  res.json({ ...config, message: 'Simulation config updated.' });
}));

// ── POST /api/v1/admin/simulation/reset ──────────────────────────────────────
router.post('/simulation/reset', asyncWrap(async (_req, res) => {
  const current = getSimConfig();
  const config  = setSimConfig({ simStatus: 'idle', simDateMs: current.simStartMs });
  res.json({ ...config, message: 'Replay reset to start.' });
}));

// ── POST /api/v1/admin/game/init ─────────────────────────────────────────────
router.post('/game/init', asyncWrap(async (req, res) => {
  const balance = Math.max(1, parseFloat(req.body?.balance) || 10000);
  const state   = priceState();
  const now     = Date.now();
  let tradesClosed = 0, ordersCancelled = 0, usersReset = 0;

  // Close all open trades at current market price
  const openTrades = await Trade.find({ status: 'open' }).lean();
  for (const t of openTrades) {
    const closePrice = t.type === 'buy' ? state.bid : state.ask;
    const pnl = calcPnl(t, closePrice);
    await Trade.findByIdAndUpdate(t._id, {
      $set: { status: 'closed', closePrice, closeTime: now, pnl, closeReason: 'game_reset' }
    });
    tradesClosed++;
  }

  // Cancel all pending orders
  const pendingOrders = await PendingOrder.find({ status: 'pending' }).lean();
  for (const o of pendingOrders) {
    await PendingOrder.findByIdAndUpdate(o._id, { $set: { status: 'cancelled', updatedAt: now } });
    ordersCancelled++;
  }

  // Reset all non-admin user balances
  const result = await User.updateMany(
    { role: { $ne: 'admin' } },
    { $set: { balance, updatedAt: now } }
  );
  usersReset = result.modifiedCount;

  res.json({
    message:        `Game initialised — ${usersReset} users reset to $${balance.toFixed(2)}.`,
    usersReset,
    tradesClosed,
    ordersCancelled,
    initialBalance: balance,
  });
}));

// ── GET /api/v1/admin/rankings ────────────────────────────────────────────────
router.get('/rankings', asyncWrap(async (req, res) => {
  const state = priceState();

  const users  = await User.find({ role: { $ne: 'admin' } }).lean();
  const trades = await Trade.find({}).lean();

  // Group trades by userId
  const tradesByUser = new Map();
  for (const t of trades) {
    const uid = String(t.userId);
    if (!tradesByUser.has(uid)) tradesByUser.set(uid, []);
    tradesByUser.get(uid).push(t);
  }

  const userStats = users.map(u => {
    const uid = String(u._id);
    const userTrades = tradesByUser.get(uid) || [];
    let totalPnl = 0, wins = 0, losses = 0, openCount = 0, closedCount = 0, livePnl = 0;

    for (const t of userTrades) {
      if (t.status === 'open') {
        openCount++;
        const cp = t.type === 'buy' ? state.bid : state.ask;
        livePnl += calcPnl(t, cp);
      } else if (t.status === 'closed') {
        closedCount++;
        const pnl = t.pnl || 0;
        totalPnl += pnl;
        if (pnl >= 0) wins++; else losses++;
      }
    }

    const winRate = closedCount > 0 ? parseFloat(((wins / closedCount) * 100).toFixed(1)) : 0;
    return {
      userId:      uid,
      name:        u.fullName || u.email,
      email:       u.email,
      balance:     parseFloat((u.balance + livePnl).toFixed(2)),
      cashBalance: parseFloat(u.balance.toFixed(2)),
      totalPnl:    parseFloat((totalPnl + livePnl).toFixed(2)),
      realizedPnl: parseFloat(totalPnl.toFixed(2)),
      livePnl:     parseFloat(livePnl.toFixed(2)),
      openTrades:  openCount,
      totalTrades: closedCount,
      wins,
      losses,
      winRate,
    };
  });

  userStats.sort((a, b) => b.balance - a.balance);
  const rankings = userStats.map((u, i) => ({ rank: i + 1, ...u }));

  res.json({ rankings, generatedAt: new Date().toISOString() });
}));

module.exports = router;
