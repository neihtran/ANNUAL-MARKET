const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { authenticate, authorize } = require('../middlewares/auth');
const { validate, validateQuery } = require('../middlewares/validate');
const {
  createReviewSchema,
  reviewQuerySchema,
} = require('../utils/validators');

router.post(
  '/',
  authenticate,
  authorize('buyer'),
  validate(createReviewSchema),
  reviewController.create
);

router.get(
  '/product/:productId',
  validateQuery(reviewQuerySchema),
  reviewController.getByProduct
);

router.get(
  '/seller',
  authenticate,
  authorize('seller', 'admin'),
  validateQuery(reviewQuerySchema),
  reviewController.getBySeller
);

router.post(
  '/:id/reply',
  authenticate,
  authorize('seller', 'admin'),
  reviewController.reply
);

router.delete(
  '/:id',
  authenticate,
  authorize('admin'),
  reviewController.delete
);

module.exports = router;
