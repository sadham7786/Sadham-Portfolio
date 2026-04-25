'use strict';
const express = require('express');
const Transaction = require('../models/Transaction');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();
router.use(authenticate);

// GET /api/v1/transactions?page=1&limit=20&type=all
router.get('/', asyncWrap(async (req, res) => {
  const page  = parseInt(req.query.page)  || 1;
  const limit = Math.min(parseInt(req.query.limit) || 20, 100);
  const type  = req.query.type || 'all';

  const query = { userId: req.userId };
  if (type !== 'all') query.type = type;

  const total = await Transaction.countDocuments(query);
  const txs   = await Transaction.find(query)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  res.json({ transactions: txs, total, page, pages: Math.ceil(total / limit) });
}));

module.exports = router;
