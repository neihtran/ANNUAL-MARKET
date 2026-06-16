const mongoose = require('mongoose');

const shipperReviewSchema = new mongoose.Schema({
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
  shipperId: {
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
    punctuality: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    attitude: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    handling: {
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
}, {
  timestamps: true,
});

shipperReviewSchema.index({ shipperId: 1, createdAt: -1 });
shipperReviewSchema.index({ buyerId: 1, createdAt: -1 });

shipperReviewSchema.statics.calculateShipperRating = async function(shipperId) {
  const stats = await this.aggregate([
    { $match: { shipperId: new mongoose.Types.ObjectId(shipperId) } },
    {
      $group: {
        _id: '$shipperId',
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 },
        rating1: { $sum: { $cond: [{ $eq: ['$rating', 1] }, 1, 0] } },
        rating2: { $sum: { $cond: [{ $eq: ['$rating', 2] }, 1, 0] } },
        rating3: { $sum: { $cond: [{ $eq: ['$rating', 3] }, 1, 0] } },
        rating4: { $sum: { $cond: [{ $eq: ['$rating', 4] }, 1, 0] } },
        rating5: { $sum: { $cond: [{ $eq: ['$rating', 5] }, 1, 0] } },
        avgPunctuality: { $avg: '$aspects.punctuality' },
        avgAttitude: { $avg: '$aspects.attitude' },
        avgHandling: { $avg: '$aspects.handling' },
      },
    },
  ]);

  if (stats.length > 0) {
    await mongoose.model('User').findByIdAndUpdate(shipperId, {
      shipperRating: Math.round(stats[0].averageRating * 10) / 10,
      shipperReviewCount: stats[0].totalReviews,
      shipperPunctualityRating: stats[0].avgPunctuality ? Math.round(stats[0].avgPunctuality * 10) / 10 : null,
      shipperAttitudeRating: stats[0].avgAttitude ? Math.round(stats[0].avgAttitude * 10) / 10 : null,
      shipperHandlingRating: stats[0].avgHandling ? Math.round(stats[0].avgHandling * 10) / 10 : null,
    });
  }
};

shipperReviewSchema.post('save', async function() {
  await this.constructor.calculateShipperRating(this.shipperId);
});

shipperReviewSchema.post('remove', async function() {
  await this.constructor.calculateShipperRating(this.shipperId);
});

module.exports = mongoose.model('ShipperReview', shipperReviewSchema);
