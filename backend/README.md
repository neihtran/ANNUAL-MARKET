# Chợ Tươi Thông Backend

Backend API cho nền tảng marketplace Chợ Tươi Thông.

## Công nghệ
- Node.js + Express.js
- MongoDB + Mongoose
- JWT Authentication
- Joi Validation
- Swagger Documentation

## Cài đặt

```bash
cd backend
npm install
```

## Chạy

```bash
# Development
npm run dev

# Production
npm start
```

## Environment Variables

Tạo file `.env` trong thư mục backend:

```env
PORT=3001
MONGODB_URI=mongodb://localhost:27017/chotruyenthong
JWT_SECRET=your-super-secret-jwt-key
JWT_REFRESH_SECRET=your-refresh-secret-key
NODE_ENV=development
CORS_ORIGIN=*
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Đăng ký
- `POST /api/v1/auth/login` - Đăng nhập
- `POST /api/v1/auth/refresh` - Làm mới token
- `GET /api/v1/auth/me` - Lấy thông tin user

### Products
- `GET /api/v1/products` - Danh sách sản phẩm
- `GET /api/v1/products/:id` - Chi tiết sản phẩm
- `POST /api/v1/products` - Tạo sản phẩm (seller)
- `PUT /api/v1/products/:id` - Cập nhật sản phẩm
- `DELETE /api/v1/products/:id` - Xóa sản phẩm

### Orders
- `GET /api/v1/orders` - Danh sách đơn hàng
- `GET /api/v1/orders/:id` - Chi tiết đơn hàng
- `POST /api/v1/orders` - Tạo đơn hàng
- `PUT /api/v1/orders/:id/status` - Cập nhật trạng thái
- `PUT /api/v1/orders/:id/accept` - Shipper nhận đơn

### Dashboard (Admin)
- `GET /api/v1/dashboard/stats` - Thống kê tổng quan

## Documentation

Swagger UI: http://localhost:3001/api-docs
