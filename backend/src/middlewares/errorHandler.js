const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
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

  if (err.name === 'CastError') {
    return res.status(400).json({
      success: false,
      message: 'ID không hợp lệ',
      error: {
        code: 'INVALID_ID',
      },
    });
  }

  if (err.code === 11000) {
    const field = Object.keys(err.keyPattern)[0];
    return res.status(409).json({
      success: false,
      message: `${field} đã tồn tại trong hệ thống`,
      error: {
        code: 'DUPLICATE_ERROR',
        field: field,
      },
    });
  }

  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Token không hợp lệ',
      error: {
        code: 'INVALID_TOKEN',
      },
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token đã hết hạn',
      error: {
        code: 'TOKEN_EXPIRED',
      },
    });
  }

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Lỗi server nội bộ';

  res.status(statusCode).json({
    success: false,
    message: message,
    error: {
      code: err.code || 'INTERNAL_ERROR',
    },
  });
};

const notFound = (req, res) => {
  res.status(404).json({
    success: false,
    message: `Không tìm thấy: ${req.method} ${req.originalUrl}`,
    error: {
      code: 'NOT_FOUND',
    },
  });
};

class AppError extends Error {
  constructor(message, statusCode, code) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

class BadRequestError extends AppError {
  constructor(message = 'Yêu cầu không hợp lệ') {
    super(message, 400, 'BAD_REQUEST');
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Không có quyền truy cập') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Bị cấm truy cập') {
    super(message, 403, 'FORBIDDEN');
  }
}

class NotFoundError extends AppError {
  constructor(message = 'Không tìm thấy tài nguyên') {
    super(message, 404, 'NOT_FOUND');
  }
}

class ConflictError extends AppError {
  constructor(message = 'Xung đột dữ liệu') {
    super(message, 409, 'CONFLICT');
  }
}

module.exports = {
  errorHandler,
  notFound,
  AppError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  NotFoundError,
  ConflictError,
};
