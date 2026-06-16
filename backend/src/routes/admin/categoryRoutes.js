const express = require('express');
const router = express.Router();
const { authenticate, adminOnly } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/validate');
const { categoryController } = require('../../controllers');
const { categoryValidation } = require('../../utils/validators');

router.use(authenticate, adminOnly);

router.get('/', categoryController.getCategories);
router.get('/tree', categoryController.getCategoryTree);
router.post('/', validate(categoryValidation.createSchema), categoryController.createCategory);
router.get('/:id', categoryController.getCategoryById);
router.put('/:id', validate(categoryValidation.updateSchema), categoryController.updateCategory);
router.patch('/:id/toggle-active', categoryController.toggleCategoryActive);
router.delete('/:id', categoryController.deleteCategory);

module.exports = router;
