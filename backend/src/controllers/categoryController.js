const { Category } = require('../models');
const { successResponse, errorResponse } = require('../utils/response');
const { buildPagination } = require('../utils/helpers');

exports.getCategories = async (req, res, next) => {
  try {
    const { page = 1, limit = 50, search, isActive, parentId, sortBy = 'sortOrder', sortOrder = 'asc' } = req.query;
    
    const query = {};
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
      ];
    }
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    if (parentId !== undefined && parentId !== '') {
      query.parentId = parentId === 'null' ? null : parentId;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'desc' ? -1 : 1 };

    const [categories, total] = await Promise.all([
      Category.find(query).sort(sort).skip(skip).limit(parseInt(limit)),
      Category.countDocuments(query),
    ]);

    return successResponse(res, {
      categories,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};

exports.getCategoryTree = async (req, res, next) => {
  try {
    const categories = await Category.find({ isActive: true }).sort({ sortOrder: 1, name: 1 });
    
    const buildTree = (parentId = null) => {
      return categories
        .filter(cat => {
          if (parentId === null) return !cat.parentId;
          return cat.parentId?.toString() === parentId?.toString();
        })
        .map(cat => ({
          ...cat.toObject(),
          children: buildTree(cat._id),
        }));
    };

    const tree = buildTree();
    return successResponse(res, { categories: tree });
  } catch (error) {
    next(error);
  }
};

exports.createCategory = async (req, res, next) => {
  try {
    const category = await Category.create(req.body);
    return successResponse(res, { category }, 'Tạo danh mục thành công', 201);
  } catch (error) {
    next(error);
  }
};

exports.getCategoryById = async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id);
    if (!category) {
      return errorResponse(res, 'Không tìm thấy danh mục', 404);
    }
    return successResponse(res, { category });
  } catch (error) {
    next(error);
  }
};

exports.updateCategory = async (req, res, next) => {
  try {
    const category = await Category.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!category) {
      return errorResponse(res, 'Không tìm thấy danh mục', 404);
    }
    return successResponse(res, { category }, 'Cập nhật danh mục thành công');
  } catch (error) {
    next(error);
  }
};

exports.toggleCategoryActive = async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id);
    if (!category) {
      return errorResponse(res, 'Không tìm thấy danh mục', 404);
    }
    category.isActive = !category.isActive;
    await category.save();
    return successResponse(res, { category }, `Danh mục đã ${category.isActive ? 'kích hoạt' : 'vô hiệu hóa'}`);
  } catch (error) {
    next(error);
  }
};

exports.deleteCategory = async (req, res, next) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) {
      return errorResponse(res, 'Không tìm thấy danh mục', 404);
    }
    return successResponse(res, null, 'Xóa danh mục thành công');
  } catch (error) {
    next(error);
  }
};
