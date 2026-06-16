const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../../middlewares/auth');
const { Order } = require('../../models');
const { successResponse, sendPaginated } = require('../../utils/response');
const shipperController = require('../../controllers/shipperController');

// ── SHIPPER: Profile & Location ──────────────────────────────────

/**
 * GET /api/v1/shipper/profile
 * Lấy thông tin profile shipper
 */
router.get('/profile', authenticate, authorize('shipper'), shipperController.getProfile);

/**
 * PATCH /api/v1/shipper/location
 * Cập nhật vị trí GPS (được gọi định kỳ từ app mobile)
 * Body: { lat, lng }
 */
router.patch('/location', authenticate, authorize('shipper'), shipperController.updateLocation);

/**
 * PATCH /api/v1/shipper/online-status
 * Bật/tắt trạng thái online
 * Body: { isOnline: boolean }
 */
router.patch('/online-status', authenticate, authorize('shipper'), shipperController.updateOnlineStatus);

// ── SHIPPER: Available Orders ───────────────────────────────────────

// Haversine distance calculation (km) — shared helper
function calcDistance(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * GET /api/v1/shipper/orders/available
 * Lấy TẤT CẢ đơn đang tìm shipper từ MỌI chợ.
 * Nếu truyền lat/lng → sắp xếp theo khoảng cách GPS gần nhất.
 * Nếu không → sắp xếp theo thời gian tạo (mới nhất trước).
 */
router.get('/orders/available', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    const shipper = await (require('../models')).User.findById(req.userId);
    if (!shipper || !shipper.isApproved || shipper.status === 'banned') {
      return res.status(403).json({
        success: false,
        message: shipper?.status === 'banned'
          ? 'Tài khoản đã bị khóa'
          : 'Tài khoản chưa được admin phê duyệt',
      });
    }

    const { page = 1, limit = 20, lat, lng } = req.query;
    const query = { status: 'finding_shipper' };

    let orders = await Order.find(query)
      .populate('marketId', 'name address location district')
      .populate('buyerId', 'fullName phone')
      .select('-__v')
      .lean();

    // Sort by GPS distance if shipper provides location, else by newest first
    if (lat && lng) {
      const shipperLat = parseFloat(lat);
      const shipperLng = parseFloat(lng);
      orders = orders.map(order => {
        const ml = order.marketId?.location;
        const dist = (ml?.lat != null && ml?.lng != null)
          ? calcDistance(shipperLat, shipperLng, ml.lat, ml.lng)
          : 9999;
        return { ...order, distance: Math.round(dist * 10) / 10 };
      });
      orders.sort((a, b) => (a.distance || 9999) - (b.distance || 9999));
    } else {
      orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    const total = orders.length;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const paginatedOrders = orders.slice(skip, skip + parseInt(limit));

    return sendPaginated(res, paginatedOrders, {
      page: parseInt(page), limit: parseInt(limit), total,
      totalPages: Math.ceil(total / parseInt(limit)),
    }, 'Lấy danh sách đơn hàng thành công');
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/shipper/orders/nearby
 * Lấy đơn gần vị trí GPS của shipper, sắp xếp theo khoảng cách
 * Query: lat, lng, radius(km), page, limit
 */
router.get('/orders/nearby', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    const shipper = await (require('../models')).User.findById(req.userId);
    if (!shipper || !shipper.isApproved || shipper.status === 'banned') {
      return res.status(403).json({
        success: false,
        message: shipper?.status === 'banned'
          ? 'Tài khoản đã bị khóa'
          : 'Tài khoản chưa được admin phê duyệt',
      });
    }
    await shipperController.getNearbyOrders(req, res, next);
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/v1/shipper/orders/:id/accept
 * Nhận đơn hàng (atomic - race condition safe)
 */
router.patch('/orders/:id/accept', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    // Block unapproved or banned shippers
    const shipper = await (require('../models')).User.findById(req.userId);
    if (!shipper || !shipper.isApproved || shipper.status === 'banned') {
      return res.status(403).json({
        success: false,
        message: shipper?.status === 'banned'
          ? 'Tài khoản đã bị khóa'
          : 'Tài khoản chưa được admin phê duyệt',
      });
    }
    const order = await Order.findOneAndUpdate(
      { _id: req.params.id, status: 'finding_shipper', shipperId: null },
      { status: 'shipper_accepted', shipperId: req.userId },
      { new: true, runValidators: true }
    )
      .populate('marketId', 'name address location')
      .populate('buyerId', 'fullName phone')
      .select('-__v');

    if (!order) {
      return res.status(409).json({
        success: false,
        message: 'Đơn hàng đã bị nhận bởi shipper khác hoặc không còn trong trạng thái chờ',
      });
    }

    return successResponse(res, { order }, 'Nhận đơn hàng thành công');
  } catch (error) {
    next(error);
  }
});

// ── SHIPPER: Active Order ──────────────────────────────────────────

/**
 * GET /api/v1/shipper/orders/active
 * Lấy đơn đang xử lý của shipper
 */
router.get('/orders/active', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    const orders = await Order.find({
      shipperId: req.userId,
      status: { $in: ['shipper_accepted', 'shopping', 'delivering'] },
    })
      .populate('marketId', 'name address location')
      .populate('buyerId', 'fullName phone')
      .populate('items.productId', 'name images')
      .populate('items.sellerId', 'fullName phone avatar')
      .select('-__v')
      .sort({ createdAt: -1 });

    return successResponse(res, { orders });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/shipper/orders/:id
 * Lấy chi tiết 1 đơn hàng của shipper
 */
router.get('/orders/:id', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, shipperId: req.userId })
      .populate('marketId', 'name address location district')
      .populate('buyerId', 'fullName phone avatar')
      .populate('items.productId', 'name images price unit')
      .populate('items.sellerId', 'fullName phone avatar')
      .populate('items.shopId', 'name')
      .select('-__v')
      .lean();

    if (!order) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng' });
    }

    return successResponse(res, { order });
  } catch (error) {
    next(error);
  }
});

// ── SHIPPER: History ─────────────────────────────────────────────

/**
 * GET /api/v1/shipper/orders/history
 * Lịch sử đơn đã giao / đã hủy
 */
router.get('/orders/history', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const query = {
      shipperId: req.userId,
      status: { $in: ['delivered', 'cancelled'] },
    };

    const [orders, total] = await Promise.all([
      Order.find(query)
        .populate('marketId', 'name address')
        .populate('buyerId', 'fullName phone')
        .select('-__v')
        .sort({ deliveredAt: -1, updatedAt: -1 })
        .skip((parseInt(page) - 1) * parseInt(limit))
        .limit(parseInt(limit)),
      Order.countDocuments(query),
    ]);

    return sendPaginated(res, { orders }, {
      page: parseInt(page), limit: parseInt(limit), total,
      totalPages: Math.ceil(total / parseInt(limit)),
    }, 'Lấy lịch sử đơn hàng thành công');
  } catch (error) {
    next(error);
  }
});

// ── SHIPPER: Stats ────────────────────────────────────────────────

/**
 * GET /api/v1/shipper/orders/stats
 * Thống kê thu nhập của shipper
 */
router.get('/orders/stats', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const weekStart = new Date(today);
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());

    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);

    const [todayOrders, weekOrders, monthOrders, allDelivered] = await Promise.all([
      Order.find({ shipperId: req.userId, status: 'delivered', deliveredAt: { $gte: today } }),
      Order.find({ shipperId: req.userId, status: 'delivered', deliveredAt: { $gte: weekStart } }),
      Order.find({ shipperId: req.userId, status: 'delivered', deliveredAt: { $gte: monthStart } }),
      Order.find({ shipperId: req.userId, status: 'delivered' }),
    ]);

    const calcRevenue = (orders) =>
      orders.reduce((sum, o) => sum + (o.shippingFee || 0), 0);

    return successResponse(res, {
      today: { count: todayOrders.length, revenue: calcRevenue(todayOrders) },
      thisWeek: { count: weekOrders.length, revenue: calcRevenue(weekOrders) },
      thisMonth: { count: monthOrders.length, revenue: calcRevenue(monthOrders) },
      allTime: { count: allDelivered.length, revenue: calcRevenue(allDelivered) },
    });
  } catch (error) {
    next(error);
  }
});

// ── SHIPPER: Update Order Status ─────────────────────────────────

/**
 * PATCH /api/v1/shipper/orders/:id/status
 * Cập nhật trạng thái: shopping → delivering → delivered
 * Body: { status, confirmImageUrl? }
 */
router.patch('/orders/:id/status', authenticate, authorize('shipper'), async (req, res, next) => {
  try {
    const { status, confirmImageUrl } = req.body;

    const VALID_TRANSITIONS = ['shipper_accepted', 'shopping', 'delivering', 'delivered'];
    if (!VALID_TRANSITIONS.includes(status)) {
      return res.status(400).json({ success: false, message: 'Trạng thái không hợp lệ' });
    }

    const order = await Order.findOne({ _id: req.params.id, shipperId: req.userId });
    if (!order) return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng' });

    // Xác nhận ảnh khi giao xong
    if (status === 'delivered' && !confirmImageUrl) {
      return res.status(400).json({ success: false, message: 'Ảnh xác nhận giao hàng là bắt buộc' });
    }

    order.status = status;
    if (status === 'delivering') order.deliveredAt = null;
    if (status === 'delivered') {
      order.deliveredAt = new Date();
      if (confirmImageUrl) order.confirmImageUrl = confirmImageUrl;
    }
    await order.save();

    const updated = await Order.findById(order._id)
      .populate('marketId', 'name address location')
      .populate('buyerId', 'fullName phone')
      .select('-__v');

    return successResponse(res, { order: updated }, 'Cập nhật trạng thái thành công');
  } catch (error) {
    next(error);
  }
});

module.exports = router;
