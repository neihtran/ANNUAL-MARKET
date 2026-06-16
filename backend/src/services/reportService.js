const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const { Order, User, Product, Market, Shop } = require('../models');

const VIETNAMESE_STATUS = {
  pending: 'Cho xac nhan',
  confirmed: 'Da xac nhan',
  preparing: 'Dang chuan bi',
  ready: 'San sang giao',
  picking_up: 'Dang lay hang',
  delivering: 'Dang giao',
  delivered: 'Da giao',
  cancelled: 'Da huy',
  finding_shipper: 'Dang tim tai xe',
  shipper_accepted: 'Tai xe da nhan',
  heading_to_market: 'Dang den cho',
  arrived_at_market: 'Da den cho',
  ready_for_pickup: 'San sang lay',
  seller_handed_over: 'Da bang giao',
  picked_up: 'Da lay hang',
  shopping: 'Dang di mua',
};

class ReportService {
  formatCurrency(vnd) {
    if (vnd == null) return '0';
    return new Intl.NumberFormat('vi-VN').format(vnd) + ' VND';
  }

  formatDate(date) {
    if (!date) return '';
    const d = new Date(date);
    return d.toLocaleDateString('vi-VN');
  }

  async generateReportData(startDate, endDate) {
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const [orders, stats, topProducts, topSellers, revenueByDay, markets, shops] = await Promise.all([
      Order.find({
        createdAt: { $gte: start, $lte: end },
      })
        .populate('buyerId', 'fullName email')
        .populate('shipperId', 'fullName')
        .lean(),
      this.getDashboardStats(start, end),
      this.getTopProducts(10, start, end),
      this.getTopSellers(10, start, end),
      this.getRevenueByDay(start, end),
      Market.countDocuments(),
      Shop.countDocuments(),
    ]);

    return { orders, stats, topProducts, topSellers, revenueByDay, markets, shops };
  }

  async getDashboardStats(start, end) {
    const [
      totalOrders,
      deliveredOrders,
      pendingOrders,
      cancelledOrders,
      totalRevenue,
      monthRevenue,
      newUsersThisMonth,
      totalProducts,
      activeProducts,
    ] = await Promise.all([
      Order.countDocuments({ createdAt: { $gte: start, $lte: end } }),
      Order.countDocuments({ createdAt: { $gte: start, $lte: end }, status: 'delivered' }),
      Order.countDocuments({ createdAt: { $gte: start, $lte: end }, status: 'pending' }),
      Order.countDocuments({ createdAt: { $gte: start, $lte: end }, status: 'cancelled' }),
      Order.aggregate([
        { $match: { createdAt: { $gte: start, $lte: end }, paymentStatus: 'paid' } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      Order.aggregate([
        { $match: { createdAt: { $gte: start, $lte: end }, paymentStatus: 'paid', status: 'delivered' } },
        { $group: { _id: null, total: { $sum: '$total' } } },
      ]),
      User.countDocuments({ createdAt: { $gte: start, $lte: end } }),
      Product.countDocuments({ createdAt: { $gte: start, $lte: end } }),
      Product.countDocuments({ createdAt: { $gte: start, $lte: end }, isAvailable: true }),
    ]);

    const ordersByStatus = await Order.aggregate([
      { $match: { createdAt: { $gte: start, $lte: end } } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);

    const statusMap = {};
    ordersByStatus.forEach(s => { statusMap[s._id] = s.count; });

    return {
      totalOrders,
      deliveredOrders,
      pendingOrders,
      cancelledOrders,
      totalRevenue: totalRevenue[0]?.total || 0,
      monthRevenue: monthRevenue[0]?.total || 0,
      newUsersThisMonth,
      totalProducts,
      activeProducts,
      ordersByStatus: statusMap,
    };
  }

  async getTopProducts(limit = 10, start, end) {
    const products = await Product.find({ createdAt: { $gte: start, $lte: end } })
      .sort({ soldCount: -1 })
      .limit(limit)
      .populate('sellerId', 'fullName')
      .lean();

    return products.map(p => ({
      name: p.name,
      seller: p.sellerId?.fullName || 'N/A',
      category: p.category || 'N/A',
      price: p.price,
      soldCount: p.soldCount || 0,
      stock: p.stock,
      isAvailable: p.isAvailable ? 'Co' : 'Khong',
    }));
  }

  async getTopSellers(limit = 10, start, end) {
    const sellers = await Order.aggregate([
      { $match: { createdAt: { $gte: start, $lte: end }, status: 'delivered' } },
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
          totalRevenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
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
          fullName: '$seller.fullName',
          email: '$seller.email',
          phone: '$seller.phone',
          totalOrders: 1,
          totalRevenue: 1,
        },
      },
    ]);

    return sellers;
  }

  async getRevenueByDay(start, end) {
    const revenue = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
          paymentStatus: 'paid',
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
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

  generatePDF(data) {
    return new Promise((resolve, reject) => {
      try {
        const { stats, topProducts, topSellers, revenueByDay } = data;
        const doc = new PDFDocument({ margin: 40, size: 'A4' });
        const chunks = [];

        doc.on('data', chunk => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        const pageWidth = doc.page.width - 80;
        let y = 40;

        const header = () => {
          doc.rect(0, 0, doc.page.width, 60).fill('#16a34a');
          doc.fillColor('white').fontSize(20).font('Helvetica-Bold')
            .text('CHO TRUYEN THONG', 40, 18, { lineBreak: false });
          doc.fontSize(10).font('Helvetica').text('Bao cao tong quan he thong', 40, 38);
          doc.text(`Ngay: ${new Date().toLocaleDateString('vi-VN')}`, doc.page.width - 150, 38);
        };

        const addSectionTitle = (title) => {
          if (y > doc.page.height - 120) {
            doc.addPage();
            y = 40;
          }
          doc.rect(40, y, pageWidth, 1).fill('#16a34a');
          y += 10;
          doc.fillColor('#16a34a').fontSize(12).font('Helvetica-Bold').text(title, 40, y);
          y += 20;
        };

        const addTwoCol = (label1, val1, label2, val2) => {
          if (y > doc.page.height - 60) { doc.addPage(); y = 40; }
          doc.fillColor('#374151').fontSize(9).font('Helvetica-Bold').text(label1, 40, y, { continued: false });
          doc.fillColor('#111827').fontSize(9).font('Helvetica').text(val1, 40, y + 12, { width: pageWidth / 2 - 20 });
          doc.fillColor('#374151').fontSize(9).font('Helvetica-Bold').text(label2, 40 + pageWidth / 2, y, { continued: false });
          doc.fillColor('#111827').fontSize(9).font('Helvetica').text(val2, 40 + pageWidth / 2, y + 12, { width: pageWidth / 2 - 20 });
          y += 28;
        };

        const addFourCol = (items) => {
          if (y > doc.page.height - 60) { doc.addPage(); y = 40; }
          const colW = pageWidth / 4;
          items.forEach((item, i) => {
            const x = 40 + i * colW;
            doc.rect(x, y, colW - 4, 40).fill('#f3f4f6');
            doc.fillColor('#6b7280').fontSize(8).font('Helvetica').text(item.label, x + 8, y + 6, { width: colW - 16 });
            doc.fillColor('#111827').fontSize(14).font('Helvetica-Bold').text(item.value, x + 8, y + 18, { width: colW - 16 });
          });
          y += 50;
        };

        const addTable = (headers, rows, colWidths) => {
          if (y > doc.page.height - 80) { doc.addPage(); y = 40; }
          const totalW = colWidths.reduce((a, b) => a + b, 0);
          let x = 40;

          doc.rect(40, y, totalW, 20).fill('#16a34a');
          headers.forEach((h, i) => {
            doc.fillColor('white').fontSize(8).font('Helvetica-Bold')
              .text(h, x + 4, y + 6, { width: colWidths[i] - 8 });
            x += colWidths[i];
          });
          y += 20;

          rows.forEach((row, ri) => {
            if (y > doc.page.height - 40) { doc.addPage(); y = 40; }
            x = 40;
            const bgColor = ri % 2 === 0 ? '#ffffff' : '#f9fafb';
            doc.rect(40, y, totalW, 18).fill(bgColor);
            row.forEach((cell, ci) => {
              doc.fillColor('#374151').fontSize(8).font('Helvetica')
                .text(String(cell), x + 4, y + 4, { width: colWidths[ci] - 8 });
              x += colWidths[ci];
            });
            y += 18;
          });
          y += 10;
        };

        header();
        y = 80;

        addSectionTitle('1. Tong quan');
        addFourCol([
          { label: 'Tong don hang', value: stats.totalOrders.toLocaleString('vi-VN') },
          { label: 'Da giao', value: stats.deliveredOrders.toLocaleString('vi-VN') },
          { label: 'Dang cho', value: stats.pendingOrders.toLocaleString('vi-VN') },
          { label: 'Da huy', value: stats.cancelledOrders.toLocaleString('vi-VN') },
        ]);
        addFourCol([
          { label: 'Tong doanh thu', value: this.formatCurrency(stats.totalRevenue) },
          { label: 'Doanh thu thang', value: this.formatCurrency(stats.monthRevenue) },
          { label: 'Nguoi dung moi', value: stats.newUsersThisMonth.toLocaleString('vi-VN') },
          { label: 'San pham', value: stats.totalProducts.toLocaleString('vi-VN') },
        ]);

        addSectionTitle('2. Don hang theo trang thai');
        const statusRows = Object.entries(stats.ordersByStatus).map(([k, v]) => [
          VIETNAMESE_STATUS[k] || k,
          v.toLocaleString('vi-VN'),
        ]);
        addTable(['Trang thai', 'So luong'], statusRows, [pageWidth * 0.6, pageWidth * 0.4]);

        addSectionTitle('3. San pham ban chay');
        const productRows = topProducts.slice(0, 10).map(p => [
          p.name.substring(0, 25),
          p.seller.substring(0, 15),
          this.formatCurrency(p.price),
          String(p.soldCount),
        ]);
        addTable(['San pham', 'Nguoi ban', 'Gia', 'Da ban'], productRows,
          [pageWidth * 0.35, pageWidth * 0.2, pageWidth * 0.25, pageWidth * 0.2]);

        addSectionTitle('4. Nguoi ban noi bat');
        const sellerRows = topSellers.map(s => [
          s.fullName || 'N/A',
          s.email || '',
          String(s.totalOrders),
          this.formatCurrency(s.totalRevenue),
        ]);
        addTable(['Nguoi ban', 'Email', 'Don hang', 'Doanh thu'], sellerRows,
          [pageWidth * 0.3, pageWidth * 0.3, pageWidth * 0.2, pageWidth * 0.2]);

        addSectionTitle('5. Doanh thu theo ngay');
        const revenueRows = revenueByDay.slice(0, 15).map(r => [
          r.date,
          r.orders.toString(),
          this.formatCurrency(r.revenue),
        ]);
        addTable(['Ngay', 'Don hang', 'Doanh thu'], revenueRows,
          [pageWidth * 0.4, pageWidth * 0.3, pageWidth * 0.3]);

        doc.fillColor('#9ca3af').fontSize(8).font('Helvetica')
          .text('Generated by Chợ Truyền Thông Admin', 40, doc.page.height - 40);
        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  async generateExcel(data) {
    try {
      const { stats, topProducts, topSellers, revenueByDay, orders } = data;
      const workbook = new ExcelJS.Workbook();
      workbook.creator = 'Chợ Truyền Thông';
      workbook.created = new Date();

      const setHeader = (ws, headers) => {
        ws.getRow(1).values = headers;
        ws.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
        ws.getRow(1).fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FF16a34a' } };
        ws.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };
        ws.getRow(1).height = 22;
      };

      const setColWidths = (ws, widths) => {
        widths.forEach((w, i) => { ws.getColumn(i + 1).width = w; });
      };

      // --- Sheet 1: Dashboard ---
      const dashWs = workbook.addWorksheet('Tong quan');
      setColWidths(dashWs, [30, 25, 30, 25]);
      dashWs.addRow(['Bao cao tong quan - Chợ Truyền Thông', '', '', '']);
      dashWs.getRow(1).font = { bold: true, size: 16, color: { argb: 'FF16a34a' } };
      dashWs.getRow(1).height = 28;
      dashWs.mergeCells('A1:D1');
      dashWs.addRow(['Ngay tao: ' + new Date().toLocaleString('vi-VN'), '', '', '']);
      dashWs.addRow([]);

      dashWs.addRow(['Chi so', 'Gia tri', 'Chi so', 'Gia tri']);
      dashWs.getRow(4).font = { bold: true };
      dashWs.getRow(4).fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF3f4f6' } };

      const kpiRows = [
        ['Tong don hang', stats.totalOrders],
        ['Don da giao', stats.deliveredOrders],
        ['Don dang cho', stats.pendingOrders],
        ['Don da huy', stats.cancelledOrders],
        ['Tong doanh thu', stats.totalRevenue],
        ['Doanh thu thang', stats.monthRevenue],
        ['Nguoi dung moi thang', stats.newUsersThisMonth],
        ['Tong san pham', stats.totalProducts],
        ['San pham hoat dong', stats.activeProducts],
      ];
      kpiRows.forEach((r, i) => {
        const row = dashWs.addRow(r);
        row.getCell(2).numFmt = r[0].includes('doanh thu') ? '#,##0' : '0';
        if (i % 2 === 0) {
          row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
        }
      });

      // --- Sheet 2: Orders by Status ---
      const statusWs = workbook.addWorksheet('Don theo trang thai');
      setColWidths(statusWs, [30, 20]);
      setHeader(statusWs, ['Trang thai', 'So luong']);
      const statusRows = Object.entries(stats.ordersByStatus).map(([k, v]) => [
        VIETNAMESE_STATUS[k] || k, v
      ]);
      statusRows.forEach((r, i) => {
        const row = statusWs.addRow(r);
        if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
      });

      // --- Sheet 3: Revenue by Day ---
      const revenueWs = workbook.addWorksheet('Doanh thu theo ngay');
      setColWidths(revenueWs, [20, 20, 20]);
      setHeader(revenueWs, ['Ngay', 'Don hang', 'Doanh thu (VND)']);
      revenueByDay.forEach((r, i) => {
        const row = revenueWs.addRow([r.date, r.orders, r.revenue]);
        row.getCell(3).numFmt = '#,##0';
        if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
      });

      // --- Sheet 4: Top Products ---
      const prodWs = workbook.addWorksheet('San pham ban chay');
      setColWidths(prodWs, [30, 20, 20, 15, 15, 15]);
      setHeader(prodWs, ['San pham', 'Nguoi ban', 'Loai', 'Gia (VND)', 'Da ban', 'Ton kho']);
      topProducts.forEach((p, i) => {
        const row = prodWs.addRow([p.name, p.seller, p.category, p.price, p.soldCount, p.stock]);
        row.getCell(4).numFmt = '#,##0';
        if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
      });

      // --- Sheet 5: Top Sellers ---
      const sellerWs = workbook.addWorksheet('Nguoi ban noi bat');
      setColWidths(sellerWs, [25, 30, 20, 20]);
      setHeader(sellerWs, ['Ho ten', 'Email', 'Don hang', 'Doanh thu (VND)']);
      topSellers.forEach((s, i) => {
        const row = sellerWs.addRow([s.fullName || 'N/A', s.email || '', s.totalOrders, s.totalRevenue]);
        row.getCell(4).numFmt = '#,##0';
        if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
      });

      // --- Sheet 6: Order Details ---
      const orderWs = workbook.addWorksheet('Chi tiet don hang');
      setColWidths(orderWs, [20, 20, 25, 15, 15, 20, 20, 15]);
      setHeader(orderWs, ['Ma don', 'Ngay tao', 'Khach hang', 'Tong (VND)', 'Phi ship', 'Trang thai', 'PT thanh toan', 'So dien thoai']);
      orders.forEach((o, i) => {
        const row = orderWs.addRow([
          o.orderNumber,
          this.formatDate(o.createdAt),
          o.buyerId?.fullName || 'N/A',
          o.total,
          o.shippingFee,
          VIETNAMESE_STATUS[o.status] || o.status,
          o.paymentMethod?.toUpperCase() || '',
          o.deliveryAddress?.contactPhone || '',
        ]);
        row.getCell(4).numFmt = '#,##0';
        row.getCell(5).numFmt = '#,##0';
        if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
      });

      // --- Sheet 7: All Users ---
      const userWs = workbook.addWorksheet('Nguoi dung');
      setColWidths(userWs, [30, 30, 20, 15, 15]);
      setHeader(userWs, ['Ho ten', 'Email', 'So dien thoai', 'Vai tro', 'Trang thai']);
      const users = await User.find().select('fullName email phone role status createdAt').lean();
      users.forEach((u, i) => {
        const row = userWs.addRow([u.fullName, u.email, u.phone || '', u.role, u.status]);
        if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
      });

      const buffer = await workbook.xlsx.writeBuffer();
      return buffer;
    } catch (err) {
      throw err;
    }
  }

  async generateActivityLog() {
    const now = new Date();
    const start = new Date(now);
    start.setDate(start.getDate() - 30);

    const recentOrders = await Order.find({ createdAt: { $gte: start } })
      .populate('buyerId', 'fullName')
      .populate('shipperId', 'fullName')
      .sort({ updatedAt: -1 })
      .limit(200)
      .lean();

    const recentUsers = await User.find({ updatedAt: { $gte: start } })
      .select('fullName email role status updatedAt createdAt')
      .sort({ updatedAt: -1 })
      .limit(100)
      .lean();

    return { recentOrders, recentUsers, generatedAt: now };
  }

  generateActivityLogPDF(data) {
    return new Promise((resolve, reject) => {
      try {
        const { recentOrders, recentUsers, generatedAt } = data;
        const doc = new PDFDocument({ margin: 40, size: 'A4' });
        const chunks = [];

        doc.on('data', chunk => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        const pageWidth = doc.page.width - 80;

        doc.rect(0, 0, doc.page.width, 60).fill('#0f172a');
        doc.fillColor('white').fontSize(18).font('Helvetica-Bold')
          .text('CHO TRUYEN THONG', 40, 18, { lineBreak: false });
        doc.fontSize(10).font('Helvetica').text('Nhật ký hoạt động hệ thống', 40, 38);
        doc.text(`Ngày tạo: ${new Date().toLocaleDateString('vi-VN')}`, doc.page.width - 160, 38);

        let y = 80;

        const addSectionTitle = (title) => {
          if (y > doc.page.height - 100) { doc.addPage(); y = 40; }
          doc.rect(40, y, pageWidth, 1).fill('#0f172a');
          y += 10;
          doc.fillColor('#0f172a').fontSize(12).font('Helvetica-Bold').text(title, 40, y);
          y += 20;
        };

        const addTable = (headers, rows, colWidths) => {
          if (y > doc.page.height - 60) { doc.addPage(); y = 40; }
          const totalW = colWidths.reduce((a, b) => a + b, 0);
          let x = 40;

          doc.rect(40, y, totalW, 20).fill('#0f172a');
          headers.forEach((h, i) => {
            doc.fillColor('white').fontSize(8).font('Helvetica-Bold')
              .text(h, x + 4, y + 6, { width: colWidths[i] - 8 });
            x += colWidths[i];
          });
          y += 20;

          rows.slice(0, 50).forEach((row, ri) => {
            if (y > doc.page.height - 30) { doc.addPage(); y = 40; }
            x = 40;
            const bgColor = ri % 2 === 0 ? '#ffffff' : '#f9fafb';
            doc.rect(40, y, totalW, 18).fill(bgColor);
            row.forEach((cell, ci) => {
              const text = String(cell).substring(0, 30);
              doc.fillColor('#374151').fontSize(8).font('Helvetica')
                .text(text, x + 4, y + 4, { width: colWidths[ci] - 8 });
              x += colWidths[ci];
            });
            y += 18;
          });
          y += 10;
        };

        addSectionTitle('1. Don hang gan day');
        addTable(
          ['Ma don', 'Khach hang', 'Tong (VND)', 'Trang thai', 'Ngay tao'],
          recentOrders.map(o => [
            o.orderNumber,
            o.buyerId?.fullName || 'N/A',
            new Intl.NumberFormat('vi-VN').format(o.total),
            VIETNAMESE_STATUS[o.status] || o.status,
            this.formatDate(o.createdAt),
          ]),
          [pageWidth * 0.2, pageWidth * 0.25, pageWidth * 0.2, pageWidth * 0.2, pageWidth * 0.15]
        );

        addSectionTitle('2. Nguoi dung gan day');
        addTable(
          ['Ho ten', 'Email', 'Vai tro', 'Trang thai', 'Ngay tao'],
          recentUsers.map(u => [
            u.fullName,
            (u.email || '').substring(0, 30),
            u.role,
            u.status,
            this.formatDate(u.createdAt),
          ]),
          [pageWidth * 0.25, pageWidth * 0.25, pageWidth * 0.15, pageWidth * 0.15, pageWidth * 0.2]
        );

        doc.fillColor('#9ca3af').fontSize(8).font('Helvetica')
          .text('Generated by Chợ Truyền Thông Admin | Activity Log', 40, doc.page.height - 40);
        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  generateActivityLogExcel(data) {
    return new Promise((resolve, reject) => {
      try {
        const { recentOrders, recentUsers, generatedAt } = data;
        const workbook = new ExcelJS.Workbook();
        workbook.creator = 'Chợ Truyền Thông';
        workbook.created = new Date();

        const setHeader = (ws, headers) => {
          ws.getRow(1).values = headers;
          ws.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
          ws.getRow(1).fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FF0f172a' } };
          ws.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };
          ws.getRow(1).height = 22;
        };

        // --- Sheet 1: Orders ---
        const orderWs = workbook.addWorksheet('Don hang gan day');
        setHeader(orderWs, ['Ma don', 'Khach hang', 'Tong (VND)', 'Phi ship', 'Trang thai', 'PT thanh toan', 'Ngay tao', 'Nguoi giao']);
        setColWidths(orderWs, [20, 25, 15, 12, 20, 15, 20, 20]);
        recentOrders.forEach((o, i) => {
          const row = orderWs.addRow([
            o.orderNumber,
            o.buyerId?.fullName || 'N/A',
            o.total,
            o.shippingFee,
            VIETNAMESE_STATUS[o.status] || o.status,
            o.paymentMethod?.toUpperCase() || '',
            this.formatDate(o.createdAt),
            o.shipperId?.fullName || 'Chua co',
          ]);
          row.getCell(3).numFmt = '#,##0';
          row.getCell(4).numFmt = '#,##0';
          if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
        });

        // --- Sheet 2: Users ---
        const userWs = workbook.addWorksheet('Nguoi dung');
        setHeader(userWs, ['Ho ten', 'Email', 'So dien thoai', 'Vai tro', 'Trang thai', 'Ngay tao', 'Ngay cap nhat']);
        setColWidths(userWs, [25, 30, 20, 15, 15, 20, 20]);
        recentUsers.forEach((u, i) => {
          const row = userWs.addRow([
            u.fullName,
            u.email || '',
            u.phone || '',
            u.role,
            u.status,
            this.formatDate(u.createdAt),
            this.formatDate(u.updatedAt),
          ]);
          if (i % 2 === 0) row.fill = { type: 'patternFill', patternType: 'solid', fgColor: { argb: 'FFF9fafb' } };
        });

        workbook.xlsx.writeBuffer().then(buffer => resolve(buffer)).catch(reject);
      } catch (err) {
        reject(err);
      }
    });
  }
}

module.exports = new ReportService();
