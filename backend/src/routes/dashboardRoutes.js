const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { authenticate, adminOnly } = require('../middlewares/auth');

router.use(authenticate);
router.use(adminOnly);

router.get('/stats', dashboardController.getStats);

router.get('/revenue', dashboardController.getRevenueByDay);

router.get('/orders', dashboardController.getOrdersByStatus);

router.get('/top-products', dashboardController.getTopProducts);

router.get('/top-sellers', dashboardController.getTopSellers);

module.exports = router;
