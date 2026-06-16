const { Product, User, Shop } = require('../models');
const { NotFoundError, BadRequestError } = require('../middlewares/errorHandler');
const { getPaginationParams, buildPaginationResponse } = require('../utils/response');

class ProductService {
  async getAll(query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = {};

    // Support both 'categoryId' and 'category' (for backward compat)
    if (query.categoryId || query.category) {
      filter.categoryId = query.categoryId || query.category;
    }

    if (query.marketId) {
      filter.marketId = query.marketId;
    }

    if (query.isAvailable !== undefined) {
      filter.isAvailable = query.isAvailable;
    }

    if (query.minPrice !== undefined || query.maxPrice !== undefined) {
      filter.price = {};
      if (query.minPrice !== undefined) filter.price.$gte = parseFloat(query.minPrice);
      if (query.maxPrice !== undefined) filter.price.$lte = parseFloat(query.maxPrice);
    }

    // Support both 'search' and 'keyword'
    if (query.search || query.keyword) {
      const term = query.search || query.keyword;
      filter.$or = [
        { name: { $regex: term, $options: 'i' } },
        { description: { $regex: term, $options: 'i' } },
      ];
    }

    const sortField = query.sortBy || 'createdAt';
    const sortOrder = query.sortOrder === 'asc' ? 1 : -1;
    const sort = { [sortField]: sortOrder };

    // Only show products from shops that are actively selling (isSelling: true)
    const activeShopIds = await Shop.find({ isSelling: true }).distinct('_id');
    filter.shopId = { $in: activeShopIds };

    const [products, total] = await Promise.all([
      Product.find(filter)
        .populate('categoryId', 'name icon')
        .populate('shopId', 'name avatar isSelling')
        .populate('sellerId', 'fullName avatar')
        .sort(sort)
        .skip(skip)
        .limit(limit)
        .lean(),
      Product.countDocuments(filter),
    ]);

    const formattedProducts = products.map(p => ({
      ...p,
      category: p.categoryId,
      shop: p.shopId,
      seller: p.sellerId,
    }));

    return {
      products: formattedProducts,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getById(id) {
    const product = await Product.findById(id)
      .populate('categoryId', 'name icon')
      .populate('shopId', 'name avatar coverImage')
      .populate('marketId', 'name address location')
      .populate('sellerId', 'fullName phone avatar')
      .lean();

    if (!product) {
      throw new NotFoundError('Sản phẩm không tồn tại');
    }

    return {
      ...product,
      category: product.categoryId,
      shop: product.shopId,
      market: product.marketId,
      seller: product.sellerId,
    };
  }

  async create(sellerId, data) {
    const seller = await User.findById(sellerId);
    if (!seller) {
      throw new NotFoundError('Người bán không tồn tại');
    }

    if (seller.role !== 'seller' && seller.role !== 'admin') {
      throw new BadRequestError('Bạn không có quyền tạo sản phẩm');
    }

    if (seller.role === 'seller' && !seller.isApproved) {
      throw new BadRequestError('Tài khoản chưa được admin duyệt');
    }

    const Shop = require('../models/Shop');
    const shop = await Shop.findOne({ sellerId });

    if (!shop) {
      throw new BadRequestError('Bạn cần tạo cửa hàng trước khi thêm sản phẩm');
    }

    const productData = {
      ...data,
      sellerId,
      shopId: shop._id,
      marketId: data.marketId || shop.marketId,
      categoryId: data.categoryId || shop.categoryId,
    };

    const product = await Product.create(productData);
    return product;
  }

  async update(id, sellerId, data) {
    const product = await Product.findById(id);

    if (!product) {
      throw new NotFoundError('Sản phẩm không tồn tại');
    }

    // Seller can only update their own products
    if (product.sellerId.toString() !== sellerId.toString()) {
      throw new BadRequestError('Bạn không có quyền cập nhật sản phẩm này');
    }

    // Only allow updating certain fields (prevent changing shopId/sellerId/marketId)
    const allowedFields = [
      'name', 'description', 'images', 'price', 'unit',
      'stock', 'minOrder', 'isAvailable', 'categoryId',
    ];
    for (const key of Object.keys(data)) {
      if (allowedFields.includes(key)) {
        product[key] = data[key];
      }
    }

    await product.save();

    return product;
  }

  async delete(id, sellerId) {
    const product = await Product.findById(id);

    if (!product) {
      throw new NotFoundError('Sản phẩm không tồn tại');
    }

    if (product.sellerId.toString() !== sellerId.toString()) {
      throw new BadRequestError('Bạn không có quyền xóa sản phẩm này');
    }

    await Product.findByIdAndDelete(id);

    return { message: 'Xóa sản phẩm thành công' };
  }

  async getBySeller(sellerId, query) {
    const { page, limit, skip } = getPaginationParams(query);

    const filter = { sellerId };

    if (query.isAvailable !== undefined) {
      filter.isAvailable = query.isAvailable;
    }

    if (query.categoryId) {
      filter.categoryId = query.categoryId;
    }

    if (query.search || query.keyword) {
      const term = query.search || query.keyword;
      filter.name = { $regex: term, $options: 'i' };
    }

    const [products, total] = await Promise.all([
      Product.find(filter)
        .populate('categoryId', 'name icon')
        .populate('shopId', 'name avatar')
        .populate('marketId', 'name address')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Product.countDocuments(filter),
    ]);

    return {
      products,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getNearby(query) {
    const { lat, lng, radius = 10, categoryId, marketId, limit = 20, page = 1 } = query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const filter = { isAvailable: true };
    if (categoryId) filter.categoryId = categoryId;
    if (marketId) filter.marketId = marketId;

    // Only show products from shops that are actively selling (isSelling: true)
    const activeShopIds = await Shop.find({ isSelling: true }).distinct('_id');
    filter.shopId = { $in: activeShopIds };

    let products = await Product.find(filter)
      .populate('categoryId', 'name icon')
      .populate('shopId', 'name avatar isSelling')
      .populate('marketId', 'name address district location')
      .populate('sellerId', 'fullName avatar')
      .sort({ soldCount: -1, rating: -1 })
      .limit(100)
      .lean();

    if (lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      const maxDist = parseFloat(radius);

      products = products
        .map(p => {
          const marketLoc = (p.marketId && p.marketId.location) || null;
          let distance = null;
          if (marketLoc && marketLoc.lat != null && marketLoc.lng != null) {
            const R = 6371;
            const dLat = (marketLoc.lat - userLat) * Math.PI / 180;
            const dLng = (marketLoc.lng - userLng) * Math.PI / 180;
            const a = Math.sin(dLat / 2) ** 2 +
              Math.cos(userLat * Math.PI / 180) * Math.cos(marketLoc.lat * Math.PI / 180) *
              Math.sin(dLng / 2) ** 2;
            distance = Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
          }
          return { ...p, distance };
        })
        .filter(p => p.distance == null || p.distance <= maxDist)
        .sort((a, b) => (a.distance || 999) - (b.distance || 999));
    }

    const total = products.length;
    products = products.slice(skip, skip + parseInt(limit));

    const formatted = products.map(p => ({
      ...p,
      category: p.categoryId,
      shop: p.shopId,
      market: p.marketId,
      seller: p.sellerId,
    }));

    return {
      products: formatted,
      pagination: buildPaginationResponse(total, parseInt(page), parseInt(limit)),
    };
  }
}

module.exports = new ProductService();
