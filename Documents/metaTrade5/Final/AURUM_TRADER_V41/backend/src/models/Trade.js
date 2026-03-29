'use strict';
const mongoose = require('mongoose');

const tradeSchema = new mongoose.Schema({
  _id:          { type: String, required: true },
  userId:       { type: String, required: true, index: true },
  symbol:       { type: String, default: 'XAU/USD' },
  type:         { type: String, enum: ['buy','sell'], required: true },
  lotSize:      { type: Number, required: true },
  openPrice:    { type: Number, required: true },
  closePrice:   { type: Number, default: null },
  stopLoss:     { type: Number, default: null },
  takeProfit:   { type: Number, default: null },
  margin:       { type: Number, default: 0 },
  status:       { type: String, enum: ['open','closed'], default: 'open', index: true },
  openTime:     { type: Number, required: true },
  closeTime:    { type: Number, default: null },
  pnl:          { type: Number, default: null },
  closeReason:  { type: String, default: null },
  pendingOrderId: { type: String, default: null },
  createdAt:    { type: Number, default: () => Date.now() },
  updatedAt:    { type: Number, default: () => Date.now() },
}, { versionKey: false });

module.exports = mongoose.model('Trade', tradeSchema);
