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
import { adminCategoryApi } from '@/lib/api-service';
import { Category, PaginationInfo } from '@/types';
import { Plus, Search, Edit, Trash2, Tag, ToggleLeft, ToggleRight, AlertCircle, RefreshCw } from 'lucide-react';
import { toast } from '@/hooks/use-toast';

export default function CategoriesPage() {
  const [categories, setCategories] = React.useState<Category[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [search, setSearch] = React.useState('');
  const [page, setPage] = React.useState(1);
  const [totalPages, setTotalPages] = React.useState(1);
  const [total, setTotal] = React.useState(0);
  const [isDialogOpen, setIsDialogOpen] = React.useState(false);
  const [editingCategory, setEditingCategory] = React.useState<Category | null>(null);
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [formError, setFormError] = React.useState<string | null>(null);
  const [formData, setFormData] = React.useState({
    name: '',
    icon: '',
    description: '',
    parentId: '__none__',
    sortOrder: 0,
  });

  const fetchCategories = React.useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const payload = await adminCategoryApi.getAll({
        page,
        limit: 20,
        search: search || undefined,
      });

      const data = (payload as any);
      setCategories(data?.categories || []);

      if (data?.pagination) {
        const pg = data.pagination;
        setTotalPages(pg.totalPages || 1);
        setTotal(pg.total || 0);
      }
    } catch (err: unknown) {
      console.error('Error fetching categories:', err);
      const errMsg = (err as { response?: { data?: { message?: string } }; message?: string }).response?.data?.message || (err as { message?: string }).message || 'Không thể tải danh sách danh mục';
      setError(errMsg);
      setCategories([]);
    } finally {
      setLoading(false);
    }
  }, [page, search]);

  React.useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  const handleSubmit = async () => {
    if (!formData.name.trim()) {
      toast({ title: 'Lỗi', description: 'Vui lòng nhập tên danh mục', variant: 'destructive' });
      return;
    }

    try {
      setIsSubmitting(true);
      setFormError(null);
      const data = {
        name: formData.name.trim(),
        icon: formData.icon.trim(),
        description: formData.description.trim(),
        parentId: formData.parentId === '__none__' ? null : formData.parentId || null,
        sortOrder: formData.sortOrder,
      };

      if (editingCategory) {
        await adminCategoryApi.update(editingCategory._id, data);
        toast({ title: 'Thành công', description: 'Đã cập nhật danh mục' });
      } else {
        await adminCategoryApi.create(data);
        toast({ title: 'Thành công', description: 'Đã thêm danh mục mới thành công' });
      }
      setIsDialogOpen(false);
      setEditingCategory(null);
      resetForm();
      fetchCategories();
    } catch (err: unknown) {
      console.error('Error saving category:', err);
      const msg = (err as { response?: { data?: { message?: string } }; message?: string }).response?.data?.message || (err as { message?: string }).message || 'Đã xảy ra lỗi khi lưu danh mục';
      setFormError(msg);
      toast({ title: 'Lỗi', description: msg, variant: 'destructive' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEdit = (category: Category) => {
    setEditingCategory(category);
    setFormError(null);
    setFormData({
      name: category.name || '',
      icon: category.icon || '',
      description: category.description || '',
      parentId: category.parentId ? String(category.parentId) : '__none__',
      sortOrder: category.sortOrder || 0,
    });
    setIsDialogOpen(true);
  };

  const handleToggleActive = async (category: Category) => {
    try {
      await adminCategoryApi.toggleActive(category._id);
      toast({
        title: 'Thành công',
        description: category.isActive ? 'Đã tắt hoạt động danh mục' : 'Đã bật hoạt động danh mục',
      });
      fetchCategories();
    } catch (err: unknown) {
      console.error('Error toggling category:', err);
      const msg = (err as { response?: { data?: { message?: string } }; message?: string }).response?.data?.message || (err as { message?: string }).message || 'Không thể thay đổi trạng thái';
      toast({
        title: 'Lỗi',
        description: msg,
        variant: 'destructive',
      });
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await adminCategoryApi.delete(id);
      toast({ title: 'Thành công', description: 'Đã xóa danh mục thành công' });
      fetchCategories();
    } catch (err: unknown) {
      console.error('Error deleting category:', err);
      const msg = (err as { response?: { data?: { message?: string } }; message?: string }).response?.data?.message || (err as { message?: string }).message || 'Không thể xóa danh mục';
      toast({
        title: 'Lỗi',
        description: msg,
        variant: 'destructive',
      });
    }
  };

  const resetForm = () => {
    setFormData({ name: '', icon: '', description: '', parentId: '__none__', sortOrder: 0 });
    setFormError(null);
  };

  const parentOptions = categories.filter(c => !editingCategory || c._id !== editingCategory._id);

  return (
    <div className="space-y-6">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Quản lý Danh mục</h1>
          <p className="text-gray-500 dark:text-gray-400">Quản lý các danh mục sản phẩm</p>
        </div>
        <Button
          onClick={() => { resetForm(); setEditingCategory(null); setIsDialogOpen(true); }}
        >
          <Plus className="mr-2 h-4 w-4" />
          Thêm danh mục mới
        </Button>
      </div>

      <div>
        <Card>
          <CardHeader>
            <div className="flex flex-col gap-4 md:flex-row md:items-center">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <Input
                  placeholder="Tìm kiếm danh mục..."
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                  className="pl-10"
                />
              </div>
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
                <Button variant="outline" className="mt-4" onClick={fetchCategories}>
                  <RefreshCw className="mr-2 h-4 w-4" />
                  Thử lại
                </Button>
              </div>
            ) : categories.length === 0 ? (
              <div className="py-12 text-center">
                <Tag className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-4 text-lg font-medium text-gray-900 dark:text-gray-100">Không có danh mục nào</h3>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                  {search ? 'Không tìm thấy danh mục phù hợp' : 'Bắt đầu bằng cách thêm danh mục mới'}
                </p>
              </div>
            ) : (
              <div>
                <div className="rounded-lg border dark:border-gray-700">
                  <div className="grid grid-cols-12 gap-4 border-b bg-gray-50 px-4 py-3 text-sm font-medium text-gray-500 dark:bg-gray-800 dark:text-gray-400">
                    <div className="col-span-4">Tên danh mục</div>
                    <div className="col-span-4">Mô tả</div>
                    <div className="col-span-2 text-center">Thứ tự</div>
                    <div className="col-span-2 text-center">Hành động</div>
                  </div>
                  {categories.map((category) => (
                    <div
                      key={category._id}
                      className="grid grid-cols-12 gap-4 border-b px-4 py-3 last:border-b-0 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800/50"
                    >
                      <div className="col-span-4 flex items-center gap-2">
                        {category.icon && <span className="text-lg">{category.icon}</span>}
                        <Tag className="h-4 w-4 text-gray-400" />
                        <span className="font-medium text-gray-900 dark:text-gray-100">{category.name}</span>
                        {!category.isActive && (
                          <span className="text-xs text-gray-400">(Tắt)</span>
                        )}
                      </div>
                      <div className="col-span-4 flex items-center text-sm text-gray-500 dark:text-gray-400">
                        {category.description || '-'}
                      </div>
                      <div className="col-span-2 flex items-center justify-center text-sm text-gray-600 dark:text-gray-400">
                        {category.sortOrder || 0}
                      </div>
                      <div className="col-span-2 flex items-center justify-center gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleToggleActive(category)}
                          title={category.isActive ? 'Tắt hoạt động' : 'Bật hoạt động'}
                        >
                          {category.isActive ? (
                            <ToggleRight className="h-5 w-5 text-green-600" />
                          ) : (
                            <ToggleLeft className="h-5 w-5 text-gray-400" />
                          )}
                        </Button>
                        <Button variant="ghost" size="icon" onClick={() => handleEdit(category)}>
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            if (confirm('Bạn có chắc muốn xóa danh mục này?')) handleDelete(category._id);
                          }}
                          className="text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="mt-4 flex items-center justify-between">
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    Hiển thị {categories.length} / {total} danh mục
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
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <Dialog
        open={isDialogOpen}
        onOpenChange={(open) => {
          if (!open) setFormError(null);
          setIsDialogOpen(open);
        }}
      >
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {editingCategory ? 'Sửa danh mục' : 'Thêm danh mục mới'}
            </DialogTitle>
            <DialogDescription>
              {editingCategory ? 'Cập nhật thông tin danh mục' : 'Nhập thông tin để tạo danh mục mới'}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            {formError && (
              <div className="rounded-md bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/30 dark:text-red-400">
                {formError}
              </div>
            )}
            <div>
              <label className="text-sm font-medium">
                Tên danh mục <span className="text-red-500">*</span>
              </label>
              <Input
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="VD: Rau củ"
              />
            </div>
            <div>
              <label className="text-sm font-medium">Icon (emoji)</label>
              <Input
                value={formData.icon}
                onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
                placeholder="VD: 🥬"
              />
            </div>
            <div>
              <label className="text-sm font-medium">Mô tả</label>
              <textarea
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                rows={3}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Mô tả danh mục..."
              />
            </div>
            <div>
              <label className="text-sm font-medium">Danh mục cha</label>
              <Select
                value={formData.parentId}
                onValueChange={(v) => setFormData({ ...formData, parentId: v })}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Không có (danh mục gốc)" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__none__">Không có (danh mục gốc)</SelectItem>
                  {parentOptions.map((cat) => (
                    <SelectItem key={cat._id} value={cat._id}>
                      {cat.icon && `${cat.icon} `}{cat.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="text-sm font-medium">Thứ tự hiển thị</label>
              <Input
                type="number"
                value={formData.sortOrder}
                onChange={(e) => setFormData({ ...formData, sortOrder: parseInt(e.target.value) || 0 })}
                placeholder="0"
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
              ) : editingCategory ? 'Cập nhật' : 'Tạo mới'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
