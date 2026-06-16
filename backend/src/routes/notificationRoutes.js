const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middlewares/auth');
const { validateQuery } = require('../middlewares/validate');

router.use(authenticate);

router.get('/', validateQuery(), notificationController.getAll);

router.patch('/:id/read', notificationController.markAsRead);

router.put('/read-all', notificationController.markAllAsRead);

router.delete('/:id', notificationController.delete);

router.delete('/', notificationController.deleteAll);

module.exports = router;
