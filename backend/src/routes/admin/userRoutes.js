const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/validate');
const { userValidation } = require('../../utils/validators');
const userController = require('../../controllers/userController');

router.use(authenticate, adminOnly);

router.post('/', validate(userValidation.createUserSchema), userController.createUser);
router.get('/', userController.getUsers);
router.get('/buyers', userController.getBuyers);
router.get('/:id', userController.getUserById);
router.patch('/:id/approve', userController.approveUser);
router.patch('/:id/reject', validate(userValidation.rejectUserSchema), userController.rejectUser);
router.patch('/:id/ban', userController.banUser);
router.patch('/:id/unban', userController.unbanUser);
router.patch('/:id/status', userController.updateStatus);
router.delete('/:id', userController.deleteUser);

module.exports = router;
