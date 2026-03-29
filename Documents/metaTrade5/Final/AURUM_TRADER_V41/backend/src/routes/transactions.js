// ── /api/v1/transactions ──────────────────────────────────────────────────────
'use strict';
const express = require('express');
const { store } = require('../models/store');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');
const router = express.Router();
router.use(authenticate);

// GET /api/v1/transactions?page=1&limit=20&type=all
router.get('/', asyncWrap(async (req, res) => {
  const page  = parseInt(req.query.page)  || 1;
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);
  const type  = req.query.type || 'all';

  const txs = [];
  if (!store.transactions) store.transactions = new Map();
  for (const tx of store.transactions.values()) {
    if (tx.userId !== req.userId) continue;
    if (type !== 'all' && tx.type !== type) continue;
    txs.push(tx);
  }
  txs.sort((a,b) => b.createdAt - a.createdAt);

  const total = txs.length;
  const paged = txs.slice((page-1)*limit, page*limit);
  res.json({ transactions: paged, total, page, pages: Math.ceil(total/limit) });
}));

module.exports = router;
