'use strict';
const express = require('express');
const { authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();
router.use(authenticate);

// In-memory notifications (ephemeral — cleared on restart)
const _notifs = new Map();

// GET /api/v1/notifications?unread=true
router.get('/', asyncWrap(async (req, res) => {
  const onlyUnread = req.query.unread === 'true';
  const notifs = [];
  for (const n of _notifs.values()) {
    if (n.userId !== req.userId) continue;
    if (onlyUnread && n.read) continue;
    notifs.push(n);
  }
  notifs.sort((a, b) => b.createdAt - a.createdAt);
  res.json({ notifications: notifs.slice(0, 50), unreadCount: notifs.filter(n => !n.read).length });
}));

// PATCH /api/v1/notifications/read-all
router.patch('/read-all', asyncWrap(async (req, res) => {
  for (const [id, n] of _notifs.entries()) {
    if (n.userId === req.userId && !n.read) {
      _notifs.set(id, { ...n, read: true });
    }
  }
  res.json({ ok: true });
}));

// PATCH /api/v1/notifications/:id/read
router.patch('/:id/read', asyncWrap(async (req, res) => {
  const n = _notifs.get(req.params.id);
  if (!n || n.userId !== req.userId) return res.status(404).json({ error: 'Not found' });
  _notifs.set(n.id, { ...n, read: true });
  res.json({ ok: true });
}));

// DELETE /api/v1/notifications/:id
router.delete('/:id', asyncWrap(async (req, res) => {
  const n = _notifs.get(req.params.id);
  if (!n || n.userId !== req.userId) return res.status(404).json({ error: 'Not found' });
  _notifs.delete(req.params.id);
  res.json({ deleted: true });
}));

module.exports = router;
