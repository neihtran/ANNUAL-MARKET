const Joi = require('joi');

const documentSchema = Joi.object({
  type: Joi.string().valid('cccd', 'driver_license', 'business_license').required(),
  url: Joi.string().required(),
});

const registerSchema = Joi.object({
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Email không hợp lệ',
      'any.required': 'Email là bắt buộc',
    }),
  password: Joi.string()
    .min(6)
    .max(50)
    .required()
    .messages({
      'string.min': 'Mật khẩu phải có ít nhất 6 ký tự',
      'string.max': 'Mật khẩu không quá 50 ký tự',
      'any.required': 'Mật khẩu là bắt buộc',
    }),
  fullName: Joi.string()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'Họ tên phải có ít nhất 2 ký tự',
      'string.max': 'Họ tên không quá 100 ký tự',
      'any.required': 'Họ tên là bắt buộc',
    }),
  phone: Joi.string()
    .pattern(/^(0[0-9]{9})$/)
    .required()
    .messages({
      'string.pattern.base': 'Số điện thoại không hợp lệ',
      'any.required': 'Số điện thoại là bắt buộc',
    }),
  role: Joi.string()
    .valid('buyer', 'seller', 'shipper')
    .default('buyer'),
  // Sellers: market + categories + CCCD documents are required
  marketId: Joi.string().when('role', {
    is: 'seller',
    then: Joi.string().required().messages({
      'any.required': 'Vui lòng chọn chợ nơi bạn buôn bán',
    }),
    otherwise: Joi.string().allow(null, ''),
  }),
  categoryIds: Joi.array().items(Joi.string()).when('role', {
    is: 'seller',
    then: Joi.array().min(1).required().messages({
      'array.min': 'Vui lòng chọn ít nhất 1 danh mục hàng bán',
      'any.required': 'Vui lòng chọn danh mục hàng bán',
    }),
    otherwise: Joi.array().items(Joi.string()),
  }),
  // Sellers: upload CCCD/CMND (min 1), Shippers: upload driver license (min 1)
  documents: Joi.array().items(documentSchema).when('role', {
    is: 'seller',
    then: Joi.array().min(1).required().messages({
      'array.min': 'Vui lòng upload ít nhất 1 ảnh CCCD/CMND',
      'any.required': 'Vui lòng upload CCCD/CMND để xác minh danh tính',
    }),
    is: 'shipper',
    then: Joi.array().min(1).required().messages({
      'array.min': 'Vui lòng upload ít nhất 1 ảnh bằng lái xe',
      'any.required': 'Vui lòng upload ảnh bằng lái xe để xác minh danh tính',
    }),
    otherwise: Joi.array().items(documentSchema),
  }),
});

const loginSchema = Joi.object({
  email: Joi.string()
    .email()
    .required()
    .messages({
      'string.email': 'Email không hợp lệ',
      'any.required': 'Email là bắt buộc',
    }),
  password: Joi.string()
    .required()
    .messages({
      'any.required': 'Mật khẩu là bắt buộc',
    }),
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string()
    .required()
    .messages({
      'any.required': 'Refresh token là bắt buộc',
    }),
});

const updateProfileSchema = Joi.object({
  fullName: Joi.string()
    .min(2)
    .max(100),
  phone: Joi.string()
    .pattern(/^(0[0-9]{9})$/),
  avatar: Joi.string()
    .uri()
    .allow(''),
  address: Joi.object({
    street: Joi.string().max(200),
    ward: Joi.string().max(100),
    district: Joi.string().max(100),
    city: Joi.string().max(100),
    coordinates: Joi.object({
      lat: Joi.number().min(-90).max(90),
      lng: Joi.number().min(-180).max(180),
    }),
  }),
  bankAccount: Joi.object({
    bankName: Joi.string().max(100),
    accountNumber: Joi.string().max(50),
    accountHolder: Joi.string().max(100),
  }),
  deviceToken: Joi.string().allow(''),
});

const updateStatusSchema = Joi.object({
  status: Joi.string()
    .valid('active', 'inactive', 'banned')
    .required()
    .messages({
      'any.only': 'Trạng thái không hợp lệ',
      'any.required': 'Trạng thái là bắt buộc',
    }),
});

const getUsersSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().allow(''),
  role: Joi.string().valid('admin', 'buyer', 'seller', 'shipper'),
  isApproved: Joi.boolean(),
  status: Joi.string().valid('active', 'inactive', 'banned'),
  marketId: Joi.string(),
  sortBy: Joi.string().valid('fullName', 'email', 'createdAt').default('createdAt'),
  sortOrder: Joi.string().valid('asc', 'desc').default('desc'),
});

const rejectUserSchema = Joi.object({
  reason: Joi.string()
    .max(500)
    .allow('')
    .optional()
    .messages({
      'any.required': 'Lý do từ chối là bắt buộc',
      'string.max': 'Lý do từ chối không quá 500 ký tự',
    }),
});

const createUserSchema = Joi.object({
  email: Joi.string().email().required().trim().lowercase(),
  password: Joi.string().required().min(6).max(100),
  fullName: Joi.string().required().trim().max(200),
  phone: Joi.string().allow('').optional().max(20),
  role: Joi.string().valid('buyer', 'seller', 'shipper').default('buyer'),
  marketId: Joi.string().allow('', null).optional(),
  isApproved: Joi.boolean().default(true),
});

module.exports = {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  updateProfileSchema,
  updateStatusSchema,
  getUsersSchema,
  rejectUserSchema,
  createUserSchema,
};
