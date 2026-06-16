require('dotenv').config();

const config = {
  port: process.env.PORT || 3001,
  nodeEnv: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  
  jwt: {
    secret: process.env.JWT_SECRET || 'default-secret-change-in-production',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-change-in-production',
    expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '7d',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },

  pagination: {
    defaultPage: 1,
    defaultLimit: 20,
    maxLimit: 100,
  },

  orderStatus: {
    pending: 'pending',
    finding_shipper: 'finding_shipper',
    shipper_accepted: 'shipper_accepted',
    shopping: 'shopping',
    delivering: 'delivering',
    delivered: 'delivered',
    cancelled: 'cancelled',
  },

  userRoles: {
    buyer: 'buyer',
    seller: 'seller',
    shipper: 'shipper',
    admin: 'admin',
  },

  paymentMethods: {
    cod: 'cod',
    momo: 'momo',
    vnpay: 'vnpay',
  },

  paymentStatus: {
    unpaid: 'unpaid',
    paid: 'paid',
    refunded: 'refunded',
  },

  shippingFee: {
    base: parseInt(process.env.SHIPPING_FEE_BASE) || 15000,
    perKm: 3000,
    freeThreshold: parseInt(process.env.SHIPPING_FEE_FREE_THRESHOLD) || 200000,
  },

  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  },

  vnpay: {
    vnpayUrl: process.env.VNPAY_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    tmnCode: process.env.VNPAY_TMN_CODE || '',
    hashSecret: process.env.VNPAY_HASH_SECRET || '',
    returnUrl: process.env.VNPAY_RETURN_URL || 'http://localhost:3000/payment/vnpay/return',
  },

  momo: {
    endpoint: process.env.MOMO_ENDPOINT || 'https://test-payment.momo.vn/v2/gateway/api/create',
    partnerCode: process.env.MOMO_PARTNER_CODE || '',
    returnUrl: process.env.MOMO_RETURN_URL || 'http://localhost:3000/payment/momo/return',
  },

  appUrl: process.env.APP_URL || 'http://localhost:3000',
};

module.exports = config;
