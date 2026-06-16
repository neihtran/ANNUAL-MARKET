'use client';

import * as React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { Download, TrendingUp, DollarSign, Wallet, CheckCircle, Clock, FileText, Table2 } from 'lucide-react';
import { dashboardApi, reportApi } from '@/lib/api-service';
import { DashboardStats, RevenueData } from '@/types';
import { formatCurrency } from '@/lib/utils';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export default function StatisticsPage() {
  const [stats, setStats] = React.useState<DashboardStats | null>(null);
  const [revenueData, setRevenueData] = React.useState<RevenueData[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [exporting, setExporting] = React.useState(false);
  const [showExportMenu, setShowExportMenu] = React.useState(false);

  React.useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const [statsRes, revenueRes] = await Promise.all([
          dashboardApi.getStats(),
          dashboardApi.getRevenueByDay(30),
        ]);
        setStats(statsRes);
        setRevenueData(revenueRes);
      } catch (err) {
        console.error('Error fetching stats:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const handleExportReport = async (format: 'pdf' | 'excel') => {
    try {
      setExporting(true);
      setShowExportMenu(false);
      const now = new Date();
      const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      const startDate = thirtyDaysAgo.toISOString().split('T')[0];
      const endDate = now.toISOString().split('T')[0];
      const blob = await reportApi.exportReport(startDate, endDate, format);
      const label = format === 'pdf' ? 'Bao-cao' : 'Bao-cao';
      downloadBlob(blob, `${label}-${startDate}-${endDate}.${format === 'pdf' ? 'pdf' : 'xlsx'}`);
    } catch (err) {
      console.error('Export failed:', err);
      alert('Xuất báo cáo thất bại. Vui lòng thử lại.');
    } finally {
      setExporting(false);
    }
  };

  const chartData = revenueData.map(r => ({
    name: r.date,
    revenue: r.revenue,
    orders: r.orders,
  }));

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">Thống kê tài chính</h1>
          <p className="text-gray-500 dark:text-gray-400 mt-1">Theo dõi doanh thu và đơn hàng của hệ thống</p>
        </div>
        <div className="relative">
          <Button
            className="bg-white hover:bg-gray-50 text-gray-700 border border-gray-200"
            onClick={() => setShowExportMenu(!showExportMenu)}
            disabled={exporting}
          >
            <Download className="mr-2 h-4 w-4" />
            {exporting ? 'Dang xuat...' : 'Export Report'}
          </Button>
          {showExportMenu && (
            <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 z-50 overflow-hidden">
              <button
                onClick={() => handleExportReport('pdf')}
                className="w-full flex items-center gap-2 px-4 py-3 text-sm text-gray-700 hover:bg-red-50 hover:text-red-600 transition-colors"
              >
                <FileText className="h-4 w-4" />
                Xuat PDF
              </button>
              <button
                onClick={() => handleExportReport('excel')}
                className="w-full flex items-center gap-2 px-4 py-3 text-sm text-gray-700 hover:bg-green-50 hover:text-green-600 transition-colors border-t border-gray-100"
              >
                <Table2 className="h-4 w-4" />
                Xuat Excel
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="rounded-2xl border-none shadow-sm">
          <CardContent className="p-6">
            <div className="flex justify-between items-start mb-4">
              <div className="rounded-lg bg-[#EBE7F1] p-3 text-[#6B52A3]">
                <TrendingUp className="h-6 w-6" strokeWidth={1.5} />
              </div>
            </div>
            <p className="text-sm font-medium text-gray-500 mb-1">Total Revenue</p>
            <h3 className="text-2xl font-bold text-gray-900">
              {loading ? <Skeleton className="h-8 w-32" /> : formatCurrency(stats?.revenue?.total ?? 0)}
            </h3>
          </CardContent>
        </Card>
        
        <Card className="rounded-2xl border-none shadow-sm">
          <CardContent className="p-6">
            <div className="flex justify-between items-start mb-4">
              <div className="rounded-lg bg-blue-50 p-3 text-blue-500">
                <DollarSign className="h-6 w-6" strokeWidth={1.5} />
              </div>
            </div>
            <p className="text-sm font-medium text-gray-500 mb-1">Orders This Month</p>
            <h3 className="text-2xl font-bold text-gray-900">
              {loading ? <Skeleton className="h-8 w-24" /> : stats?.orders?.thisMonth ?? 0}
            </h3>
          </CardContent>
        </Card>
        
        <Card className="rounded-2xl border-none shadow-sm">
          <CardContent className="p-6">
            <div className="flex justify-between items-start mb-4">
              <div className="rounded-lg bg-green-50 p-3 text-green-500">
                <CheckCircle className="h-6 w-6" strokeWidth={1.5} />
              </div>
            </div>
            <p className="text-sm font-medium text-gray-500 mb-1">Delivered Orders</p>
            <h3 className="text-2xl font-bold text-gray-900">
              {loading ? <Skeleton className="h-8 w-24" /> : stats?.orders?.delivered ?? 0}
            </h3>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="rounded-2xl border-none shadow-sm lg:col-span-2">
          <div className="p-6 border-b border-gray-100 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">Revenue Trend (30 Days)</h2>
            <div className="flex items-center gap-4 text-sm text-gray-500">
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-full bg-[#6B52A3]"></div> Revenue
              </div>
            </div>
          </div>
          <CardContent className="p-6 h-[400px]">
            {loading ? (
              <Skeleton className="h-full w-full" />
            ) : revenueData.length === 0 ? (
              <div className="flex items-center justify-center h-full text-gray-400">No revenue data</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#6B52A3" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#6B52A3" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F3F4F6" />
                  <XAxis 
                    dataKey="name" 
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: '#9CA3AF', fontSize: 12 }}
                    dy={10}
                    tickFormatter={(val: string) => {
                      const parts = val.split('-');
                      if (parts.length === 3) return `${parts[2]}/${parts[1]}`;
                      return val;
                    }}
                  />
                  <YAxis 
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: '#9CA3AF', fontSize: 12 }}
                    tickFormatter={(val: number) => `${(val / 1000).toFixed(0)}k`}
                  />
                  <Tooltip 
                    formatter={(value: number) => [formatCurrency(value), 'Revenue']}
                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                    cursor={{ stroke: '#EBE7F1', strokeWidth: 2, strokeDasharray: '4 4' }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="revenue" 
                    stroke="#6B52A3" 
                    strokeWidth={3}
                    fillOpacity={1} 
                    fill="url(#colorRev)" 
                  />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-none shadow-sm">
          <div className="p-6 border-b border-gray-100 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">Orders Summary</h2>
          </div>
          <CardContent className="p-0">
            <div className="divide-y divide-gray-50">
              {loading ? (
                [...Array(4)].map((_, i) => (
                  <div key={i} className="p-4"><Skeleton className="h-12 w-full" /></div>
                ))
              ) : (
                <>
                  <div className="p-4 flex items-center justify-between hover:bg-gray-50/50">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full flex items-center justify-center shrink-0 bg-green-50 text-green-600">
                        <CheckCircle className="w-5 h-5" />
                      </div>
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">Delivered</h4>
                        <p className="text-xs text-gray-500">Orders completed</p>
                      </div>
                    </div>
                    <p className="text-lg font-bold text-green-600">{stats?.orders?.delivered ?? 0}</p>
                  </div>
                  <div className="p-4 flex items-center justify-between hover:bg-gray-50/50">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full flex items-center justify-center shrink-0 bg-amber-50 text-amber-600">
                        <Clock className="w-5 h-5" />
                      </div>
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">Pending</h4>
                        <p className="text-xs text-gray-500">Orders waiting</p>
                      </div>
                    </div>
                    <p className="text-lg font-bold text-amber-600">{stats?.orders?.pending ?? 0}</p>
                  </div>
                  <div className="p-4 flex items-center justify-between hover:bg-gray-50/50">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full flex items-center justify-center shrink-0 bg-red-50 text-red-600">
                        <Wallet className="w-5 h-5" />
                      </div>
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">Cancelled</h4>
                        <p className="text-xs text-gray-500">Orders cancelled</p>
                      </div>
                    </div>
                    <p className="text-lg font-bold text-red-600">{stats?.orders?.cancelled ?? 0}</p>
                  </div>
                  <div className="p-4 flex items-center justify-between hover:bg-gray-50/50">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full flex items-center justify-center shrink-0 bg-blue-50 text-blue-600">
                        <DollarSign className="w-5 h-5" />
                      </div>
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">Total Orders</h4>
                        <p className="text-xs text-gray-500">All time</p>
                      </div>
                    </div>
                    <p className="text-lg font-bold text-blue-600">{stats?.orders?.total ?? 0}</p>
                  </div>
                </>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}