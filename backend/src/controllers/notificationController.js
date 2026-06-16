const notificationService = require('../services/notificationService');
const { sendSuccess, sendPaginated } = require('../utils/response');

class NotificationController {
  async getAll(req, res, next) {
    try {
      const result = await notificationService.getAll(req.userId, req.query);
      // Prevent 304 Not Modified caching so each poll always returns fresh data
      res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.set('Pragma', 'no-cache');
      res.set('Expires', '0');
      sendPaginated(
        res,
        {
          notifications: result.notifications,
          unreadCount: result.unreadCount,
        },
        result.pagination,
        'Lấy danh sách thông báo thành công'
      );
    } catch (error) {
      next(error);
    }
  }

  async markAsRead(req, res, next) {
    try {
      const notification = await notificationService.markAsRead(req.params.id, req.userId);
      sendSuccess(res, notification, 'Đánh dấu đã đọc thành công');
    } catch (error) {
      next(error);
    }
  }

  async markAllAsRead(req, res, next) {
    try {
      const result = await notificationService.markAllAsRead(req.userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      const result = await notificationService.delete(req.params.id, req.userId);
      sendSuccess(res, result, 'Xóa thông báo thành công');
    } catch (error) {
      next(error);
    }
  }

  async deleteAll(req, res, next) {
    try {
      const result = await notificationService.deleteAll(req.userId);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new NotificationController();
