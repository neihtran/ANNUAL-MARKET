# Chợ Tươi Thông Mobile App

Mobile app cho nền tảng marketplace Chợ Tươi Thông.

## Công nghệ
- Flutter 3.x
- Dart
- BLoC/Cubit State Management
- Dio HTTP Client
- Material Design 3

## Cài đặt

```bash
cd mobile
flutter pub get
```

## Chạy

```bash
# Android Emulator
flutter run -d emulator-5554

# iOS Simulator
flutter run -d iPhone
```

## Tính năng

### Người mua (Buyer)
- Khám phá sản phẩm
- Tìm kiếm
- Xem đơn hàng
- Quản lý hồ sơ

### Người bán (Seller)
- Dashboard với thống kê
- Quản lý sản phẩm
- Quản lý đơn hàng
- Cài đặt cửa hàng

### Shipper
- Danh sách đơn có sẵn
- Đơn đang giao
- Lịch sử giao hàng
- Bản đồ (sắp ra mắt)

## Cấu hình

Thêm vào `launch.json` hoặc sử dụng `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3001/api/v1
```

## Màu sắc theo Role

- **Buyer**: Cam (#f97316)
- **Seller**: Xanh dương (#2563eb)
- **Shipper**: Xanh ngọc (#0d9488)
