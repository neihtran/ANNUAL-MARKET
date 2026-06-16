const sellerReviewService = require('../services/sellerReviewService');
const { sendSuccess, sendCreated, sendPaginated } = require('../utils/response');

class SellerReviewController {
  async create(req, res, next) {
    try {
      const review = await sellerReviewService.create(req.userId, req.body);
      sendCreated(res, review, 'Đánh giá người bán thành công');
    } catch (error) {
      next(error);
    }
  }

  async getBySeller(req, res, next) {
    try {
      const result = await sellerReviewService.getBySeller(req.userId, req.query);
      sendPaginated(res, {
        reviews: result.reviews,
        stats: result.stats,
      }, result.pagination, 'Lấy danh sách đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }

  async reply(req, res, next) {
    try {
      const result = await sellerReviewService.reply(req.params.id, req.userId, req.body.comment);
      sendSuccess(res, result, 'Phản hồi đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      await sellerReviewService.delete(req.params.id);
      sendSuccess(res, null, 'Xóa đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SellerReviewController();
