const Joi = require('joi');

const createProductSchema = Joi.object({
  name: Joi.string()
    .min(2)
    .max(200)
    .required()
    .messages({
      'string.min': 'Tên sản phẩm phải có ít nhất 2 ký tự',
      'string.max': 'Tên sản phẩm không quá 200 ký tự',
      'any.required': 'Tên sản phẩm là bắt buộc',
    }),
  description: Joi.string()
    .max(2000)
    .allow('')
    .default(''),
  categoryId: Joi.string()
    .required()
    .messages({
      'any.required': 'Danh mục là bắt buộc',
    }),
  images: Joi.array()
    .items(Joi.string().allow(''))
    .max(10)
    .default([]),
  price: Joi.number()
    .min(0)
    .required()
    .messages({
      'number.min': 'Giá không được âm',
      'any.required': 'Giá là bắt buộc',
    }),
  unit: Joi.string()
    .valid('kg', 'bó', 'con', 'cái', 'lít', 'lon', 'gói', 'hộp', 'bịch', 'vỉ', 'phần')
    .default('kg'),
  stock: Joi.number()
    .min(0)
    .default(0),
  minOrder: Joi.number()
    .min(1)
    .default(1),
  isAvailable: Joi.boolean()
    .default(true),
});

const updateProductSchema = Joi.object({
  name: Joi.string()
    .min(2)
    .max(200),
  description: Joi.string()
    .max(2000)
    .allow(''),
  categoryId: Joi.string(),
  images: Joi.array()
    .items(Joi.string().allow(''))
    .max(10),
  price: Joi.number()
    .min(0),
  unit: Joi.string()
    .valid('kg', 'bó', 'con', 'cái', 'lít', 'lon', 'gói', 'hộp', 'bịch', 'vỉ', 'phần'),
  stock: Joi.number()
    .min(0),
  minOrder: Joi.number()
    .min(1),
  isAvailable: Joi.boolean(),
});

const productQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().allow(''),
  categoryId: Joi.string(),
  marketId: Joi.string(),
  keyword: Joi.string().allow(''),
  minPrice: Joi.number().min(0),
  maxPrice: Joi.number().min(0),
  isAvailable: Joi.boolean(),
  sortBy: Joi.string()
    .valid('createdAt', 'price', 'name')
    .default('createdAt'),
  sortOrder: Joi.string()
    .valid('asc', 'desc')
    .default('desc'),
});

const nearbyQuerySchema = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  radius: Joi.number().min(1).max(50).default(10),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

module.exports = {
  createProductSchema,
  updateProductSchema,
  productQuerySchema,
  nearbyQuerySchema,
};
