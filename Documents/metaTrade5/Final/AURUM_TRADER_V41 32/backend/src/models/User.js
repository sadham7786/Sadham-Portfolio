'use strict';
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  _id:         { type: String, required: true },   // uuid — keep same id format
  fullName:    { type: String, required: true, trim: true },
  email:       { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash:{ type: String, required: true },
  balance:     { type: Number, default: 10000.00 },
  accountType: { type: String, default: 'DEMO' },
  leverage:    { type: Number, default: 100 },
  role:        { type: String, default: 'user' },
  createdAt:   { type: Number, default: () => Date.now() },
  updatedAt:   { type: Number, default: () => Date.now() },
}, { versionKey: false });

// Never expose passwordHash in JSON responses
userSchema.methods.toSafe = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  obj.id = obj._id;
  delete obj._id;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
