'use client';

import * as React from 'react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { adminCategoryApi, adminProductApi } from '@/lib/api-service';
import { Category, Product, PaginationInfo } from '@/types';
import { formatCurrency, formatDateShort } from '@/lib/utils';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  ImageIcon,
  Package,
  AlertCircle,
  RefreshCw,
  ToggleLeft,
  ToggleRight,
} from 'lucide-react';
import { toast } from '@/hooks/use-toast';

export default function ProductsPage() {
  const [categories, setCategories] = React.useState<Category[]>([]);
  const [products, setProducts] = React.useState<Product[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [search, setSearch] = React.useState('');
  const [categoryFilter, setCategoryFilter] = React.useState('__none__');
  const [page, setPage] = React.useState(1);
  const [totalPages, setTotalPages] = React.useState(1);
  const [total, setTotal] = React.useState(0);
  const [isDialogOpen, setIsDialogOpen] = React.useState(false);
  const [editingProduct, setEditingProduct] = React.useState<Product | null>(null);
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [formError, setFormError] = React.useState<string | null>(null);
  const [formData, setFormData] = React.useState({
    name: '',
    categoryId: '__none__',
    price: '',
    unit: 'kg',
    stock: '',
    minOrder: '1',
    description: '',
  });

  const fetchCategories = React.useCallback(async () => {
    try {
      const data = await adminCategoryApi.getAll({ limit: 100 });
      setCategories((data as any)?.categories || []);
    } catch (err) {
      console.error('Error fetching categories:', err);
    }
  }, []);

  const fetchProducts = React.useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await adminProductApi.getAll({
        page,
        limit: 10,
        search: search || undefined,
        categoryId: categoryFilter === '__none__' ? undefined : categoryFilter || undefined,
      });

      const payload = (data as any);
      setProducts(payload?.products || []);

      const pagination = payload?.pagination;
      if (pagination) {
        setTotalPages(pagination.totalPages || 1);
        setTotal(pagination.total || 0);
      }
    } catch (err: unknown) {
      const error = err as { response?: { data?: { message?: string } }; message?: string };
      console.error('Error fetching products:', err);
      setError(error?.response?.data?.message || error?.message || 'Không thể tải danh sách sản phẩm');
      setProducts([]);
    } finally {
      setLoading(false);
    }
  }, [page, search, categoryFilter]);

  React.useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  React.useEffect(() => {
    fetchProducts();
  }, [page, search, categoryFilter]);

  const handleSubmit = async () => {
    if (!formData.name.trim()) {
      toast({ title: 'Lỗi', description: 'Vui lòng nhập tên sản phẩm', variant: 'destructive' });
      return;
    }
    if (!formData.price || parseFloat(formData.price) <= 0) {
      toast({ title: 'Lỗi', description: 'Vui lòng nhập giá sản phẩm hợp lệ', variant: 'destructive' });
      return;
    }

    try {
      setIsSubmitting(true);
      setFormError(null);
      const data = {
        name: formData.name.trim(),
        categoryId: formData.categoryId === '__none__' ? undefined : formData.categoryId || undefined,
        price: parseFloat(formData.price),
        unit: formData.unit as Product['unit'],
        stock: formData.stock ? parseInt(formData.stock) : 0,
        minOrder: formData.minOrder ? parseInt(formData.minOrder) : 1,
        description: formData.description.trim(),
      };

      if (editingProduct) {
        await adminProductApi.update(editingProduct._id, data);
        toast({ title: 'Thành công', description: 'Đã cập nhật sản phẩm' });
        setIsDialogOpen(false);
        setEditingProduct(null);
        resetForm();
        fetchProducts();
      } else {
        toast({
          title: 'Không thể tạo sản phẩm',
          description: 'Admin không tạo sản phẩm trực tiếp. Sản phẩm được tạo bởi Người bán (Seller) sau khi tạo Gian hàng.',
          variant: 'destructive',
        });
      }
    } catch (err: unknown) {
      const error = err as { response?: { data?: { message?: string } }; message?: string };
      console.error('Error saving product:', err);
      const msg = error?.response?.data?.message || error?.message || 'Đã xảy ra lỗi khi lưu sản phẩm';
      setFormError(msg);
      toast({ title: 'Lỗi', description: msg, variant: 'destructive' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setFormError(null);
    const catId = product.categoryId ? String(product.categoryId) : '__none__';
    setFormData({
      name: product.name || '',
      categoryId: catId,
      price: product.price?.toString() || '',
      unit: product.unit || 'kg',
      stock: product.stock?.toString() || '',
      minOrder: product.minOrder?.toString() || '1',
      description: product.description || '',
    });
    setIsDialogOpen(true);
  };

  const handleToggleAvailability = async (id: string) => {
    try {
      await adminProductApi.toggleAvailability(id);
      toast({ title: 'Thành công', description: 'Đã cập nhật trạng thái sản phẩm' });
      fetchProducts();
    } catch (err: unknown) {
      const error = err as { response?: { data?: { message?: string } }; message?: string };
      console.error('Error toggling availability:', err);
      toast({
        title: 'Lỗi',
        description: error?.response?.data?.message || error?.message || 'Không thể cập nhật trạng thái',
        variant: 'destructive',
      });
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await adminProductApi.delete(id);
      toast({ title: 'Thành công', description: 'Đã xóa sản phẩm' });
      fetchProducts();
    } catch (err: unknown) {
      const error = err as { response?: { data?: { message?: string } }; message?: string };
      console.error('Error deleting product:', err);
      toast({
        title: 'Lỗi',
        description: error?.response?.data?.message || error?.message || 'Không thể xóa sản phẩm',
        variant: 'destructive',
      });
    }
  };

  const resetForm = () => {
    setFormData({ name: '', categoryId: '__none__', price: '', unit: 'kg', stock: '', minOrder: '1', description: '' });
    setFormError(null);
  };

  const getCategoryName = (categoryId: string | Category): string => {
    if (typeof categoryId === 'object' && categoryId !== null) {
      return (categoryId as Category).name || 'N/A';
    }
    const cat = categories.find(c => c._id === categoryId);
    return cat?.name || 'N/A';
  };

  const units = ['kg', 'bó', 'con', 'cái', 'lít', 'lon', 'gói', 'hộp', 'bịch'];

  return (
    <div className="space-y-6">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Sản phẩm</h1>
          <p className="text-gray-500 dark:text-gray-400">Quản lý sản phẩm trong hệ thống</p>
        </div>
        <Button onClick={() => {
          toast({
            title: 'Thông báo',
            description: 'Admin không tạo sản phẩm trực tiếp. Sản phẩm do Người bán (Seller) tạo sau khi có Gian hàng.',
            variant: 'default'
          });
        }}>
          <Plus className="mr-2 h-4 w-4" /> Thêm sản phẩm
        </Button>
      </div>

      <div>
        <Card>
          <CardHeader>
            <div className="flex flex-col gap-4 md:flex-row md:items-center">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <Input
                  placeholder="Tìm kiếm sản phẩm..."
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                  className="pl-10"
                />
              </div>
              <Select value={categoryFilter} onValueChange={(v) => { setCategoryFilter(v); setPage(1); }}>
                <SelectTrigger className="w-[200px]">
                  <SelectValue placeholder="Danh mục" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__none__">Tất cả danh mục</SelectItem>
                  {categories.map((cat) => (
                    <SelectItem key={cat._id} value={cat._id}>
                      {cat.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="space-y-4">
                {[...Array(5)].map((_, i) => (
                  <Skeleton key={i} className="h-16 w-full" />
                ))}
              </div>
            ) : error ? (
              <div className="py-12 text-center">
                <AlertCircle className="mx-auto h-12 w-12 text-red-400" />
                <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">Không thể tải dữ liệu</h3>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">{error}</p>
                <Button variant="outline" className="mt-4" onClick={fetchProducts}>
                  <RefreshCw className="mr-2 h-4 w-4" />
                  Thử lại
                </Button>
              </div>
            ) : products.length === 0 ? (
              <div className="py-12 text-center">
                <Package className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">Không có sản phẩm</h3>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                  {search || categoryFilter ? 'Không tìm thấy sản phẩm phù hợp' : 'Bắt đầu bằng cách thêm sản phẩm mới'}
                </p>
              </div>
            ) : (
              <>
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b text-left text-sm text-gray-500 dark:text-gray-400">
                        <th className="pb-3 font-medium">Hình ảnh</th>
                        <th className="pb-3 font-medium">Tên sản phẩm</th>
                        <th className="pb-3 font-medium">Danh mục</th>
                        <th className="pb-3 text-right font-medium">Giá</th>
                        <th className="pb-3 text-right font-medium">Tồn kho</th>
                        <th className="pb-3 font-medium">Trạng thái</th>
                        <th className="pb-3 text-right font-medium">Hành động</th>
                      </tr>
                    </thead>
                    <tbody>
                      {products.map((product) => (
                        <tr key={product._id} className="border-b last:border-0 hover:bg-gray-50 dark:hover:bg-gray-800/50">
                          <td className="py-3 pr-3">
                            {product.images && product.images[0] ? (
                              <img
                                src={product.images[0]}
                                alt={product.name}
                                className="h-12 w-12 rounded-lg object-cover"
                                onError={(e) => {
                                  const target = e.target as HTMLImageElement;
                                  target.style.display = 'none';
                                }}
                              />
                            ) : (
                              <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-gray-100 dark:bg-gray-700">
                                <ImageIcon className="h-6 w-6 text-gray-400" />
                              </div>
                            )}
                          </td>
                          <td className="py-3">
                            <div>
                              <p className="font-medium text-gray-900 dark:text-gray-100">{product.name}</p>
                              <p className="text-xs text-gray-500 dark:text-gray-400">{formatDateShort(product.createdAt)}</p>
                            </div>
                          </td>
                          <td className="py-3 text-sm text-gray-600 dark:text-gray-400">
                            {getCategoryName(product.categoryId)}
                          </td>
                          <td className="py-3 text-right font-medium text-gray-900 dark:text-gray-100">
                            {formatCurrency(product.price)}
                          </td>
                          <td className="py-3 text-right text-gray-600 dark:text-gray-400">
                            {product.stock} {product.unit}
                          </td>
                          <td className="py-3">
                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-medium ${
                              product.isAvailable
                                ? 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-400'
                                : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                            }`}>
                              {product.isAvailable ? 'Còn hàng' : 'Hết hàng'}
                            </span>
                          </td>
                          <td className="py-3 text-right">
                            <div className="flex justify-end gap-1">
                              <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => handleToggleAvailability(product._id)}
                                title={product.isAvailable ? 'Tắt trạng thái' : 'Bật trạng thái'}
                              >
                                {product.isAvailable ? (
                                  <ToggleRight className="h-4 w-4 text-green-600" />
                                ) : (
                                  <ToggleLeft className="h-4 w-4 text-gray-400" />
                                )}
                              </Button>
                              <Button variant="ghost" size="icon" onClick={() => handleEdit(product)}>
                                <Edit className="h-4 w-4" />
                              </Button>
                              <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => {
                                  if (confirm('Bạn có chắc muốn xóa sản phẩm này?')) {
                                    handleDelete(product._id);
                                  }
                                }}
                                className="text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                <div className="mt-4 flex items-center justify-between">
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Hiển thị {products.length} / {total} sản phẩm
                  </p>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setPage(p => Math.max(1, p - 1))}
                      disabled={page <= 1}
                    >
                      Trước
                    </Button>
                    <span className="flex items-center px-3 text-sm text-gray-600 dark:text-gray-400">
                      Trang {page} / {totalPages}
                    </span>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                      disabled={page >= totalPages}
                    >
                      Sau
                    </Button>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      <Dialog open={isDialogOpen} onOpenChange={(open) => {
        if (!open) setFormError(null);
        setIsDialogOpen(open);
      }}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingProduct ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới'}</DialogTitle>
            <DialogDescription>
              Cập nhật thông tin sản phẩm (Admin chỉ có thể sửa, không tạo sản phẩm mới)
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            {formError && (
              <div className="rounded-md bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/30 dark:text-red-400">
                {formError}
              </div>
            )}
            <div>
              <label className="text-sm font-medium">Tên sản phẩm <span className="text-red-500">*</span></label>
              <Input
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="VD: Rau muống tươi"
              />
            </div>
            <div>
              <label className="text-sm font-medium">Danh mục</label>
              <Select value={formData.categoryId} onValueChange={(v) => setFormData({ ...formData, categoryId: v })}>
                <SelectTrigger>
                  <SelectValue placeholder="Chọn danh mục" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map((cat) => (
                    <SelectItem key={cat._id} value={cat._id}>
                      {cat.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Giá (VNĐ) <span className="text-red-500">*</span></label>
                <Input
                  type="number"
                  min="0"
                  value={formData.price}
                  onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                  placeholder="VD: 15000"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Đơn vị</label>
                <Select value={formData.unit} onValueChange={(v) => setFormData({ ...formData, unit: v })}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {units.map((u) => (
                      <SelectItem key={u} value={u}>{u}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Số lượng tồn kho</label>
                <Input
                  type="number"
                  min="0"
                  value={formData.stock}
                  onChange={(e) => setFormData({ ...formData, stock: e.target.value })}
                  placeholder="VD: 100"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Đơn hàng tối thiểu</label>
                <Input
                  type="number"
                  min="1"
                  value={formData.minOrder}
                  onChange={(e) => setFormData({ ...formData, minOrder: e.target.value })}
                  placeholder="VD: 1"
                />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium">Mô tả</label>
              <textarea
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                rows={3}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Mô tả sản phẩm..."
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)} disabled={isSubmitting}>
              Hủy
            </Button>
            <Button onClick={handleSubmit} disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                  Đang xử lý...
                </>
              ) : (
                editingProduct ? 'Cập nhật' : 'Tạo mới'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
