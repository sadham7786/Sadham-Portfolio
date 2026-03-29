// ── /api/v1/notifications ─────────────────────────────────────────────────────
'use strict';
const express = require('express');
const { store } = require('../models/store');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');
const router = express.Router();
router.use(authenticate);

// GET /api/v1/notifications?unread=true
router.get('/', asyncWrap(async (req, res) => {
  const onlyUnread = req.query.unread === 'true';
  const notifs = [];
  for (const n of store.notifications.values()) {
    if (n.userId !== req.userId) continue;
    if (onlyUnread && n.read) continue;
    notifs.push(n);
  }
  notifs.sort((a,b) => b.createdAt - a.createdAt);
  const paged = notifs.slice(0, 50);
  res.json({ notifications: paged, unreadCount: notifs.filter(n => !n.read).length });
}));

// PATCH /api/v1/notifications/read-all
router.patch('/read-all', asyncWrap(async (req, res) => {
  for (const [id, n] of store.notifications.entries()) {
    if (n.userId === req.userId && !n.read) {
      store.notifications.set(id, { ...n, read: true });
    }
  }
  res.json({ ok: true });
}));

// PATCH /api/v1/notifications/:id/read
router.patch('/:id/read', asyncWrap(async (req, res) => {
  const n = store.notifications.get(req.params.id);
  if (!n || n.userId !== req.userId) return res.status(404).json({ error: 'Not found' });
  store.notifications.set(n.id, { ...n, read: true });
  res.json({ ok: true });
}));

// DELETE /api/v1/notifications/:id
router.delete('/:id', asyncWrap(async (req, res) => {
  const n = store.notifications.get(req.params.id);
  if (!n || n.userId !== req.userId) return res.status(404).json({ error: 'Not found' });
  store.notifications.delete(req.params.id);
  res.json({ deleted: true });
}));

module.exports = router;
