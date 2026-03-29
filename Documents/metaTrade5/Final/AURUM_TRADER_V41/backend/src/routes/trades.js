'use strict';

const express  = require('express');
const { v4: uuidv4 } = require('uuid');
const { store, priceState, calcPnl, saveUser, saveTrade, savePendingOrder, addTransaction, getSimConfig } = require('../models/store');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();
router.use(authenticate);

// ── GET /api/v1/trades ────────────────────────────────────────────────────────
router.get('/', asyncWrap(async (req, res) => {
  const status = req.query.status || 'all';
  const page = parseInt(req.query.page) || 1;
  const limit = Math.min(parseInt(req.query.limit) || 50, 100);
  let trades = [];
  for (const t of store.trades.values()) {
    if (t.userId !== req.userId) continue;
    if (status !== 'all' && t.status !== status) continue;
    trades.push(_enrichTrade(t));
  }
  trades.sort((a,b) => { if(a.status!==b.status) return a.status==='open'?-1:1; return (b.closeTime||b.openTime)-(a.closeTime||a.openTime); });
  const total = trades.length;
  res.json({ trades: trades.slice((page-1)*limit,page*limit), total, page, pages: Math.ceil(total/limit) });
}));

// ── GET /api/v1/trades/open ───────────────────────────────────────────────────
router.get('/open', asyncWrap(async (req, res) => {
  const state = priceState();
  const open = []; let totalPnl = 0;
  for (const t of store.trades.values()) {
    if (t.userId !== req.userId || t.status !== 'open') continue;
    const closePrice = t.type === 'buy' ? state.bid : state.ask;
    const pnl = calcPnl(t, closePrice);
    totalPnl += pnl;
    open.push({ ..._enrichTrade(t), currentPrice: closePrice, livePnl: parseFloat(pnl.toFixed(2)) });
  }
  res.json({ trades: open, count: open.length, totalLivePnl: parseFloat(totalPnl.toFixed(2)), bid: state.bid, ask: state.ask });
}));

// ── GET /api/v1/trades/history ────────────────────────────────────────────────
router.get('/history', asyncWrap(async (req, res) => {
  const page = parseInt(req.query.page)||1, limit = Math.min(parseInt(req.query.limit)||20,100);
  let closed=[], totalPnl=0, wins=0, losses=0;
  for (const t of store.trades.values()) {
    if (t.userId !== req.userId || t.status !== 'closed') continue;
    closed.push(_enrichTrade(t)); totalPnl += t.pnl||0;
    if((t.pnl||0)>=0) wins++; else losses++;
  }
  closed.sort((a,b)=>(b.closeTime||0)-(a.closeTime||0));
  const total = closed.length;
  res.json({ trades: closed.slice((page-1)*limit,page*limit), total, page, pages: Math.ceil(total/limit), summary: { totalPnl: parseFloat(totalPnl.toFixed(2)), totalTrades: total, wins, losses, winRate: total>0?parseFloat(((wins/total)*100).toFixed(1)):0 } });
}));

// ── GET /api/v1/trades/pending ────────────────────────────────────────────────
router.get('/pending', asyncWrap(async (req, res) => {
  const orders = [];
  for (const o of store.pendingOrders.values()) { if(o.userId===req.userId&&o.status==='pending') orders.push(_enrichPending(o)); }
  orders.sort((a,b)=>b.createdAt-a.createdAt);
  res.json({ orders, count: orders.length });
}));

// ── POST /api/v1/trades/pending ───────────────────────────────────────────────
router.post('/pending', asyncWrap(async (req, res) => {
  if (!_simGate(res)) return;
  const { type, lotSize, price, stopLoss, takeProfit, expiry } = req.body;
  const validTypes = ['buy_limit','sell_limit','buy_stop','sell_stop'];
  if (!validTypes.includes(type)) return res.status(400).json({ error: `type must be one of: ${validTypes.join(', ')}` });
  const lot = parseFloat(lotSize);
  if (isNaN(lot)||lot<0.01||lot>100) return res.status(400).json({ error: 'lotSize must be 0.01–100.' });
  const triggerPrice = parseFloat(price);
  if (isNaN(triggerPrice)||triggerPrice<=0) return res.status(400).json({ error: 'price must be a positive number.' });
  const state = priceState();
  const cur = state.bid;
  const SLIPPAGE = 0.50;
  if (type==='buy_limit' &&triggerPrice>=cur+SLIPPAGE) return res.status(400).json({ error: `Buy Limit price must be BELOW current price ${cur.toFixed(2)}.` });
  if (type==='sell_limit'&&triggerPrice<=cur-SLIPPAGE) return res.status(400).json({ error: `Sell Limit price must be ABOVE current price ${cur.toFixed(2)}.` });
  if (type==='buy_stop'  &&triggerPrice<=cur-SLIPPAGE) return res.status(400).json({ error: `Buy Stop price must be ABOVE current price ${cur.toFixed(2)}.` });
  if (type==='sell_stop' &&triggerPrice>=cur+SLIPPAGE) return res.status(400).json({ error: `Sell Stop price must be BELOW current price ${cur.toFixed(2)}.` });
  const now = Date.now();
  const order = { id:uuidv4(), userId:req.userId, symbol:'XAU/USD', type, lotSize:lot, price:triggerPrice, stopLoss:stopLoss!=null?parseFloat(stopLoss):null, takeProfit:takeProfit!=null?parseFloat(takeProfit):null, expiry:expiry?parseInt(expiry):null, status:'pending', createdAt:now, updatedAt:now };
  await savePendingOrder(order);
  res.status(201).json({ pending: _enrichPending(order), message: `${type} order placed at ${triggerPrice}` });
}));

// ── DELETE /api/v1/trades/pending/:id ────────────────────────────────────────
router.delete('/pending/:id', asyncWrap(async (req, res) => {
  const order = store.pendingOrders.get(req.params.id);
  if (!order||order.userId!==req.userId) return res.status(404).json({ error: 'Order not found.' });
  if (order.status!=='pending') return res.status(409).json({ error: 'Order already triggered or cancelled.' });
  await savePendingOrder({ ...order, status:'cancelled', updatedAt:Date.now() });
  res.json({ message: 'Order cancelled.', id: order.id });
}));

// ── PATCH /api/v1/trades/pending/:id ─────────────────────────────────────────
router.patch('/pending/:id', asyncWrap(async (req, res) => {
  const order = store.pendingOrders.get(req.params.id);
  if (!order||order.userId!==req.userId) return res.status(404).json({ error: 'Order not found.' });
  if (order.status!=='pending') return res.status(409).json({ error: 'Cannot modify a triggered/cancelled order.' });
  const { price, stopLoss, takeProfit, lotSize } = req.body;
  const updated = { ...order, price:price!=null?parseFloat(price):order.price, stopLoss:stopLoss!==undefined?(stopLoss!=null?parseFloat(stopLoss):null):order.stopLoss, takeProfit:takeProfit!==undefined?(takeProfit!=null?parseFloat(takeProfit):null):order.takeProfit, lotSize:lotSize!=null?parseFloat(lotSize):order.lotSize, updatedAt:Date.now() };
  await savePendingOrder(updated);
  res.json({ pending: _enrichPending(updated), message: 'Order modified.' });
}));

// ── GET /api/v1/trades/:id ────────────────────────────────────────────────────
router.get('/:id', asyncWrap(async (req, res) => {
  const trade = store.trades.get(req.params.id);
  if (!trade||trade.userId!==req.userId) return res.status(404).json({ error: 'Trade not found.' });
  let livePnl = null;
  if (trade.status==='open') { const state=priceState(); livePnl=parseFloat(calcPnl(trade,trade.type==='buy'?state.bid:state.ask).toFixed(2)); }
  res.json({ trade: { ..._enrichTrade(trade), livePnl } });
}));

// ── Simulation gate — shared by market + pending order routes ─────────────────
function _simGate(res) {
  const sim = getSimConfig();
  if (sim.simStatus === 'stopped') {
    res.status(403).json({ error: 'Trading period has ended (Dec 31, 2025). No new orders accepted.' });
    return false;
  }
  if (sim.simStatus === 'paused') {
    res.status(403).json({ error: 'Trading is currently paused by the administrator.' });
    return false;
  }
  if (sim.simStatus === 'idle') {
    res.status(403).json({ error: 'Trading has not started yet. Please wait for the administrator to start.' });
    return false;
  }
  if (sim.simDateMs < sim.simStartMs || sim.simDateMs > sim.simEndMs) {
    res.status(403).json({ error: 'Trading is only permitted between Jan 1, 2025 and Dec 31, 2025.' });
    return false;
  }
  return true;
}

// ── POST /api/v1/trades ───────────────────────────────────────────────────────
router.post('/', asyncWrap(async (req, res) => {
  if (!_simGate(res)) return;
  const { type, lotSize, stopLoss, takeProfit } = req.body;
  if (!type||!['buy','sell'].includes(type)) return res.status(400).json({ error: 'type must be "buy" or "sell".' });
  const lot = parseFloat(lotSize);
  if (isNaN(lot)||lot<0.01||lot>100) return res.status(400).json({ error: 'lotSize must be 0.01–100.' });
  const state = priceState();
  const openPrice = type==='buy' ? state.ask : state.bid;
  const SLIPPAGE = 0.10;
  if (stopLoss!=null) { const sl=parseFloat(stopLoss); if(type==='buy'&&sl>=openPrice+SLIPPAGE) return res.status(400).json({error:`SL ${sl} must be below open price ${openPrice} for BUY.`}); if(type==='sell'&&sl<=openPrice-SLIPPAGE) return res.status(400).json({error:`SL ${sl} must be above open price ${openPrice} for SELL.`}); }
  if (takeProfit!=null) { const tp=parseFloat(takeProfit); if(type==='buy'&&tp<=openPrice-SLIPPAGE) return res.status(400).json({error:`TP ${tp} must be above open price ${openPrice} for BUY.`}); if(type==='sell'&&tp>=openPrice+SLIPPAGE) return res.status(400).json({error:`TP ${tp} must be below open price ${openPrice} for SELL.`}); }
  const now = Date.now();
  const openUser = store.users.get(req.userId);
  const leverage = openUser?.leverage || 100;
  const margin   = parseFloat((lot * openPrice * 100 / leverage).toFixed(2));
  const trade    = { id:uuidv4(), userId:req.userId, symbol:'XAU/USD', type, lotSize:lot, openPrice, closePrice:null, stopLoss:stopLoss!=null?parseFloat(stopLoss):null, takeProfit:takeProfit!=null?parseFloat(takeProfit):null, margin, status:'open', openTime:now, closeTime:null, pnl:null, closeReason:null, createdAt:now, updatedAt:now };
  await saveTrade(trade);
  if (openUser) await saveUser({ ...openUser, balance: parseFloat((openUser.balance - margin).toFixed(2)), updatedAt: now });
  await addTransaction(req.userId, 'trade_open', -margin, `${type.toUpperCase()} ${lot} lots @ ${openPrice} (margin: $${margin})`);
  res.status(201).json({ trade: _enrichTrade(trade), message: `${type.toUpperCase()} opened at ${openPrice}` });
}));

// ── DELETE /api/v1/trades/:id ─────────────────────────────────────────────────
router.delete('/:id', asyncWrap(async (req, res) => {
  const trade = store.trades.get(req.params.id);
  if (!trade||trade.userId!==req.userId) return res.status(404).json({ error: 'Trade not found.' });
  if (trade.status!=='open') return res.status(409).json({ error: 'Trade already closed.' });
  const state = priceState();
  const closePrice = trade.type==='buy' ? state.bid : state.ask;
  const pnl = parseFloat(calcPnl(trade, closePrice).toFixed(2));
  const now = Date.now();
  const closed = { ...trade, status:'closed', closePrice, closeTime:now, pnl, closeReason:'manual', updatedAt:now };
  await saveTrade(closed);
  const user = store.users.get(req.userId);
  if (user) await saveUser({ ...user, balance: parseFloat((user.balance + (trade.margin||0) + pnl).toFixed(2)), updatedAt:now });
  await addTransaction(req.userId, pnl>=0?'profit':'loss', pnl, `Closed ${trade.type.toUpperCase()} @ ${closePrice} — P&L: ${pnl>=0?'+':''}$${pnl}`);
  res.json({ trade: _enrichTrade(closed), pnl, message: `Closed @ ${closePrice}. P&L: ${pnl>=0?'+':''}$${pnl}` });
}));

// ── PATCH /api/v1/trades/:id ──────────────────────────────────────────────────
router.patch('/:id', asyncWrap(async (req, res) => {
  const trade = store.trades.get(req.params.id);
  if (!trade||trade.userId!==req.userId) return res.status(404).json({ error: 'Trade not found.' });
  if (trade.status!=='open') return res.status(409).json({ error: 'Cannot modify closed trade.' });
  const { stopLoss, takeProfit } = req.body;
  const updated = { ...trade, stopLoss:stopLoss!==undefined?(stopLoss!=null?parseFloat(stopLoss):null):trade.stopLoss, takeProfit:takeProfit!==undefined?(takeProfit!=null?parseFloat(takeProfit):null):trade.takeProfit, updatedAt:Date.now() };
  await saveTrade(updated);
  res.json({ trade: _enrichTrade(updated), message: 'Modified.' });
}));

function _enrichTrade(t) {
  return { id:t.id, symbol:t.symbol, type:t.type, lotSize:t.lotSize, openPrice:t.openPrice, closePrice:t.closePrice, stopLoss:t.stopLoss, takeProfit:t.takeProfit, status:t.status, openTime:t.openTime, closeTime:t.closeTime, pnl:t.pnl, closeReason:t.closeReason, margin:t.margin??null };
}
function _enrichPending(o) {
  return { id:o.id, symbol:o.symbol, type:o.type, lotSize:o.lotSize, price:o.price, stopLoss:o.stopLoss, takeProfit:o.takeProfit, status:o.status, createdAt:o.createdAt, expiry:o.expiry||null };
}

module.exports = router;
