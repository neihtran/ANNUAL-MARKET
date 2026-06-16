const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { Market } = require('../models');
const { successResponse } = require('../utils/response');

// Haversine distance calculation (km)
function calcDistance(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * GET /api/v1/markets
 * Lấy danh sách chợ (public)
 * Query: lat, lng, isActive, search, page, limit
 */
router.get('/', async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, isActive, lat, lng } = req.query;

    const query = {};
    // Only filter by isActive if explicitly provided; default shows all markets
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { address: { $regex: search, $options: 'i' } },
      ];
    }

    let markets = await Market.find(query)
      .select('-__v')
      .sort({ isActive: -1, createdAt: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    if (lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      markets = markets.map(m => {
        const distance = (m.location && m.location.lat != null && m.location.lng != null)
          ? calcDistance(userLat, userLng, m.location.lat, m.location.lng)
          : null;
        return { ...m.toObject(), distance };
      });
      markets.sort((a, b) => (a.distance || 999) - (b.distance || 999));
    } else {
      markets = markets.map(m => m.toObject());
    }

    const total = await Market.countDocuments(query);

    return successResponse(res, {
      markets,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/markets/:id/categories
 * Lấy danh mục của 1 chợ (dựa trên sản phẩm trong chợ đó, chỉ từ gian hàng đang bán)
 */
router.get('/:id/categories', async (req, res, next) => {
  try {
    const { Category, Product, Shop } = require('../models');
    // Skip if id is not a valid ObjectId (e.g., "all")
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return successResponse(res, { categories: [] });
    }
    // Only count products from shops that are actively selling
    const activeShopIds = await Shop.find({ isSelling: true }).distinct('_id');
    const productCategories = await Product.distinct('categoryId', {
      marketId: req.params.id,
      shopId: { $in: activeShopIds },
    });
    const categories = await Category.find({
      _id: { $in: productCategories },
      isActive: true,
    }).sort({ sortOrder: 1 });
    return successResponse(res, { categories });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/markets/:id/shops
 * Lấy danh sách gian hàng trong chợ
 */
router.get('/:id/shops', async (req, res, next) => {
  try {
    const { Shop, Market } = require('../models');
    const { page = 1, limit = 20, isOpen } = req.query;
    const query = { marketId: req.params.id, isApproved: true };
    if (isOpen !== undefined) query.isOpen = isOpen === 'true';

    const [shops, total, market] = await Promise.all([
      Shop.find(query)
        .populate('categoryId', 'name icon')
        .populate('sellerId', 'fullName avatar')
        .select('-__v')
        .sort({ rating: -1 })
        .skip((parseInt(page) - 1) * parseInt(limit))
        .limit(parseInt(limit)),
      Shop.countDocuments(query),
      Market.findById(req.params.id).select('openTime closeTime is24h isActive').lean(),
    ]);

    // Calculate isCurrentlyOpen from market data
    const now = new Date();
    const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    const isMarketCurrentlyOpen = market ? (market.is24h || (market.isActive !== false && currentTime >= (market.openTime || '06:00') && currentTime <= (market.closeTime || '18:00'))) : false;

    const shopsWithStatus = shops.map(shop => {
      // shops is from Mongoose, but market is from .lean() so it's already plain object
      const shopObj = typeof shop.toObject === 'function' ? shop.toObject() : shop;
      // market is already plain object from .lean()
      // Thêm thông tin giờ mở cửa chợ và trạng thái real-time
      shopObj.marketInfo = market ? {
        openTime: market.openTime,
        closeTime: market.closeTime,
        is24h: market.is24h,
        isCurrentlyOpen: isMarketCurrentlyOpen,
      } : null;
      return shopObj;
    });

    return successResponse(res, {
      shops: shopsWithStatus,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/markets/:id
 * Lấy chi tiết 1 chợ
 * NOTE: Must be LAST to avoid conflict with /:id/categories and /:id/shops
 */
router.get('/:id', async (req, res, next) => {
  try {
    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(404).json({ 
        success: false, 
        message: 'ID chợ không hợp lệ',
        data: null 
      });
    }
    
    const market = await Market.findById(req.params.id).select('-__v').lean();
    
    if (!market) {
      return res.status(404).json({ 
        success: false, 
        message: 'Không tìm thấy chợ',
        data: null 
      });
    }
    
    return successResponse(res, { market });
  } catch (error) {
    console.error('Error fetching market:', error);
    next(error);
  }
});

module.exports = router;
