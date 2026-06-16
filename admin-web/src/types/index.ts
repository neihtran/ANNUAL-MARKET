export interface User {
  _id: string;
  email: string;
  fullName: string;
  phone: string;
  avatar?: string;
  role: 'buyer' | 'seller' | 'shipper' | 'admin';
  isApproved: boolean;
  isVerified: boolean;
  rejectedReason?: string;
  status: 'active' | 'inactive' | 'banned' | 'rejected';
  marketId?: string | Market;
  categoryIds?: Array<string | Category>;
  documents?: Array<{
    type: 'cccd' | 'driver_license' | 'business_license';
    url: string;
  }>;
  bankInfo?: {
    bankName?: string;
    accountNumber?: string;
    accountName?: string;
  };
  location?: { lat: number; lng: number };
  createdAt: string;
  updatedAt: string;
}

export interface Market {
  _id: string;
  name: string;
  address: string;
  district?: string;
  location?: {
    lat: number;
    lng: number;
  };
  phone?: string;
  images: string[];
  openTime: string;
  closeTime: string;
  is24h?: boolean;
  description?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Category {
  _id: string;
  name: string;
  icon?: string;
  description?: string;
  parentId?: string | null;
  isActive: boolean;
  sortOrder?: number;
  children?: Category[];
  createdAt: string;
  updatedAt: string;
}

export interface Shop {
  _id: string;
  sellerId: string | User;
  marketId: string | Market;
  categoryId: string | Category;
  name: string;
  description?: string;
  avatar?: string;
  coverImage?: string;
  rating: number;
  totalReviews: number;
  isOpen: boolean;
  isApproved: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Product {
  _id: string;
  shopId: string | Shop;
  sellerId: string | User;
  marketId: string | Market;
  categoryId: string | Category;
  name: string;
  description?: string;
  images: string[];
  price: number;
  unit: 'kg' | 'bó' | 'con' | 'cái' | 'lít' | 'lon' | 'gói' | 'hộp' | 'bịch' | 'vỉ' | 'phần';
  stock: number;
  minOrder?: number;
  isAvailable: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface OrderItem {
  productId: string | Product;
  shopId: string | Shop;
  shopName: string;
  name: string;
  imageUrl?: string;
  price: number;
  quantity: number;
  unit: string;
}

export interface DeliveryAddress {
  address: string;
  lat: number;
  lng: number;
  contactName: string;
  contactPhone: string;
}

export interface Order {
  _id: string;
  orderNumber: string;
  buyerId: string | User;
  marketId: string | Market;
  items: OrderItem[];
  shipperId?: string | User;
  deliveryAddress: DeliveryAddress;
  subtotal: number;
  shippingFee: number;
  discount: number;
  total: number;
  status: 'pending' | 'finding_shipper' | 'shipper_accepted' | 'heading_to_market' | 'arrived_at_market' | 'ready_for_pickup' | 'seller_handed_over' | 'picked_up' | 'shopping' | 'delivering' | 'delivered' | 'cancelled';
  paymentMethod: 'cod' | 'vnpay' | 'momo';
  paymentStatus: 'unpaid' | 'paid' | 'refunded';
  note?: string;
  cancelReason?: string;
  cancelBy?: 'buyer' | 'seller' | 'shipper' | 'admin' | '';
  shippingDistance?: number;
  estimatedMinutes?: number;
  confirmImageUrl?: string;
  deliveredAt?: string;
  statusHistory?: Array<{ status: string; timestamp: string; note?: string }>;
  createdAt: string;
  updatedAt: string;
}

export interface Review {
  _id: string;
  orderId: string;
  productId: string | Product;
  shopId: string | Shop;
  buyerId: string | User;
  rating: number;
  comment?: string;
  images?: string[];
  sellerReply?: string;
  createdAt: string;
}

export interface DashboardStats {
  orders: {
    total: number;
    today: number;
    thisWeek: number;
    thisMonth: number;
    delivered: number;
    pending: number;
    cancelled: number;
  };
  users: {
    total: number;
    active: number;
    newToday: number;
    newThisWeek: number;
    newThisMonth: number;
    byRole: Record<string, number>;
  };
  products: {
    total: number;
    available: number;
  };
  revenue: {
    total: number;
    today: number;
    thisWeek: number;
    thisMonth: number;
  };
  markets?: {
    total: number;
    active: number;
  };
  shops?: {
    total: number;
    approved: number;
  };
  shippers: {
    active: number;
  };
}

export interface RevenueData {
  date: string;
  revenue: number;
  orders: number;
}

export interface PaginationParams {
  page?: number;
  limit?: number;
}

export interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Notification {
  _id: string;
  userId: string;
  title: string;
  body: string;
  type: string;  // Dynamic type from backend — use string to avoid narrowing issues
  referenceId?: string;
  data?: Record<string, unknown>;
  isRead: boolean;
  createdAt: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  pagination?: PaginationInfo;
}

export const ORDER_STATUS_COLORS: Record<string, { bg: string; text: string; label: string }> = {
  pending: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Chờ xử lý' },
  finding_shipper: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'Đang tìm shipper' },
  shipper_accepted: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'Shipper đã nhận' },
  shopping: { bg: 'bg-purple-100', text: 'text-purple-800', label: 'Đang mua hàng' },
  delivering: { bg: 'bg-orange-100', text: 'text-orange-800', label: 'Đang giao' },
  delivered: { bg: 'bg-green-100', text: 'text-green-800', label: 'Đã giao' },
  cancelled: { bg: 'bg-red-100', text: 'text-red-800', label: 'Đã hủy' },
};

export const PAYMENT_STATUS_COLORS: Record<string, { bg: string; text: string; label: string }> = {
  unpaid: { bg: 'bg-red-100', text: 'text-red-800', label: 'Chưa thanh toán' },
  paid: { bg: 'bg-green-100', text: 'text-green-800', label: 'Đã thanh toán' },
  refunded: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Đã hoàn tiền' },
};

export const CATEGORY_LABELS: Record<string, string> = {
  vegetables: 'Rau củ',
  fruits: 'Trái cây',
  meat: 'Thịt',
  seafood: 'Hải sản',
  eggs: 'Trứng',
  others: 'Khác',
};
