const { User } = require('../models');
const { Notification } = require('../models');
const { NotFoundError, BadRequestError } = require('../middlewares/errorHandler');
const { getPaginationParams, buildPaginationResponse } = require('../utils/response');

class UserService {
  async getAll(query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = {};

    if (query.role) filter.role = query.role;
    if (query.status) filter.status = query.status;
    if (query.isApproved !== undefined) filter.isApproved = query.isApproved === true;
    if (query.marketId) filter.marketId = query.marketId;

    if (query.search) {
      filter.$or = [
        { fullName: { $regex: query.search, $options: 'i' } },
        { email: { $regex: query.search, $options: 'i' } },
        { phone: { $regex: query.search, $options: 'i' } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .populate('marketId', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      User.countDocuments(filter),
    ]);

    return {
      users,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getById(id) {
    const user = await User.findById(id).populate('marketId', 'name').lean();
    if (!user) throw new NotFoundError('Người dùng không tồn tại');
    return user;
  }

  async update(id, data) {
    // Prevent role/status injection
    delete data.role;
    delete data.status;
    delete data.isApproved;

    const user = await User.findByIdAndUpdate(
      id,
      { $set: data },
      { new: true, runValidators: true }
    ).populate('marketId', 'name').lean();

    if (!user) throw new NotFoundError('Người dùng không tồn tại');
    return user;
  }

  async updateStatus(id, status) {
    const user = await User.findByIdAndUpdate(
      id,
      { $set: { status } },
      { new: true, runValidators: true }
    ).lean();
    if (!user) throw new NotFoundError('Người dùng không tồn tại');
    return user;
  }

  async delete(id) {
    const user = await User.findByIdAndDelete(id);
    if (!user) throw new NotFoundError('Người dùng không tồn tại');
    return { message: 'Xóa người dùng thành công' };
  }

  async approve(id) {
    const user = await User.findByIdAndUpdate(
      id,
      { $set: { isApproved: true, status: 'active' } },
      { new: true, runValidators: true }
    ).lean();
    if (!user) throw new NotFoundError('Người dùng không tồn tại');

    await Notification.createNotification(
      user._id,
      'Tài khoản được duyệt',
      `Tài khoản "${user.fullName}" đã được admin duyệt. Bạn có thể bắt đầu sử dụng dịch vụ.`,
      'account_approved',
      { userId: user._id }
    );

    return user;
  }

  async reject(id, reason) {
    const user = await User.findByIdAndUpdate(
      id,
      { $set: { isApproved: false, status: 'rejected', rejectedReason: reason || '' } },
      { new: true, runValidators: true }
    ).lean();
    if (!user) throw new NotFoundError('Người dùng không tồn tại');

    await Notification.createNotification(
      user._id,
      'Tài khoản bị từ chối',
      `Tài khoản "${user.fullName}" đã bị admin từ chối${reason ? `: ${reason}` : ''}. Vui lòng liên hệ hỗ trợ.`,
      'account_rejected',
      { userId: user._id, reason }
    );

    return user;
  }

  async ban(id) {
    const user = await User.findByIdAndUpdate(
      id,
      { $set: { status: 'banned' } },
      { new: true }
    );
    if (!user) throw new NotFoundError('Người dùng không tồn tại');

    await Notification.createNotification(
      user._id,
      'Tài khoản bị khóa',
      `Tài khoản "${user.fullName}" đã bị khóa. Vui lòng liên hệ hỗ trợ.`,
      'account_banned',
      { userId: user._id }
    );

    return user;
  }

  async getSellers(query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { role: 'seller' };
    if (query.isApproved !== undefined) filter.isApproved = query.isApproved === true;
    if (query.status) filter.status = query.status;

    if (query.search) {
      filter.$or = [
        { fullName: { $regex: query.search, $options: 'i' } },
        { email: { $regex: query.search, $options: 'i' } },
        { phone: { $regex: query.search, $options: 'i' } },
      ];
    }

    const [sellers, total] = await Promise.all([
      User.find(filter)
        .populate('marketId', 'name')
        .select('fullName email phone avatar isApproved status marketId createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      User.countDocuments(filter),
    ]);

    return {
      sellers,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getShippers(query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { role: 'shipper' };
    if (query.isApproved !== undefined) filter.isApproved = query.isApproved === true;
    if (query.status) filter.status = query.status;

    const [shippers, total] = await Promise.all([
      User.find(filter)
        .select('fullName email phone avatar isApproved status createdAt')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      User.countDocuments(filter),
    ]);

    return {
      shippers,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }
}

module.exports = new UserService();
