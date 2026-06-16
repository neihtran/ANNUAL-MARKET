const jwt = require('jsonwebtoken');
const config = require('../config/constants');
const { User } = require('../models');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Không có token xác thực',
        error: { code: 'UNAUTHORIZED' },
      });
    }

    const token = authHeader.split(' ')[1];

    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      
      const user = await User.findById(decoded.userId);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Người dùng không tồn tại',
          error: { code: 'USER_NOT_FOUND' },
        });
      }

      if (user.status === 'banned') {
        return res.status(403).json({
          success: false,
          message: 'Tài khoản đã bị khóa',
          error: { code: 'ACCOUNT_BANNED' },
        });
      }

      if (user.status === 'inactive') {
        return res.status(403).json({
          success: false,
          message: 'Tài khoản đang chờ duyệt. Vui lòng đợi admin phê duyệt.',
          error: { code: 'ACCOUNT_INACTIVE' },
        });
      }

      req.user = user;
      req.userId = user._id;
      next();
    } catch (jwtError) {
      if (jwtError.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token đã hết hạn',
          error: { code: 'TOKEN_EXPIRED' },
        });
      }
      
      return res.status(401).json({
        success: false,
        message: 'Token không hợp lệ',
        error: { code: 'INVALID_TOKEN' },
      });
    }
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server khi xác thực',
      error: { code: 'AUTH_ERROR' },
    });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.split(' ')[1];

    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await User.findById(decoded.userId);
      
      if (user && user.status === 'active') {
        req.user = user;
        req.userId = user._id;
      }
    } catch (jwtError) {
      // Ignore JWT errors for optional auth
    }
    
    next();
  } catch (error) {
    next();
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Vui lòng đăng nhập',
        error: { code: 'UNAUTHORIZED' },
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền thực hiện hành động này',
        error: { code: 'FORBIDDEN' },
      });
    }

    next();
  };
};

const adminOnly = authorize('admin');
const sellerOrAdmin = authorize('seller', 'admin');
const shipperOrAdmin = authorize('shipper', 'admin');
const allRoles = authorize('buyer', 'seller', 'shipper', 'admin');

module.exports = {
  authenticate,
  optionalAuth,
  authorize,
  adminOnly,
  sellerOrAdmin,
  shipperOrAdmin,
  allRoles,
};
