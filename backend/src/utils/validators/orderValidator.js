const Joi = require('joi');

const orderItemSchema = Joi.object({
  productId: Joi.string()
    .required()
    .messages({
      'any.required': 'ID sản phẩm là bắt buộc',
    }),
  quantity: Joi.number()
    .integer()
    .min(1)
    .required()
    .messages({
      'number.min': 'Số lượng phải lớn hơn 0',
      'any.required': 'Số lượng là bắt buộc',
    }),
});

const deliveryAddressSchema = Joi.object({
  address: Joi.string().max(500).required(),
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  contactName: Joi.string().max(100).required(),
  contactPhone: Joi.string().pattern(/^(0[0-9]{9})$/).required(),
});

const createOrderSchema = Joi.object({
  marketId: Joi.string()
    .required()
    .messages({
      'any.required': 'ID chợ là bắt buộc',
    }),
  items: Joi.array()
    .items(orderItemSchema)
    .min(1)
    .required()
    .messages({
      'array.min': 'Đơn hàng phải có ít nhất 1 sản phẩm',
      'any.required': 'Danh sách sản phẩm là bắt buộc',
    }),
  deliveryAddress: deliveryAddressSchema.required(),
  paymentMethod: Joi.string()
    .valid('cod', 'momo', 'vnpay')
    .default('cod'),
  note: Joi.string()
    .max(500)
    .allow('')
    .default(''),
});

const updateOrderSchema = Joi.object({
  items: Joi.array()
    .items(orderItemSchema)
    .min(1),
  deliveryAddress: deliveryAddressSchema,
  paymentMethod: Joi.string()
    .valid('cod', 'momo', 'vnpay'),
  note: Joi.string()
    .max(500)
    .allow(''),
});

const updateOrderStatusSchema = Joi.object({
  status: Joi.string()
    .valid(
      'pending',
      'finding_shipper',
      'shipper_accepted',
      'heading_to_market',
      'arrived_at_market',
      'ready_for_pickup',
      'seller_handed_over',
      'picked_up',
      'shopping',
      'delivering',
      'delivered',
      'cancelled'
    )
    .required()
    .messages({
      'any.only': 'Trạng thái không hợp lệ',
      'any.required': 'Trạng thái là bắt buộc',
    }),
  note: Joi.string()
    .max(500)
    .allow(''),
  confirmImageUrl: Joi.string().allow(''),
});

const cancelOrderSchema = Joi.object({
  reason: Joi.string()
    .max(500)
    .allow('')
    .optional()
    .default(''),
});

const orderQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().allow(''),
  status: Joi.string().valid(
    'pending',
    'finding_shipper',
    'shipper_accepted',
    'heading_to_market',
    'arrived_at_market',
    'ready_for_pickup',
    'seller_handed_over',
    'picked_up',
    'shopping',
    'delivering',
    'delivered',
    'cancelled'
  ),
  paymentStatus: Joi.string().valid('unpaid', 'paid', 'refunded'),
  marketId: Joi.string(),
  sortBy: Joi.string()
    .valid('createdAt', 'total')
    .default('createdAt'),
  sortOrder: Joi.string()
    .valid('asc', 'desc')
    .default('desc'),
});

module.exports = {
  createOrderSchema,
  updateOrderSchema,
  updateOrderStatusSchema,
  cancelOrderSchema,
  orderQuerySchema,
};
