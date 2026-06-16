const dashboardService = require('../services/dashboardService');
const { sendSuccess } = require('../utils/response');

class DashboardController {
  async getStats(req, res, next) {
    try {
      const stats = await dashboardService.getStats();
      sendSuccess(res, stats);
    } catch (error) {
      next(error);
    }
  }

  async getRevenueByDay(req, res, next) {
    try {
      const days = parseInt(req.query.days) || 30;
      const revenue = await dashboardService.getRevenueByDay(days);
      sendSuccess(res, revenue);
    } catch (error) {
      next(error);
    }
  }

  async getOrdersByStatus(req, res, next) {
    try {
      const byStatus = await dashboardService.getOrdersByStatus();
      sendSuccess(res, byStatus);
    } catch (error) {
      next(error);
    }
  }

  async getTopProducts(req, res, next) {
    try {
      const limit = parseInt(req.query.limit) || 10;
      const products = await dashboardService.getTopProducts(limit);
      sendSuccess(res, products);
    } catch (error) {
      next(error);
    }
  }

  async getTopSellers(req, res, next) {
    try {
      const limit = parseInt(req.query.limit) || 10;
      const sellers = await dashboardService.getTopSellers(limit);
      sendSuccess(res, sellers);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new DashboardController();
