const rateLimit = require('express-rate-limit');

const isTrustedLocalRequest = (req) => {
  const forwardedFor = req.headers['x-forwarded-for'];
  const ip = (Array.isArray(forwardedFor) ? forwardedFor[0] : forwardedFor) || req.ip || req.socket?.remoteAddress || '';
  const origin = req.headers.origin || '';
  const referer = req.headers.referer || '';

  const isLocalIp =
    ip === '::1' ||
    ip === '127.0.0.1' ||
    ip === '::ffff:127.0.0.1' ||
    ip === 'localhost';

  const isLocalAdminOrigin =
    origin.startsWith('http://localhost:3002') ||
    referer.startsWith('http://localhost:3002') ||
    origin.startsWith('http://127.0.0.1:3002') ||
    referer.startsWith('http://127.0.0.1:3002');

  return isLocalIp && isLocalAdminOrigin;
};

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  skip: isTrustedLocalRequest,
  message: {
    success: false,
    message: 'Quá nhiều yêu cầu, vui lòng thử lại sau',
    error: { code: 'RATE_LIMIT_EXCEEDED' },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  skipSuccessfulRequests: true,
  skipFailedRequests: false,
  message: {
    success: false,
    message: 'Quá nhiều lần đăng nhập thất bại, vui lòng thử lại sau 15 phút',
    error: { code: 'AUTH_RATE_LIMIT' },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const orderLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  message: {
    success: false,
    message: 'Quá nhiều yêu cầu tạo đơn hàng',
    error: { code: 'ORDER_RATE_LIMIT' },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  apiLimiter,
  authLimiter,
  orderLimiter,
};
