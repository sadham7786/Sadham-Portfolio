'use strict';
const mongoose = require('mongoose');

// Stores the single simulation config document.
// We use a fixed _id of 'sim' so findByIdAndUpdate with upsert=true
// always writes exactly one document.
const configSchema = new mongoose.Schema({
  _id:           { type: String, default: 'sim' },
  tickIntervalMs:{ type: Number, default: 29 },
  volatility:    { type: Number, default: 2.5 },
  drift:         { type: Number, default: 0.0 },
  running:       { type: Boolean, default: true },
  simStatus:     { type: String, default: 'running' },
  simDateMs:     { type: Number, default: () => new Date('2025-01-01').getTime() },
  simStartMs:    { type: Number, default: () => new Date('2025-01-01').getTime() },
  simEndMs:      { type: Number, default: () => new Date('2025-12-31T23:59:59').getTime() },
}, { versionKey: false });

module.exports = mongoose.model('Config', configSchema);
