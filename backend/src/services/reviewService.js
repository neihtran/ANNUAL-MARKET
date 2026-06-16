const { Review, Order, Product } = require('../models');
const { NotFoundError, BadRequestError } = require('../middlewares/errorHandler');
const { getPaginationParams, buildPaginationResponse } = require('../utils/response');

class ReviewService {
  async create(buyerId, data) {
    const order = await Order.findById(data.orderId)
      .populate('items.productId');

    if (!order) throw new NotFoundError('Đơn hàng không tồn tại');

    if (order.buyerId.toString() !== buyerId.toString()) {
      throw new BadRequestError('Bạn không có quyền đánh giá đơn hàng này');
    }

    if (order.status !== 'delivered') {
      throw new BadRequestError('Chỉ có thể đánh giá đơn hàng đã giao');
    }

    const existingReview = await Review.findOne({
      orderId: data.orderId,
      productId: data.productId,
      buyerId: buyerId,
    });
    if (existingReview) throw new BadRequestError('Bạn đã đánh giá sản phẩm này trong đơn hàng này');

    const itemExists = order.items.find(
      item => item.productId?._id?.toString() === data.productId.toString()
    );
    if (!itemExists) throw new BadRequestError('Sản phẩm không thuộc đơn hàng này');

    // Find product to get sellerId
    const product = await Product.findById(data.productId);
    if (!product) throw new NotFoundError('Sản phẩm không tồn tại');

    const review = new Review({
      orderId: data.orderId,
      productId: data.productId,
      buyerId: buyerId,
      sellerId: product.sellerId,
      rating: data.rating,
      comment: data.comment || '',
      images: data.images || [],
    });

    await review.save();

    return review;
  }

  async getByProduct(productId, query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { productId };

    const [reviews, total] = await Promise.all([
      Review.find(filter)
        .populate('buyerId', 'fullName avatar')
        .populate('sellerId', 'fullName')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Review.countDocuments(filter),
    ]);

    const formattedReviews = reviews.map(r => ({
      ...r,
      buyer: r.buyerId,
      seller: r.sellerId,
    }));

    const stats = await Review.aggregate([
      { $match: { productId: new (require('mongoose')).Types.ObjectId(productId) } },
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
        },
      },
    ]);

    return {
      reviews: formattedReviews,
      stats: stats[0] || {
        averageRating: 0, totalReviews: 0,
        rating1: 0, rating2: 0, rating3: 0, rating4: 0, rating5: 0,
      },
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getBySeller(sellerId, query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { sellerId };

    const [reviews, total] = await Promise.all([
      Review.find(filter)
        .populate('buyerId', 'fullName avatar')
        .populate('productId', 'name images')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Review.countDocuments(filter),
    ]);

    return {
      reviews: reviews.map(r => ({
        ...r,
        buyer: r.buyerId,
        product: r.productId,
      })),
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async reply(reviewId, sellerId, reply) {
    const review = await Review.findById(reviewId);
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
    const review = await Review.findById(reviewId);
    if (!review) throw new NotFoundError('Không tìm thấy đánh giá');
    await review.deleteOne();
    return { message: 'Xóa đánh giá thành công' };
  }
}

module.exports = new ReviewService();
