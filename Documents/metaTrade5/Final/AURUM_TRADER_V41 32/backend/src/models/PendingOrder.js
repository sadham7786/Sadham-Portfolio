'use strict';
const mongoose = require('mongoose');

const pendingOrderSchema = new mongoose.Schema({
  _id:        { type: String, required: true },
  userId:     { type: String, required: true, index: true },
  symbol:     { type: String, default: 'XAU/USD' },
  type:       { type: String, enum: ['buy_limit','sell_limit','buy_stop','sell_stop'], required: true },
  lotSize:    { type: Number, required: true },
  price:      { type: Number, required: true },
  stopLoss:   { type: Number, default: null },
  takeProfit: { type: Number, default: null },
  expiry:     { type: Number, default: null },
  status:     { type: String, enum: ['pending','triggered','cancelled','expired'], default: 'pending', index: true },
  tradeId:    { type: String, default: null },
  triggeredAt:{ type: Number, default: null },
  createdAt:  { type: Number, default: () => Date.now() },
  updatedAt:  { type: Number, default: () => Date.now() },
}, { versionKey: false });

module.exports = mongoose.model('PendingOrder', pendingOrderSchema);
