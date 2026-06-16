const mongoose = require('mongoose');

const buyerAddressSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  label: {
    type: String,
    enum: ['home', 'work', 'other'],
    default: 'home',
  },
  address: {
    type: String,
    required: [true, 'Địa chỉ là bắt buộc'],
    trim: true,
    maxlength: [500, 'Địa chỉ không quá 500 ký tự'],
  },
  district: {
    type: String,
    trim: true,
  },
  city: {
    type: String,
    default: 'Đà Nẵng',
  },
  location: {
    lat: { type: Number, required: [true, 'Vĩ độ là bắt buộc'] },
    lng: { type: Number, required: [true, 'Kinh độ là bắt buộc'] },
  },
  contactName: {
    type: String,
    trim: true,
    maxlength: [100, 'Tên liên hệ không quá 100 ký tự'],
  },
  contactPhone: {
    type: String,
    trim: true,
  },
  isDefault: {
    type: Boolean,
    default: false,
  },
  instructions: {
    type: String,
    maxlength: [300, 'Hướng dẫn không quá 300 ký tự'],
    default: '',
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

buyerAddressSchema.index({ userId: 1, isDefault: 1 });
buyerAddressSchema.index({ 'location.lat': 1, 'location.lng': 1 });

buyerAddressSchema.pre('save', async function (next) {
  if (this.isDefault) {
    await this.constructor.updateMany(
      { userId: this.userId, _id: { $ne: this._id } },
      { isDefault: false },
    );
  }
  next();
});

module.exports = mongoose.model('BuyerAddress', buyerAddressSchema);
