'use strict';

// ── File-based persistence ─────────────────────────────────────────────────────
// Saves critical store data (users, trades, pending orders, transactions)
// to data/store.json so the state survives Render free-tier cold restarts.
// Uses Node built-in `fs` — no extra dependencies.

const fs   = require('fs');
const path = require('path');

const DATA_DIR  = path.join(__dirname, '../../data');
const DATA_FILE = path.join(DATA_DIR, 'store.json');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

// ── Serialize Maps to plain objects ──────────────────────────────────────────
function _mapToObj(map) {
  const obj = {};
  for (const [k, v] of map.entries()) obj[k] = v;
  return obj;
}

// ── Save store to disk (debounced — max 1 write per 500ms) ───────────────────
let _saveTimer = null;
function save(store) {
  if (_saveTimer) return;         // already scheduled
  _saveTimer = setTimeout(() => {
    _saveTimer = null;
    try {
      const data = {
        users:         _mapToObj(store.users),
        trades:        _mapToObj(store.trades),
        pendingOrders: _mapToObj(store.pendingOrders),
        transactions:  _mapToObj(store.transactions),
        savedAt:       Date.now(),
      };
      fs.writeFileSync(DATA_FILE, JSON.stringify(data), 'utf8');
    } catch (e) {
      console.warn('[persist] save error:', e.message);
    }
  }, 500);
}

// ── Load store from disk on startup ──────────────────────────────────────────
function load(store) {
  if (!fs.existsSync(DATA_FILE)) {
    console.log('[persist] No saved data — starting fresh.');
    return;
  }
  try {
    const raw  = fs.readFileSync(DATA_FILE, 'utf8');
    const data = JSON.parse(raw);
    let users = 0, trades = 0, orders = 0, txns = 0;

    if (data.users)  {
      for (const [k, v] of Object.entries(data.users))  { store.users.set(k, v);  users++; }
    }
    if (data.trades) {
      for (const [k, v] of Object.entries(data.trades)) { store.trades.set(k, v); trades++; }
    }
    if (data.pendingOrders) {
      for (const [k, v] of Object.entries(data.pendingOrders)) {
        store.pendingOrders.set(k, v); orders++;
      }
    }
    if (data.transactions) {
      for (const [k, v] of Object.entries(data.transactions)) {
        store.transactions.set(k, v); txns++;
      }
    }
    const age = data.savedAt
      ? Math.round((Date.now() - data.savedAt) / 1000) + 's ago'
      : 'unknown age';
    console.log(
      `[persist] Loaded: ${users} users, ${trades} trades, ` +
      `${orders} pending orders, ${txns} transactions (saved ${age})`
    );
  } catch (e) {
    console.warn('[persist] Load error — starting fresh:', e.message);
  }
}

module.exports = { save, load };
