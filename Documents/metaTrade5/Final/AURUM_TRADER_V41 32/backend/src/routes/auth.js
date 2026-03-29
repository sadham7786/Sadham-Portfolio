'use strict';

const express  = require('express');
const bcrypt   = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { store, saveUser } = require('../models/store');
const { signToken, authenticate } = require('../middleware/auth');
const { asyncWrap } = require('../middleware/errorHandler');

const router = express.Router();

// ── POST /api/v1/auth/register ───────────────────────────────────────────────
router.post('/register', asyncWrap(async (req, res) => {
  const { fullName, email, password } = req.body;
  if (!fullName || !email || !password)
    return res.status(400).json({ error: 'fullName, email and password are required.' });
  if (password.length < 6)
    return res.status(400).json({ error: 'Password must be at least 6 characters.' });

  const emailLower = email.trim().toLowerCase();
  for (const u of store.users.values()) {
    if (u.email === emailLower) return res.status(409).json({ error: 'Email is already registered.' });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const now = Date.now();
  const user = { id: uuidv4(), fullName: fullName.trim(), email: emailLower, passwordHash, balance: 10000.00, accountType: 'DEMO', leverage: 100, role: 'user', createdAt: now, updatedAt: now };
  await saveUser(user);
  res.status(201).json({ token: signToken(user.id), user: _safeUser(user) });
}));

// ── POST /api/v1/auth/login ──────────────────────────────────────────────────
router.post('/login', asyncWrap(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'email and password are required.' });
  const emailLower = email.trim().toLowerCase();
  let found = null;
  for (const u of store.users.values()) { if (u.email === emailLower) { found = u; break; } }
  if (!found) return res.status(401).json({ error: 'Invalid email or password.' });
  const valid = await bcrypt.compare(password, found.passwordHash);
  if (!valid) return res.status(401).json({ error: 'Invalid email or password.' });
  res.json({ token: signToken(found.id), user: _safeUser(found) });
}));

// ── GET /api/v1/auth/me ──────────────────────────────────────────────────────
router.get('/me', authenticate, asyncWrap(async (req, res) => {
  const user = store.users.get(req.userId);
  if (!user) return res.status(404).json({ error: 'User not found.' });
  res.json({ user: _safeUser(user) });
}));

// ── POST /api/v1/auth/logout ─────────────────────────────────────────────────
router.post('/logout', authenticate, (req, res) => res.json({ message: 'Logged out successfully.' }));

// ── PUT /api/v1/auth/change-password ────────────────────────────────────────
router.put('/change-password', authenticate, asyncWrap(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) return res.status(400).json({ error: 'currentPassword and newPassword are required.' });
  if (newPassword.length < 6) return res.status(400).json({ error: 'New password must be at least 6 characters.' });
  const user = store.users.get(req.userId);
  if (!user) return res.status(404).json({ error: 'User not found.' });
  if (!await bcrypt.compare(currentPassword, user.passwordHash)) return res.status(401).json({ error: 'Current password is incorrect.' });
  await saveUser({ ...user, passwordHash: await bcrypt.hash(newPassword, 10), updatedAt: Date.now() });
  res.json({ message: 'Password changed successfully.' });
}));

function _safeUser(u) { const { passwordHash, ...s } = u; return s; }

module.exports = router;
