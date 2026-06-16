const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  shopId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Shop',
    required: true,
  },
  shopName: {
    type: String,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  imageUrl: {
    type: String,
    default: '',
  },
  price: {
    type: Number,
    required: true,
    min: 0,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  unit: {
    type: String,
    default: 'kg',
  },
}, { _id: false });

const deliveryAddressSchema = new mongoose.Schema({
  address: {
    type: String,
    required: true,
  },
  lat: {
    type: Number,
    required: true,
  },
  lng: {
    type: Number,
    required: true,
  },
  contactName: {
    type: String,
    required: true,
  },
  contactPhone: {
    type: String,
    required: true,
  },
}, { _id: false });

const orderSchema = new mongoose.Schema({
  orderNumber: {
    type: String,
    unique: true,
    index: true,
  },
  buyerId: {
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
  items: {
    type: [orderItemSchema],
    required: true,
    validate: {
      validator: function(v) {
        return v && v.length > 0;
      },
      message: 'Đơn hàng phải có ít nhất 1 sản phẩm',
    },
  },
  shipperId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
    index: true,
  },
  deliveryAddress: {
    type: deliveryAddressSchema,
    required: true,
  },
  subtotal: {
    type: Number,
    required: true,
    min: 0,
  },
  shippingFee: {
    type: Number,
    default: 0,
    min: 0,
  },
  discount: {
    type: Number,
    default: 0,
    min: 0,
  },
  total: {
    type: Number,
    required: true,
    min: 0,
  },
  status: {
    type: String,
    enum: [
      'pending',
      'finding_shipper',
      'shipper_accepted',
      'heading_to_market',
      'arrived_at_market',
      'ready_for_pickup',
      'seller_handed_over',
      'picked_up',
      'shopping',
      'delivering',
      'delivered',
      'cancelled',
    ],
    default: 'pending',
    index: true,
  },
  paymentMethod: {
    type: String,
    enum: ['cod', 'vnpay', 'momo'],
    default: 'cod',
  },
  paymentStatus: {
    type: String,
    enum: ['unpaid', 'paid', 'refunded'],
    default: 'unpaid',
  },
  note: {
    type: String,
    maxlength: [500, 'Ghi chú không quá 500 ký tự'],
    default: '',
  },
  cancelReason: {
    type: String,
    default: '',
  },
  cancelBy: {
    type: String,
    enum: ['buyer', 'seller', 'shipper', 'admin', ''],
    default: '',
  },
  shippingDistance: {
    type: Number,
    default: 0,
  },
  estimatedMinutes: {
    type: Number,
    default: 0,
  },
  confirmImageUrl: {
    type: String,
    default: '',
  },
  deliveredAt: {
    type: Date,
  },
  /// Realtime GPS location of the shipper (updated during delivery for buyer tracking)
  shipperLocation: {
    lat: { type: Number, default: null },
    lng: { type: Number, default: null },
    updatedAt: { type: Date, default: null },
  },
  statusHistory: [{
    status: String,
    timestamp: { type: Date, default: Date.now },
    note: String,
  }],
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

orderSchema.index({ buyerId: 1, createdAt: -1 });
orderSchema.index({ marketId: 1, status: 1 });
orderSchema.index({ shipperId: 1, status: 1 });
orderSchema.index({ status: 1, createdAt: -1 });

orderSchema.pre('save', async function(next) {
  if (!this.orderNumber) {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 6).toUpperCase();
    this.orderNumber = `CTT-${timestamp}-${random}`;
  }
  
  if (this.isModified('status')) {
    this.statusHistory.push({
      status: this.status,
      timestamp: new Date(),
    });
  }
  
  next();
});

module.exports = mongoose.model('Order', orderSchema);
