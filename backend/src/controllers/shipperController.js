const shipperService = require('../services/shipperService');
const { successResponse, sendPaginated, buildPaginationResponse } = require('../utils/response');

class ShipperController {
  async updateLocation(req, res, next) {
    try {
      const { lat, lng } = req.body;
      if (lat == null || lng == null) {
        return res.status(400).json({ success: false, message: 'lat và lng là bắt buộc' });
      }
      await shipperService.updateLocation(req.userId, parseFloat(lat), parseFloat(lng));
      return successResponse(res, { lat: parseFloat(lat), lng: parseFloat(lng) }, 'Cập nhật vị trí thành công');
    } catch (error) {
      next(error);
    }
  }

  async updateOnlineStatus(req, res, next) {
    try {
      const { isOnline } = req.body;
      if (isOnline == null) {
        return res.status(400).json({ success: false, message: 'isOnline là bắt buộc' });
      }
      const user = await shipperService.updateOnlineStatus(req.userId, !!isOnline);
      return successResponse(res, { isOnline: user.status === 'active' }, 'Cập nhật trạng thái thành công');
    } catch (error) {
      next(error);
    }
  }

  async getNearbyOrders(req, res, next) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const { orders, total } = await shipperService.getNearbyAvailableOrders(req.userId, req.query);
      return sendPaginated(res, { orders }, buildPaginationResponse(total, parseInt(page), parseInt(limit)));
    } catch (error) {
      next(error);
    }
  }

  async getProfile(req, res, next) {
    try {
      const profile = await shipperService.getShipperProfile(req.userId);
      if (!profile) return res.status(404).json({ success: false, message: 'Không tìm thấy tài khoản' });
      return successResponse(res, { user: profile });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ShipperController();
