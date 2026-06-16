const { User } = require('../models');
const { generateTokens, verifyRefreshToken } = require('../utils/jwt');
const { BadRequestError, UnauthorizedError, NotFoundError, ConflictError } = require('../middlewares/errorHandler');
const Notification = require('../models/Notification');
const socketService = require('./socketService');

class AuthService {
  async register(data) {
    const existingUser = await User.findOne({ email: data.email });
    if (existingUser) {
      throw new ConflictError('Email đã được sử dụng');
    }

    const user = new User({
      email: data.email,
      password: data.password,
      fullName: data.fullName,
      phone: data.phone || '',
      role: data.role || 'buyer',
      status: 'inactive',
      isApproved: false,
      // Sellers: market + categories + documents are saved for admin review
      ...(data.role === 'seller' && {
        marketId: data.marketId || null,
        categoryIds: data.categoryIds || [],
        documents: data.documents || [],
      }),
      // Shippers: no marketId (free agent), but must upload driver license
      ...(data.role === 'shipper' && {
        marketId: null,
        categoryIds: [],
        documents: data.documents || [],
      }),
    });

    // Auto-approve buyers immediately — no admin approval needed
    if (user.role === 'buyer') {
      user.status = 'active';
      user.isApproved = true;
    }

    await user.save();

      // Notify admin when seller or shipper registers (they need approval)
    if (user.role === 'seller' || user.role === 'shipper') {
      const admins = await User.find({ role: 'admin', status: 'active' });

      if (admins.length > 0) {
        // Build detailed notification body
        const roleLabel = user.role === 'seller' ? 'Người bán' : 'Shipper';
        let notifBody = `Người dùng "${user.fullName}" (${roleLabel}) vừa đăng ký.`;
        if (user.role === 'seller') {
          if (user.marketId) notifBody += ` | Chợ: ${user.marketId}`;
          if (user.categoryIds?.length) notifBody += ` | Danh mục: ${user.categoryIds.length} mục`;
          notifBody += ` | CCCD: ${user.documents?.length || 0} tài liệu`;
        }
        if (user.role === 'shipper') {
          const dlCount = user.documents?.filter(d => d.type === 'driver_license').length || 0;
          notifBody += ` | Bằng lái xe: ${dlCount} tài liệu`;
        }
        notifBody += ` | Email: ${user.email}`;

        const notifDocs = admins.map(admin => ({
          userId: admin._id,
          title: user.role === 'seller' ? 'Đăng ký Người bán mới' : 'Đăng ký Shipper mới',
          body: notifBody,
          type: 'user_register',
          referenceId: user._id,
          data: {
            userId: user._id.toString(),
            role: user.role,
            email: user.email,
            fullName: user.fullName,
            phone: user.phone,
            marketId: user.marketId?.toString() || null,
            categoryIds: user.categoryIds || [],
            documentsCount: user.documents?.length || 0,
          },
        }));

        await Notification.insertMany(notifDocs);

        // Emit real-time to admins via Socket.io
        admins.forEach(admin => {
          socketService.sendNotification(admin._id.toString(), {
            title: 'Đăng ký mới',
            body: notifDocs.find(n => n.userId.toString() === admin._id.toString())?.body,
            type: 'user_register',
            referenceId: user._id,
            data: { userId: user._id.toString(), role: user.role, email: user.email },
          });

          socketService.emitToUser(admin._id.toString(), 'admin:new_registration', {
            title: 'Đăng ký mới',
            body: notifDocs.find(n => n.userId.toString() === admin._id.toString())?.body,
            type: 'user_register',
            referenceId: user._id,
            data: { userId: user._id.toString(), role: user.role, email: user.email },
            createdAt: new Date().toISOString(),
          });
        });
      }
    }

    const tokens = generateTokens(user._id);

    return {
      user: user.toSafeObject(),
      ...tokens,
    };
  }

  async login(email, password) {
    const user = await User.findOne({ email }).select('+password');
    
    if (!user) {
      throw new UnauthorizedError('Email hoặc mật khẩu không đúng');
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      throw new UnauthorizedError('Email hoặc mật khẩu không đúng');
    }

    if (user.status === 'banned') {
      throw new UnauthorizedError('Tài khoản đã bị khóa');
    }

    if (user.status === 'inactive') {
      throw new UnauthorizedError('Tài khoản đang chờ duyệt. Vui lòng đợi admin phê duyệt.');
    }

    const tokens = generateTokens(user._id);

    return {
      user: user.toSafeObject(),
      ...tokens,
    };
  }

  async refreshToken(refreshToken) {
    try {
      const decoded = verifyRefreshToken(refreshToken);
      
      if (decoded.type !== 'refresh') {
        throw new BadRequestError('Token không hợp lệ');
      }

      const user = await User.findById(decoded.userId);
      if (!user) {
        throw new UnauthorizedError('Người dùng không tồn tại');
      }

      if (user.status !== 'active') {
        throw new UnauthorizedError('Tài khoản không hoạt động');
      }

      const tokens = generateTokens(user._id);
      
      return {
        user: user.toSafeObject(),
        ...tokens,
      };
    } catch (error) {
      throw new UnauthorizedError('Refresh token không hợp lệ hoặc đã hết hạn');
    }
  }

  async getMe(userId) {
    const user = await User.findById(userId);
    if (!user) {
      throw new NotFoundError('Người dùng không tồn tại');
    }
    return user.toSafeObject();
  }

  async logout(userId) {
    return { message: 'Đăng xuất thành công' };
  }
}

module.exports = new AuthService();
