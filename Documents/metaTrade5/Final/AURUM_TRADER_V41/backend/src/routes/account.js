'use strict';
const express  = require('express');
const { v4: uuidv4 } = require('uuid');
const { priceState, calcPnl } = require('../models/store');
const User        = require('../models/User');
const Trade       = require('../models/Trade');
const Transaction = require('../models/Transaction');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();
router.use(authenticate);

// ── GET /api/v1/account ───────────────────────────────────────────────────────
router.get('/', asyncWrap(async (req, res) => {
  const user = await User.findById(req.userId).lean();
  if (!user) return res.status(404).json({ error: 'Account not found.' });
  const state = priceState();
  let livePnl = 0, openLots = 0, openCount = 0, usedMargin = 0;
  const openTrades = await Trade.find({ userId: req.userId, status: 'open' }).lean();
  for (const t of openTrades) {
    livePnl    += calcPnl(t, t.type === 'buy' ? state.bid : state.ask);
    openLots   += t.lotSize;
    openCount++;
    usedMargin += (t.margin || 0);
  }
  livePnl = parseFloat(livePnl.toFixed(2));
  const equity      = parseFloat((user.balance + livePnl).toFixed(2));
  const margin      = parseFloat(usedMargin.toFixed(2));
  const freeMargin  = parseFloat((equity - margin).toFixed(2));
  const marginLevel = margin > 0 ? parseFloat(((equity / margin) * 100).toFixed(1)) : 0;
  res.json({ account: { id: user._id, fullName: user.fullName, email: user.email, accountType: user.accountType, currency: 'USD', leverage: user.leverage || 100, balance: user.balance, equity, livePnl, margin, freeMargin, marginLevel, openPositions: openCount, openLots: parseFloat(openLots.toFixed(2)), createdAt: user.createdAt } });
}));

// ── GET /api/v1/account/stats ─────────────────────────────────────────────────
router.get('/stats', asyncWrap(async (req, res) => {
  const trades = await Trade.find({ userId: req.userId, status: 'closed' }).lean();
  let total = 0, wins = 0, losses = 0, totalPnl = 0, totalLots = 0, best = null, worst = null;
  for (const t of trades) {
    total++; totalLots += t.lotSize;
    const p = t.pnl || 0; totalPnl += p;
    if (p >= 0) wins++; else losses++;
    if (!best  || p > best.pnl)  best  = t;
    if (!worst || p < worst.pnl) worst = t;
  }
  res.json({ stats: { totalTrades: total, wins, losses, winRate: total > 0 ? parseFloat(((wins / total) * 100).toFixed(1)) : 0, totalPnl: parseFloat(totalPnl.toFixed(2)), avgPnl: total > 0 ? parseFloat((totalPnl / total).toFixed(2)) : 0, totalLots: parseFloat(totalLots.toFixed(2)), bestTrade: best ? { pnl: best.pnl, openPrice: best.openPrice } : null, worstTrade: worst ? { pnl: worst.pnl, openPrice: worst.openPrice } : null } });
}));

// ── GET /api/v1/account/transactions ─────────────────────────────────────────
router.get('/transactions', asyncWrap(async (req, res) => {
  const page  = parseInt(req.query.page)  || 1;
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);
  const total = await Transaction.countDocuments({ userId: req.userId });
  const txs   = await Transaction.find({ userId: req.userId })
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();
  res.json({ transactions: txs, total, page, pages: Math.ceil(total / limit) });
}));

// ── GET/PUT /api/v1/account/leverage ─────────────────────────────────────────
router.get('/leverage', asyncWrap(async (req, res) => {
  const user = await User.findById(req.userId).lean();
  res.json({ leverage: user?.leverage || 100, available: [1, 10, 25, 50, 100, 200, 500] });
}));
router.put('/leverage', asyncWrap(async (req, res) => {
  const valid = [1, 10, 25, 50, 100, 200, 500];
  const lev = parseInt(req.body.leverage);
  if (!valid.includes(lev)) return res.status(400).json({ error: `leverage must be one of: ${valid.join(', ')}` });
  const user = await User.findById(req.userId).lean();
  if (!user) return res.status(404).json({ error: 'Account not found.' });
  await User.findByIdAndUpdate(req.userId, { $set: { leverage: lev, updatedAt: Date.now() } });
  res.json({ leverage: lev, message: `Leverage set to 1:${lev}` });
}));

// ── Deposit / Withdraw ────────────────────────────────────────────────────────
router.post('/deposit', asyncWrap(async (req, res) => {
  const dep = parseFloat(req.body.amount);
  if (isNaN(dep) || dep <= 0 || dep > 1_000_000) return res.status(400).json({ error: 'amount must be 1–1,000,000.' });
  const user = await User.findById(req.userId).lean();
  if (!user) return res.status(404).json({ error: 'Account not found.' });
  const newBalance = parseFloat((user.balance + dep).toFixed(2));
  await User.findByIdAndUpdate(req.userId, { $set: { balance: newBalance, updatedAt: Date.now() } });
  await Transaction.create({ _id: uuidv4(), userId: req.userId, type: 'deposit', amount: dep, description: `Deposit of $${dep.toFixed(2)}`, createdAt: Date.now() });
  res.json({ balance: newBalance, deposited: dep, message: `$${dep.toFixed(2)} deposited.` });
}));
router.post('/withdraw', asyncWrap(async (req, res) => {
  const amt = parseFloat(req.body.amount);
  if (isNaN(amt) || amt <= 0) return res.status(400).json({ error: 'amount must be positive.' });
  const user = await User.findById(req.userId).lean();
  if (!user) return res.status(404).json({ error: 'Account not found.' });
  if (amt > user.balance) return res.status(400).json({ error: 'Insufficient balance.' });
  const newBalance = parseFloat((user.balance - amt).toFixed(2));
  await User.findByIdAndUpdate(req.userId, { $set: { balance: newBalance, updatedAt: Date.now() } });
  await Transaction.create({ _id: uuidv4(), userId: req.userId, type: 'withdrawal', amount: -amt, description: `Withdrawal of $${amt.toFixed(2)}`, createdAt: Date.now() });
  res.json({ balance: newBalance, withdrawn: amt, message: `$${amt.toFixed(2)} withdrawn.` });
}));

// ── Profile update ────────────────────────────────────────────────────────────
router.put('/profile', asyncWrap(async (req, res) => {
  const { fullName } = req.body;
  if (!fullName?.trim()) return res.status(400).json({ error: 'fullName is required.' });
  const user = await User.findById(req.userId).lean();
  if (!user) return res.status(404).json({ error: 'User not found.' });
  await User.findByIdAndUpdate(req.userId, { $set: { fullName: fullName.trim(), updatedAt: Date.now() } });
  res.json({ user: { ...user, id: user._id, fullName: fullName.trim() }, message: 'Profile updated.' });
}));

module.exports = router;
