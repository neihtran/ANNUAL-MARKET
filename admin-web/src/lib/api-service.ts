import { apiClient, PaginatedResult } from './api';
import {
  User,
  Market,
  Category,
  Product,
  Order,
  DashboardStats,
  RevenueData,
  PaginationInfo,
  Notification,
} from '@/types';

// NOTE: api.ts already sets baseURL = /api/v1, so use empty prefix here
const PREFIX = '';

// Auth
export const authApi = {
  login: (data: { email: string; password: string }) =>
    apiClient.post<{ user: User; accessToken: string; refreshToken: string }>(
      `${PREFIX}/auth/login`,
      data
    ),

  register: (data: {
    email: string;
    password: string;
    fullName: string;
    phone: string;
    role?: string;
    marketId?: string;
    categoryIds?: string[];
  }) =>
    apiClient.post<{ user: User; accessToken: string; refreshToken: string }>(
      `${PREFIX}/auth/register`,
      data
    ),

  getMe: () => apiClient.get<User>(`${PREFIX}/auth/me`),

  logout: () => apiClient.post<{ message: string }>(`${PREFIX}/auth/logout`),
};

// Admin Users
export const adminUserApi = {
  getAll: (params?: { page?: number; limit?: number; role?: string; isApproved?: boolean; search?: string; marketId?: string }) =>
    apiClient.get<{ users: User[]; pagination: PaginationInfo }>(`${PREFIX}/admin/users`, params as Record<string, unknown>),

  getById: (id: string) => apiClient.get<{ user: User }>(`${PREFIX}/admin/users/${id}`),

  create: (data: { email: string; password: string; fullName: string; phone: string; role: string; marketId?: string | null }) =>
    apiClient.post<{ user: User }>(`${PREFIX}/admin/users`, data),

  approve: (id: string) =>
    apiClient.patch<{ user: User }>(`${PREFIX}/admin/users/${id}/approve`),

  reject: (id: string, reason: string) =>
    apiClient.patch<{ user: User }>(`${PREFIX}/admin/users/${id}/reject`, { reason }),

  ban: (id: string) =>
    apiClient.patch<{ user: User }>(`${PREFIX}/admin/users/${id}/ban`),

  unban: (id: string) =>
    apiClient.patch<{ user: User }>(`${PREFIX}/admin/users/${id}/unban`),

  delete: (id: string) =>
    apiClient.delete<null>(`${PREFIX}/admin/users/${id}`),
};

// Admin Markets
export const adminMarketApi = {
  getAll: (params?: { page?: number; limit?: number; search?: string; isActive?: boolean }) =>
    apiClient.get<{ markets: Market[]; pagination: PaginationInfo }>(`${PREFIX}/admin/markets`, params as Record<string, unknown>),

  getById: (id: string) => apiClient.get<{ market: Market }>(`${PREFIX}/admin/markets/${id}`),

  create: (data: Partial<Market>) =>
    apiClient.post<{ market: Market }>(`${PREFIX}/admin/markets`, data),

  update: (id: string, data: Partial<Market>) =>
    apiClient.put<{ market: Market }>(`${PREFIX}/admin/markets/${id}`, data),

  toggleActive: (id: string) =>
    apiClient.patch<{ market: Market }>(`${PREFIX}/admin/markets/${id}/toggle-active`),

  delete: (id: string) =>
    apiClient.delete<null>(`${PREFIX}/admin/markets/${id}`),
};

// Admin Categories
export const adminCategoryApi = {
  getAll: (params?: { page?: number; limit?: number; search?: string; isActive?: boolean }) =>
    apiClient.get<{ categories: Category[]; pagination: PaginationInfo }>(`${PREFIX}/admin/categories`, params as Record<string, unknown>),

  getTree: () =>
    apiClient.get<{ categories: Category[] }>(`${PREFIX}/admin/categories/tree`),

  getById: (id: string) => apiClient.get<{ category: Category }>(`${PREFIX}/admin/categories/${id}`),

  create: (data: Partial<Category>) =>
    apiClient.post<{ category: Category }>(`${PREFIX}/admin/categories`, data),

  update: (id: string, data: Partial<Category>) =>
    apiClient.put<{ category: Category }>(`${PREFIX}/admin/categories/${id}`, data),

  toggleActive: (id: string) =>
    apiClient.patch<{ category: Category }>(`${PREFIX}/admin/categories/${id}/toggle-active`),

  delete: (id: string) =>
    apiClient.delete<null>(`${PREFIX}/admin/categories/${id}`),
};

// Admin Products
export const adminProductApi = {
  getAll: (params?: { page?: number; limit?: number; search?: string; categoryId?: string; marketId?: string; isAvailable?: boolean }) =>
    apiClient.get<{ products: Product[]; pagination: PaginationInfo }>(`${PREFIX}/admin/products`, params as Record<string, unknown>),

  getById: (id: string) => apiClient.get<{ product: Product }>(`${PREFIX}/admin/products/${id}`),

  create: (data: Partial<Product>) =>
    apiClient.post<{ product: Product }>(`${PREFIX}/admin/products`, data),

  update: (id: string, data: Partial<Product>) =>
    apiClient.put<{ product: Product }>(`${PREFIX}/admin/products/${id}`, data),

  toggleAvailability: (id: string) =>
    apiClient.patch<{ product: Product }>(`${PREFIX}/admin/products/${id}/toggle-availability`),

  delete: (id: string) =>
    apiClient.delete<null>(`${PREFIX}/admin/products/${id}`),
};

// Products (public)
export const productApi = {
  getAll: (params?: { page?: number; limit?: number; search?: string; categoryId?: string; marketId?: string }) =>
    apiClient.get<{ products: Product[]; pagination: PaginationInfo }>(`${PREFIX}/products`, params as Record<string, unknown>),

  getById: (id: string) => apiClient.get<{ product: Product }>(`${PREFIX}/products/${id}`),

  create: (data: Partial<Product>) =>
    apiClient.post<{ product: Product }>(`${PREFIX}/products`, data),

  update: (id: string, data: Partial<Product>) =>
    apiClient.put<{ product: Product }>(`${PREFIX}/products/${id}`, data),

  delete: (id: string) =>
    apiClient.delete<null>(`${PREFIX}/products/${id}`),
};

// Orders
export const orderApi = {
  getAll: async (params?: { page?: number; limit?: number; status?: string; search?: string }): Promise<{ orders: Order[]; pagination?: PaginationInfo }> => {
    const response = await apiClient.getWithPagination<Order[] | { orders?: Order[] }>(`${PREFIX}/orders`, params as Record<string, unknown>);
    const rawData = response.data;
    const orders = Array.isArray(rawData)
      ? rawData
      : Array.isArray(rawData?.orders)
        ? rawData.orders
        : [];

    return {
      orders,
      pagination: response.pagination,
    };
  },

  getById: (id: string) => apiClient.get<{ order: Order }>(`${PREFIX}/orders/${id}`),

  updateStatus: (id: string, status: string, note?: string) =>
    apiClient.patch<{ order: Order }>(`${PREFIX}/orders/${id}/status`, { status, note }),

  cancel: (id: string, reason?: string) =>
    apiClient.patch<{ order: Order }>(`${PREFIX}/orders/${id}/cancel`, { reason }),
};

// Dashboard
export const dashboardApi = {
  getStats: () => apiClient.get<DashboardStats>(`${PREFIX}/dashboard/stats`),

  getRevenueByDay: (days?: number) =>
    apiClient.get<RevenueData[]>(`${PREFIX}/dashboard/revenue`, { days } as Record<string, unknown>),

  getOrdersByStatus: () =>
    apiClient.get<Record<string, number>>(`${PREFIX}/dashboard/orders`),
};

// Notifications
export const notificationApi = {
  getAll: (params?: { limit?: number }) =>
    apiClient.get<{ notifications: Notification[]; unreadCount: number }>(`${PREFIX}/notifications`, params as Record<string, unknown>),

  markAsRead: (id: string) =>
    apiClient.patch<Notification>(`${PREFIX}/notifications/${id}/read`),

  markAllAsRead: () =>
    apiClient.put<{ message: string }>(`${PREFIX}/notifications/read-all`),
};

// Reports
export const reportApi = {
  exportReport: async (startDate: string, endDate: string, format: 'pdf' | 'excel') => {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001/api/v1'}/reports/export-report/${format}?startDate=${startDate}&endDate=${endDate}`,
      {
        headers: {
          Authorization: `Bearer ${document.cookie
            .split('; ')
            .find(row => row.startsWith('accessToken='))
            ?.split('=')[1] || ''}`,
        },
      }
    );
    if (!response.ok) throw new Error('Export failed');
    return response.blob();
  },

  exportActivityLog: async (format: 'pdf' | 'excel') => {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001/api/v1'}/reports/export-activity-log/${format}`,
      {
        headers: {
          Authorization: `Bearer ${document.cookie
            .split('; ')
            .find(row => row.startsWith('accessToken='))
            ?.split('=')[1] || ''}`,
        },
      }
    );
    if (!response.ok) throw new Error('Export failed');
    return response.blob();
  },
};
