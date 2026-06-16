const express = require('express');
const router = express.Router();
const shipperReviewController = require('../controllers/shipperReviewController');
const { authenticate, authorize } = require('../middlewares/auth');
const { validate } = require('../middlewares/validate');
const {
  createShipperReviewSchema,
  shipperReviewQuerySchema,
} = require('../utils/validators');

router.post(
  '/',
  authenticate,
  authorize('buyer'),
  validate(createShipperReviewSchema),
  shipperReviewController.create
);

router.get(
  '/me',
  authenticate,
  authorize('shipper', 'admin'),
  validate(shipperReviewQuerySchema),
  shipperReviewController.getByShipper
);

router.delete(
  '/:id',
  authenticate,
  authorize('admin'),
  shipperReviewController.delete
);

module.exports = router;
