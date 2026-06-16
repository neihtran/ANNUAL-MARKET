const discoveryService = require('../services/discoveryService');
const { successResponse, sendPaginated, buildPaginationResponse } = require('../utils/response');

class DiscoveryController {
  async getNearbyProducts(req, res, next) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const { products, total } = await discoveryService.getNearbyProducts(req.query);
      return sendPaginated(res, { products }, buildPaginationResponse(total, parseInt(page), parseInt(limit)));
    } catch (error) {
      next(error);
    }
  }

  async getNearbyMarkets(req, res, next) {
    try {
      const markets = await discoveryService.getNearbyMarkets(req.query);
      // Return markets as a direct array for mobile app compatibility
      return successResponse(res, markets);
    } catch (error) {
      next(error);
    }
  }

  async search(req, res, next) {
    try {
      const results = await discoveryService.globalSearch(req.query);
      return successResponse(res, results);
    } catch (error) {
      next(error);
    }
  }

  async getFeaturedProducts(req, res, next) {
    try {
      const results = await discoveryService.getFeaturedProducts(req.query);
      return successResponse(res, results);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new DiscoveryController();
