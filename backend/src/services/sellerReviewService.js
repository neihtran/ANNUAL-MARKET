const { SellerReview, Order } = require('../models');
const { NotFoundError, BadRequestError } = require('../middlewares/errorHandler');
const { getPaginationParams, buildPaginationResponse } = require('../utils/response');

class SellerReviewService {
  async create(buyerId, data) {
    const order = await Order.findById(data.orderId);

    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    if (order.buyerId.toString() !== buyerId.toString()) {
      throw new BadRequestError('Bạn không có quyền đánh giá đơn hàng này');
    }

    if (order.status !== 'delivered') {
      throw new BadRequestError('Chỉ có thể đánh giá khi đơn hàng đã được giao');
    }

    const existingReview = await SellerReview.findOne({
      orderId: data.orderId,
      buyerId: buyerId,
    });
    if (existingReview) throw new BadRequestError('Bạn đã đánh giá người bán cho đơn hàng này');

    // Extract unique sellerIds from order items
    const sellerIdsInOrder = [...new Set(order.items.map(item => item.sellerId.toString()))];

    const review = new SellerReview({
      orderId: data.orderId,
      buyerId: buyerId,
      sellerId: data.sellerId,
      rating: data.rating,
      aspects: {
        quality: data.aspects?.quality || null,
        communication: data.aspects?.communication || null,
        delivery: data.aspects?.delivery || null,
      },
      comment: data.comment || '',
    });

    await review.save();

    return review;
  }

  async getBySeller(sellerId, query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { sellerId };

    const [reviews, total] = await Promise.all([
      SellerReview.find(filter)
        .populate('buyerId', 'fullName avatar')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      SellerReview.countDocuments(filter),
    ]);

    const formattedReviews = reviews.map(r => ({
      ...r,
      buyer: r.buyerId,
    }));

    const stats = await SellerReview.aggregate([
      { $match: { sellerId: new (require('mongoose')).Types.ObjectId(sellerId) } },
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
          avgQuality: { $avg: '$aspects.quality' },
          avgCommunication: { $avg: '$aspects.communication' },
          avgDelivery: { $avg: '$aspects.delivery' },
        },
      },
    ]);

    return {
      reviews: formattedReviews,
      stats: stats[0] || {
        averageRating: 0, totalReviews: 0,
        rating1: 0, rating2: 0, rating3: 0, rating4: 0, rating5: 0,
        avgQuality: 0, avgCommunication: 0, avgDelivery: 0,
      },
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async reply(reviewId, sellerId, reply) {
    const review = await SellerReview.findById(reviewId);
    if (!review) throw new NotFoundError('Không tìm thấy đánh giá');
    if (review.sellerId.toString() !== sellerId) {
      throw new BadRequestError('Bạn không có quyền trả lời đánh giá này');
    }
    review.sellerReply = reply;
    review.replyAt = new Date();
    await review.save();
    return review;
  }

  async delete(reviewId) {
    const review = await SellerReview.findById(reviewId);
    if (!review) throw new NotFoundError('Không tìm thấy đánh giá');
    await review.deleteOne();
    return { message: 'Xóa đánh giá thành công' };
  }
}

module.exports = new SellerReviewService();
