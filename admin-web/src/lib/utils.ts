import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
  }).format(amount);
}

export function formatDate(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatDateShort(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
}

export function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

export function truncate(str: string, length: number): string {
  if (str.length <= length) return str;
  return str.slice(0, length) + '...';
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
  unpaid: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Chưa thanh toán' },
  paid: { bg: 'bg-green-100', text: 'text-green-800', label: 'Đã thanh toán' },
  refunded: { bg: 'bg-orange-100', text: 'text-orange-800', label: 'Đã hoàn tiền' },
};

export const USER_ROLE_COLORS: Record<string, { bg: string; text: string; label: string }> = {
  buyer: { bg: 'bg-pink-100', text: 'text-pink-800', label: 'Người mua' },
  seller: { bg: 'bg-blue-100', text: 'text-blue-800', label: 'Người bán' },
  shipper: { bg: 'bg-teal-100', text: 'text-teal-800', label: 'Shipper' },
  admin: { bg: 'bg-violet-100', text: 'text-violet-800', label: 'Admin' },
};

export const USER_STATUS_COLORS: Record<string, { bg: string; text: string; label: string }> = {
  active: { bg: 'bg-green-100', text: 'text-green-800', label: 'Hoạt động' },
  inactive: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Không hoạt động' },
  banned: { bg: 'bg-red-100', text: 'text-red-800', label: 'Bị khóa' },
  pending: { bg: 'bg-yellow-100', text: 'text-yellow-800', label: 'Chờ duyệt' },
};

export const CATEGORY_LABELS: Record<string, string> = {
  vegetables: 'Rau củ',
  fruits: 'Trái cây',
  meat: 'Thịt',
  seafood: 'Hải sản',
  eggs: 'Trứng',
  others: 'Khác',
};
