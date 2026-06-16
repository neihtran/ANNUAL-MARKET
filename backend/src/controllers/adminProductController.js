const { Product, Shop, Market, Category } = require('../models');
const { successResponse, errorResponse } = require('../utils/response');
const { buildPagination } = require('../utils/helpers');

exports.getProducts = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, categoryId, marketId, isAvailable, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;

    const query = {};
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }
    if (categoryId) {
      query.categoryId = categoryId;
    }
    if (marketId) {
      query.marketId = marketId;
    }
    if (isAvailable !== undefined) {
      query.isAvailable = isAvailable === 'true';
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [products, total] = await Promise.all([
      Product.find(query)
        .populate('shopId', 'name sellerId')
        .populate('sellerId', 'fullName email')
        .populate('marketId', 'name address')
        .populate('categoryId', 'name icon')
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit)),
      Product.countDocuments(query),
    ]);

    return successResponse(res, {
      products,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};

exports.getProductById = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate('shopId', 'name sellerId')
      .populate('sellerId', 'fullName email phone')
      .populate('marketId', 'name address location')
      .populate('categoryId', 'name icon');

    if (!product) {
      return errorResponse(res, 'Không tìm thấy sản phẩm', 404);
    }
    return successResponse(res, { product });
  } catch (error) {
    next(error);
  }
};

exports.createProduct = async (req, res, next) => {
  try {
    const { shopId, name, description, images, price, unit, stock, minOrder, categoryId, marketId, isAvailable } = req.body;

    if (!shopId) {
      return errorResponse(res, 'Shop ID là bắt buộc', 400);
    }
    if (!name) {
      return errorResponse(res, 'Tên sản phẩm là bắt buộc', 400);
    }
    if (price === undefined || price < 0) {
      return errorResponse(res, 'Giá không hợp lệ', 400);
    }

    const shop = await Shop.findById(shopId);
    if (!shop) {
      return errorResponse(res, 'Không tìm thấy cửa hàng', 404);
    }

    const product = await Product.create({
      shopId,
      sellerId: shop.sellerId,
      marketId: marketId || shop.marketId,
      categoryId: categoryId || null,
      name,
      description: description || '',
      images: images || [],
      price,
      unit: unit || 'kg',
      stock: stock || 0,
      minOrder: minOrder || 1,
      isAvailable: isAvailable !== undefined ? isAvailable : true,
    });

    const populated = await Product.findById(product._id)
      .populate('shopId', 'name sellerId')
      .populate('sellerId', 'fullName email')
      .populate('marketId', 'name address')
      .populate('categoryId', 'name icon');

    return successResponse(res, { product: populated }, 'Tạo sản phẩm thành công', 201);
  } catch (error) {
    next(error);
  }
};

exports.updateProduct = async (req, res, next) => {
  try {
    const { name, description, images, price, unit, stock, minOrder, categoryId, marketId, isAvailable } = req.body;

    if (name !== undefined && !name.trim()) {
      return errorResponse(res, 'Tên sản phẩm không được để trống', 400);
    }
    if (price !== undefined && price < 0) {
      return errorResponse(res, 'Giá không hợp lệ', 400);
    }

    const updateData = {};
    if (name !== undefined) updateData.name = name.trim();
    if (description !== undefined) updateData.description = description.trim();
    if (images !== undefined) updateData.images = images;
    if (price !== undefined) updateData.price = price;
    if (unit !== undefined) updateData.unit = unit;
    if (stock !== undefined) updateData.stock = stock;
    if (minOrder !== undefined) updateData.minOrder = minOrder;
    if (categoryId !== undefined) updateData.categoryId = categoryId;
    if (marketId !== undefined) updateData.marketId = marketId;
    if (isAvailable !== undefined) updateData.isAvailable = isAvailable;

    const product = await Product.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    )
      .populate('shopId', 'name sellerId')
      .populate('sellerId', 'fullName email')
      .populate('marketId', 'name address')
      .populate('categoryId', 'name icon');

    if (!product) {
      return errorResponse(res, 'Không tìm thấy sản phẩm', 404);
    }

    return successResponse(res, { product }, 'Cập nhật sản phẩm thành công');
  } catch (error) {
    next(error);
  }
};

exports.toggleAvailability = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) {
      return errorResponse(res, 'Không tìm thấy sản phẩm', 404);
    }
    product.isAvailable = !product.isAvailable;
    await product.save();
    return successResponse(res, { product }, `Sản phẩm đã ${product.isAvailable ? 'được bật' : 'bị tắt'}`);
  } catch (error) {
    next(error);
  }
};

exports.deleteProduct = async (req, res, next) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) {
      return errorResponse(res, 'Không tìm thấy sản phẩm', 404);
    }
    return successResponse(res, null, 'Xóa sản phẩm thành công');
  } catch (error) {
    next(error);
  }
};

exports.getAllShops = async (req, res, next) => {
  try {
    const { page = 1, limit = 50, search, marketId } = req.query;
    const query = { isApproved: true };
    if (search) {
      query.name = { $regex: search, $options: 'i' };
    }
    if (marketId) {
      query.marketId = marketId;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [shops, total] = await Promise.all([
      Shop.find(query)
        .populate('sellerId', 'fullName email')
        .populate('marketId', 'name address')
        .populate('categoryId', 'name icon')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Shop.countDocuments(query),
    ]);

    return successResponse(res, {
      shops,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};
