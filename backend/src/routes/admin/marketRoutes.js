const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/validate');
const { marketController } = require('../../controllers');
const { marketValidation } = require('../../utils/validators');

router.use(authenticate, adminOnly);

router.get('/', marketController.getMarkets);
router.post('/', validate(marketValidation.createSchema), marketController.createMarket);
router.get('/:id', marketController.getMarketById);
router.put('/:id', validate(marketValidation.updateSchema), marketController.updateMarket);
router.patch('/:id/toggle-active', marketController.toggleMarketActive);
router.delete('/:id', marketController.deleteMarket);

module.exports = router;
