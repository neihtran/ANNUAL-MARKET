const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { authenticate, optionalAuth, sellerOrAdmin } = require('../middlewares/auth');
const { validate, validateQuery } = require('../middlewares/validate');
const {
  createProductSchema,
  updateProductSchema,
  productQuerySchema,
  nearbyQuerySchema,
} = require('../utils/validators');

// IMPORTANT: specific routes MUST come BEFORE /:id wildcard

router.get('/', optionalAuth, validateQuery(productQuerySchema), productController.getAll);

router.get('/nearby', optionalAuth, validateQuery(nearbyQuerySchema), productController.getNearby);

router.get('/seller', authenticate, validateQuery(productQuerySchema), productController.getBySeller);

// Generic /:id MUST be last to avoid intercepting /nearby and /seller
router.get('/:id', optionalAuth, productController.getById);

router.post(
  '/',
  authenticate,
  sellerOrAdmin,
  validate(createProductSchema),
  productController.create
);

router.put(
  '/:id',
  authenticate,
  sellerOrAdmin,
  validate(updateProductSchema),
  productController.update
);

router.delete(
  '/:id',
  authenticate,
  sellerOrAdmin,
  productController.delete
);

router.patch('/:id/toggle-available', authenticate, sellerOrAdmin, async (req, res, next) => {
  try {
    const Shop = require('../models/Shop');
    const Product = require('../models/Product');
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });
    }
    const product = await Product.findOne({ _id: req.params.id, shopId: shop._id });
    if (!product) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy sản phẩm' });
    }
    product.isAvailable = !product.isAvailable;
    await product.save();
    return res.json({ success: true, message: product.isAvailable ? 'Sản phẩm đã được bật' : 'Sản phẩm đã được tắt', data: { product } });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
