const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  title: {
    type: String,
    required: [true, 'Tiêu đề là bắt buộc'],
    maxlength: [200, 'Tiêu đề không quá 200 ký tự'],
  },
  body: {
    type: String,
    required: [true, 'Nội dung là bắt buộc'],
    maxlength: [500, 'Nội dung không quá 500 ký tự'],
  },
  type: {
    type: String,
    enum: [
      'order_new', 'order_status', 'approved', 'rejected',
      'review', 'order', 'promotion', 'system',
      'user_register', 'account_approved', 'account_rejected',
      'account_banned', 'account_unbanned',
      // Legacy aliases
      'account_approval', 'user_approval', 'order_approved',
    ],
    default: 'order_status',
  },
  referenceId: {
    type: mongoose.Schema.Types.ObjectId,
    default: null,
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  isRead: {
    type: Boolean,
    default: false,
    index: true,
  },
  readAt: {
    type: Date,
  },
}, {
  timestamps: true,
});

notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });

notificationSchema.methods.markAsRead = async function() {
  this.isRead = true;
  this.readAt = new Date();
  return this.save();
};

notificationSchema.statics.createNotification = async function(userId, title, body, type = 'system', data = {}) {
  const notification = new this({ userId, title, body, type, data });
  return notification.save();
};

notificationSchema.statics.createManyNotifications = async function(notifications) {
  const docs = notifications.map(n => ({
    userId: n.userId,
    title: n.title,
    body: n.body,
    type: n.type || 'system',
    data: n.data || {},
  }));
  return this.insertMany(docs);
};

module.exports = mongoose.model('Notification', notificationSchema);
