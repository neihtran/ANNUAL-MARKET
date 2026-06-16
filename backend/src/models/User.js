const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const documentSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['cccd', 'driver_license', 'business_license'],
    required: true,
  },
  url: {
    type: String,
    required: true,
  },
  uploadedAt: {
    type: Date,
    default: Date.now,
  },
}, { _id: false });

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email là bắt buộc'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Email không hợp lệ'],
  },
  password: {
    type: String,
    required: [true, 'Mật khẩu là bắt buộc'],
    minlength: [6, 'Mật khẩu phải có ít nhất 6 ký tự'],
    select: false,
  },
  fullName: {
    type: String,
    required: [true, 'Họ tên là bắt buộc'],
    trim: true,
    maxlength: [100, 'Họ tên không quá 100 ký tự'],
  },
  phone: {
    type: String,
    required: [false, 'Số điện thoại là bắt buộc'],
    default: '',
  },
  avatar: {
    type: String,
    default: '',
  },
  role: {
    type: String,
    enum: ['admin', 'seller', 'buyer', 'shipper'],
    required: true,
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  isApproved: {
    type: Boolean,
    default: false,
  },
  rejectedReason: {
    type: String,
    default: '',
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'banned', 'rejected'],
    default: 'active',
  },
  deviceToken: {
    type: String,
    default: '',
  },
  isOnline: {
    type: Boolean,
    default: false,
  },
  location: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  documents: [documentSchema],
  marketId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Market',
    default: null,
  },
  categoryIds: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
  }],
  bankInfo: {
    bankName: { type: String, default: '' },
    accountNumber: { type: String, default: '' },
    accountName: { type: String, default: '' },
  },
  // Seller rating fields
  sellerRating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5,
  },
  sellerReviewCount: {
    type: Number,
    default: 0,
  },
  sellerQualityRating: {
    type: Number,
    default: null,
  },
  sellerCommunicationRating: {
    type: Number,
    default: null,
  },
  sellerDeliveryRating: {
    type: Number,
    default: null,
  },
  // Shipper rating fields
  shipperRating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5,
  },
  shipperReviewCount: {
    type: Number,
    default: 0,
  },
  shipperPunctualityRating: {
    type: Number,
    default: null,
  },
  shipperAttitudeRating: {
    type: Number,
    default: null,
  },
  shipperHandlingRating: {
    type: Number,
    default: null,
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

userSchema.methods.toSafeObject = function() {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

userSchema.index({ phone: 1 });
userSchema.index({ role: 1 });
userSchema.index({ status: 1 });
userSchema.index({ isApproved: 1 });
userSchema.index({ marketId: 1 });
userSchema.index({ role: 1, isApproved: 1 });

module.exports = mongoose.model('User', userSchema);
