'use strict';
const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  _id:        { type: String, required: true },
  userId:     { type: String, required: true, index: true },
  type:       { type: String, required: true },
  amount:     { type: Number, required: true },
  description:{ type: String, default: '' },
  createdAt:  { type: Number, default: () => Date.now() },
}, { versionKey: false });

module.exports = mongoose.model('Transaction', transactionSchema);
