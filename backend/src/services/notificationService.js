const { Notification } = require('../models');
const { NotFoundError } = require('../middlewares/errorHandler');
const { getPaginationParams, buildPaginationResponse } = require('../utils/response');

class NotificationService {
  async getAll(userId, query) {
    const { page, limit, skip } = getPaginationParams(query);
    
    const filter = { userId };

    if (query.isRead !== undefined) {
      filter.isRead = query.isRead === 'true';
    }

    const [notifications, total, unreadCount] = await Promise.all([
      Notification.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Notification.countDocuments(filter),
      Notification.countDocuments({ userId, isRead: false }),
    ]);

    return {
      notifications,
      unreadCount,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async markAsRead(notificationId, userId) {
    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, userId },
      { $set: { isRead: true, readAt: new Date() } },
      { new: true }
    );

    if (!notification) {
      throw new NotFoundError('Thông báo không tồn tại');
    }

    return notification;
  }

  async markAllAsRead(userId) {
    await Notification.updateMany(
      { userId, isRead: false },
      { $set: { isRead: true, readAt: new Date() } }
    );

    return { message: 'Đã đánh dấu tất cả thông báo là đã đọc' };
  }

  async delete(notificationId, userId) {
    const notification = await Notification.findOneAndDelete({
      _id: notificationId,
      userId,
    });

    if (!notification) {
      throw new NotFoundError('Thông báo không tồn tại');
    }

    return { message: 'Xóa thông báo thành công' };
  }

  async deleteAll(userId) {
    await Notification.deleteMany({ userId });
    return { message: 'Xóa tất cả thông báo thành công' };
  }
}

module.exports = new NotificationService();
