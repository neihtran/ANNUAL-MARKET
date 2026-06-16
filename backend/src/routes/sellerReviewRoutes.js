const express = require('express');
const router = express.Router();
const sellerReviewController = require('../controllers/sellerReviewController');
const { authenticate, authorize } = require('../middlewares/auth');
const { validate } = require('../middlewares/validate');
const {
  createSellerReviewSchema,
  sellerReviewQuerySchema,
  sellerReviewReplySchema,
} = require('../utils/validators');

router.post(
  '/',
  authenticate,
  authorize('buyer'),
  validate(createSellerReviewSchema),
  sellerReviewController.create
);

router.get(
  '/me',
  authenticate,
  authorize('seller', 'admin'),
  validate(sellerReviewQuerySchema),
  sellerReviewController.getBySeller
);

router.post(
  '/:id/reply',
  authenticate,
  authorize('seller', 'admin'),
  validate(sellerReviewReplySchema),
  sellerReviewController.reply
);

router.delete(
  '/:id',
  authenticate,
  authorize('admin'),
  sellerReviewController.delete
);

module.exports = router;
