const { Order, User, Product, Market, Shop } = require('../models');

class DashboardService {
  async getStats() {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(startOfToday);
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalOrders,
      todayOrders,
      weekOrders,
      monthOrders,
      totalUsers,
      activeUsers,
      newUsersToday,
      newUsersThisWeek,
      newUsersThisMonth,
      totalProducts,
      availableProducts,
      totalRevenue,
      todayRevenue,
      weekRevenue,
      monthRevenue,
      deliveredOrders,
      pendingOrders,
      cancelledOrders,
    ] = await Promise.all([
      Order.countDocuments(),
      Order.countDocuments({ createdAt: { $gte: startOfToday } }),
      Order.countDocuments({ createdAt: { $gte: startOfWeek } }),
      Order.countDocuments({ createdAt: { $gte: startOfMonth } }),
      User.countDocuments(),
      User.countDocuments({ status: 'active' }),
      User.countDocuments({ createdAt: { $gte: startOfToday } }),
      User.countDocuments({ createdAt: { $gte: startOfWeek } }),
      User.countDocuments({ createdAt: { $gte: startOfMonth } }),
      Product.countDocuments(),
      Product.countDocuments({ isAvailable: true }),
      Order.aggregate([
        { $match: { paymentStatus: 'paid' } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      Order.aggregate([
        { $match: { paymentStatus: 'paid', createdAt: { $gte: startOfToday } } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      Order.aggregate([
        { $match: { paymentStatus: 'paid', createdAt: { $gte: startOfWeek } } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      Order.aggregate([
        { $match: { paymentStatus: 'paid', createdAt: { $gte: startOfMonth } } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      Order.countDocuments({ status: 'delivered' }),
      Order.countDocuments({ status: 'pending' }),
      Order.countDocuments({ status: 'cancelled' }),
    ]);

    const activeShippers = await User.countDocuments({
      role: 'shipper',
      status: 'active',
    });

    const [totalMarkets, activeMarkets, totalShops, approvedShops] = await Promise.all([
      Market.countDocuments(),
      Market.countDocuments({ isActive: true }),
      Shop.countDocuments(),
      Shop.countDocuments({ isApproved: true }),
    ]);

    return {
      orders: {
        total: totalOrders,
        today: todayOrders,
        thisWeek: weekOrders,
        thisMonth: monthOrders,
        delivered: deliveredOrders,
        pending: pendingOrders,
        cancelled: cancelledOrders,
      },
      users: {
        total: totalUsers,
        active: activeUsers,
        newToday: newUsersToday,
        newThisWeek: newUsersThisWeek,
        newThisMonth: newUsersThisMonth,
        byRole: await this.getUsersByRole(),
      },
      products: {
        total: totalProducts,
        available: availableProducts,
      },
      revenue: {
        total: totalRevenue[0]?.total || 0,
        today: todayRevenue[0]?.total || 0,
        thisWeek: weekRevenue[0]?.total || 0,
        thisMonth: monthRevenue[0]?.total || 0,
      },
      markets: {
        total: totalMarkets,
        active: activeMarkets,
      },
      shops: {
        total: totalShops,
        approved: approvedShops,
      },
      shippers: {
        active: activeShippers,
      },
    };
  }

  async getUsersByRole() {
    const roles = await User.aggregate([
      { $group: { _id: '$role', count: { $sum: 1 } } },
    ]);

    const byRole = {};
    roles.forEach(r => {
      byRole[r._id] = r.count;
    });

    return byRole;
  }

  async getRevenueByDay(days = 30) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const revenue = await Order.aggregate([
      {
        $match: {
          paymentStatus: 'paid',
          createdAt: { $gte: startDate },
        },
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
          },
          revenue: { $sum: '$total' },
          orders: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    return revenue.map(r => ({
      date: r._id,
      revenue: r.revenue,
      orders: r.orders,
    }));
  }

  async getOrdersByStatus() {
    const statuses = await Order.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);

    const byStatus = {};
    statuses.forEach(s => {
      byStatus[s._id] = s.count;
    });

    return byStatus;
  }

  async getTopProducts(limit = 10) {
    const topProducts = await Product.find()
      .sort({ soldCount: -1 })
      .limit(limit)
      .populate('sellerId', 'fullName')
      .lean();

    return topProducts.map(p => ({
      ...p,
      seller: p.sellerId,
      sellerId: p.sellerId?._id,
    }));
  }

  async getTopSellers(limit = 10) {
    const topSellers = await Order.aggregate([
      { $match: { status: 'delivered' } },
      { $unwind: '$items' },
      {
        $lookup: {
          from: 'products',
          localField: 'items.productId',
          foreignField: '_id',
          as: 'productInfo',
        },
      },
      { $unwind: '$productInfo' },
      {
        $group: {
          _id: '$productInfo.sellerId',
          totalOrders: { $sum: 1 },
          totalRevenue: {
            $sum: {
              $multiply: ['$items.price', '$items.quantity'],
            },
          },
        },
      },
      { $match: { _id: { $ne: null } } },
      { $sort: { totalRevenue: -1 } },
      { $limit: parseInt(limit) },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'seller',
        },
      },
      { $unwind: '$seller' },
      {
        $project: {
          sellerId: '$_id',
          fullName: '$seller.fullName',
          avatar: '$seller.avatar',
          email: '$seller.email',
          totalOrders: 1,
          totalRevenue: 1,
        },
      },
    ]);

    return topSellers;
  }
}

module.exports = new DashboardService();
