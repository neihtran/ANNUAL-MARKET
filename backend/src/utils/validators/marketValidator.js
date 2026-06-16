const Joi = require('joi');

const createMarketSchema = Joi.object({
  name: Joi.string().required().trim().max(200),
  address: Joi.string().required().trim(),
  district: Joi.string().required().trim(),
  location: Joi.object({
    lat: Joi.number().required(),
    lng: Joi.number().required(),
  }).default({ lat: 16.0544, lng: 108.2022 }),
  images: Joi.array().items(Joi.string()).max(10).default([]),
  openTime: Joi.string().default('06:00'),
  closeTime: Joi.string().default('18:00'),
  description: Joi.string().max(1000).allow('').default(''),
  phone: Joi.string().allow('').default(''),
  is24h: Joi.boolean().default(false),
  isActive: Joi.boolean().default(true),
});

const updateMarketSchema = Joi.object({
  name: Joi.string().trim().max(200),
  address: Joi.string().trim(),
  district: Joi.string().trim(),
  location: Joi.object({
    lat: Joi.number(),
    lng: Joi.number(),
  }),
  images: Joi.array().items(Joi.string()).max(10),
  openTime: Joi.string(),
  closeTime: Joi.string(),
  description: Joi.string().max(1000).allow(''),
  phone: Joi.string().allow(''),
  is24h: Joi.boolean(),
  isActive: Joi.boolean(),
});

const marketQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().allow(''),
  isActive: Joi.boolean(),
  sortBy: Joi.string().valid('name', 'createdAt').default('createdAt'),
  sortOrder: Joi.string().valid('asc', 'desc').default('desc'),
});

module.exports = {
  createSchema: createMarketSchema,
  updateSchema: updateMarketSchema,
  querySchema: marketQuerySchema,
};
