const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const {
  authenticate,
  adminOnly,
  authorize,
} = require('../middlewares/auth');
const { validate, validateQuery } = require('../middlewares/validate');
const { orderLimiter } = require('../middlewares/rateLimit');
const {
  createOrderSchema,
  updateOrderSchema,
  updateOrderStatusSchema,
  cancelOrderSchema,
  orderQuerySchema,
} = require('../utils/validators');

router.post(
  '/',
  authenticate,
  authorize('buyer'),
  orderLimiter,
  validate(createOrderSchema),
  orderController.create
);

router.get('/', authenticate, validateQuery(orderQuerySchema), orderController.getAll);

router.get('/buyer', authenticate, authorize('buyer'), validateQuery(orderQuerySchema), orderController.getByBuyer);

router.get('/seller', authenticate, authorize('seller', 'admin'), validateQuery(orderQuerySchema), orderController.getBySeller);

router.get('/shipper/available', authenticate, authorize('shipper', 'admin'), orderController.getAvailableForShipper);

router.get('/shipper/active', authenticate, authorize('shipper'), orderController.getActiveForShipper);

router.get('/shipper/history', authenticate, authorize('shipper'), orderController.getHistoryForShipper);

router.get('/:id', authenticate, orderController.getById);

router.put(
  '/:id',
  authenticate,
  authorize('buyer', 'admin'),
  validate(updateOrderSchema),
  orderController.update
);

router.patch(
  '/:id/status',
  authenticate,
  authorize('shipper', 'seller', 'buyer', 'admin'),
  validate(updateOrderStatusSchema),
  orderController.updateStatus
);

router.patch(
  '/:id/accept',
  authenticate,
  authorize('shipper'),
  orderController.acceptOrder
);

/**
 * PATCH /api/v1/orders/:id/cancel
 * Hủy đơn hàng — buyer hoặc admin có thể hủy
 * Body: { reason?: string }
 */
router.patch(
  '/:id/cancel',
  authenticate,
  authorize('buyer', 'shipper', 'admin'),
  validate(cancelOrderSchema),
  orderController.cancel
);

/**
 * PATCH /api/v1/orders/:id/shipper-location
 * Shipper cập nhật vị trí GPS của mình trong quá trình giao hàng.
 * Body: { lat, lng }
 */
router.patch(
  '/:id/shipper-location',
  authenticate,
  authorize('shipper', 'admin'),
  orderController.updateShipperLocation
);

/**
 * GET /api/v1/orders/:id/track
 * Buyer/Shipper lấy thông tin đơn hàng kèm vị trí shipper (để theo dõi realtime trên bản đồ).
 */
router.get(
  '/:id/track',
  authenticate,
  authorize('buyer', 'shipper', 'admin'),
  orderController.getOrderTrack
);

module.exports = router;
