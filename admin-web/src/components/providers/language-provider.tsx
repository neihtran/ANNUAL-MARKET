'use client';

import * as React from 'react';

type Language = 'vi' | 'en';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: string) => string;
}

const LanguageContext = React.createContext<LanguageContextType | undefined>(undefined);

const translations: Record<Language, Record<string, string>> = {
  vi: {
    // General
    'app.title': 'Chợ Truyền Thông',
    'common.save': 'Lưu thay đổi',
    'common.cancel': 'Hủy',
    'common.delete': 'Xóa',
    'common.edit': 'Sửa',
    'common.add': 'Thêm',
    'common.search': 'Tìm kiếm',
    'common.loading': 'Đang tải...',
    'common.noData': 'Không có dữ liệu',
    
    // Markets
    'markets.title': 'Quản lý Chợ',
    'markets.add': 'Thêm chợ mới',
    'markets.name': 'Tên chợ',
    'markets.address': 'Địa chỉ',
    'markets.location': 'Vị trí',
    'markets.clickToSelect': 'Nhấn vào bản đồ để chọn vị trí',
    'markets.openTime': 'Giờ mở cửa',
    'markets.closeTime': 'Giờ đóng cửa',
    'markets.description': 'Mô tả',
    'markets.active': 'Hoạt động',
    'markets.inactive': 'Không hoạt động',
    
    // Products
    'products.title': 'Sản phẩm',
    'products.add': 'Thêm sản phẩm',
    'products.name': 'Tên sản phẩm',
    'products.price': 'Giá',
    'products.stock': 'Tồn kho',
    'products.category': 'Danh mục',
    'products.available': 'Còn hàng',
    'products.unavailable': 'Hết hàng',
    
    // Users
    'users.title': 'Người dùng',
    'users.add': 'Thêm người dùng',
    'users.name': 'Họ tên',
    'users.email': 'Email',
    'users.phone': 'Số điện thoại',
    'users.role': 'Vai trò',
    'users.status': 'Trạng thái',
    'users.buyer': 'Người mua',
    'users.seller': 'Người bán',
    'users.shipper': 'Shipper',
    'users.admin': 'Admin',
    'users.active': 'Hoạt động',
    'users.inactive': 'Không hoạt động',
    'users.banned': 'Bị khóa',
    'users.pending': 'Chờ duyệt',
    'users.approve': 'Phê duyệt',
    'users.reject': 'Từ chối',
    'users.ban': 'Khóa',
    'users.unban': 'Mở khóa',
    
    // Settings
    'settings.title': 'Cài đặt',
    'settings.appearance': 'Giao diện',
    'settings.darkMode': 'Chế độ tối',
    'settings.darkModeDesc': 'Bật giao diện màu tối',
    'settings.language': 'Ngôn ngữ',
    'settings.notifications': 'Thông báo',
    'settings.emailNotif': 'Thông báo qua email',
    'settings.pushNotif': 'Thông báo đẩy',
    'settings.orderUpdates': 'Cập nhật đơn hàng',
    'settings.promotions': 'Khuyến mãi',
    'settings.security': 'Bảo mật',
    'settings.changePassword': 'Đổi mật khẩu',
    'settings.currentPassword': 'Mật khẩu hiện tại',
    'settings.newPassword': 'Mật khẩu mới',
    'settings.confirmPassword': 'Xác nhận mật khẩu mới',
    
    // Pagination
    'pagination.showing': 'Hiển thị',
    'pagination.of': 'của',
    'pagination.prev': 'Trước',
    'pagination.next': 'Sau',
    
    // Messages
    'msg.saveSuccess': 'Lưu thành công',
    'msg.saveError': 'Lưu thất bại',
    'msg.deleteConfirm': 'Bạn có chắc muốn xóa?',
    'msg.approveSuccess': 'Phê duyệt thành công',
    'msg.rejectSuccess': 'Từ chối thành công',
    'msg.banSuccess': 'Khóa tài khoản thành công',
    'msg.unbanSuccess': 'Mở khóa tài khoản thành công',
  },
  en: {
    // General
    'app.title': 'Traditional Market',
    'common.save': 'Save Changes',
    'common.cancel': 'Cancel',
    'common.delete': 'Delete',
    'common.edit': 'Edit',
    'common.add': 'Add',
    'common.search': 'Search',
    'common.loading': 'Loading...',
    'common.noData': 'No data',
    
    // Markets
    'markets.title': 'Manage Markets',
    'markets.add': 'Add New Market',
    'markets.name': 'Market Name',
    'markets.address': 'Address',
    'markets.location': 'Location',
    'markets.clickToSelect': 'Click on the map to select location',
    'markets.openTime': 'Opening Time',
    'markets.closeTime': 'Closing Time',
    'markets.description': 'Description',
    'markets.active': 'Active',
    'markets.inactive': 'Inactive',
    
    // Products
    'products.title': 'Products',
    'products.add': 'Add Product',
    'products.name': 'Product Name',
    'products.price': 'Price',
    'products.stock': 'Stock',
    'products.category': 'Category',
    'products.available': 'Available',
    'products.unavailable': 'Out of Stock',
    
    // Users
    'users.title': 'Users',
    'users.add': 'Add User',
    'users.name': 'Full Name',
    'users.email': 'Email',
    'users.phone': 'Phone',
    'users.role': 'Role',
    'users.status': 'Status',
    'users.buyer': 'Buyer',
    'users.seller': 'Seller',
    'users.shipper': 'Shipper',
    'users.admin': 'Admin',
    'users.active': 'Active',
    'users.inactive': 'Inactive',
    'users.banned': 'Banned',
    'users.pending': 'Pending',
    'users.approve': 'Approve',
    'users.reject': 'Reject',
    'users.ban': 'Ban',
    'users.unban': 'Unban',
    
    // Settings
    'settings.title': 'Settings',
    'settings.appearance': 'Appearance',
    'settings.darkMode': 'Dark Mode',
    'settings.darkModeDesc': 'Enable dark theme',
    'settings.language': 'Language',
    'settings.notifications': 'Notifications',
    'settings.emailNotif': 'Email Notifications',
    'settings.pushNotif': 'Push Notifications',
    'settings.orderUpdates': 'Order Updates',
    'settings.promotions': 'Promotions',
    'settings.security': 'Security',
    'settings.changePassword': 'Change Password',
    'settings.currentPassword': 'Current Password',
    'settings.newPassword': 'New Password',
    'settings.confirmPassword': 'Confirm New Password',
    
    // Pagination
    'pagination.showing': 'Showing',
    'pagination.of': 'of',
    'pagination.prev': 'Previous',
    'pagination.next': 'Next',
    
    // Messages
    'msg.saveSuccess': 'Saved successfully',
    'msg.saveError': 'Save failed',
    'msg.deleteConfirm': 'Are you sure you want to delete?',
    'msg.approveSuccess': 'Approved successfully',
    'msg.rejectSuccess': 'Rejected successfully',
    'msg.banSuccess': 'Account banned successfully',
    'msg.unbanSuccess': 'Account unbanned successfully',
  },
};

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [language, setLanguage] = React.useState<Language>(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('language');
      return (saved as Language) || 'vi';
    }
    return 'vi';
  });

  React.useEffect(() => {
    localStorage.setItem('language', language);
    document.documentElement.lang = language;
  }, [language]);

  const t = React.useCallback((key: string): string => {
    return translations[language][key] || key;
  }, [language]);

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = React.useContext(LanguageContext);
  if (context === undefined) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
}
