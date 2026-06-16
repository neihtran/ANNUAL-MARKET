const productService = require('../services/productService');
const { sendSuccess, sendCreated, sendPaginated } = require('../utils/response');

class ProductController {
  async getAll(req, res, next) {
    try {
      const result = await productService.getAll(req.query);
      sendPaginated(res, result.products, result.pagination, 'Lấy danh sách sản phẩm thành công');
    } catch (error) {
      next(error);
    }
  }

  async getById(req, res, next) {
    try {
      const product = await productService.getById(req.params.id);
      sendSuccess(res, product);
    } catch (error) {
      next(error);
    }
  }

  async create(req, res, next) {
    try {
      const product = await productService.create(req.userId, req.body);
      sendCreated(res, product, 'Tạo sản phẩm thành công');
    } catch (error) {
      next(error);
    }
  }

  async update(req, res, next) {
    try {
      const product = await productService.update(req.params.id, req.userId, req.body);
      sendSuccess(res, product, 'Cập nhật sản phẩm thành công');
    } catch (error) {
      next(error);
    }
  }

  async delete(req, res, next) {
    try {
      const result = await productService.delete(req.params.id, req.userId);
      sendSuccess(res, result, 'Xóa sản phẩm thành công');
    } catch (error) {
      next(error);
    }
  }

  async getBySeller(req, res, next) {
    try {
      const sellerId = req.params.sellerId || req.userId;
      const result = await productService.getBySeller(sellerId, req.query);
      sendPaginated(res, result.products, result.pagination, 'Lấy danh sách sản phẩm thành công');
    } catch (error) {
      next(error);
    }
  }

  async getNearby(req, res, next) {
    try {
      const result = await productService.getNearby(req.query);
      sendPaginated(res, result.products, result.pagination, 'Lấy sản phẩm gần đây thành công');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ProductController();
