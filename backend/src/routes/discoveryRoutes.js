const express = require('express');
const router = express.Router();
const discoveryController = require('../controllers/discoveryController');
const { optionalAuth } = require('../middlewares/auth');

/**
 * GET /api/v1/products/nearby
 * Tìm sản phẩm gần vị trí
 * Query: lat, lng, radius(km), categoryId, marketId, search, limit, page
 */
router.get('/products/nearby', optionalAuth, discoveryController.getNearbyProducts);

/**
 * GET /api/v1/products/featured
 * Sản phẩm nổi bật: top bán chạy + top đánh giá cao
 * Query: limit, categoryId
 */
router.get('/products/featured', optionalAuth, discoveryController.getFeaturedProducts);

/**
 * GET /api/v1/markets/nearby
 * Tìm chợ gần vị trí
 * Query: lat, lng, radius(km), district, isActive, limit
 */
router.get('/markets/nearby', optionalAuth, discoveryController.getNearbyMarkets);

/**
 * GET /api/v1/search
 * Tìm kiếm toàn diện: sản phẩm + cửa hàng + chợ
 * Query: q, lat, lng, type(products|shops|markets), limit
 */
router.get('/search', optionalAuth, discoveryController.search);

module.exports = router;
