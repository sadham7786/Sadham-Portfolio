'use strict';
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { priceState } = require('../models/store');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();
router.use(authenticate);

// In-memory alert store (price alerts are ephemeral — no DB needed)
const _alerts = new Map();

// GET /api/v1/alerts
router.get('/', asyncWrap(async (req, res) => {
  const alerts = [];
  for (const a of _alerts.values()) {
    if (a.userId === req.userId) alerts.push(_enrich(a));
  }
  alerts.sort((a, b) => b.createdAt - a.createdAt);
  res.json({ alerts });
}));

// POST /api/v1/alerts   { symbol, price, condition: 'above'|'below', note? }
router.post('/', asyncWrap(async (req, res) => {
  const { symbol, price, condition, note } = req.body;
  if (!price || isNaN(parseFloat(price))) return res.status(400).json({ error: 'price required' });
  if (!['above', 'below'].includes(condition)) return res.status(400).json({ error: 'condition must be above or below' });
  const id = uuidv4();
  const alert = {
    id, userId: req.userId,
    symbol: (symbol || 'XAU/USD').toUpperCase(),
    price: parseFloat(price),
    condition,
    note: note || null,
    status: 'active',
    triggeredAt: null,
    createdAt: Date.now(),
  };
  _alerts.set(id, alert);
  res.status(201).json({ alert: _enrich(alert) });
}));

// DELETE /api/v1/alerts/:id
router.delete('/:id', asyncWrap(async (req, res) => {
  const alert = _alerts.get(req.params.id);
  if (!alert || alert.userId !== req.userId) return res.status(404).json({ error: 'Alert not found' });
  _alerts.delete(req.params.id);
  res.json({ deleted: true });
}));

// PATCH /api/v1/alerts/:id  — re-activate triggered alert
router.patch('/:id', asyncWrap(async (req, res) => {
  const alert = _alerts.get(req.params.id);
  if (!alert || alert.userId !== req.userId) return res.status(404).json({ error: 'Alert not found' });
  const { price, condition, note } = req.body;
  const updated = {
    ...alert,
    price:      price     !== undefined ? parseFloat(price) : alert.price,
    condition:  condition || alert.condition,
    note:       note      !== undefined ? note : alert.note,
    status:     'active',
    triggeredAt: null,
  };
  _alerts.set(alert.id, updated);
  res.json({ alert: _enrich(updated) });
}));

function _enrich(a) {
  return { id: a.id, symbol: a.symbol, price: a.price, condition: a.condition,
           note: a.note, status: a.status, triggeredAt: a.triggeredAt, createdAt: a.createdAt };
}

module.exports = router;
