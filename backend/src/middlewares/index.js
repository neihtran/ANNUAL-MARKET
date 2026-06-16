const { authenticate } = require('./auth');
const { validate, validateQuery, validateParams } = require('./validate');
const { errorHandler, notFound } = require('./errorHandler');
const { apiLimiter, authLimiter, orderLimiter } = require('./rateLimit');

module.exports = {
  authenticate,
  validate,
  validateQuery,
  validateParams,
  errorHandler,
  notFound,
  apiLimiter,
  authLimiter,
  orderLimiter,
};
