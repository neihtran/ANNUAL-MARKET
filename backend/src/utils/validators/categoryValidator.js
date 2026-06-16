const Joi = require('joi');

const createCategorySchema = Joi.object({
  name: Joi.string().required().trim().max(100),
  icon: Joi.string().allow('').default(''),
  description: Joi.string().max(500).allow('').default(''),
  parentId: Joi.string().allow(null).default(null),
  sortOrder: Joi.number().integer().min(0).default(0),
});

const updateCategorySchema = Joi.object({
  name: Joi.string().trim().max(100),
  icon: Joi.string().allow(''),
  description: Joi.string().max(500).allow(''),
  parentId: Joi.string().allow(null),
  sortOrder: Joi.number().integer().min(0),
});

const categoryQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().allow(''),
  isActive: Joi.boolean(),
  parentId: Joi.string().allow(null, ''),
  sortBy: Joi.string().valid('name', 'sortOrder', 'createdAt').default('sortOrder'),
  sortOrder: Joi.string().valid('asc', 'desc').default('asc'),
});

module.exports = {
  createSchema: createCategorySchema,
  updateSchema: updateCategorySchema,
  querySchema: categoryQuerySchema,
};
