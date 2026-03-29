'use strict';

const User         = require('./User');
const Trade        = require('./Trade');
const PendingOrder = require('./PendingOrder');
const Transaction  = require('./Transaction');
const { v4: uuidv4 } = require('uuid');

// ── In-memory caches (populated from MongoDB on startup) ─────────────────────
// Routes still read from these Maps for hot-path reads (price tick loop, SL/TP).
// Writes go to MongoDB AND update the cache atomically.
const store = {
  users:         new Map(),
  trades:        new Map(),
  sessions:      new Map(),
  pendingOrders: new Map(),
  transactions:  new Map(),
  watchlists:    new Map(),
  alerts:        new Map(),
  notifications: new Map(),
};

// ── Connect to MongoDB & seed in-memory cache ─────────────────────────────────
const mongoose = require('mongoose');

async function connectDB() {
  const uri = process.env.MONGODB_URI|| 'mongodb+srv://aurum_user:Sadham%407866@aurum.vzow14b.mongodb.net/?appName=aurum';
  if (!uri) {
    console.warn('[db] MONGODB_URI not set — running in memory-only mode (data lost on restart).');
    return;
  }
  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 8000 });
    console.log('[db] Connected to MongoDB');
    await _loadCache();
  } catch (err) {
    console.error('[db] MongoDB connection failed:', err.message);
    console.warn('[db] Falling back to in-memory mode.');
  }
}

async function _loadCache() {
  const [users, trades, orders, txns] = await Promise.all([
    User.find().lean(),
    Trade.find().lean(),
    PendingOrder.find().lean(),
    Transaction.find().lean(),
  ]);
  for (const u of users)  { const obj = { ...u, id: u._id }; delete obj._id; store.users.set(obj.id, obj); }
  for (const t of trades) { const obj = { ...t, id: t._id }; delete obj._id; store.trades.set(obj.id, obj); }
  for (const o of orders) { const obj = { ...o, id: o._id }; delete obj._id; store.pendingOrders.set(obj.id, obj); }
  for (const tx of txns)  { const obj = { ...tx, id: tx._id }; delete obj._id; store.transactions.set(obj.id, obj); }
  console.log(`[db] Cache loaded: ${users.length} users, ${trades.length} trades, ${orders.length} pending orders, ${txns.length} txns`);
}

// ── DB write helpers ──────────────────────────────────────────────────────────
// Each helper updates the in-memory Map AND persists to MongoDB.
// Routes that used store.users.set() / store.trades.set() now call these.

async function saveUser(user) {
  store.users.set(user.id, user);
  if (mongoose.connection.readyState === 1) {
    const { id, ...fields } = user;
    await User.findByIdAndUpdate(id, { $set: { ...fields, _id: id } }, { upsert: true, new: true });
  }
}

async function saveTrade(trade) {
  store.trades.set(trade.id, trade);
  if (mongoose.connection.readyState === 1) {
    const { id, ...fields } = trade;
    await Trade.findByIdAndUpdate(id, { $set: { ...fields, _id: id } }, { upsert: true, new: true });
  }
}

async function savePendingOrder(order) {
  store.pendingOrders.set(order.id, order);
  if (mongoose.connection.readyState === 1) {
    const { id, ...fields } = order;
    await PendingOrder.findByIdAndUpdate(id, { $set: { ...fields, _id: id } }, { upsert: true, new: true });
  }
}

async function saveTransaction(tx) {
  store.transactions.set(tx.id, tx);
  if (mongoose.connection.readyState === 1) {
    const { id, ...fields } = tx;
    await Transaction.findByIdAndUpdate(id, { $set: { ...fields, _id: id } }, { upsert: true, new: true });
  }
}

// ── Simulation Config ─────────────────────────────────────────────────────────
const simConfig = {
  tickIntervalMs: 29,
  volatility:     2.5,
  drift:          0.0,
  running:        true,
  basePrice:      3200.00,
};

// ── Candle seeders ────────────────────────────────────────────────────────────
function _seedCandles(base) {
  const candles = [];
  let price = base - 30;
  const now = Date.now();
  for (let i = 1439; i >= 0; i--) {
    const open  = price;
    const drift = (Math.random() - 0.48) * 3.5;
    const close = parseFloat((open + drift).toFixed(2));
    const wick  = Math.random() * 3.0;
    candles.push({ time: now - i*60_000, open: parseFloat(open.toFixed(2)), high: parseFloat((Math.max(open,close)+wick).toFixed(2)), low: parseFloat((Math.min(open,close)-wick).toFixed(2)), close });
    price = close;
  }
  return candles;
}

function _seedDailyCandles(base) {
  const candles = [];
  let price = base - 200;
  const now = Date.now();
  const D = 86_400_000;
  for (let i = 364; i >= 0; i--) {
    const open = price;
    const drift = (Math.random() - 0.46) * 25;
    const close = parseFloat((open + drift).toFixed(2));
    const range = Math.abs(close - open) + Math.random() * 12;
    candles.push({ time: Math.floor((now-i*D)/D)*D, open: parseFloat(open.toFixed(2)), high: parseFloat((Math.max(open,close)+range*0.4).toFixed(2)), low: parseFloat((Math.min(open,close)-range*0.4).toFixed(2)), close });
    price = close;
  }
  return candles;
}

function _seedWeeklyCandles(base) {
  const candles = [];
  let price = base - 800;
  const now = Date.now();
  const W = 7*86_400_000;
  for (let i = 259; i >= 0; i--) {
    const open = price;
    const drift = (Math.random() - 0.45) * 60;
    const close = parseFloat((open + drift).toFixed(2));
    const range = Math.abs(close - open) + Math.random() * 40;
    candles.push({ time: Math.floor((now-i*W)/W)*W, open: parseFloat(open.toFixed(2)), high: parseFloat((Math.max(open,close)+range*0.5).toFixed(2)), low: parseFloat((Math.min(open,close)-range*0.5).toFixed(2)), close });
    price = close;
  }
  return candles;
}

// ── Price State ───────────────────────────────────────────────────────────────
let _priceState = (() => {
  const base = simConfig.basePrice;
  return {
    bid: base, ask: parseFloat((base+0.35).toFixed(2)),
    high24h: parseFloat((base+18).toFixed(2)), low24h: parseFloat((base-17).toFixed(2)),
    open24h: parseFloat((base-7.67).toFixed(2)), change: 7.67, changePercent: 0.328,
    spread: 0.35, timestamp: Date.now(),
    candles: _seedCandles(base), dailyCandles: _seedDailyCandles(base), weeklyCandles: _seedWeeklyCandles(base),
  };
})();

// ── Simulation tick ───────────────────────────────────────────────────────────
let _tickTimer = null;

function _startTick() {
  if (_tickTimer) clearInterval(_tickTimer);
  if (!simConfig.running) return;
  _tickTimer = setInterval(() => {
    const prev   = _priceState.bid;
    const drift  = (Math.random() - (0.5 - simConfig.drift)) * simConfig.volatility;
    const newBid = Math.min(Math.max(parseFloat((prev+drift).toFixed(2)), 2500), 4500);
    const newAsk = parseFloat((newBid+0.35).toFixed(2));
    const now    = Date.now();

    const candles = [..._priceState.candles];
    const last1m  = candles[candles.length-1];
    if (now - last1m.time >= 60_000) { candles.push({time:Math.floor(now/60_000)*60_000,open:newBid,high:newBid,low:newBid,close:newBid}); if(candles.length>2880)candles.shift(); }
    else { candles[candles.length-1]={...last1m,high:Math.max(last1m.high,newBid),low:Math.min(last1m.low,newBid),close:newBid}; }

    const daily=[..._priceState.dailyCandles],lastD=daily[daily.length-1],ds=Math.floor(now/86_400_000)*86_400_000;
    if(now-lastD.time>=86_400_000){daily.push({time:ds,open:newBid,high:newBid,low:newBid,close:newBid});if(daily.length>400)daily.shift();}
    else{daily[daily.length-1]={...lastD,high:Math.max(lastD.high,newBid),low:Math.min(lastD.low,newBid),close:newBid};}

    const weekly=[..._priceState.weeklyCandles],lastW=weekly[weekly.length-1],ws=Math.floor(now/(7*86_400_000))*(7*86_400_000);
    if(now-lastW.time>=7*86_400_000){weekly.push({time:ws,open:newBid,high:newBid,low:newBid,close:newBid});if(weekly.length>270)weekly.shift();}
    else{weekly[weekly.length-1]={...lastW,high:Math.max(lastW.high,newBid),low:Math.min(lastW.low,newBid),close:newBid};}

    const open24h=_priceState.open24h, change=parseFloat((newBid-open24h).toFixed(2)), changePercent=parseFloat(((change/open24h)*100).toFixed(3));
    _priceState={bid:newBid,ask:newAsk,high24h:Math.max(_priceState.high24h,newBid),low24h:Math.min(_priceState.low24h,newBid),open24h,change,changePercent,spread:parseFloat((newAsk-newBid).toFixed(2)),timestamp:now,candles,dailyCandles:daily,weeklyCandles:weekly};

    _checkSlTp(newBid, newAsk);
    _checkAlerts(newBid);
    _checkPendingOrders(newBid, newAsk);
  }, simConfig.tickIntervalMs);
}

function setSimConfig(updates) {
  if (updates.tickIntervalMs!==undefined) simConfig.tickIntervalMs=Math.min(Math.max(parseInt(updates.tickIntervalMs),20),30_000);
  if (updates.volatility!==undefined)    simConfig.volatility=Math.min(Math.max(parseFloat(updates.volatility),0.1),50);
  if (updates.drift!==undefined)         simConfig.drift=Math.min(Math.max(parseFloat(updates.drift),-0.5),0.5);
  if (updates.running!==undefined)       simConfig.running=Boolean(updates.running);
  if (updates.tickIntervalMs!==undefined||updates.running!==undefined) _startTick();
  return {...simConfig};
}
function getSimConfig() { return {...simConfig}; }

// ── SL/TP auto-close ──────────────────────────────────────────────────────────
function _checkSlTp(bid, ask) {
  for (const [id, trade] of store.trades.entries()) {
    if (trade.status !== 'open') continue;
    const closePrice = trade.type === 'buy' ? bid : ask;
    let shouldClose = false, reason = '';
    if (trade.stopLoss!=null)   { if(trade.type==='buy'&&bid<=trade.stopLoss) {shouldClose=true;reason='stop_loss';} if(trade.type==='sell'&&ask>=trade.stopLoss) {shouldClose=true;reason='stop_loss';} }
    if (trade.takeProfit!=null) { if(trade.type==='buy'&&bid>=trade.takeProfit){shouldClose=true;reason='take_profit';}if(trade.type==='sell'&&ask<=trade.takeProfit){shouldClose=true;reason='take_profit';} }
    if (shouldClose) {
      const pnl    = _calcPnl(trade, closePrice);
      const closed = {...trade, status:'closed', closePrice, closeTime:Date.now(), pnl, closeReason:reason};
      saveTrade(closed).catch(()=>{});
      const user = store.users.get(trade.userId);
      if (user) {
        const updated = {...user, balance:parseFloat((user.balance+(trade.margin||0)+pnl).toFixed(2))};
        saveUser(updated).catch(()=>{});
      }
      addTransaction(trade.userId, pnl>=0?'profit':'loss', pnl, `Auto-closed ${trade.type.toUpperCase()} @ ${closePrice} (${reason})`).catch(()=>{});
    }
  }
}

// ── PnL ───────────────────────────────────────────────────────────────────────
function _calcPnl(trade, closePrice) {
  const diff = trade.type==='buy' ? closePrice-trade.openPrice : trade.openPrice-closePrice;
  return parseFloat((diff*trade.lotSize*100*0.01*1000).toFixed(2));
}

// ── Price alerts ──────────────────────────────────────────────────────────────
function _checkAlerts(bid) {
  if (!store.alerts) return;
  for (const [id, alert] of store.alerts.entries()) {
    if (alert.status !== 'active') continue;
    const triggered = (alert.condition==='above'&&bid>=alert.price)||(alert.condition==='below'&&bid<=alert.price);
    if (triggered) store.alerts.set(id, {...alert, status:'triggered', triggeredAt:Date.now()});
  }
}

// ── Pending order trigger ─────────────────────────────────────────────────────
function _checkPendingOrders(bid, ask) {
  if (!store.pendingOrders) return;
  for (const [id, order] of store.pendingOrders.entries()) {
    if (order.status !== 'pending') continue;
    if (order.expiry && order.expiry < Date.now()) { savePendingOrder({...order,status:'expired',updatedAt:Date.now()}).catch(()=>{}); continue; }
    let shouldTrigger=false;
    const execPrice = order.type.startsWith('buy') ? ask : bid;
    if(order.type==='buy_limit' &&ask<=order.price) shouldTrigger=true;
    if(order.type==='sell_limit'&&bid>=order.price) shouldTrigger=true;
    if(order.type==='buy_stop'  &&ask>=order.price) shouldTrigger=true;
    if(order.type==='sell_stop' &&bid<=order.price) shouldTrigger=true;
    if (shouldTrigger) {
      const baseType = order.type.startsWith('buy')?'buy':'sell';
      const now = Date.now();
      const user = store.users.get(order.userId);
      const leverage = user?.leverage || 100;
      const margin = parseFloat((order.lotSize*execPrice*100/leverage).toFixed(2));
      const trade = {id:uuidv4(),userId:order.userId,symbol:'XAU/USD',type:baseType,lotSize:order.lotSize,openPrice:execPrice,closePrice:null,stopLoss:order.stopLoss,takeProfit:order.takeProfit,margin,status:'open',openTime:now,closeTime:null,pnl:null,closeReason:null,pendingOrderId:id,createdAt:now,updatedAt:now};
      saveTrade(trade).catch(()=>{});
      savePendingOrder({...order,status:'triggered',triggeredAt:now,tradeId:trade.id,updatedAt:now}).catch(()=>{});
      if (user) saveUser({...user,balance:parseFloat((user.balance-margin).toFixed(2)),updatedAt:now}).catch(()=>{});
      addTransaction(order.userId,'trade_open',-margin,`${order.type.replace('_',' ').toUpperCase()} triggered @ ${execPrice}`).catch(()=>{});
    }
  }
}

// ── Transaction helper (exported for routes) ──────────────────────────────────
async function addTransaction(userId, type, amount, description) {
  const tx = {id:uuidv4(),userId,type,amount:parseFloat((amount||0).toFixed(2)),description,createdAt:Date.now()};
  await saveTransaction(tx);
}

// ── Notification helper ───────────────────────────────────────────────────────
function addNotification(userId, type, message, meta={}) {
  const id = uuidv4();
  store.notifications.set(id, {id,userId,type,message,meta,read:false,createdAt:Date.now()});
}

// ── Real gold price sync ──────────────────────────────────────────────────────
function _syncRealPrice() {
  const https = require('https');
  https.get('https://query1.finance.yahoo.com/v8/finance/chart/GC%3DF?interval=1m&range=1d',
    {headers:{'User-Agent':'Mozilla/5.0','Accept':'application/json'},timeout:10000}, (res) => {
    let raw='';
    res.on('data',c=>{raw+=c;});
    res.on('end',()=>{
      try {
        const mid=JSON.parse(raw)?.chart?.result?.[0]?.meta?.regularMarketPrice;
        if(!mid||mid<100) return;
        if(Math.abs(mid-_priceState.bid)/_priceState.bid<0.005) return;
        _priceState={..._priceState,bid:mid,ask:parseFloat((mid+0.35).toFixed(2))};
        console.log(`[price-sync] Re-anchored to ${mid}`);
      } catch(e){console.warn('[price-sync]',e.message);}
    });
  }).on('error',e=>console.warn('[price-sync]',e.message));
}

// ── Boot ──────────────────────────────────────────────────────────────────────
_startTick();
_syncRealPrice();
setInterval(_syncRealPrice, 5*60*1000);

module.exports = {
  store,
  priceState:       () => _priceState,
  calcPnl:          _calcPnl,
  setSimConfig,
  getSimConfig,
  addTransaction,
  addNotification,
  // DB write helpers (used by routes)
  saveUser,
  saveTrade,
  savePendingOrder,
  saveTransaction,
  connectDB,
};
