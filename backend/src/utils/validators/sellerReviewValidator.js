const Joi = require('joi');

const createSellerReviewSchema = Joi.object({
  orderId: Joi.string()
    .required()
    .messages({
      'any.required': 'ID đơn hàng là bắt buộc',
    }),
  sellerId: Joi.string()
    .required()
    .messages({
      'any.required': 'ID người bán là bắt buộc',
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
    quality: Joi.number().integer().min(1).max(5),
    communication: Joi.number().integer().min(1).max(5),
    delivery: Joi.number().integer().min(1).max(5),
  }).optional(),
  comment: Joi.string()
    .max(1000)
    .allow('')
    .default(''),
});

const sellerReviewQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(10),
});

const sellerReviewReplySchema = Joi.object({
  comment: Joi.string()
    .max(1000)
    .required()
    .messages({
      'string.max': 'Phản hồi không quá 1000 ký tự',
      'any.required': 'Nội dung phản hồi là bắt buộc',
    }),
});

module.exports = {
  createSellerReviewSchema,
  sellerReviewQuerySchema,
  sellerReviewReplySchema,
};
