'use strict';

const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const User = require('./User');
const Trade = require('./Trade');
const PendingOrder = require('./PendingOrder');
const Transaction = require('./Transaction');


// ─────────────────────────────────────────────
// ✅ CONNECT DB
// ─────────────────────────────────────────────
async function connectDB() {
  const uri = process.env.MONGODB_URI|| 'mongodb+srv://aurum_user:Sadham%407866@aurum.vzow14b.mongodb.net/?appName=aurum';
  if (!uri) throw new Error('MONGODB_URI missing');

  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 8000
  });

  console.log('[db] MongoDB connected');
}


// ─────────────────────────────────────────────
// ✅ SIMULATION CONFIG
// ─────────────────────────────────────────────
const simConfig = {
  tickIntervalMs: 200, // ⚠️ Increased for DB safety
  volatility: 2.5,
  drift: 0,
  running: true,
  basePrice: 3200,

  simStatus: 'running',
  simDateMs: new Date('2025-01-01').getTime(),
  simStartMs: new Date('2025-01-01').getTime(),
  simEndMs: new Date('2025-12-31').getTime(),
};


// ─────────────────────────────────────────────
// ✅ PRICE STATE + CANDLES
// ─────────────────────────────────────────────
let priceState = {
  bid:           simConfig.basePrice,
  ask:           simConfig.basePrice + 0.35,
  spread:        0.35,
  timestamp:     Date.now(),
  high24h:       simConfig.basePrice,
  low24h:        simConfig.basePrice,
  open24h:       simConfig.basePrice,
  change:        0,
  changePercent: 0,
  candles:       [],   // per-tick (4-hour sim candles)
  dailyCandles:  [],   // one per sim day (6 ticks)
  weeklyCandles: [],   // one per sim week (42 ticks)
};

// ── Candle accumulators ───────────────────────
let _tickCount   = 0;          // total ticks since start
let _dayCandle   = null;       // current building daily candle
let _weekCandle  = null;       // current building weekly candle
const TICKS_PER_DAY  = 6;     // 6 × 4h = 1 sim day
const TICKS_PER_WEEK = 42;    // 6 × 7  = 1 sim week
const MAX_TICK_CANDLES   = 2880;
const MAX_DAILY_CANDLES  = 400;
const MAX_WEEKLY_CANDLES = 270;

function _buildCandle(open, high, low, close, timeMs) {
  return { time: Math.floor(timeMs / 1000), open, high, low, close };
}

function _pushCandle(arr, candle, max) {
  arr.push(candle);
  if (arr.length > max) arr.shift();
}

function _updateCandleAccumulators(bid, simDateMs) {
  const dayIdx  = Math.floor(_tickCount / TICKS_PER_DAY);
  const weekIdx = Math.floor(_tickCount / TICKS_PER_WEEK);

  // ── Tick candle (one per tick) ──
  const tickTime = simDateMs - (4 * 3600000); // start of this 4h period
  _pushCandle(priceState.candles, _buildCandle(bid, bid, bid, bid, tickTime), MAX_TICK_CANDLES);

  // ── Daily candle accumulation ──
  if (!_dayCandle) {
    _dayCandle = { open: bid, high: bid, low: bid, close: bid, dayIdx, timeMs: simDateMs };
  } else if (dayIdx !== _dayCandle.dayIdx) {
    // Close out the completed day candle
    _pushCandle(priceState.dailyCandles,
      _buildCandle(_dayCandle.open, _dayCandle.high, _dayCandle.low, _dayCandle.close, _dayCandle.timeMs),
      MAX_DAILY_CANDLES);
    _dayCandle = { open: bid, high: bid, low: bid, close: bid, dayIdx, timeMs: simDateMs };
  } else {
    _dayCandle.high  = Math.max(_dayCandle.high, bid);
    _dayCandle.low   = Math.min(_dayCandle.low, bid);
    _dayCandle.close = bid;
  }

  // ── Weekly candle accumulation ──
  if (!_weekCandle) {
    _weekCandle = { open: bid, high: bid, low: bid, close: bid, weekIdx, timeMs: simDateMs };
  } else if (weekIdx !== _weekCandle.weekIdx) {
    _pushCandle(priceState.weeklyCandles,
      _buildCandle(_weekCandle.open, _weekCandle.high, _weekCandle.low, _weekCandle.close, _weekCandle.timeMs),
      MAX_WEEKLY_CANDLES);
    _weekCandle = { open: bid, high: bid, low: bid, close: bid, weekIdx, timeMs: simDateMs };
  } else {
    _weekCandle.high  = Math.max(_weekCandle.high, bid);
    _weekCandle.low   = Math.min(_weekCandle.low, bid);
    _weekCandle.close = bid;
  }

  // ── 24h stats (last TICKS_PER_DAY ticks) ──
  const last24 = priceState.candles.slice(-TICKS_PER_DAY);
  const open24 = last24.length > 0 ? last24[0].open : bid;
  const high24 = last24.reduce((m, c) => Math.max(m, c.high), bid);
  const low24  = last24.reduce((m, c) => Math.min(m, c.low), bid);
  const chg    = parseFloat((bid - open24).toFixed(2));
  const chgPct = open24 > 0 ? parseFloat(((chg / open24) * 100).toFixed(2)) : 0;

  priceState.high24h       = high24;
  priceState.low24h        = low24;
  priceState.open24h       = open24;
  priceState.change        = chg;
  priceState.changePercent = chgPct;

  _tickCount++;
}


// ─────────────────────────────────────────────
// ✅ PNL
// ─────────────────────────────────────────────
function calcPnl(trade, closePrice) {
  const diff = trade.type === 'buy'
    ? closePrice - trade.openPrice
    : trade.openPrice - closePrice;

  return parseFloat((diff * trade.lotSize * 100).toFixed(2));
}


// ─────────────────────────────────────────────
// ✅ TRANSACTION
// ─────────────────────────────────────────────
async function addTransaction(userId, type, amount, description) {
  await Transaction.create({
    _id: uuidv4(),
    userId,
    type,
    amount,
    description,
    createdAt: Date.now()
  });
}


// ─────────────────────────────────────────────
// ✅ SL / TP CHECK
// ─────────────────────────────────────────────
async function checkSlTp(bid, ask) {
  const trades = await Trade.find({ status: 'open' });

  for (const trade of trades) {

    const price = trade.type === 'buy' ? bid : ask;

    let close = false;
    let reason = '';

    if (trade.stopLoss) {
      if (trade.type === 'buy' && bid <= trade.stopLoss) {
        close = true; reason = 'SL';
      }
      if (trade.type === 'sell' && ask >= trade.stopLoss) {
        close = true; reason = 'SL';
      }
    }

    if (trade.takeProfit) {
      if (trade.type === 'buy' && bid >= trade.takeProfit) {
        close = true; reason = 'TP';
      }
      if (trade.type === 'sell' && ask <= trade.takeProfit) {
        close = true; reason = 'TP';
      }
    }

    if (!close) continue;

    const pnl = calcPnl(trade, price);

    await Trade.findByIdAndUpdate(trade._id, {
      status: 'closed',
      closePrice: price,
      pnl,
      closeReason: reason,
      closeTime: Date.now()
    });

    await User.findByIdAndUpdate(trade.userId, {
      $inc: { balance: pnl + (trade.margin || 0) }
    });

    await addTransaction(
      trade.userId,
      pnl >= 0 ? 'profit' : 'loss',
      pnl,
      `Auto closed (${reason})`
    );
  }
}


// ─────────────────────────────────────────────
// ✅ PENDING ORDERS
// ─────────────────────────────────────────────
async function checkPendingOrders(bid, ask) {
  const orders = await PendingOrder.find({ status: 'pending' });

  for (const order of orders) {

    let trigger = false;

    if (order.type === 'buy_limit' && ask <= order.price) trigger = true;
    if (order.type === 'sell_limit' && bid >= order.price) trigger = true;
    if (order.type === 'buy_stop' && ask >= order.price) trigger = true;
    if (order.type === 'sell_stop' && bid <= order.price) trigger = true;

    if (!trigger) continue;

    const execPrice = order.type.includes('buy') ? ask : bid;

    const trade = await Trade.create({
      _id: uuidv4(),
      userId: order.userId,
      type: order.type.includes('buy') ? 'buy' : 'sell',
      lotSize: order.lotSize,
      openPrice: execPrice,
      margin: order.margin || 0,
      status: 'open',
      openTime: Date.now()
    });

    await PendingOrder.findByIdAndUpdate(order._id, {
      status: 'triggered',
      tradeId: trade._id
    });

    await User.findByIdAndUpdate(order.userId, {
      $inc: { balance: -trade.margin }
    });

    await addTransaction(
      order.userId,
      'trade_open',
      -trade.margin,
      'Pending order triggered'
    );
  }
}


// ─────────────────────────────────────────────
// ✅ PRICE TICK ENGINE
// ─────────────────────────────────────────────
let tickTimer = null;

function startTick() {

  if (tickTimer) clearInterval(tickTimer);

  tickTimer = setInterval(async () => {

    if (!simConfig.running) return;

    const drift = (Math.random() - 0.5) * simConfig.volatility;

    const newBid = Math.max(2500,
      Math.min(4500, priceState.bid + drift)
    );

    const newAsk = newBid + 0.35;

    priceState = {
      ...priceState,                           // keep candle arrays + 24h stats
      bid:       parseFloat(newBid.toFixed(2)),
      ask:       parseFloat(newAsk.toFixed(2)),
      spread:    0.35,
      timestamp: Date.now()
    };

    // 🔥 DB-based checks
    await checkSlTp(priceState.bid, priceState.ask);
    await checkPendingOrders(priceState.bid, priceState.ask);

    // Advance simulation date + build candles
    if (simConfig.simStatus === 'running') {
      simConfig.simDateMs += 4 * 3600000;
      _updateCandleAccumulators(priceState.bid, simConfig.simDateMs);

      if (simConfig.simDateMs >= simConfig.simEndMs) {
        simConfig.running = false;
        simConfig.simStatus = 'stopped';
      }
    }

  }, simConfig.tickIntervalMs);
}


// ─────────────────────────────────────────────
// ✅ DELETE USER
// ─────────────────────────────────────────────
async function deleteUser(userId) {
  await Trade.deleteMany({ userId });
  await PendingOrder.deleteMany({ userId });
  await Transaction.deleteMany({ userId });
  await User.deleteOne({ _id: userId });
}


// ─────────────────────────────────────────────
// ✅ SIM CONFIG ACCESSORS
// ─────────────────────────────────────────────
function _speedLabel(ms) {
  if (ms <= 30)   return 'TURBO';
  if (ms <= 100)  return 'ULTRA';
  if (ms <= 500)  return 'FAST';
  if (ms <= 1000) return 'NORMAL';
  if (ms <= 3000) return 'SLOW';
  return 'CRAWL';
}

function getSimConfig() {
  const totalMs  = simConfig.simEndMs - simConfig.simStartMs;
  const elapsed  = simConfig.simDateMs - simConfig.simStartMs;
  return {
    ...simConfig,
    speedLabel:  _speedLabel(simConfig.tickIntervalMs),
    simDateStr:  new Date(simConfig.simDateMs).toISOString().slice(0, 10),
    simStartStr: new Date(simConfig.simStartMs).toISOString().slice(0, 10),
    simEndStr:   new Date(simConfig.simEndMs).toISOString().slice(0, 10),
    progressPct: totalMs > 0 ? parseFloat(((elapsed / totalMs) * 100).toFixed(1)) : 0,
  };
}

function setSimConfig(updates) {
  const prevTickMs = simConfig.tickIntervalMs;

  Object.assign(simConfig, updates);

  // Keep simConfig.running in sync with simStatus
  if (updates.simStatus === 'running') simConfig.running = true;
  if (updates.simStatus === 'paused' || updates.simStatus === 'stopped' || updates.simStatus === 'idle') {
    simConfig.running = false;
  }

  // Restart the tick timer when tickIntervalMs changes — setInterval captures
  // the delay at creation time so speed changes only take effect after a restart
  if (updates.tickIntervalMs !== undefined && updates.tickIntervalMs !== prevTickMs) {
    startTick();
  }

  return getSimConfig();
}


// ─────────────────────────────────────────────
// ✅ EXPORTS
// ─────────────────────────────────────────────
module.exports = {
  connectDB,
  startTick,
  deleteUser,
  priceState: () => priceState,
  calcPnl,
  getSimConfig,
  setSimConfig,
};