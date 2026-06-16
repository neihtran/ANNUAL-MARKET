const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth');
const paymentController = require('../controllers/paymentController');

router.post('/vnpay/create', authenticate, paymentController.createVNPayPayment);
router.get('/vnpay/return', paymentController.vnpayReturn);
router.post('/momo/create', authenticate, paymentController.createMoMoPayment);
router.post('/momo/notify', paymentController.momoNotify);

module.exports = router;
