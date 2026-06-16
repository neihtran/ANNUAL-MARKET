const { Market } = require('../models');
const { successResponse, errorResponse } = require('../utils/response');
const { buildPagination } = require('../utils/helpers');

exports.getMarkets = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, isActive, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;
    
    const query = {};
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { address: { $regex: search, $options: 'i' } },
      ];
    }
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [markets, total] = await Promise.all([
      Market.find(query).sort(sort).skip(skip).limit(parseInt(limit)),
      Market.countDocuments(query),
    ]);

    return successResponse(res, {
      markets,
      pagination: buildPagination(page, limit, total),
    });
  } catch (error) {
    next(error);
  }
};

exports.createMarket = async (req, res, next) => {
  try {
    const market = await Market.create(req.body);
    return successResponse(res, { market }, 'Tạo chợ thành công', 201);
  } catch (error) {
    next(error);
  }
};

exports.getMarketById = async (req, res, next) => {
  try {
    const market = await Market.findById(req.params.id);
    if (!market) {
      return errorResponse(res, 'Không tìm thấy chợ', 404);
    }
    return successResponse(res, { market });
  } catch (error) {
    next(error);
  }
};

exports.updateMarket = async (req, res, next) => {
  try {
    const market = await Market.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!market) {
      return errorResponse(res, 'Không tìm thấy chợ', 404);
    }
    return successResponse(res, { market }, 'Cập nhật chợ thành công');
  } catch (error) {
    next(error);
  }
};

exports.toggleMarketActive = async (req, res, next) => {
  try {
    const market = await Market.findById(req.params.id);
    if (!market) {
      return errorResponse(res, 'Không tìm thấy chợ', 404);
    }
    market.isActive = !market.isActive;
    await market.save();
    return successResponse(res, { market }, `Chợ đã ${market.isActive ? 'kích hoạt' : 'vô hiệu hóa'}`);
  } catch (error) {
    next(error);
  }
};

exports.deleteMarket = async (req, res, next) => {
  try {
    const market = await Market.findByIdAndDelete(req.params.id);
    if (!market) {
      return errorResponse(res, 'Không tìm thấy chợ', 404);
    }
    return successResponse(res, null, 'Xóa chợ thành công');
  } catch (error) {
    next(error);
  }
};
