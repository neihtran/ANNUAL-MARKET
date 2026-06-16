const { ShipperReview, Order } = require('../models');
const { NotFoundError, BadRequestError } = require('../middlewares/errorHandler');
const { getPaginationParams, buildPaginationResponse } = require('../utils/response');

class ShipperReviewService {
  async create(buyerId, data) {
    const order = await Order.findById(data.orderId);

    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    if (order.buyerId.toString() !== buyerId.toString()) {
      throw new BadRequestError('Bạn không có quyền đánh giá đơn hàng này');
    }

    if (!order.shipperId) {
      throw new BadRequestError('Đơn hàng không có người giao hàng');
    }

    if (order.status !== 'delivered') {
      throw new BadRequestError('Chỉ có thể đánh giá khi đơn hàng đã được giao');
    }

    const existingReview = await ShipperReview.findOne({
      orderId: data.orderId,
      buyerId: buyerId,
    });
    if (existingReview) throw new BadRequestError('Bạn đã đánh giá người giao hàng cho đơn hàng này');

    const review = new ShipperReview({
      orderId: data.orderId,
      buyerId: buyerId,
      shipperId: order.shipperId,
      rating: data.rating,
      aspects: {
        punctuality: data.aspects?.punctuality || null,
        attitude: data.aspects?.attitude || null,
        handling: data.aspects?.handling || null,
      },
      comment: data.comment || '',
    });

    await review.save();

    return review;
  }

  async getByShipper(shipperId, query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { shipperId };

    const [reviews, total] = await Promise.all([
      ShipperReview.find(filter)
        .populate('buyerId', 'fullName avatar')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      ShipperReview.countDocuments(filter),
    ]);

    const formattedReviews = reviews.map(r => ({
      ...r,
      buyer: r.buyerId,
    }));

    const stats = await ShipperReview.aggregate([
      { $match: { shipperId: new (require('mongoose')).Types.ObjectId(shipperId) } },
      {
        $group: {
          _id: null,
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

    return {
      reviews: formattedReviews,
      stats: stats[0] || {
        averageRating: 0, totalReviews: 0,
        rating1: 0, rating2: 0, rating3: 0, rating4: 0, rating5: 0,
        avgPunctuality: 0, avgAttitude: 0, avgHandling: 0,
      },
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async delete(reviewId) {
    const review = await ShipperReview.findById(reviewId);
    if (!review) throw new NotFoundError('Không tìm thấy đánh giá');
    await review.deleteOne();
    return { message: 'Xóa đánh giá thành công' };
  }
}

module.exports = new ShipperReviewService();
