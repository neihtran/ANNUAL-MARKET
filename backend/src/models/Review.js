const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    required: true,
    index: true,
  },
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
    index: true,
  },
  buyerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  rating: {
    type: Number,
    required: [true, 'Đánh giá là bắt buộc'],
    min: [1, 'Đánh giá tối thiểu là 1 sao'],
    max: [5, 'Đánh giá tối đa là 5 sao'],
  },
  comment: {
    type: String,
    maxlength: [1000, 'Bình luận không quá 1000 ký tự'],
    default: '',
  },
  images: {
    type: [String],
    default: [],
    validate: {
      validator: function(v) {
        return v.length <= 5;
      },
      message: 'Tối đa 5 hình ảnh',
    },
  },
  isVerified: {
    type: Boolean,
    default: true,
  },
  sellerReply: {
    type: String,
    maxlength: [1000, 'Phản hồi không quá 1000 ký tự'],
    default: '',
  },
  replyAt: {
    type: Date,
  },
}, {
  timestamps: true,
});

reviewSchema.index({ productId: 1, createdAt: -1 });
reviewSchema.index({ sellerId: 1, createdAt: -1 });
reviewSchema.index({ rating: -1 });

reviewSchema.statics.calculateProductRating = async function(productId) {
  const stats = await this.aggregate([
    { $match: { productId: productId } },
    {
      $group: {
        _id: '$productId',
        averageRating: { $avg: '$rating' },
        reviewCount: { $sum: 1 },
      },
    },
  ]);

  if (stats.length > 0) {
    await mongoose.model('Product').findByIdAndUpdate(productId, {
      rating: Math.round(stats[0].averageRating * 10) / 10,
      reviewCount: stats[0].reviewCount,
    });
  }
};

reviewSchema.post('save', async function() {
  await this.constructor.calculateProductRating(this.productId);
});

reviewSchema.post('remove', async function() {
  await this.constructor.calculateProductRating(this.productId);
});

module.exports = mongoose.model('Review', reviewSchema);
