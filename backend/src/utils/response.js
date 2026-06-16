const config = require('../config/constants');

const successResponse = (res, data, message = 'Thành công', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

const errorResponse = (res, message = 'Đã xảy ra lỗi', statusCode = 500, errorCode = 'ERROR') => {
  return res.status(statusCode).json({
    success: false,
    message,
    error: { code: errorCode },
  });
};

const buildPaginationResponse = (total, page, limit) => {
  return {
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit),
  };
};

const getPaginationParams = (query) => {
  const page = parseInt(query.page) || config.pagination.defaultPage;
  const limit = parseInt(query.limit) || config.pagination.defaultLimit;
  const skip = (page - 1) * limit;
  
  return {
    page,
    limit: Math.min(limit, config.pagination.maxLimit),
    skip,
  };
};

const sendSuccess = successResponse;
const sendCreated = (res, data, message = 'Tạo thành công') => successResponse(res, data, message, 201);
const sendPaginated = (res, data, pagination, message = 'Thành công') => {
  return res.status(200).json({
    success: true,
    message,
    data,
    pagination,
  });
};
const sendError = (res, message, errorCode = 'ERROR', statusCode = 500) => errorResponse(res, message, statusCode, errorCode);

module.exports = {
  successResponse,
  errorResponse,
  buildPaginationResponse,
  getPaginationParams,
  sendSuccess,
  sendCreated,
  sendPaginated,
  sendError,
};
