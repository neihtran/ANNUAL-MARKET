const Joi = require('joi');

const validate = (schema) => {
  return (req, res, next) => {
    // Skip validation if no schema provided
    if (!schema) return next();

    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Dữ liệu không hợp lệ',
        error: {
          code: 'VALIDATION_ERROR',
          details: errors,
        },
      });
    }

    req.body = value;
    next();
  };
};

const validateQuery = (schema) => {
  return (req, res, next) => {
    // Skip validation if no schema provided
    if (!schema) return next();

    const { error, value } = schema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Tham số truy vấn không hợp lệ',
        error: {
          code: 'VALIDATION_ERROR',
          details: errors,
        },
      });
    }

    req.query = value;
    next();
  };
};

const validateParams = (schema) => {
  return (req, res, next) => {
    // Skip validation if no schema provided
    if (!schema) return next();

    const { error, value } = schema.validate(req.params, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Tham số URL không hợp lệ',
        error: {
          code: 'VALIDATION_ERROR',
          details: errors,
        },
      });
    }

    req.params = value;
    next();
  };
};

module.exports = {
  validate,
  validateQuery,
  validateParams,
};
