const { BuyerAddress, Favorite, Product, Market } = require('../models');
const { successResponse } = require('../utils/response');

class BuyerController {
  // ── Addresses ──────────────────────────────────────────────────────────

  async getAddresses(req, res, next) {
    try {
      const addresses = await BuyerAddress.find({ userId: req.userId }).sort({ isDefault: -1, createdAt: -1 });
      return successResponse(res, { addresses });
    } catch (error) {
      next(error);
    }
  }

  async createAddress(req, res, next) {
    try {
      const data = { ...req.body, userId: req.userId };
      const address = await BuyerAddress.create(data);
      return successResponse(res, { address }, 'Thêm địa chỉ thành công', 201);
    } catch (error) {
      next(error);
    }
  }

  async updateAddress(req, res, next) {
    try {
      const address = await BuyerAddress.findOneAndUpdate(
        { _id: req.params.id, userId: req.userId },
        req.body,
        { new: true, runValidators: true }
      );
      if (!address) return res.status(404).json({ success: false, message: 'Không tìm thấy địa chỉ' });
      return successResponse(res, { address }, 'Cập nhật địa chỉ thành công');
    } catch (error) {
      next(error);
    }
  }

  async deleteAddress(req, res, next) {
    try {
      const address = await BuyerAddress.findOneAndDelete({ _id: req.params.id, userId: req.userId });
      if (!address) return res.status(404).json({ success: false, message: 'Không tìm thấy địa chỉ' });
      return successResponse(res, null, 'Xóa địa chỉ thành công');
    } catch (error) {
      next(error);
    }
  }

  async setDefaultAddress(req, res, next) {
    try {
      await BuyerAddress.updateMany({ userId: req.userId }, { isDefault: false });
      const address = await BuyerAddress.findOneAndUpdate(
        { _id: req.params.id, userId: req.userId },
        { isDefault: true },
        { new: true }
      );
      if (!address) return res.status(404).json({ success: false, message: 'Không tìm thấy địa chỉ' });
      return successResponse(res, { address }, 'Đặt địa chỉ mặc định thành công');
    } catch (error) {
      next(error);
    }
  }

  // ── Favorites ────────────────────────────────────────────────────────

  async getFavorites(req, res, next) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const [favorites, total] = await Promise.all([
        Favorite.find({ userId: req.userId })
          .populate({
            path: 'productId',
            populate: [
              { path: 'categoryId', select: 'name icon' },
              { path: 'marketId', select: 'name district location' },
              { path: 'shopId', select: 'name avatar' },
            ],
          })
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(parseInt(limit))
          .lean(),
        Favorite.countDocuments({ userId: req.userId }),
      ]);

      const products = favorites
        .filter(f => f.productId)
        .map(f => f.productId);

      return res.status(200).json({
        success: true,
        message: 'Lấy danh sách yêu thích thành công',
        data: { products },
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
  }

  async addFavorite(req, res, next) {
    try {
      const { productId } = req.body;
      if (!productId) return res.status(400).json({ success: false, message: 'Product ID là bắt buộc' });

      const product = await Product.findById(productId);
      if (!product) return res.status(404).json({ success: false, message: 'Sản phẩm không tồn tại' });

      const existing = await Favorite.findOne({ userId: req.userId, productId });
      if (existing) return res.status(409).json({ success: false, message: 'Sản phẩm đã có trong danh sách yêu thích' });

      await Favorite.create({ userId: req.userId, productId });
      return successResponse(res, null, 'Thêm vào yêu thích thành công', 201);
    } catch (error) {
      next(error);
    }
  }

  async removeFavorite(req, res, next) {
    try {
      const deleted = await Favorite.findOneAndDelete({ userId: req.userId, productId: req.params.productId });
      if (!deleted) return res.status(404).json({ success: false, message: 'Sản phẩm không có trong danh sách yêu thích' });
      return successResponse(res, null, 'Xóa khỏi yêu thích thành công');
    } catch (error) {
      next(error);
    }
  }

  async checkFavorite(req, res, next) {
    try {
      const exists = await Favorite.exists({ userId: req.userId, productId: req.params.productId });
      return successResponse(res, { isFavorite: !!exists });
    } catch (error) {
      next(error);
    }
  }

  // ── Districts ────────────────────────────────────────────────────────

  async getDistricts(req, res, next) {
    try {
      const districts = Market.getDNDistricts();
      return successResponse(res, { districts });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new BuyerController();
