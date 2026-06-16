const mongoose = require('mongoose');

const shopSchema = new mongoose.Schema({
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  marketId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Market',
    required: true,
    index: true,
  },
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: true,
  },
  name: {
    type: String,
    required: [true, 'Tên cửa hàng là bắt buộc'],
    trim: true,
    maxlength: [200, 'Tên cửa hàng không quá 200 ký tự'],
  },
  description: {
    type: String,
    default: '',
    maxlength: [1000, 'Mô tả không quá 1000 ký tự'],
  },
  avatar: {
    type: String,
    default: '',
  },
  coverImage: {
    type: String,
    default: '',
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5,
  },
  totalReviews: {
    type: Number,
    default: 0,
    min: 0,
  },
  isOpen: {
    type: Boolean,
    default: true,
  },
  isSelling: {
    type: Boolean,
    default: true,
    description: 'Trạng thái bán hàng - true: đang bán, false: tạm ngưng bán',
  },
  isApproved: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

shopSchema.index({ name: 'text' });
shopSchema.index({ marketId: 1, isApproved: 1 });
shopSchema.index({ categoryId: 1 });
shopSchema.index({ isSelling: 1 });

// Virtual property: Kiểm tra sạp có đang mở bán thực sự không (dựa vào isSelling + giờ chợ)
shopSchema.virtual('isCurrentlySelling').get(function() {
  // Nếu shop không bật isSelling = false thì đóng
  if (!this.isSelling) return false;
  return true;
});

// Virtual: Trạng thái hiển thị cho người mua
shopSchema.virtual('statusDisplay').get(function() {
  if (!this.isSelling) return 'closed';
  return 'open';
});

module.exports = mongoose.model('Shop', shopSchema);
