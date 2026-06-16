const reviewService = require('../services/reviewService');
const { sendSuccess, sendCreated, sendPaginated } = require('../utils/response');

class ReviewController {
  async create(req, res, next) {
    try {
      const review = await reviewService.create(req.userId, req.body);
      sendCreated(res, review, 'Đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }

  async getByProduct(req, res, next) {
    try {
      const result = await reviewService.getByProduct(req.params.productId, req.query);
      sendPaginated(res, {
        reviews: result.reviews,
        stats: result.stats,
      }, result.pagination, 'Lấy danh sách đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }

  async getBySeller(req, res, next) {
    try {
      const result = await reviewService.getBySeller(req.userId, req.query);
      sendPaginated(res, result.reviews, result.pagination, 'Lấy danh sách đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }

  async reply(req, res, next) {
    try {
      const result = await reviewService.reply(req.params.id, req.userId, req.body.comment);
      sendSuccess(res, result, 'Phản hồi đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      await reviewService.delete(req.params.id);
      sendSuccess(res, null, 'Xóa đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReviewController();
