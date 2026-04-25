'use strict';
const express = require('express');
const { priceState, calcPnl } = require('../models/store');
const User  = require('../models/User');
const Trade = require('../models/Trade');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();
router.use(authenticate);

// GET /api/v1/analytics/summary
router.get('/summary', asyncWrap(async (req, res) => {
  const trades = await Trade.find({ userId: req.userId, status: 'closed' }).sort({ closeTime: 1 }).lean();

  let equity = 0, peak = 0, maxDrawdown = 0;
  let wins = 0, losses = 0, totalPnl = 0;
  let maxStreak = 0, curStreak = 0, bestTrade = null, worstTrade = null;
  const pnlCurve = [];

  for (const t of trades) {
    const pnl = t.pnl || 0;
    equity   += pnl;
    totalPnl += pnl;
    if (pnl > 0) { wins++; curStreak++; maxStreak = Math.max(maxStreak, curStreak); }
    else          { losses++; curStreak = 0; }
    peak = Math.max(peak, equity);
    const dd = peak > 0 ? ((peak - equity) / peak) * 100 : 0;
    maxDrawdown = Math.max(maxDrawdown, dd);
    if (!bestTrade  || pnl > bestTrade.pnl)  bestTrade  = t;
    if (!worstTrade || pnl < worstTrade.pnl) worstTrade = t;
    pnlCurve.push({ time: t.closeTime, pnl: parseFloat(pnl.toFixed(2)), equity: parseFloat(equity.toFixed(2)) });
  }

  const user  = await User.findById(req.userId).lean();
  const state = priceState();
  const openTrades = await Trade.find({ userId: req.userId, status: 'open' }).lean();
  let livePnl = 0, openCount = 0, openLots = 0;
  for (const t of openTrades) {
    const cp = t.type === 'buy' ? state.bid : state.ask;
    livePnl  += calcPnl(t, cp);
    openCount++; openLots += t.lotSize;
  }

  // Daily PnL breakdown (last 30 sim days)
  const dayMap = {};
  for (const t of trades) {
    const day = new Date(t.closeTime).toISOString().split('T')[0];
    dayMap[day] = (dayMap[day] || 0) + (t.pnl || 0);
  }
  const dailyPnl = Object.entries(dayMap)
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-30)
    .map(([date, pnl]) => ({ date, pnl: parseFloat(pnl.toFixed(2)) }));

  let buyWins = 0, buyTotal = 0, sellWins = 0, sellTotal = 0;
  for (const t of trades) {
    if (t.type === 'buy')  { buyTotal++;  if ((t.pnl || 0) > 0) buyWins++;  }
    else                   { sellTotal++; if ((t.pnl || 0) > 0) sellWins++; }
  }

  const total = trades.length;
  res.json({
    summary: {
      totalTrades: total, wins, losses,
      winRate:      total > 0 ? parseFloat(((wins / total) * 100).toFixed(1)) : 0,
      totalPnl:     parseFloat(totalPnl.toFixed(2)),
      livePnl:      parseFloat(livePnl.toFixed(2)),
      avgPnl:       total > 0 ? parseFloat((totalPnl / total).toFixed(2)) : 0,
      maxDrawdown:  parseFloat(maxDrawdown.toFixed(2)),
      maxWinStreak: maxStreak,
      bestTrade:    bestTrade  ? { pnl: bestTrade.pnl,  type: bestTrade.type,  openPrice: bestTrade.openPrice,  closePrice: bestTrade.closePrice  } : null,
      worstTrade:   worstTrade ? { pnl: worstTrade.pnl, type: worstTrade.type, openPrice: worstTrade.openPrice, closePrice: worstTrade.closePrice } : null,
      openPositions: openCount,
      openLots:     parseFloat(openLots.toFixed(2)),
      balance:      user?.balance || 0,
      equity:       parseFloat(((user?.balance || 0) + livePnl).toFixed(2)),
      byType: {
        buy:  { total: buyTotal,  wins: buyWins,  winRate: buyTotal  > 0 ? parseFloat(((buyWins  / buyTotal)  * 100).toFixed(1)) : 0 },
        sell: { total: sellTotal, wins: sellWins, winRate: sellTotal > 0 ? parseFloat(((sellWins / sellTotal) * 100).toFixed(1)) : 0 },
      },
    },
    pnlCurve,
    dailyPnl,
  });
}));

// GET /api/v1/analytics/leaderboard
router.get('/leaderboard', asyncWrap(async (req, res) => {
  const trades = await Trade.find({ status: 'closed' }).lean();
  const byUser = {};
  for (const t of trades) {
    if (!byUser[t.userId]) byUser[t.userId] = { pnl: 0, trades: 0, wins: 0 };
    byUser[t.userId].pnl    += t.pnl || 0;
    byUser[t.userId].trades++;
    if ((t.pnl || 0) > 0) byUser[t.userId].wins++;
  }

  const uids  = Object.keys(byUser);
  const users = await User.find({ _id: { $in: uids } }).lean();
  const userMap = new Map(users.map(u => [u._id, u]));

  const board = Object.entries(byUser).map(([uid, s]) => {
    const u    = userMap.get(uid);
    const name = u ? u.fullName.split(' ')[0] + ' ' + (u.fullName.split(' ')[1]?.[0] || '') + '.' : 'Trader';
    return {
      name:    uid === req.userId ? 'You (' + name + ')' : name,
      isMe:    uid === req.userId,
      pnl:     parseFloat(s.pnl.toFixed(2)),
      trades:  s.trades,
      winRate: s.trades > 0 ? parseFloat(((s.wins / s.trades) * 100).toFixed(1)) : 0,
    };
  }).sort((a, b) => b.pnl - a.pnl).slice(0, 10);

  res.json({ leaderboard: board });
}));

module.exports = router;
