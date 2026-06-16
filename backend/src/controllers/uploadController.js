const { successResponse, errorResponse } = require('../utils/response');

exports.uploadImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return errorResponse(res, 'Không có file được tải lên', 400);
    }

    // Cloudinary returns secure_url
    const url = req.file.path || req.file.secure_url;

    return successResponse(res, {
      url: url,
      filename: req.file.filename,
      originalName: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
    }, 'Tải ảnh lên thành công', 201);
  } catch (error) {
    next(error);
  }
};

exports.uploadImages = async (req, res, next) => {
  try {
    if (!req.files || req.files.length === 0) {
      return errorResponse(res, 'Không có file nào được tải lên', 400);
    }

    const images = req.files.map(file => {
      const url = file.path || file.secure_url;
      return {
        url: url,
        filename: file.filename,
        originalName: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
      };
    });

    return successResponse(res, { images }, `Tải ${images.length} ảnh lên thành công`, 201);
  } catch (error) {
    next(error);
  }
};
