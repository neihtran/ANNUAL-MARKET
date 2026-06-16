'use client';

import * as React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { adminMarketApi, adminCategoryApi, dashboardApi } from '@/lib/api-service';
import { Market, Category, DashboardStats } from '@/types';
import { MapPin, Plus, Edit2, Trash2 } from 'lucide-react';
import { Switch } from '@/components/ui/switch';
import { toast } from '@/hooks/use-toast';
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

const DN_DISTRICTS = [
  'Hai Chau', 'Thanh Khe', 'Son Tra', 'Ngu Hanh Son',
  'Lien Chieu', 'Cam Le', 'Hoa Vang', 'Hoa Khanh',
];

const initialMarketForm = {
  name: '',
  address: '',
  district: '',
  openTime: '06:00',
  closeTime: '18:00',
  description: '',
  phone: '',
  images: '',
  is24h: false,
  isActive: true,
};

const initialCategoryForm = {
  name: '',
  icon: '',
  description: '',
  sortOrder: 0,
};

export default function MarketsPage() {
  const [markets, setMarkets] = React.useState<Market[]>([]);
  const [categories, setCategories] = React.useState<Category[]>([]);
  const [stats, setStats] = React.useState<DashboardStats | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  // Market dialog state
  const [marketDialogOpen, setMarketDialogOpen] = React.useState(false);
  const [editingMarket, setEditingMarket] = React.useState<Market | null>(null);
  const [marketForm, setMarketForm] = React.useState(initialMarketForm);
  const [marketSaving, setMarketSaving] = React.useState(false);

  // Category dialog state
  const [categoryDialogOpen, setCategoryDialogOpen] = React.useState(false);
  const [editingCategory, setEditingCategory] = React.useState<Category | null>(null);
  const [categoryForm, setCategoryForm] = React.useState(initialCategoryForm);
  const [categorySaving, setCategorySaving] = React.useState(false);

  const fetchData = React.useCallback(async () => {
    try {
      setLoading(true);
      const [marketsRes, categoriesRes, statsRes] = await Promise.all([
        adminMarketApi.getAll({ page: 1, limit: 50 }),
        adminCategoryApi.getAll({ page: 1, limit: 100 }),
        dashboardApi.getStats().catch(() => null),
      ]);

      const mData = (marketsRes as any);
      const cData = (categoriesRes as any);
      setMarkets(mData?.markets || []);
      setCategories(cData?.categories || []);
      if (statsRes) setStats(statsRes as any);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Không thể tải dữ liệu chợ';
      setError(msg);
      console.error('Error fetching data:', err);
      toast({ title: 'Lỗi', description: msg, variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => {
    fetchData();
  }, [fetchData]);

  const activeCount = markets.filter(m => m.isActive).length;

  // ---- Market handlers ----
  const openAddMarket = () => {
    setEditingMarket(null);
    setMarketForm(initialMarketForm);
    setMarketDialogOpen(true);
  };

  const openEditMarket = (market: Market) => {
    setEditingMarket(market);
    setMarketForm({
      name: market.name || '',
      address: market.address || '',
      district: market.district || '',
      openTime: market.openTime || '06:00',
      closeTime: market.closeTime || '18:00',
      description: market.description || '',
      phone: market.phone || '',
      images: Array.isArray(market.images) ? market.images.join(', ') : (market.images as string) || '',
      is24h: market.is24h || false,
      isActive: market.isActive ?? true,
    });
    setMarketDialogOpen(true);
  };

  const handleSaveMarket = async () => {
    if (!marketForm.name.trim()) {
      toast({ title: 'Lỗi', description: 'Vui lòng nhập tên chợ', variant: 'destructive' });
      return;
    }
    if (!marketForm.address.trim()) {
      toast({ title: 'Lỗi', description: 'Vui lòng nhập địa chỉ', variant: 'destructive' });
      return;
    }
    if (!marketForm.district) {
      toast({ title: 'Lỗi', description: 'Vui lòng chọn quận/huyện', variant: 'destructive' });
      return;
    }

    setMarketSaving(true);
    try {
      const data = {
        name: marketForm.name.trim(),
        address: marketForm.address.trim(),
        district: marketForm.district,
        openTime: marketForm.openTime,
        closeTime: marketForm.is24h ? '23:59' : marketForm.closeTime,
        description: marketForm.description.trim(),
        phone: marketForm.phone.trim(),
        images: marketForm.images.split(',').map(s => s.trim()).filter(Boolean),
        is24h: marketForm.is24h,
        isActive: marketForm.isActive,
      };

      if (editingMarket) {
        await adminMarketApi.update(editingMarket._id, data);
        toast({ title: 'Thành công', description: 'Đã cập nhật chợ' });
      } else {
        await adminMarketApi.create(data);
        toast({ title: 'Thành công', description: 'Đã thêm chợ mới' });
      }
      setMarketDialogOpen(false);
      fetchData();
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || 'Đã xảy ra lỗi';
      toast({ title: 'Lỗi', description: msg, variant: 'destructive' });
    } finally {
      setMarketSaving(false);
    }
  };

  const handleToggleMarketActive = async (market: Market) => {
    try {
      await adminMarketApi.toggleActive(market._id);
      toast({ title: 'Thành công', description: 'Đã cập nhật trạng thái' });
      fetchData();
    } catch {
      toast({ title: 'Lỗi', description: 'Không thể cập nhật trạng thái', variant: 'destructive' });
      fetchData();
    }
  };

  const handleDeleteMarket = async (market: Market) => {
    if (!confirm(`Xóa chợ "${market.name}"? Hành động này không thể hoàn tác.`)) return;
    try {
      await adminMarketApi.delete(market._id);
      toast({ title: 'Thành công', description: 'Đã xóa chợ' });
      fetchData();
    } catch {
      toast({ title: 'Lỗi', description: 'Không thể xóa chợ', variant: 'destructive' });
    }
  };

  // ---- Category handlers ----
  const openAddCategory = () => {
    setEditingCategory(null);
    setCategoryForm(initialCategoryForm);
    setCategoryDialogOpen(true);
  };

  const openEditCategory = (cat: Category) => {
    setEditingCategory(cat);
    setCategoryForm({
      name: cat.name || '',
      icon: cat.icon || '',
      description: cat.description || '',
      sortOrder: cat.sortOrder || 0,
    });
    setCategoryDialogOpen(true);
  };

  const handleSaveCategory = async () => {
    if (!categoryForm.name.trim()) {
      toast({ title: 'Lỗi', description: 'Vui lòng nhập tên danh mục', variant: 'destructive' });
      return;
    }
    setCategorySaving(true);
    try {
      const data = {
        name: categoryForm.name.trim(),
        icon: categoryForm.icon.trim(),
        description: categoryForm.description.trim(),
        sortOrder: categoryForm.sortOrder,
      };
      if (editingCategory) {
        await adminCategoryApi.update(editingCategory._id, data);
        toast({ title: 'Thành công', description: 'Đã cập nhật danh mục' });
      } else {
        await adminCategoryApi.create(data);
        toast({ title: 'Thành công', description: 'Đã thêm danh mục mới' });
      }
      setCategoryDialogOpen(false);
      fetchData();
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || 'Đã xảy ra lỗi';
      toast({ title: 'Lỗi', description: msg, variant: 'destructive' });
    } finally {
      setCategorySaving(false);
    }
  };

  const handleToggleCategoryActive = async (cat: Category) => {
    try {
      await adminCategoryApi.toggleActive(cat._id);
      toast({ title: 'Thành công', description: 'Đã cập nhật trạng thái danh mục' });
      fetchData();
    } catch {
      toast({ title: 'Lỗi', description: 'Không thể cập nhật trạng thái', variant: 'destructive' });
      fetchData();
    }
  };

  const handleDeleteCategory = async (cat: Category) => {
    if (!confirm(`Xóa danh mục "${cat.name}"?`)) return;
    try {
      await adminCategoryApi.delete(cat._id);
      toast({ title: 'Thành công', description: 'Đã xóa danh mục' });
      fetchData();
    } catch {
      toast({ title: 'Lỗi', description: 'Không thể xóa danh mục', variant: 'destructive' });
    }
  };

  return (
    <div className="space-y-6">
      {/* Error Banner */}
      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 flex items-center justify-between dark:bg-red-900/20 dark:border-red-800">
          <div className="flex items-center gap-3">
            <span className="text-red-500 text-lg">⚠</span>
            <div>
              <p className="text-sm font-medium text-red-700 dark:text-red-300">Không thể tải dữ liệu</p>
              <p className="text-xs text-red-500 dark:text-red-400">{error}</p>
            </div>
          </div>
          <button
            onClick={fetchData}
            className="text-sm px-3 py-1.5 bg-red-100 hover:bg-red-200 text-red-700 rounded-md transition-colors dark:bg-red-800 dark:text-red-200 dark:hover:bg-red-700"
          >
            Thử lại
          </button>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Quản lý Chợ & Danh mục</h1>
          <p className="text-gray-500 dark:text-gray-400 mt-1">Quản lý hệ thống chợ và danh mục sản phẩm</p>
        </div>
        <Button className="bg-[#4B3B70] hover:bg-[#3D2F5B] text-white" onClick={openAddMarket}>
          <Plus className="mr-2 h-4 w-4" /> Thêm chợ mới
        </Button>
      </div>

      {/* Stats */}
      <div className="grid gap-6 md:grid-cols-3">
        <Card className="rounded-2xl border-none shadow-sm">
          <CardContent className="p-6">
            <p className="text-sm font-medium text-gray-500 mb-1">Tổng số chợ</p>
            <h3 className="text-2xl font-bold text-gray-900">{stats?.markets?.total ?? markets.length}</h3>
          </CardContent>
        </Card>
        <Card className="rounded-2xl border-none shadow-sm">
          <CardContent className="p-6">
            <p className="text-sm font-medium text-gray-500 mb-1">Chợ đang hoạt động</p>
            <h3 className="text-2xl font-bold text-green-600">{activeCount}</h3>
          </CardContent>
        </Card>
        <Card className="rounded-2xl border-none shadow-sm">
          <CardContent className="p-6">
            <p className="text-sm font-medium text-gray-500 mb-1">Tổng danh mục</p>
            <h3 className="text-2xl font-bold text-[#6B52A3]">{categories.length}</h3>
          </CardContent>
        </Card>
      </div>

      <div className="grid lg:grid-cols-2 gap-8">
        {/* Left: Markets */}
        <div>
          <h2 className="text-lg font-semibold mb-4 text-gray-900">Danh sách chợ</h2>
          <div className="space-y-4">
            {loading ? (
              [...Array(3)].map((_, i) => <Skeleton key={i} className="h-32 w-full rounded-2xl" />)
            ) : markets.length === 0 ? (
              <Card className="rounded-2xl border-none shadow-sm p-8 text-center">
                <p className="text-gray-500">Chưa có chợ nào. Hãy thêm chợ mới!</p>
              </Card>
            ) : (
              markets.map((market, idx) => (
                <Card key={market._id || idx} className={`rounded-2xl border-none shadow-sm ${!market.isActive ? 'bg-gray-50' : 'bg-white'}`}>
                  <CardContent className="p-5">
                    <div className="flex gap-4">
                      <div className="w-16 h-16 rounded-xl bg-gray-200 overflow-hidden flex-shrink-0">
                        <img
                          src={market.images?.[0] || 'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?auto=format&fit=crop&q=80&w=200'}
                          alt={market.name}
                          className="w-full h-full object-cover"
                          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                        />
                      </div>
                      <div className="flex-1">
                        <div className="flex justify-between items-start">
                          <div>
                            <h3 className={`font-semibold ${!market.isActive ? 'text-gray-500' : 'text-gray-900'}`}>{market.name}</h3>
                            <p className="text-sm text-gray-500 flex items-center gap-1 mt-0.5">
                              <MapPin className="h-3.5 w-3.5" /> {market.address}
                            </p>
                            {market.district && (
                              <p className="text-xs text-gray-400">{market.district}</p>
                            )}
                          </div>
                          <Switch checked={market.isActive} onCheckedChange={() => handleToggleMarketActive(market)} />
                        </div>
                        <div className="flex items-center justify-end mt-3">
                          <button className="text-[#6B52A3] hover:text-[#4B3B70] p-2 bg-[#F4F2F7] rounded-lg mr-2" onClick={() => openEditMarket(market)} title="Sửa chợ">
                            <Edit2 className="h-4 w-4" />
                          </button>
                          <button className="text-red-400 hover:text-red-600 p-2 bg-red-50 rounded-lg" onClick={() => handleDeleteMarket(market)} title="Xóa chợ">
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </div>

        {/* Right: Categories */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Danh mục sản phẩm</h2>
            <Button size="sm" className="bg-green-600 hover:bg-green-700 text-white rounded-md h-8" onClick={openAddCategory}>
              <Plus className="mr-1 h-4 w-4" /> Thêm danh mục
            </Button>
          </div>
          <div className="space-y-3">
            {loading ? (
              [...Array(4)].map((_, i) => <Skeleton key={i} className="h-14 w-full rounded-xl" />)
            ) : categories.length === 0 ? (
              <Card className="rounded-2xl border-none shadow-sm p-8 text-center">
                <p className="text-gray-500">Chưa có danh mục nào. Hãy thêm danh mục mới!</p>
              </Card>
            ) : (
              categories.map((cat) => (
                <Card key={cat._id} className="rounded-xl border-none shadow-sm">
                  <div className="p-4 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-[#EBE7F1] flex items-center justify-center text-[#6B52A3] text-lg font-bold">
                      {cat.icon || cat.name?.[0] || '?'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold text-gray-900 truncate">{cat.name}</h3>
                      <p className="text-xs text-gray-500 truncate">{cat.description || 'Không có mô tả'}</p>
                    </div>
                    <div className={`px-2.5 py-1 text-xs font-medium rounded-full shrink-0 ${cat.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                      {cat.isActive ? 'Hoạt động' : 'Tắt'}
                    </div>
                    <div className="flex gap-1 shrink-0">
                      <button className="p-2 text-gray-400 hover:text-gray-600" onClick={() => openEditCategory(cat)} title="Sửa danh mục">
                        <Edit2 className="h-4 w-4" />
                      </button>
                      <button className="p-2 text-gray-400 hover:text-gray-600" onClick={() => handleToggleCategoryActive(cat)} title="Đổi trạng thái">
                        <Switch checked={cat.isActive} onCheckedChange={() => handleToggleCategoryActive(cat)} className="scale-75" />
                      </button>
                      <button className="p-2 text-red-400 hover:text-red-600" onClick={() => handleDeleteCategory(cat)} title="Xóa danh mục">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </Card>
              ))
            )}
          </div>
        </div>
      </div>

      {/* ---- Market Dialog ---- */}
      <Dialog open={marketDialogOpen} onOpenChange={setMarketDialogOpen}>
        <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingMarket ? 'Sửa thông tin chợ' : 'Thêm chợ mới'}</DialogTitle>
            <DialogDescription>
              {editingMarket ? 'Cập nhật thông tin chợ truyền thống tại Đà Nẵng' : 'Tạo mới một chợ truyền thống tại Đà Nẵng'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-1 block">Tên chợ <span className="text-red-500">*</span></label>
              <Input value={marketForm.name} onChange={e => setMarketForm(f => ({ ...f, name: e.target.value }))} placeholder="VD: Chợ Hòa Cường" />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Địa chỉ <span className="text-red-500">*</span></label>
              <Input value={marketForm.address} onChange={e => setMarketForm(f => ({ ...f, address: e.target.value }))} placeholder="VD: 123 Đường Lê Duẩn, P.Hòa Cường" />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Quận/Huyện (Đà Nẵng) <span className="text-red-500">*</span></label>
              <Select value={marketForm.district} onValueChange={v => setMarketForm(f => ({ ...f, district: v }))}>
                <SelectTrigger>
                  <SelectValue placeholder="Chọn quận/huyện" />
                </SelectTrigger>
                <SelectContent>
                  {DN_DISTRICTS.map(d => <SelectItem key={d} value={d}>{d}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium mb-1 block">Giờ mở cửa</label>
                <Input type="time" value={marketForm.openTime} onChange={e => setMarketForm(f => ({ ...f, openTime: e.target.value }))} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">Giờ đóng cửa</label>
                <Input type="time" value={marketForm.closeTime} onChange={e => setMarketForm(f => ({ ...f, closeTime: e.target.value }))} disabled={marketForm.is24h} />
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Switch id="is24h" checked={marketForm.is24h} onCheckedChange={v => setMarketForm(f => ({ ...f, is24h: v }))} />
              <label htmlFor="is24h" className="text-sm font-medium">Mở cửa 24h</label>
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Số điện thoại</label>
              <Input value={marketForm.phone} onChange={e => setMarketForm(f => ({ ...f, phone: e.target.value }))} placeholder="VD: 0905123456" />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Ảnh chợ (URL, cách nhau bởi dấu phẩy)</label>
              <Input value={marketForm.images} onChange={e => setMarketForm(f => ({ ...f, images: e.target.value }))} placeholder="https://...jpg, https://...png" />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Mô tả</label>
              <textarea
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                rows={3}
                value={marketForm.description}
                onChange={e => setMarketForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Mô tả về chợ..."
              />
            </div>
            {editingMarket && (
              <div className="flex items-center gap-2">
                <Switch id="isActive" checked={marketForm.isActive} onCheckedChange={v => setMarketForm(f => ({ ...f, isActive: v }))} />
                <label htmlFor="isActive" className="text-sm font-medium">Đang hoạt động</label>
              </div>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setMarketDialogOpen(false)} disabled={marketSaving}>Hủy</Button>
            <Button onClick={handleSaveMarket} disabled={marketSaving} className="bg-[#4B3B70] hover:bg-[#3D2F5B]">
              {marketSaving ? 'Đang lưu...' : editingMarket ? 'Cập nhật' : 'Tạo mới'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ---- Category Dialog ---- */}
      <Dialog open={categoryDialogOpen} onOpenChange={setCategoryDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>{editingCategory ? 'Sửa danh mục' : 'Thêm danh mục mới'}</DialogTitle>
            <DialogDescription>
              {editingCategory ? 'Cập nhật thông tin danh mục sản phẩm' : 'Tạo mới một danh mục sản phẩm'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-1 block">Tên danh mục <span className="text-red-500">*</span></label>
              <Input value={categoryForm.name} onChange={e => setCategoryForm(f => ({ ...f, name: e.target.value }))} placeholder="VD: Rau củ tươi" />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Icon (emoji)</label>
              <Input value={categoryForm.icon} onChange={e => setCategoryForm(f => ({ ...f, icon: e.target.value }))} placeholder="VD: 🥬" />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Mô tả</label>
              <textarea
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                rows={3}
                value={categoryForm.description}
                onChange={e => setCategoryForm(f => ({ ...f, description: e.target.value }))}
                placeholder="Mô tả danh mục..."
              />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">Thứ tự hiển thị</label>
              <Input type="number" min="0" value={categoryForm.sortOrder} onChange={e => setCategoryForm(f => ({ ...f, sortOrder: parseInt(e.target.value) || 0 }))} placeholder="0" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCategoryDialogOpen(false)} disabled={categorySaving}>Hủy</Button>
            <Button onClick={handleSaveCategory} disabled={categorySaving} className="bg-green-600 hover:bg-green-700">
              {categorySaving ? 'Đang lưu...' : editingCategory ? 'Cập nhật' : 'Tạo mới'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
