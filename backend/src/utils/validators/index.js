const {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  updateProfileSchema,
  updateStatusSchema,
  getUsersSchema,
  rejectUserSchema,
  createUserSchema,
} = require('./userValidator');

const {
  createProductSchema,
  updateProductSchema,
  productQuerySchema,
} = require('./productValidator');

const {
  createOrderSchema,
  updateOrderSchema,
  updateOrderStatusSchema,
  cancelOrderSchema,
  orderQuerySchema,
} = require('./orderValidator');

const {
  createReviewSchema,
  reviewQuerySchema,
} = require('./reviewValidator');

const {
  createSellerReviewSchema,
  sellerReviewQuerySchema,
  sellerReviewReplySchema,
} = require('./sellerReviewValidator');

const {
  createShipperReviewSchema,
  shipperReviewQuerySchema,
} = require('./shipperReviewValidator');

const {
  createSchema: createMarketSchema,
  updateSchema: updateMarketSchema,
  querySchema: marketQuerySchema,
} = require('./marketValidator');

const {
  createSchema: createCategorySchema,
  updateSchema: updateCategorySchema,
  querySchema: categoryQuerySchema,
} = require('./categoryValidator');

const userValidation = {
  getUsersSchema,
  rejectUserSchema,
  createUserSchema,
};

const marketValidation = {
  createSchema: createMarketSchema,
  updateSchema: updateMarketSchema,
  querySchema: marketQuerySchema,
};

const categoryValidation = {
  createSchema: createCategorySchema,
  updateSchema: updateCategorySchema,
  querySchema: categoryQuerySchema,
};

module.exports = {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  updateProfileSchema,
  updateStatusSchema,
  createProductSchema,
  updateProductSchema,
  productQuerySchema,
  createOrderSchema,
  updateOrderSchema,
  updateOrderStatusSchema,
  cancelOrderSchema,
  orderQuerySchema,
  createReviewSchema,
  reviewQuerySchema,
  createSellerReviewSchema,
  sellerReviewQuerySchema,
  sellerReviewReplySchema,
  createShipperReviewSchema,
  shipperReviewQuerySchema,
  userValidation,
  marketValidation,
  categoryValidation,
};
