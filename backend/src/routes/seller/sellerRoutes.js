const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../../middlewares/auth');
const { validate } = require('../../middlewares/validate');
const { Shop, Product, Market, Category } = require('../../models');
const { successResponse, sendPaginated } = require('../../utils/response');
const Joi = require('joi');

// ── Validators ──────────────────────────────────────────────────
const createShopSchema = Joi.object({
  name: Joi.string().required().max(200),
  description: Joi.string().allow('').max(2000),
  categoryId: Joi.string().allow(null),
  phone: Joi.string().allow(''),
  address: Joi.string().allow(''),
  avatar: Joi.string().allow(''),
  banner: Joi.string().allow(''),
});

const createProductSchema = Joi.object({
  name: Joi.string().required().max(200),
  description: Joi.string().allow('').max(5000),
  price: Joi.number().min(0).required(),
  unit: Joi.string().required().max(50),
  categoryId: Joi.string().required(),
  stock: Joi.number().integer().min(0).default(0),
  minOrder: Joi.number().integer().min(1).default(1),
  images: Joi.array().items(Joi.string()).default([]),
  isAvailable: Joi.boolean().default(true),
});

// ── SELLER: Shop Management ──────────────────────────────────────────

/**
 * GET /api/v1/seller/shop
 * Lấy shop của seller hiện tại
 */
router.get('/shop', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId })
      .populate('marketId', 'name address location')
      .populate('categoryId', 'name icon')
      .lean();
    return successResponse(res, { shop });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/seller/shop
 * Tạo shop mới (chỉ seller đã được duyệt bởi admin)
 * Body: { name, description, phone, address, avatar, banner, categoryId }
 */
router.post('/shop', authenticate, authorize('seller'), validate(createShopSchema), async (req, res, next) => {
  try {
    // Block unapproved sellers
    if (req.user.role === 'seller' && !req.user.isApproved) {
      return res.status(403).json({ success: false, message: 'Tài khoản chưa được admin duyệt' });
    }
    const existing = await Shop.findOne({ sellerId: req.userId });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Bạn đã có cửa hàng' });
    }

    // Use the marketId and categoryId from the seller's registration data
    const sellerMarketId = req.user.marketId;
    if (!sellerMarketId) {
      return res.status(400).json({ success: false, message: 'Tài khoản seller không có marketId — liên hệ admin' });
    }

    // Validate marketId exists
    const market = await Market.findById(sellerMarketId);
    if (!market) {
      return res.status(400).json({ success: false, message: 'Chợ không tồn tại' });
    }

    const sellerCategoryId = req.user.categoryIds?.[0] || req.body.categoryId;
    if (!sellerCategoryId) {
      return res.status(400).json({ success: false, message: 'Seller chưa có danh mục bán hàng hợp lệ' });
    }

    const category = await Category.findById(sellerCategoryId);
    if (!category) {
      return res.status(400).json({ success: false, message: 'Danh mục không tồn tại' });
    }

    const shop = await Shop.create({
      ...req.body,
      sellerId: req.userId,
      marketId: sellerMarketId,
      categoryId: sellerCategoryId,
      isApproved: true,
    });
    const populated = await Shop.findById(shop._id)
      .populate('marketId', 'name address location')
      .populate('categoryId', 'name icon');
    return successResponse(res, { shop: populated }, 'Tạo cửa hàng thành công', 201);
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/v1/seller/shop
 * Cập nhật thông tin shop
 */
router.put('/shop', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOneAndUpdate(
      { sellerId: req.userId },
      req.body,
      { new: true, runValidators: true }
    ).populate('marketId', 'name address location').populate('categoryId', 'name icon');
    if (!shop) return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });
    return successResponse(res, { shop }, 'Cập nhật cửa hàng thành công');
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/v1/seller/shop/toggle-open
 * Bật/tắt trạng thái mở cửa
 */
router.patch('/shop/toggle-open', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });
    shop.isOpen = !shop.isOpen;
    await shop.save();
    return successResponse(res, { shop }, shop.isOpen ? 'Cửa hàng đã mở cửa' : 'Cửa hàng đã đóng cửa');
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/v1/seller/shop/toggle-selling
 * Bật/tắt trạng thái bán hàng (tạm ngưng bán khi bận hoặc không muốn nhận đơn)
 */
router.patch('/shop/toggle-selling', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId }).lean();
    if (!shop) return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });
    const newSellingStatus = !shop.isSelling;
    await Shop.findByIdAndUpdate(shop._id, { isSelling: newSellingStatus });
    return successResponse(res, { 
      shop: { ...shop, isSelling: newSellingStatus },
      message: newSellingStatus ? 'Đã bật bán hàng - Sạp đang mở' : 'Đã tắt bán hàng - Sạp tạm đóng' 
    }, newSellingStatus ? 'Cửa hàng đã bật bán hàng' : 'Cửa hàng đã tạm ngưng bán');
  } catch (error) {
    next(error);
  }
});

// ── SELLER: Products ────────────────────────────────────────────────

/**
 * GET /api/v1/seller/products
 * Lấy sản phẩm của seller hiện tại
 */
router.get('/products', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, isAvailable, categoryId } = req.query;
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) return successResponse(res, { products: [], pagination: { page: 1, limit: 20, total: 0, totalPages: 0 } });

    const query = { shopId: shop._id };
    if (search) query.name = { $regex: search, $options: 'i' };
    if (isAvailable !== undefined) query.isAvailable = isAvailable === 'true';
    if (categoryId) query.categoryId = categoryId;

    const [products, total] = await Promise.all([
      Product.find(query).populate('categoryId', 'name icon').select('-__v')
        .sort({ createdAt: -1 }).skip((parseInt(page) - 1) * parseInt(limit)).limit(parseInt(limit))
        .lean(),
      Product.countDocuments(query),
    ]);

    return sendPaginated(res, products, {
      page: parseInt(page), limit: parseInt(limit), total,
      totalPages: Math.ceil(total / parseInt(limit)),
    }, 'Lấy danh sách sản phẩm thành công');
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/seller/products
 * Tạo sản phẩm mới
 */
router.post('/products', authenticate, authorize('seller'), validate(createProductSchema), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) return res.status(404).json({ success: false, message: 'Bạn chưa có cửa hàng' });
    if (!shop.isApproved) return res.status(403).json({ success: false, message: 'Cửa hàng chưa được duyệt' });

    const product = await Product.create({ ...req.body, shopId: shop._id, sellerId: req.userId, marketId: shop.marketId });
    const populated = await Product.findById(product._id).populate('categoryId', 'name icon').select('-__v');
    return successResponse(res, { product: populated }, 'Tạo sản phẩm thành công', 201);
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/v1/seller/products/:id
 * Cập nhật sản phẩm
 */
router.put('/products/:id', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });

    const product = await Product.findOneAndUpdate(
      { _id: req.params.id, shopId: shop._id },
      req.body,
      { new: true, runValidators: true }
    ).populate('categoryId', 'name icon').select('-__v');

    if (!product) return res.status(404).json({ success: false, message: 'Không tìm thấy sản phẩm' });
    return successResponse(res, { product }, 'Cập nhật sản phẩm thành công');
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/v1/seller/products/:id/toggle-available
 * Bật/tắt trạng thái sản phẩm
 */
router.patch('/products/:id/toggle-available', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });

    const product = await Product.findOne({ _id: req.params.id, shopId: shop._id });
    if (!product) return res.status(404).json({ success: false, message: 'Không tìm thấy sản phẩm' });

    product.isAvailable = !product.isAvailable;
    await product.save();
    return successResponse(res, { product }, product.isAvailable ? 'Sản phẩm đã được bật' : 'Sản phẩm đã được tắt');
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/v1/seller/products/:id
 * Xóa sản phẩm
 */
router.delete('/products/:id', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });

    const product = await Product.findOneAndDelete({ _id: req.params.id, shopId: shop._id });
    if (!product) return res.status(404).json({ success: false, message: 'Không tìm thấy sản phẩm' });
    return successResponse(res, null, 'Xóa sản phẩm thành công');
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/seller/products/:id
 * Lấy chi tiết 1 sản phẩm của seller
 */
router.get('/products/:id', authenticate, authorize('seller'), async (req, res, next) => {
  try {
    const shop = await Shop.findOne({ sellerId: req.userId });
    if (!shop) return res.status(404).json({ success: false, message: 'Không tìm thấy cửa hàng' });

    const product = await Product.findOne({ _id: req.params.id, shopId: shop._id })
      .populate('categoryId', 'name icon')
      .populate('marketId', 'name address')
      .select('-__v');
    if (!product) return res.status(404).json({ success: false, message: 'Không tìm thấy sản phẩm' });
    return successResponse(res, { product });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
