const { Order } = require('../models');
const { successResponse, errorResponse } = require('../utils/response');
const config = require('../config/constants');

exports.createVNPayPayment = async (req, res, next) => {
  try {
    const { orderId } = req.body;

    if (!orderId) {
      return errorResponse(res, 'Order ID là bắt buộc', 400);
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return errorResponse(res, 'Không tìm thấy đơn hàng', 404);
    }

    if (order.paymentMethod !== 'vnpay') {
      return errorResponse(res, 'Đơn hàng không phải thanh toán qua VNPay', 400);
    }

    if (order.paymentStatus === 'paid') {
      return errorResponse(res, 'Đơn hàng đã được thanh toán', 400);
    }

    // Generate VNPay payment URL
    const vnp_TmnCode = config.vnpay.tmnCode;
    const vnp_HashSecret = config.vnpay.hashSecret;
    const vnp_Url = config.vnpay.vnpayUrl;
    const vnp_ReturnUrl = `${config.appUrl}/api/v1/payment/vnpay/return`;

    const vnp_TxnRef = `${order._id}-${Date.now()}`;
    const vnp_Amount = Math.round(order.total * 100); // Amount in VND * 100
    const vnp_OrderInfo = `Thanh toan don hang ${order.orderNumber}`;
    const vnp_Locale = 'vn';

    // Build payment URL (simplified - real integration needs crypto)
    const paymentUrl = new URL(vnp_Url);
    paymentUrl.searchParams.set('vnp_TmnCode', vnp_TmnCode);
    paymentUrl.searchParams.set('vnp_Amount', vnp_Amount.toString());
    paymentUrl.searchParams.set('vnp_TxnRef', vnp_TxnRef);
    paymentUrl.searchParams.set('vnp_OrderInfo', vnp_OrderInfo);
    paymentUrl.searchParams.set('vnp_ReturnUrl', vnp_ReturnUrl);
    paymentUrl.searchParams.set('vnp_Locale', vnp_Locale);
    paymentUrl.searchParams.set('vnp_CreateDate', new Date().toISOString().replace(/[-:]/g, '').split('.')[0]);

    return successResponse(res, {
      paymentUrl: paymentUrl.toString(),
      txnRef: vnp_TxnRef,
      orderId: order._id,
    }, 'Tạo link thanh toán VNPay thành công');
  } catch (error) {
    next(error);
  }
};

exports.vnpayReturn = async (req, res, next) => {
  try {
    const { vnp_ResponseCode, vnp_TxnRef } = req.query;

    if (vnp_ResponseCode === '00') {
      // Payment successful - extract orderId from txnRef
      const orderId = vnp_TxnRef.split('-')[0];
      await Order.findByIdAndUpdate(orderId, { paymentStatus: 'paid' });
      return successResponse(res, { success: true, message: 'Thanh toán thành công' });
    } else {
      return errorResponse(res, `Thanh toán thất bại: Mã lỗi ${vnp_ResponseCode}`, 400);
    }
  } catch (error) {
    next(error);
  }
};

exports.createMoMoPayment = async (req, res, next) => {
  try {
    const { orderId } = req.body;

    if (!orderId) {
      return errorResponse(res, 'Order ID là bắt buộc', 400);
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return errorResponse(res, 'Không tìm thấy đơn hàng', 404);
    }

    if (order.paymentMethod !== 'momo') {
      return errorResponse(res, 'Đơn hàng không phải thanh toán qua MoMo', 400);
    }

    if (order.paymentStatus === 'paid') {
      return errorResponse(res, 'Đơn hàng đã được thanh toán', 400);
    }

    // Generate MoMo payment URL (simplified)
    const momoEndpoint = config.momo.endpoint;
    const momoPartnerCode = config.momo.partnerCode;
    const momoReturnUrl = `${config.appUrl}/api/v1/payment/momo/return`;

    const orderId2 = `${order._id}-${Date.now()}`;
    const amount = Math.round(order.total);

    // Build MoMo payment URL (simplified - real integration needs signature)
    const paymentUrl = `${momoEndpoint}?partnerCode=${momoPartnerCode}&orderId=${orderId2}&amount=${amount}&returnUrl=${momoReturnUrl}&orderInfo=Thanh+toan+don+hang+${order.orderNumber}`;

    return successResponse(res, {
      paymentUrl,
      orderId2,
      orderId: order._id,
    }, 'Tạo link thanh toán MoMo thành công');
  } catch (error) {
    next(error);
  }
};

exports.momoNotify = async (req, res, next) => {
  try {
    const { orderId, resultCode } = req.body;

    if (resultCode === 0) {
      await Order.findByIdAndUpdate(orderId, { paymentStatus: 'paid' });
    }

    return successResponse(res, { received: true });
  } catch (error) {
    next(error);
  }
};
