const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  shopId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Shop',
    index: true,
  },
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'ID người bán là bắt buộc'],
    index: true,
  },
  marketId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Market',
    index: true,
  },
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    index: true,
  },
  name: {
    type: String,
    required: [true, 'Tên sản phẩm là bắt buộc'],
    trim: true,
    maxlength: [200, 'Tên sản phẩm không quá 200 ký tự'],
  },
  description: {
    type: String,
    maxlength: [2000, 'Mô tả không quá 2000 ký tự'],
    default: '',
  },
  images: {
    type: [String],
    default: [],
    validate: {
      validator: function(v) {
        return v.length <= 10;
      },
      message: 'Tối đa 10 hình ảnh',
    },
  },
  price: {
    type: Number,
    required: [true, 'Giá là bắt buộc'],
    min: [0, 'Giá không được âm'],
  },
  unit: {
    type: String,
    required: [true, 'Đơn vị là bắt buộc'],
    enum: ['kg', 'bó', 'con', 'cái', 'lít', 'lon', 'gói', 'hộp', 'bịch', 'vỉ', 'phần'],
    default: 'kg',
  },
  stock: {
    type: Number,
    required: [true, 'Số lượng tồn kho là bắt buộc'],
    min: [0, 'Số lượng không được âm'],
    default: 0,
  },
  minOrder: {
    type: Number,
    min: [1, 'Đơn hàng tối thiểu phải ít nhất là 1'],
    default: 1,
  },
  isAvailable: {
    type: Boolean,
    default: true,
    index: true,
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5,
  },
  reviewCount: {
    type: Number,
    default: 0,
    min: 0,
  },
  soldCount: {
    type: Number,
    default: 0,
    min: 0,
  },
  productLocation: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
  },
  isOrganic: {
    type: Boolean,
    default: false,
  },
  isFresh: {
    type: Boolean,
    default: true,
  },
  tags: [{
    type: String,
    trim: true,
  }],
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

productSchema.index({ name: 'text', description: 'text' });
productSchema.index({ price: 1 });
productSchema.index({ marketId: 1, categoryId: 1, isAvailable: 1 });
productSchema.index({ sellerId: 1, isAvailable: 1 });
// location uses application-level Haversine distance, no MongoDB 2dsphere needed

module.exports = mongoose.model('Product', productSchema);
