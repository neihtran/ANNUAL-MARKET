# Chợ Truyền Thống - Technical Specification

## 1. Project Overview

### Project Name
**Chợ Truyền Thống** - Nền tảng Marketplace 3 bên

### Core Functionality
Marketplace kết nối người mua (Buyer), người bán (Seller) và đơn vị vận chuyển (Shipper) với trải nghiệm mua sắm thực phẩm tươi sạch.

### Target Users
- **Buyer**: Người tiêu dùng mua thực phẩm tươi
- **Seller**: Chủ cửa hàng, trang trại bán sản phẩm
- **Shipper**: Đơn vị vận chuyển
- **Admin**: Quản lý hệ thống

---

## 2. System Architecture

### Tech Stack
```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend Layer                            │
├──────────────────┬──────────────────┬───────────────────────────┤
│   Admin Web      │   Mobile App     │   (Future) Buyer Web      │
│   Next.js 14      │   Flutter 3.x    │                           │
│   TypeScript      │   Dart           │                           │
└────────┬─────────┴────────┬─────────┴───────────────────────────┘
         │                   │
         ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                           │
│                   (Express.js Backend)                          │
│                   localhost:3001                                │
└────────┬──────────────────────────────────────────────┬────────┘
         │                                              │
         ▼                                              ▼
┌─────────────────────┐                    ┌─────────────────────────┐
│   MongoDB           │                    │   External Services     │
│   localhost:27017   │                    │   - Payment Gateway     │
│   chotruyenthong    │                    │   - Map Services         │
└─────────────────────┘                    └─────────────────────────┘
```

### Project Structure
```
d:/chotruyenthong/
├── backend/                    # Node.js + Express API
│   ├── src/
│   │   ├── config/            # Database, env configs
│   │   ├── controllers/       # Route handlers
│   │   ├── middlewares/       # Auth, validation, error handling
│   │   ├── models/            # MongoDB schemas
│   │   ├── routes/            # API routes
│   │   ├── services/          # Business logic
│   │   ├── utils/             # Helpers, constants
│   │   └── index.js           # Entry point
│   ├── package.json
│   └── .env
│
├── admin-web/                  # Next.js 14 Admin Dashboard
│   ├── src/
│   │   ├── app/               # App router pages
│   │   ├── components/       # UI components
│   │   ├── lib/               # Utilities, API client
│   │   └── types/             # TypeScript types
│   ├── package.json
│   └── next.config.js
│
└── mobile/                     # Flutter Mobile App
    ├── lib/
    │   ├── core/              # Config, theme, constants
    │   ├── data/              # Models, repositories
    │   ├── presentation/      # Screens, widgets, blocs
    │   └── main.dart
    ├── pubspec.yaml
    └── android/
```

---

## 3. Data Models (MongoDB)

### 3.1 User Model
```javascript
{
  _id: ObjectId,
  email: String (unique, required),
  password: String (hashed, required),
  fullName: String (required),
  phone: String (required),
  avatar: String (URL, optional),
  role: Enum ['buyer', 'seller', 'shipper', 'admin'],
  status: Enum ['active', 'inactive', 'banned', 'rejected'],
  isApproved: Boolean (false for seller/shipper until admin approves),
  documents: [{
    type: Enum ['cccd', 'driver_license', 'business_license'],
    url: String,
    uploadedAt: Date
  }],
  marketId: ObjectId (ref: Market, nullable),
  categoryIds: [ObjectId] (ref: Category),
  bankInfo: {
    bankName: String,
    accountNumber: String,
    accountName: String
  },
  // Seller rating fields
  sellerRating: Number (0-5, default: 0),
  sellerReviewCount: Number (default: 0),
  sellerQualityRating: Number (1-5, optional),
  sellerCommunicationRating: Number (1-5, optional),
  sellerDeliveryRating: Number (1-5, optional),
  // Shipper rating fields
  shipperRating: Number (0-5, default: 0),
  shipperReviewCount: Number (default: 0),
  shipperPunctualityRating: Number (1-5, optional),
  shipperAttitudeRating: Number (1-5, optional),
  shipperHandlingRating: Number (1-5, optional),
  createdAt: Date,
  updatedAt: Date
}
```

### Registration Requirements
| Role | Required Fields | Auto-approved |
|------|----------------|---------------|
| Buyer | email, password, fullName, phone | Yes (status=active, isApproved=true) |
| Seller | + marketId, categoryIds (min 1), documents (min 1, type=cccd/business_license) | No (status=inactive, isApproved=false) |
| Shipper | + documents (min 1, type=driver_license) | No (status=inactive, isApproved=false) |

### 3.2 Product Model
```javascript
{
  _id: ObjectId,
  sellerId: ObjectId (ref: User),
  name: String (required),
  description: String,
  category: Enum ['vegetables', 'fruits', 'meat', 'seafood', 'eggs', 'others'],
  images: [String] (URL array),
  price: Number (required, VND),
  unit: String ('kg', 'piece', 'bunch', etc.),
  stock: Number (required),
  minOrder: Number (default: 1),
  isOrganic: Boolean,
  isAvailable: Boolean,
  rating: Number (0-5),
  reviewCount: Number,
  createdAt: Date,
  updatedAt: Date
}
```

### 3.3 Order Model
```javascript
{
  _id: ObjectId,
  orderNumber: String (unique, auto-generated),
  buyerId: ObjectId (ref: User),
  sellerId: ObjectId (ref: User),
  shipperId: ObjectId (ref: User, nullable),
  items: [{
    productId: ObjectId,
    name: String,
    price: Number,
    quantity: Number,
    unit: String
  }],
  subtotal: Number,
  shippingFee: Number,
  total: Number,
  status: Enum [
    'pending',        // Chờ xác nhận
    'confirmed',     // Đã xác nhận
    'preparing',      // Đang chuẩn bị
    'ready',          // Sẵn sàng giao
    'picking_up',     // Đang lấy hàng
    'delivering',    // Đang giao
    'delivered',     // Đã giao
    'cancelled'      // Đã hủy
  ],
  paymentMethod: Enum ['cod', 'momo', 'vnpay'],
  paymentStatus: Enum ['unpaid', 'paid', 'refunded'],
  shippingAddress: {
    street: String,
    ward: String,
    district: String,
    city: String,
    coordinates: { lat: Number, lng: Number }
  },
  note: String,
  estimatedDelivery: Date,
  deliveredAt: Date,
  cancelledAt: Date,
  cancelReason: String,
  createdAt: Date,
  updatedAt: Date
}
```

### 3.4 Review Model (Product Review)
```javascript
{
  _id: ObjectId,
  orderId: ObjectId (ref: Order),
  productId: ObjectId (ref: Product),
  buyerId: ObjectId (ref: User),
  sellerId: ObjectId (ref: User),
  rating: Number (1-5),
  comment: String,
  images: [String],
  isVerified: Boolean,
  sellerReply: String,
  replyAt: Date,
  createdAt: Date
}
```

### 3.5 Seller Review Model
```javascript
{
  _id: ObjectId,
  orderId: ObjectId (ref: Order),
  buyerId: ObjectId (ref: User),
  sellerId: ObjectId (ref: User),
  rating: Number (1-5, required),
  aspects: {
    quality: Number (1-5, optional),
    communication: Number (1-5, optional),
    delivery: Number (1-5, optional),
  },
  comment: String,
  isVerified: Boolean,
  sellerReply: String,
  replyAt: Date,
  createdAt: Date
}
```

### 3.6 Shipper Review Model
```javascript
{
  _id: ObjectId,
  orderId: ObjectId (ref: Order),
  buyerId: ObjectId (ref: User),
  shipperId: ObjectId (ref: User),
  rating: Number (1-5, required),
  aspects: {
    punctuality: Number (1-5, optional),
    attitude: Number (1-5, optional),
    handling: Number (1-5, optional),
  },
  comment: String,
  isVerified: Boolean,
  createdAt: Date
}
```

### 3.7 Notification Model
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: User),
  title: String,
  body: String,
  type: Enum ['order', 'promotion', 'system'],
  data: Object (JSON payload),
  isRead: Boolean,
  createdAt: Date
}
```

---

## 4. API Endpoints

### Base URL: `http://localhost:3001/api/v1`

### 4.1 Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /auth/register | Đăng ký tài khoản |
| POST | /auth/login | Đăng nhập |
| POST | /auth/refresh | Refresh token |
| POST | /auth/logout | Đăng xuất |
| GET | /auth/me | Lấy thông tin user hiện tại |

### 4.2 Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /users | Danh sách users (admin) |
| GET | /users/:id | Chi tiết user |
| PUT | /users/:id | Cập nhật user |
| DELETE | /users/:id | Xóa user (admin) |
| PUT | /users/:id/status | Cập nhật trạng thái user |

### 4.3 Products
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /products | Danh sách sản phẩm |
| GET | /products/:id | Chi tiết sản phẩm |
| POST | /products | Tạo sản phẩm (seller) |
| PUT | /products/:id | Cập nhật sản phẩm |
| DELETE | /products/:id | Xóa sản phẩm |
| GET | /products/seller | Sản phẩm của seller |
| GET | /products/nearby | Sản phẩm gần đây |

**Query Parameters (GET /products):**
| Param | Type | Description |
|-------|------|-------------|
| keyword | string | Tìm kiếm theo tên/mô tả |
| categoryId | string | Lọc theo danh mục |
| marketId | string | Lọc theo chợ |
| minPrice | number | Giá tối thiểu |
| maxPrice | number | Giá tối đa |
| sortBy | string | Sắp xếp: createdAt, price, name |
| sortOrder | string | asc hoặc desc |
| isAvailable | boolean | Chỉ sản phẩm còn hàng |
| page | number | Trang |
| limit | number | Số lượng mỗi trang |

### 4.4 Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /orders | Danh sách đơn hàng |
| GET | /orders/:id | Chi tiết đơn hàng |
| POST | /orders | Tạo đơn hàng (buyer) |
| PUT | /orders/:id | Cập nhật đơn hàng |
| PUT | /orders/:id/status | Cập nhật trạng thái |
| PUT | /orders/:id/accept | Shipper nhận đơn (atomic) |
| PUT | /orders/:id/cancel | Hủy đơn hàng |
| GET | /orders/buyer | Đơn hàng của buyer |
| GET | /orders/seller | Đơn hàng của seller |
| GET | /orders/shipper/available | Đơn chờ shipper |
| GET | /orders/shipper/active | Đơn đang giao của shipper |

### 4.5 Reviews (Product Review)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /reviews | Tạo review sản phẩm |
| GET | /reviews/product/:productId | Reviews của sản phẩm |
| GET | /reviews/seller | Reviews của seller (seller) |
| POST | /reviews/:id/reply | Seller phản hồi review |
| DELETE | /reviews/:id | Xóa review (admin) |

### 4.6 Seller Reviews
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /seller-reviews | Buyer đánh giá seller |
| GET | /seller-reviews/me | Danh sách review của seller |
| POST | /seller-reviews/:id/reply | Seller phản hồi review |
| DELETE | /seller-reviews/:id | Xóa review (admin) |

### 4.7 Shipper Reviews
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /shipper-reviews | Buyer đánh giá shipper |
| GET | /shipper-reviews/me | Danh sách review của shipper |
| DELETE | /shipper-reviews/:id | Xóa review (admin) |

### 4.8 Dashboard (Admin)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /dashboard/stats | Thống kê tổng quan |
| GET | /dashboard/revenue | Doanh thu theo ngày |
| GET | /dashboard/orders | Đơn hàng theo trạng thái |

### 4.9 Reports (Admin)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /reports/export-report/pdf | Xuất báo cáo PDF (query: startDate, endDate) |
| GET | /reports/export-report/excel | Xuất báo cáo Excel (query: startDate, endDate) |
| GET | /reports/export-activity-log/pdf | Xuất nhật ký hoạt động PDF |
| GET | /reports/export-activity-log/excel | Xuất nhật ký hoạt động Excel |
| GET | /reports/data | Lấy dữ liệu báo cáo (query: startDate, endDate) |

### 4.10 Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /notifications | Danh sách thông báo |
| PUT | /notifications/:id/read | Đánh dấu đã đọc |
| PUT | /notifications/read-all | Đánh dấu đã đọc tất cả |

---

## 5. API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": {
    "code": "VALIDATION_ERROR",
    "details": [ ... ]
  }
}
```

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict (duplicate)
- `500` - Internal Server Error

---

## 6. UI/UX Specification

### 6.1 Admin Web Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Primary Green | #16a34a | Primary buttons, active states |
| Primary Dark | #15803d | Hover states |
| White | #ffffff | Backgrounds, cards |
| Light Gray | #f8fafc | Page background |
| Gray 100 | #f1f5f9 | Borders, dividers |
| Gray 500 | #64748b | Secondary text |
| Gray 900 | #0f172a | Primary text |
| Success | #22c55e | Success states |
| Warning | #f59e0b | Warning states |
| Error | #ef4444 | Error states |

### 6.2 Mobile App Color Scheme

**Buyer Theme (Orange)**
| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #f97316 | Primary buttons, headers |
| Primary Dark | #ea580c | Hover |
| Surface | #fff7ed | Cards, backgrounds |
| On Primary | #ffffff | Text on primary |

**Seller Theme (Blue)**
| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #2563eb | Primary buttons, headers |
| Primary Dark | #1d4ed8 | Hover |
| Surface | #eff6ff | Cards, backgrounds |
| On Primary | #ffffff | Text on primary |

**Shipper Theme (Teal)**
| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #0d9488 | Primary buttons, headers |
| Primary Dark | #0f766e | Hover |
| Surface | #f0fdfa | Cards, backgrounds |
| On Primary | #ffffff | Text on primary |

### 6.3 Typography
- **Admin Web**: Inter font (system fallback: -apple-system, sans-serif)
- **Mobile**: Roboto (default Material)

### 6.4 Spacing System
```
4px - xs
8px - sm
16px - md
24px - lg
32px - xl
48px - 2xl
```

---

## 7. State Management

### Admin Web (Next.js)
- React Context for auth state
- TanStack Query for server state
- Local state for UI

### Mobile (Flutter)
- BLoC/Cubit pattern
- States: `Initial`, `Loading`, `Success<T>`, `Failure`

---

## 8. Security Considerations

### Authentication
- JWT tokens with 7-day expiry
- Refresh tokens with 30-day expiry
- Password hashing with bcrypt (10 rounds)

### Authorization
- Role-based access control (RBAC)
- Middleware validation on all protected routes

### Validation
- Backend: Joi schema validation
- Admin Web: Zod schema validation
- Mobile: Flutter form validation

---

## 9. Environment Variables

### Backend (.env)
```
PORT=3001
MONGODB_URI=mongodb://localhost:27017/chotruyenthong
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-refresh-secret-key-change-in-production
NODE_ENV=development
CORS_ORIGIN=*
```

### Admin Web
```javascript
NEXT_PUBLIC_API_URL=http://localhost:3001/api/v1
```

### Mobile API Configuration
```
// Default: uses device IP (configurable at runtime via Settings button on login screen)
Server default IP: 192.168.1.26 (configurable)

// Runtime server switch: Tap "Server" button on login screen → enter new IP:port
// Server URL is persisted in FlutterSecureStorage (survives app restart)

// --dart-define: Override server URL at compile time
API_BASE_URL=http://10.0.2.2:3001/api/v1
// For iOS simulator: http://localhost:3001/api/v1
```

---

## 10. Implementation Priorities

### Phase 1: Backend Foundation
1. Project setup, MongoDB connection
2. User model & auth endpoints
3. Product model & CRUD
4. Order model & status flow
5. Dashboard analytics

### Phase 2: Admin Web
1. Next.js setup with Shadcn/ui
2. Authentication flow
3. Dashboard with charts
4. User management
5. Product management
6. Order management

### Phase 3: Mobile App
1. Flutter project setup
2. Buyer flow (browse, cart, order)
3. Seller flow (manage products, orders)
4. Shipper flow (accept, deliver)

---

## 11. Test Scenarios

### Race Condition Test - Shipper Accept Order
```
1. Order created with shipperId: null
2. Shipper A taps "Accept" at T+0
3. Shipper B taps "Accept" at T+0.5
4. Only Shipper A should succeed
5. Order.shipperId should be Shipper A
6. Shipper B should receive error
```

---

*Document Version: 1.1*
*Last Updated: 2026-06-11*
