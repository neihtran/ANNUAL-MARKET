const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate, adminOnly } = require('../middlewares/auth');
const { validate, validateQuery } = require('../middlewares/validate');
const {
  updateProfileSchema,
  updateStatusSchema,
} = require('../utils/validators');

router.use(authenticate);

router.get('/', adminOnly, userController.getUsers);

router.get('/sellers', userController.getSellers);

router.get('/shippers', adminOnly, userController.getShippers);

router.get('/:id', userController.getById);

router.put('/:id', validate(updateProfileSchema), userController.update);

router.patch('/:id/status', adminOnly, validate(updateStatusSchema), userController.updateStatus);

router.patch('/:id/change-password', userController.changePassword);

router.delete('/:id', adminOnly, userController.deleteUser);

module.exports = router;
