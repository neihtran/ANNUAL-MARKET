const express = require('express');
const router = express.Router();
const { Category } = require('../models');
const { successResponse } = require('../utils/response');

/**
 * GET /api/v1/categories
 * Lấy danh sách danh mục (public)
 */
router.get('/', async (req, res, next) => {
  try {
    const { isActive = 'true', search } = req.query;
    const query = {};
    if (isActive !== undefined) query.isActive = isActive === 'true';
    if (search) query.name = { $regex: search, $options: 'i' };

    const categories = await Category.find(query)
      .select('-__v')
      .sort({ sortOrder: 1, name: 1 });

    return successResponse(res, { categories });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/categories/tree
 * Lấy cây danh mục (parent → children)
 */
router.get('/tree', async (req, res, next) => {
  try {
    const categories = await Category.find({ isActive: true })
      .select('-__v')
      .sort({ sortOrder: 1, name: 1 });

    const buildTree = (parentId = null) =>
      categories
        .filter(c => {
          if (parentId === null) return !c.parentId;
          return c.parentId?.toString() === parentId?.toString();
        })
        .map(c => ({
          ...c.toObject(),
          children: buildTree(c._id.toString()),
        }));

    return successResponse(res, { categories: buildTree() });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/categories/:id
 * Lấy chi tiết 1 danh mục
 */
router.get('/:id', async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id).select('-__v');
    if (!category) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy danh mục' });
    }
    return successResponse(res, { category });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
