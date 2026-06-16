const { User } = require('../models');
const { successResponse, errorResponse } = require('../utils/response');
const { buildPagination } = require('../utils/helpers');
const Notification = require('../models/Notification');
const socketService = require('../services/socketService');

async function sendUserNotification(userId, title, body, type, referenceId) {
  const notif = await Notification.create({
    userId,
    title,
    body,
    type,
    referenceId,
  });
  socketService.sendNotification(userId.toString(), {
    _id: notif._id,
    title,
    body,
    type,
    referenceId,
    isRead: false,
    createdAt: notif.createdAt,
  });
}

exports.getUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, role, isApproved, status, marketId, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;
    
    const query = {};
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }
    if (role) {
      query.role = role;
    }
    if (isApproved !== undefined) {
      query.isApproved = isApproved === 'true';
    }
    if (status) {
      query.status = status;
    }
    if (marketId) {
      query.marketId = marketId;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [users, total] = await Promise.all([
      User.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .populate('marketId', 'name address district')
        .populate('categoryIds', 'name icon description'),
      User.countDocuments(query),
    ]);

    return successResponse(res, {
      users,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};

exports.createUser = async (req, res, next) => {
  try {
    const { email, password, fullName, phone, role, marketId, isApproved } = req.body;

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return errorResponse(res, 'Email đã được sử dụng', 409);
    }

    // Sellers and shippers must be manually approved by admin — never auto-approved
    const requiresApproval = role === 'seller' || role === 'shipper';
    const shouldAutoApprove = isApproved === true && !requiresApproval;

    const user = new User({
      email,
      password,
      fullName,
      phone: phone || '',
      role: role || 'buyer',
      marketId: marketId || null,
      isApproved: shouldAutoApprove,
      status: shouldAutoApprove ? 'active' : 'inactive',
    });

    await user.save();

    return successResponse(res, { user: user.toSafeObject() }, 'Tạo tài khoản thành công');
  } catch (error) {
    next(error);
  }
};

exports.getUserById = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id)
      .populate('marketId', 'name address district')
      .populate('categoryIds', 'name icon description');
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    return successResponse(res, { user });
  } catch (error) {
    next(error);
  }
};

exports.approveUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isApproved: true, status: 'active' },
      { new: true, runValidators: true }
    );
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }

    const roleMessages = {
      seller: 'Tài khoản của bạn đã được phê duyệt. Bây giờ bạn có thể tạo Gian hàng và đăng bán sản phẩm.',
      shipper: 'Tài khoản Shipper của bạn đã được phê duyệt. Bây giờ bạn có thể nhận đơn hàng từ mọi chợ.',
      buyer: 'Tài khoản của bạn đã được phê duyệt.',
    };
    const message = roleMessages[user.role] || 'Tài khoản của bạn đã được phê duyệt.';

    await sendUserNotification(
      user._id,
      'Tài khoản được phê duyệt',
      message,
      'account_approved',
      user._id
    );
    return successResponse(res, { user }, 'Phê duyệt người dùng thành công');
  } catch (error) {
    next(error);
  }
};

exports.rejectUser = async (req, res, next) => {
  try {
    const { reason } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isApproved: false, rejectedReason: reason, status: 'rejected' },
      { new: true, runValidators: true }
    );
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    await sendUserNotification(
      user._id,
      'Tài khoản bị từ chối',
      reason
        ? `Tài khoản của bạn đã bị từ chối với lý do: ${reason}`
        : `Tài khoản của bạn đã bị từ chối. Vui lòng liên hệ admin để biết thêm chi tiết.`,
      'account_rejected',
      user._id
    );
    return successResponse(res, { user }, 'Từ chối người dùng thành công');
  } catch (error) {
    next(error);
  }
};

exports.banUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { status: 'banned' },
      { new: true, runValidators: true }
    );
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    await sendUserNotification(
      user._id,
      'Tài khoản bị khóa',
      `Tài khoản của bạn đã bị khóa bởi admin. Bạn sẽ không thể đăng nhập cho đến khi được mở khóa.`,
      'account_banned',
      user._id
    );
    return successResponse(res, { user }, 'Khóa tài khoản thành công');
  } catch (error) {
    next(error);
  }
};

exports.unbanUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { status: 'active' },
      { new: true, runValidators: true }
    );
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    await sendUserNotification(
      user._id,
      'Tài khoản đã được mở khóa',
      `Tài khoản của bạn đã được admin mở khóa. Bây giờ bạn có thể đăng nhập bình thường.`,
      'account_unbanned',
      user._id
    );
    return successResponse(res, { user }, 'Mở khóa tài khoản thành công');
  } catch (error) {
    next(error);
  }
};

exports.deleteUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    return successResponse(res, null, 'Xóa người dùng thành công');
  } catch (error) {
    next(error);
  }
};

exports.getBuyers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, status, marketId } = req.query;

    const query = { role: 'buyer' };
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }
    if (status) query.status = status;
    if (marketId) query.marketId = marketId;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [buyers, total] = await Promise.all([
      User.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      User.countDocuments(query),
    ]);

    return successResponse(res, {
      buyers,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};

exports.getSellers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, isApproved, marketId } = req.query;
    
    const query = { role: 'seller' };
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }
    if (isApproved !== undefined) {
      query.isApproved = isApproved === 'true';
    }
    if (marketId) {
      query.marketId = marketId;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [sellers, total] = await Promise.all([
      User.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      User.countDocuments(query),
    ]);

    return successResponse(res, {
      sellers,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};

exports.getShippers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, isApproved } = req.query;
    
    const query = { role: 'shipper' };
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }
    if (isApproved !== undefined) {
      query.isApproved = isApproved === 'true';
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [shippers, total] = await Promise.all([
      User.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      User.countDocuments(query),
    ]);

    return successResponse(res, {
      shippers,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};

exports.getById = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    return successResponse(res, { user });
  } catch (error) {
    next(error);
  }
};

exports.update = async (req, res, next) => {
  try {
    const userId = req.params.id;
    if (req.userId.toString() !== userId && req.user.role !== 'admin') {
      return errorResponse(res, 'Không có quyền cập nhật', 403);
    }
    const user = await User.findByIdAndUpdate(
      userId,
      req.body,
      { new: true, runValidators: true }
    );
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    return successResponse(res, { user }, 'Cập nhật thành công');
  } catch (error) {
    next(error);
  }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const userService = require('../services/userService');
    const user = await userService.updateStatus(req.params.id, status);
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }
    return successResponse(res, { user }, 'Cập nhật trạng thái thành công');
  } catch (error) {
    next(error);
  }
};

exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.params.id;

    if (req.userId.toString() !== userId && req.user.role !== 'admin') {
      return errorResponse(res, 'Không có quyền đổi mật khẩu', 403);
    }

    if (!currentPassword || !newPassword) {
      return errorResponse(res, 'Vui lòng nhập đầy đủ mật khẩu hiện tại và mật khẩu mới', 400);
    }

    if (newPassword.length < 6) {
      return errorResponse(res, 'Mật khẩu mới phải có ít nhất 6 ký tự', 400);
    }

    const user = await User.findById(userId).select('+password');
    if (!user) {
      return errorResponse(res, 'Không tìm thấy người dùng', 404);
    }

    // If changing own password, verify current password
    if (req.userId.toString() === userId) {
      const isMatch = await user.comparePassword(currentPassword);
      if (!isMatch) {
        return errorResponse(res, 'Mật khẩu hiện tại không đúng', 400);
      }
    }

    user.password = newPassword;
    await user.save();

    return successResponse(res, null, 'Đổi mật khẩu thành công');
  } catch (error) {
    next(error);
  }
};
