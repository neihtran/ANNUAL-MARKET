const Joi = require('joi');

const createShipperReviewSchema = Joi.object({
  orderId: Joi.string()
    .required()
    .messages({
      'any.required': 'ID đơn hàng là bắt buộc',
    }),
  rating: Joi.number()
    .integer()
    .min(1)
    .max(5)
    .required()
    .messages({
      'number.min': 'Đánh giá tối thiểu là 1 sao',
      'number.max': 'Đánh giá tối đa là 5 sao',
      'any.required': 'Đánh giá là bắt buộc',
    }),
  aspects: Joi.object({
    punctuality: Joi.number().integer().min(1).max(5),
    attitude: Joi.number().integer().min(1).max(5),
    handling: Joi.number().integer().min(1).max(5),
  }).optional(),
  comment: Joi.string()
    .max(1000)
    .allow('')
    .default(''),
});

const shipperReviewQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(10),
});

module.exports = {
  createShipperReviewSchema,
  shipperReviewQuerySchema,
};
