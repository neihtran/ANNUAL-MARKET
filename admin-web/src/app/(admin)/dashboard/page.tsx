'use client';

import * as React from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { dashboardApi, reportApi } from '@/lib/api-service';
import { DashboardStats, RevenueData } from '@/types';
import { formatCurrency } from '@/lib/utils';
import {
  Banknote,
  Store,
  User,
  Truck,
  FileText,
  Table2,
  Download,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ElementType;
  trend?: { value: number; isPositive: boolean; text: string };
  loading?: boolean;
}

function StatCard({ title, value, icon: Icon, trend, loading }: StatCardProps) {
  if (loading) {
    return (
      <Card className="rounded-2xl border-none shadow-sm dark:bg-gray-900">
        <CardContent className="p-6">
          <Skeleton className="h-4 w-24 mb-4" />
          <Skeleton className="h-8 w-32" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
      <CardContent className="p-6">
        <div className="flex justify-between items-start mb-4">
          <div className="rounded-lg bg-[#EBE7F1] p-3 text-[#6B52A3] dark:bg-gray-800 dark:text-gray-200">
            <Icon className="h-6 w-6" strokeWidth={1.5} />
          </div>
          {trend && (
            <div className={`flex items-center text-sm font-medium ${trend.isPositive ? 'text-green-600' : trend.value === 0 ? 'text-gray-500' : 'text-red-500'}`}>
              {trend.text}
            </div>
          )}
        </div>
        <div>
          <p className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">{title}</p>
          <h3 className="text-2xl font-bold text-gray-900 dark:text-gray-100">{value}</h3>
        </div>
      </CardContent>
    </Card>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = React.useState<DashboardStats | null>(null);
  const [revenueData, setRevenueData] = React.useState<RevenueData[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [exporting, setExporting] = React.useState(false);
  const [showExportMenu, setShowExportMenu] = React.useState(false);

  const fetchData = React.useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const [statsRes, revenueRes] = await Promise.all([
        dashboardApi.getStats() as Promise<{ orders: DashboardStats['orders']; users: DashboardStats['users']; products: DashboardStats['products']; revenue: DashboardStats['revenue']; markets?: DashboardStats['markets']; shops?: DashboardStats['shops']; shippers: DashboardStats['shippers'] }>,
        dashboardApi.getRevenueByDay(30) as Promise<RevenueData[]>,
      ]);
      const stats: DashboardStats = {
        orders: statsRes.orders,
        users: statsRes.users,
        products: statsRes.products,
        revenue: statsRes.revenue,
        markets: statsRes.markets,
        shops: statsRes.shops,
        shippers: statsRes.shippers,
      };
      setStats(stats);
      setRevenueData(revenueRes || []);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Không thể tải dữ liệu dashboard';
      setError(msg);
      console.error('[Dashboard]', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const handleExportActivityLog = async (format: 'pdf' | 'excel') => {
    try {
      setExporting(true);
      setShowExportMenu(false);
      const blob = await reportApi.exportActivityLog(format);
      const now = new Date().toISOString().split('T')[0];
      const label = format === 'pdf' ? 'Nhat-ky-hoat-dong' : 'Nhat-ky-hoat-dong';
      downloadBlob(blob, `${label}-${now}.${format === 'pdf' ? 'pdf' : 'xlsx'}`);
    } catch (err) {
      console.error('Export failed:', err);
      alert('Xuat nhat ky hoat dong that bai. Vui long thu lai.');
    } finally {
      setExporting(false);
    }
  };

  const downloadBlob = (blob: Blob, filename: string) => {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  React.useEffect(() => {
    fetchData();
  }, []);

  const sellers = stats?.users?.byRole?.seller ?? 0;
  const buyers = stats?.users?.byRole?.buyer ?? 0;
  const shippers = stats?.users?.byRole?.shipper ?? 0;
  const admins = stats?.users?.byRole?.admin ?? 0;

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

      {/* Stat Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Revenue"
          value={stats ? formatCurrency(stats.revenue.total) : '0đ'}
          icon={Banknote}
          trend={stats && stats.revenue.today > 0 ? { value: Math.round((stats.revenue.today / Math.max(stats.revenue.total, 1)) * 100), isPositive: true, text: `Today ${formatCurrency(stats.revenue.today)}` } : undefined}
          loading={loading}
        />
        <StatCard
          title="Total Markets"
          value={stats?.markets?.total ?? 0}
          icon={Store}
          trend={undefined}
          loading={loading}
        />
        <StatCard
          title="Active Sellers"
          value={sellers}
          icon={User}
          trend={undefined}
          loading={loading}
        />
        <StatCard
          title="Active Shippers"
          value={shippers}
          icon={Truck}
          trend={undefined}
          loading={loading}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Revenue Trend Chart */}
        <Card className="lg:col-span-2 rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardHeader className="flex flex-row items-center justify-between pb-2 border-b-0">
            <div>
              <CardTitle className="text-base font-semibold text-gray-900">Revenue Trend</CardTitle>
              <CardDescription className="text-sm text-gray-500">Daily performance over last 30 days</CardDescription>
            </div>
            <div className="rounded-lg bg-gray-100 px-3 py-1.5 text-sm font-medium text-gray-600">
              Last 30 Days
            </div>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-[250px] w-full" />
            ) : revenueData.length === 0 ? (
              <div className="h-[250px] flex items-center justify-center text-gray-400">
                No revenue data available
              </div>
            ) : (
              <div className="h-[250px] mt-4">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={revenueData} margin={{ top: 10, right: 0, left: 0, bottom: 0 }}>
                    <defs>
                      <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10B981" stopOpacity={0.2}/>
                        <stop offset="95%" stopColor="#10B981" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <Tooltip
                      formatter={(value: number) => [formatCurrency(value), 'Revenue']}
                      labelFormatter={(label: string) => `Date: ${label}`}
                      contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                    />
                    <Area
                      type="monotone"
                      dataKey="revenue"
                      stroke="#10B981"
                      strokeWidth={4}
                      fillOpacity={1}
                      fill="url(#colorRevenue)"
                    />
                    <XAxis 
                      dataKey="date" 
                      axisLine={false} 
                      tickLine={false} 
                      tick={{ fill: '#6B7280', fontSize: 12 }}
                      tickFormatter={(val: string) => {
                        const parts = val.split('-');
                        if (parts.length === 3) return `${parts[2]}/${parts[1]}`;
                        return val;
                      }}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Orders by Status */}
        <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardHeader className="pb-4">
            <CardTitle className="text-base font-semibold text-gray-900">Orders by Status</CardTitle>
            <CardDescription className="text-sm text-gray-500">Current order distribution</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 mt-2">
            {loading ? (
              <>
                {[1,2,3,4].map(i => <Skeleton key={i} className="h-8 w-full" />)}
              </>
            ) : stats ? (
              <>
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-gray-700">Tổng đơn hàng</span>
                  <span className="text-[#10B981]">{stats.orders.total}</span>
                </div>
                <div className="h-2.5 w-full bg-gray-100 rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-[#10B981]" style={{ width: '100%' }} />
                </div>
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-gray-700">Đã giao</span>
                  <span className="text-[#10B981]">{stats.orders.delivered}</span>
                </div>
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-gray-700">Đang chờ</span>
                  <span className="text-amber-500">{stats.orders.pending}</span>
                </div>
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-gray-700">Đã hủy</span>
                  <span className="text-red-500">{stats.orders.cancelled}</span>
                </div>
                <div className="flex justify-between text-sm font-medium">
                  <span className="text-gray-700">Hôm nay</span>
                  <span className="text-[#6B52A3]">{stats.orders.today}</span>
                </div>
              </>
            ) : (
              <p className="text-gray-400 text-sm">No data</p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-6 md:grid-cols-3 lg:grid-cols-6">
        <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-[#10B981]">{stats?.orders.total ?? 0}</p>
            <p className="text-xs text-gray-500 mt-1">Total Orders</p>
          </CardContent>
        </Card>
        <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-blue-600">{stats?.products?.total ?? 0}</p>
            <p className="text-xs text-gray-500 mt-1">Total Products</p>
          </CardContent>
        </Card>
        <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-orange-500">{stats?.products?.available ?? 0}</p>
            <p className="text-xs text-gray-500 mt-1">Available</p>
          </CardContent>
        </Card>
        <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-violet-600">{sellers}</p>
            <p className="text-xs text-gray-500 mt-1">Sellers</p>
          </CardContent>
        </Card>
        <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-pink-600">{buyers}</p>
            <p className="text-xs text-gray-500 mt-1">Buyers</p>
          </CardContent>
        </Card>
        <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-teal-600">{shippers}</p>
            <p className="text-xs text-gray-500 mt-1">Shippers</p>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card className="rounded-2xl border-none shadow-sm bg-white dark:bg-gray-900">
        <CardHeader className="flex flex-row items-center justify-between py-5 border-b border-gray-100">
          <CardTitle className="text-base font-semibold text-gray-900">Recent Activity</CardTitle>
          <div className="relative flex gap-2">
            <button
              onClick={() => setShowExportMenu(!showExportMenu)}
              disabled={exporting}
              className="px-4 py-2 bg-[#4B3B70] text-white text-sm font-medium rounded-lg hover:bg-[#3D2F5B] transition-colors flex items-center gap-2 disabled:opacity-50"
            >
              <Download className="h-4 w-4" />
              {exporting ? 'Dang xuat...' : 'Export Log'}
            </button>
            {showExportMenu && (
              <div className="absolute right-0 top-full mt-2 w-44 bg-white rounded-lg shadow-lg border border-gray-200 z-50 overflow-hidden">
                <button
                  onClick={() => handleExportActivityLog('pdf')}
                  className="w-full flex items-center gap-2 px-4 py-3 text-sm text-gray-700 hover:bg-red-50 hover:text-red-600 transition-colors"
                >
                  <FileText className="h-4 w-4" />
                  Xuat PDF
                </button>
                <button
                  onClick={() => handleExportActivityLog('excel')}
                  className="w-full flex items-center gap-2 px-4 py-3 text-sm text-gray-700 hover:bg-green-50 hover:text-green-600 transition-colors border-t border-gray-100"
                >
                  <Table2 className="h-4 w-4" />
                  Xuat Excel
                </button>
              </div>
            )}
          </div>
        </CardHeader>
        <CardContent className="p-6">
          <div className="text-center text-gray-400">
            <p className="text-sm">Activity log will appear here as actions occur</p>
          </div>
        </CardContent>
      </Card>

      <div className="text-center pt-8 pb-4">
        <p className="text-sm text-gray-500">© 2026 Chợ Truyền Thông Admin Console</p>
      </div>
    </div>
  );
}
