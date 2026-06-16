const shipperReviewService = require('../services/shipperReviewService');
const { sendSuccess, sendCreated, sendPaginated } = require('../utils/response');

class ShipperReviewController {
  async create(req, res, next) {
    try {
      const review = await shipperReviewService.create(req.userId, req.body);
      sendCreated(res, review, 'Đánh giá người giao hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async getByShipper(req, res, next) {
    try {
      const result = await shipperReviewService.getByShipper(req.userId, req.query);
      sendPaginated(res, {
        reviews: result.reviews,
        stats: result.stats,
      }, result.pagination, 'Lấy danh sách đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      await shipperReviewService.delete(req.params.id);
      sendSuccess(res, null, 'Xóa đánh giá thành công');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ShipperReviewController();
