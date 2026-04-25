'use strict';

const express  = require('express');
const { v4: uuidv4 } = require('uuid');
const { priceState, calcPnl } = require('../models/store');
const User         = require('../models/User');
const Trade        = require('../models/Trade');
const PendingOrder = require('../models/PendingOrder');
const Transaction  = require('../models/Transaction');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();
router.use(authenticate);

// ── GET /api/v1/trades ────────────────────────────────────────────────────────
router.get('/', asyncWrap(async (req, res) => {
  const status = req.query.status || 'all';
  const page   = parseInt(req.query.page)  || 1;
  const limit  = Math.min(parseInt(req.query.limit) || 50, 100);
  const query  = { userId: req.userId };
  if (status !== 'all') query.status = status;
  const total  = await Trade.countDocuments(query);
  const trades = await Trade.find(query)
    .sort({ openTime: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();
  res.json({ trades: trades.map(_enrichTrade), total, page, pages: Math.ceil(total / limit) });
}));

// ── GET /api/v1/trades/open ───────────────────────────────────────────────────
router.get('/open', asyncWrap(async (req, res) => {
  const state  = priceState();
  const trades = await Trade.find({ userId: req.userId, status: 'open' }).lean();
  let totalPnl = 0;
  const open = trades.map(t => {
    const cp  = t.type === 'buy' ? state.bid : state.ask;
    const pnl = calcPnl(t, cp);
    totalPnl += pnl;
    return { ..._enrichTrade(t), currentPrice: cp, livePnl: parseFloat(pnl.toFixed(2)) };
  });
  res.json({ trades: open, count: open.length, totalLivePnl: parseFloat(totalPnl.toFixed(2)), bid: state.bid, ask: state.ask });
}));

// ── GET /api/v1/trades/history ────────────────────────────────────────────────
router.get('/history', asyncWrap(async (req, res) => {
  const page   = parseInt(req.query.page)  || 1;
  const limit  = Math.min(parseInt(req.query.limit) || 20, 100);
  const total  = await Trade.countDocuments({ userId: req.userId, status: 'closed' });
  const trades = await Trade.find({ userId: req.userId, status: 'closed' })
    .sort({ closeTime: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();
  let totalPnl = 0, wins = 0, losses = 0;
  const allClosed = await Trade.find({ userId: req.userId, status: 'closed' }).lean();
  for (const t of allClosed) {
    totalPnl += t.pnl || 0;
    if ((t.pnl || 0) >= 0) wins++; else losses++;
  }
  res.json({ trades: trades.map(_enrichTrade), total, page, pages: Math.ceil(total / limit), summary: { totalPnl: parseFloat(totalPnl.toFixed(2)), totalTrades: total, wins, losses, winRate: total > 0 ? parseFloat(((wins / total) * 100).toFixed(1)) : 0 } });
}));

// ── GET /api/v1/trades/pending ────────────────────────────────────────────────
router.get('/pending', asyncWrap(async (req, res) => {
  const orders = await PendingOrder.find({ userId: req.userId, status: 'pending' }).sort({ createdAt: -1 }).lean();
  res.json({ orders: orders.map(_enrichPending), count: orders.length });
}));

// ── POST /api/v1/trades/pending ───────────────────────────────────────────────
router.post('/pending', asyncWrap(async (req, res) => {
  const { type, lotSize, price, stopLoss, takeProfit, expiry } = req.body;
  const validTypes = ['buy_limit', 'sell_limit', 'buy_stop', 'sell_stop'];
  if (!validTypes.includes(type)) return res.status(400).json({ error: `type must be one of: ${validTypes.join(', ')}` });
  const lot = parseFloat(lotSize);
  if (isNaN(lot) || lot < 0.01 || lot > 100) return res.status(400).json({ error: 'lotSize must be 0.01–100.' });
  const triggerPrice = parseFloat(price);
  if (isNaN(triggerPrice) || triggerPrice <= 0) return res.status(400).json({ error: 'price must be a positive number.' });
  const state = priceState();
  const cur   = state.bid;
  const SLIP  = 0.50;
  if (type === 'buy_limit'  && triggerPrice >= cur + SLIP) return res.status(400).json({ error: `Buy Limit price must be BELOW current price ${cur.toFixed(2)}.` });
  if (type === 'sell_limit' && triggerPrice <= cur - SLIP) return res.status(400).json({ error: `Sell Limit price must be ABOVE current price ${cur.toFixed(2)}.` });
  if (type === 'buy_stop'   && triggerPrice <= cur - SLIP) return res.status(400).json({ error: `Buy Stop price must be ABOVE current price ${cur.toFixed(2)}.` });
  if (type === 'sell_stop'  && triggerPrice >= cur + SLIP) return res.status(400).json({ error: `Sell Stop price must be BELOW current price ${cur.toFixed(2)}.` });
  const now   = Date.now();
  const order = { _id: uuidv4(), userId: req.userId, symbol: 'XAU/USD', type, lotSize: lot, price: triggerPrice, stopLoss: stopLoss != null ? parseFloat(stopLoss) : null, takeProfit: takeProfit != null ? parseFloat(takeProfit) : null, expiry: expiry ? parseInt(expiry) : null, status: 'pending', createdAt: now, updatedAt: now };
  await PendingOrder.create(order);
  res.status(201).json({ pending: _enrichPending({ ...order, id: order._id }), message: `${type} order placed at ${triggerPrice}` });
}));

// ── DELETE /api/v1/trades/pending/:id ────────────────────────────────────────
router.delete('/pending/:id', asyncWrap(async (req, res) => {
  const order = await PendingOrder.findById(req.params.id).lean();
  if (!order || order.userId !== req.userId) return res.status(404).json({ error: 'Order not found.' });
  if (order.status !== 'pending') return res.status(409).json({ error: 'Order already triggered or cancelled.' });
  await PendingOrder.findByIdAndUpdate(req.params.id, { $set: { status: 'cancelled', updatedAt: Date.now() } });
  res.json({ message: 'Order cancelled.', id: req.params.id });
}));

// ── PATCH /api/v1/trades/pending/:id ─────────────────────────────────────────
router.patch('/pending/:id', asyncWrap(async (req, res) => {
  const order = await PendingOrder.findById(req.params.id).lean();
  if (!order || order.userId !== req.userId) return res.status(404).json({ error: 'Order not found.' });
  if (order.status !== 'pending') return res.status(409).json({ error: 'Cannot modify a triggered/cancelled order.' });
  const { price, stopLoss, takeProfit, lotSize } = req.body;
  const updates = {
    price:      price      != null ? parseFloat(price)      : order.price,
    stopLoss:   stopLoss   !== undefined ? (stopLoss   != null ? parseFloat(stopLoss)   : null) : order.stopLoss,
    takeProfit: takeProfit !== undefined ? (takeProfit != null ? parseFloat(takeProfit) : null) : order.takeProfit,
    lotSize:    lotSize    != null ? parseFloat(lotSize)    : order.lotSize,
    updatedAt:  Date.now(),
  };
  const updated = await PendingOrder.findByIdAndUpdate(req.params.id, { $set: updates }, { new: true }).lean();
  res.json({ pending: _enrichPending({ ...updated, id: updated._id }), message: 'Order modified.' });
}));

// ── GET /api/v1/trades/:id ────────────────────────────────────────────────────
router.get('/:id', asyncWrap(async (req, res) => {
  const trade = await Trade.findById(req.params.id).lean();
  if (!trade || trade.userId !== req.userId) return res.status(404).json({ error: 'Trade not found.' });
  let livePnl = null;
  if (trade.status === 'open') {
    const state = priceState();
    livePnl = parseFloat(calcPnl(trade, trade.type === 'buy' ? state.bid : state.ask).toFixed(2));
  }
  res.json({ trade: { ..._enrichTrade(trade), livePnl } });
}));

// ── POST /api/v1/trades ───────────────────────────────────────────────────────
router.post('/', asyncWrap(async (req, res) => {
  const { type, lotSize, stopLoss, takeProfit } = req.body;
  if (!type || !['buy', 'sell'].includes(type)) return res.status(400).json({ error: 'type must be "buy" or "sell".' });
  const lot = parseFloat(lotSize);
  if (isNaN(lot) || lot < 0.01 || lot > 100) return res.status(400).json({ error: 'lotSize must be 0.01–100.' });
  const state     = priceState();
  const openPrice = type === 'buy' ? state.ask : state.bid;
  const SLIP      = 0.10;
  if (stopLoss   != null) { const sl = parseFloat(stopLoss);   if (type === 'buy'  && sl >= openPrice + SLIP) return res.status(400).json({ error: `SL ${sl} must be below open price ${openPrice} for BUY.` });   if (type === 'sell' && sl <= openPrice - SLIP) return res.status(400).json({ error: `SL ${sl} must be above open price ${openPrice} for SELL.` }); }
  if (takeProfit != null) { const tp = parseFloat(takeProfit); if (type === 'buy'  && tp <= openPrice - SLIP) return res.status(400).json({ error: `TP ${tp} must be above open price ${openPrice} for BUY.` });  if (type === 'sell' && tp >= openPrice + SLIP) return res.status(400).json({ error: `TP ${tp} must be below open price ${openPrice} for SELL.` }); }
  const user      = await User.findById(req.userId).lean();
  const leverage  = user?.leverage || 100;
  const margin    = parseFloat((lot * openPrice * 100 / leverage).toFixed(2));
  const now       = Date.now();
  const tradeDoc  = { _id: uuidv4(), userId: req.userId, symbol: 'XAU/USD', type, lotSize: lot, openPrice, closePrice: null, stopLoss: stopLoss != null ? parseFloat(stopLoss) : null, takeProfit: takeProfit != null ? parseFloat(takeProfit) : null, margin, status: 'open', openTime: now, closeTime: null, pnl: null, closeReason: null, createdAt: now, updatedAt: now };
  await Trade.create(tradeDoc);
  if (user) await User.findByIdAndUpdate(req.userId, { $set: { balance: parseFloat((user.balance - margin).toFixed(2)), updatedAt: now } });
  await Transaction.create({ _id: uuidv4(), userId: req.userId, type: 'trade_open', amount: -margin, description: `${type.toUpperCase()} ${lot} lots @ ${openPrice} (margin: $${margin})`, createdAt: now });
  res.status(201).json({ trade: _enrichTrade({ ...tradeDoc, id: tradeDoc._id }), message: `${type.toUpperCase()} opened at ${openPrice}` });
}));

// ── DELETE /api/v1/trades/:id ─────────────────────────────────────────────────
router.delete('/:id', asyncWrap(async (req, res) => {
  const trade = await Trade.findById(req.params.id).lean();
  if (!trade || trade.userId !== req.userId) return res.status(404).json({ error: 'Trade not found.' });
  if (trade.status !== 'open') return res.status(409).json({ error: 'Trade already closed.' });
  const state      = priceState();
  const closePrice = trade.type === 'buy' ? state.bid : state.ask;
  const pnl        = parseFloat(calcPnl(trade, closePrice).toFixed(2));
  const now        = Date.now();
  await Trade.findByIdAndUpdate(req.params.id, { $set: { status: 'closed', closePrice, closeTime: now, pnl, closeReason: 'manual', updatedAt: now } });
  const user = await User.findById(req.userId).lean();
  if (user) await User.findByIdAndUpdate(req.userId, { $set: { balance: parseFloat((user.balance + (trade.margin || 0) + pnl).toFixed(2)), updatedAt: now } });
  await Transaction.create({ _id: uuidv4(), userId: req.userId, type: pnl >= 0 ? 'profit' : 'loss', amount: pnl, description: `Closed ${trade.type.toUpperCase()} @ ${closePrice} — P&L: ${pnl >= 0 ? '+' : ''}$${pnl}`, createdAt: now });
  res.json({ trade: _enrichTrade({ ...trade, id: trade._id, status: 'closed', closePrice, closeTime: now, pnl }), pnl, message: `Closed @ ${closePrice}. P&L: ${pnl >= 0 ? '+' : ''}$${pnl}` });
}));

// ── PATCH /api/v1/trades/:id ──────────────────────────────────────────────────
router.patch('/:id', asyncWrap(async (req, res) => {
  const trade = await Trade.findById(req.params.id).lean();
  if (!trade || trade.userId !== req.userId) return res.status(404).json({ error: 'Trade not found.' });
  if (trade.status !== 'open') return res.status(409).json({ error: 'Cannot modify closed trade.' });
  const { stopLoss, takeProfit } = req.body;
  const updates = {
    stopLoss:   stopLoss   !== undefined ? (stopLoss   != null ? parseFloat(stopLoss)   : null) : trade.stopLoss,
    takeProfit: takeProfit !== undefined ? (takeProfit != null ? parseFloat(takeProfit) : null) : trade.takeProfit,
    updatedAt:  Date.now(),
  };
  const updated = await Trade.findByIdAndUpdate(req.params.id, { $set: updates }, { new: true }).lean();
  res.json({ trade: _enrichTrade({ ...updated, id: updated._id }), message: 'Modified.' });
}));

function _enrichTrade(t) {
  return { id: t.id || t._id, symbol: t.symbol, type: t.type, lotSize: t.lotSize, openPrice: t.openPrice, closePrice: t.closePrice, stopLoss: t.stopLoss, takeProfit: t.takeProfit, status: t.status, openTime: t.openTime, closeTime: t.closeTime, pnl: t.pnl, closeReason: t.closeReason, margin: t.margin ?? null };
}
function _enrichPending(o) {
  return { id: o.id || o._id, symbol: o.symbol, type: o.type, lotSize: o.lotSize, price: o.price, stopLoss: o.stopLoss, takeProfit: o.takeProfit, status: o.status, createdAt: o.createdAt, expiry: o.expiry || null };
}

module.exports = router;
