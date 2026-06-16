const mongoose = require('mongoose');

const sellerReviewSchema = new mongoose.Schema({
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
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
  aspects: {
    quality: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    communication: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    delivery: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
  },
  comment: {
    type: String,
    maxlength: [1000, 'Bình luận không quá 1000 ký tự'],
    default: '',
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

sellerReviewSchema.index({ sellerId: 1, createdAt: -1 });
sellerReviewSchema.index({ buyerId: 1, createdAt: -1 });

sellerReviewSchema.statics.calculateSellerRating = async function(sellerId) {
  const stats = await this.aggregate([
    { $match: { sellerId: new mongoose.Types.ObjectId(sellerId) } },
    {
      $group: {
        _id: '$sellerId',
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 },
        rating1: { $sum: { $cond: [{ $eq: ['$rating', 1] }, 1, 0] } },
        rating2: { $sum: { $cond: [{ $eq: ['$rating', 2] }, 1, 0] } },
        rating3: { $sum: { $cond: [{ $eq: ['$rating', 3] }, 1, 0] } },
        rating4: { $sum: { $cond: [{ $eq: ['$rating', 4] }, 1, 0] } },
        rating5: { $sum: { $cond: [{ $eq: ['$rating', 5] }, 1, 0] } },
        avgQuality: { $avg: '$aspects.quality' },
        avgCommunication: { $avg: '$aspects.communication' },
        avgDelivery: { $avg: '$aspects.delivery' },
      },
    },
  ]);

  if (stats.length > 0) {
    await mongoose.model('User').findByIdAndUpdate(sellerId, {
      sellerRating: Math.round(stats[0].averageRating * 10) / 10,
      sellerReviewCount: stats[0].totalReviews,
      sellerQualityRating: stats[0].avgQuality ? Math.round(stats[0].avgQuality * 10) / 10 : null,
      sellerCommunicationRating: stats[0].avgCommunication ? Math.round(stats[0].avgCommunication * 10) / 10 : null,
      sellerDeliveryRating: stats[0].avgDelivery ? Math.round(stats[0].avgDelivery * 10) / 10 : null,
    });
  }
};

sellerReviewSchema.post('save', async function() {
  await this.constructor.calculateSellerRating(this.sellerId);
});

sellerReviewSchema.post('remove', async function() {
  await this.constructor.calculateSellerRating(this.sellerId);
});

module.exports = mongoose.model('SellerReview', sellerReviewSchema);
