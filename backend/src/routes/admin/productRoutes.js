const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../../middlewares/auth');
const adminProductController = require('../../controllers/adminProductController');

router.use(authenticate, adminOnly);

router.get('/', adminProductController.getProducts);
router.get('/shops', adminProductController.getAllShops);
router.post('/', adminProductController.createProduct);
router.get('/:id', adminProductController.getProductById);
router.put('/:id', adminProductController.updateProduct);
router.patch('/:id/toggle-availability', adminProductController.toggleAvailability);
router.delete('/:id', adminProductController.deleteProduct);

module.exports = router;
