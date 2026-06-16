const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../../middlewares/auth');
const buyerController = require('../../controllers/buyerController');

// All buyer routes require authentication
router.use(authenticate, authorize('buyer'));

// Addresses
router.get('/addresses', buyerController.getAddresses);
router.post('/addresses', buyerController.createAddress);
router.put('/addresses/:id', buyerController.updateAddress);
router.patch('/addresses/:id/set-default', buyerController.setDefaultAddress);
router.delete('/addresses/:id', buyerController.deleteAddress);

// Favorites
router.get('/favorites', buyerController.getFavorites);
router.post('/favorites', buyerController.addFavorite);
router.delete('/favorites/:productId', buyerController.removeFavorite);
router.get('/favorites/check/:productId', buyerController.checkFavorite);

// Districts (public but useful for buyer)
router.get('/districts', buyerController.getDistricts);

module.exports = router;
