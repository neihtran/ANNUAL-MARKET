const orderService = require('../services/orderService');
const { sendSuccess, sendCreated, sendPaginated } = require('../utils/response');

class OrderController {
  async create(req, res, next) {
    try {
      const order = await orderService.create(req.userId, req.body);
      const orderObj = typeof order.toObject === 'function' ? order.toObject() : order;
      sendCreated(res, orderObj, 'Tạo đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async getAll(req, res, next) {
    try {
      const result = await orderService.getAll(req.query);
      sendPaginated(res, result.orders, result.pagination, 'Lấy danh sách đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const order = await orderService.getById(req.params.id);
      sendSuccess(res, order);
    } catch (error) {
      next(error);
    }
  }

  async getByBuyer(req, res, next) {
    try {
      const result = await orderService.getByBuyer(req.userId, req.query);
      sendPaginated(res, result.orders, result.pagination, 'Lấy danh sách đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async getBySeller(req, res, next) {
    try {
      const result = await orderService.getBySeller(req.userId, req.query);
      sendPaginated(res, result.orders, result.pagination, 'Lấy danh sách đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async getAvailableForShipper(req, res, next) {
    try {
      const result = await orderService.getAvailableForShipper(req.query);
      sendPaginated(res, result.orders, result.pagination, 'Lấy danh sách đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async getActiveForShipper(req, res, next) {
    try {
      const result = await orderService.getActiveForShipper(req.userId, req.query);
      sendPaginated(res, result.orders, result.pagination, 'Lấy danh sách đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async getHistoryForShipper(req, res, next) {
    try {
      const result = await orderService.getHistoryForShipper(req.userId, req.query);
      sendPaginated(res, result.orders, result.pagination, 'Lấy danh sách đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async acceptOrder(req, res, next) {
    try {
      const order = await orderService.acceptOrder(req.params.id, req.userId);
      sendSuccess(res, order, 'Nhận đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  async updateStatus(req, res, next) {
    try {
      const { status, note, confirmImageUrl } = req.body;
      const order = await orderService.updateStatus(
        req.params.id,
        status,
        req.userId,
        req.user.role,
        note,
        confirmImageUrl
      );
      sendSuccess(res, order, 'Cập nhật trạng thái thành công');
    } catch (error) {
      next(error);
    }
  }

  async cancel(req, res, next) {
    try {
      const { reason } = req.body;
      console.log(`[CANCEL] buyerId=${req.userId} role=${req.user.role} orderId=${req.params.id} reason="${reason}"`);
      const order = await orderService.cancel(req.params.id, req.userId, req.user.role, reason);
      const message = req.user.role === 'shipper' ? 'Trả đơn thành công' : 'Hủy đơn hàng thành công';
      sendSuccess(res, order, message);
    } catch (error) {
      console.error(`[CANCEL ERROR] ${error.message}`);
      next(error);
    }
  }

  async update(req, res, next) {
    try {
      const order = await orderService.update(req.params.id, req.userId, req.user.role, req.body);
      sendSuccess(res, order, 'Cập nhật đơn hàng thành công');
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /orders/:id/shipper-location
   * Shipper updates their current GPS location for tracking.
   */
  async updateShipperLocation(req, res, next) {
    try {
      const { lat, lng } = req.body;
      if (lat == null || lng == null) {
        return res.status(400).json({ success: false, message: 'lat và lng là bắt buộc' });
      }
      const order = await orderService.updateShipperLocation(req.params.id, req.userId, lat, lng);
      sendSuccess(res, order, 'Cập nhật vị trí thành công');
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /orders/:id/track
   * Buyer/Shipper: lấy thông tin đơn + vị trí shipper (để hiển thị trên map).
   */
  async getOrderTrack(req, res, next) {
    try {
      const order = await orderService.getOrderTrack(req.params.id, req.userId, req.user.role);
      sendSuccess(res, order, 'Lấy thông tin theo dõi thành công');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new OrderController();
