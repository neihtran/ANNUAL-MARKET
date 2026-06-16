const reportService = require('../services/reportService');

class ReportController {
  async exportReportPDF(req, res, next) {
    try {
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({
          success: false,
          message: 'startDate và endDate là bắt buộc',
        });
      }

      const data = await reportService.generateReportData(startDate, endDate);
      const pdfBuffer = await reportService.generatePDF(data);

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="bao-cao-${startDate}-${endDate}.pdf"`);
      res.setHeader('Content-Length', pdfBuffer.length);
      res.end(pdfBuffer);
    } catch (error) {
      next(error);
    }
  }

  async exportReportExcel(req, res, next) {
    try {
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({
          success: false,
          message: 'startDate và endDate là bắt buộc',
        });
      }

      const data = await reportService.generateReportData(startDate, endDate);
      const excelBuffer = await reportService.generateExcel(data);

      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename="bao-cao-${startDate}-${endDate}.xlsx"`);
      res.setHeader('Content-Length', excelBuffer.length);
      res.end(excelBuffer);
    } catch (error) {
      next(error);
    }
  }

  async exportActivityLogPDF(req, res, next) {
    try {
      const data = await reportService.generateActivityLog();
      const pdfBuffer = await reportService.generateActivityLogPDF(data);

      const now = new Date().toISOString().split('T')[0];
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="nhat-ky-hoat-dong-${now}.pdf"`);
      res.setHeader('Content-Length', pdfBuffer.length);
      res.end(pdfBuffer);
    } catch (error) {
      next(error);
    }
  }

  async exportActivityLogExcel(req, res, next) {
    try {
      const data = await reportService.generateActivityLog();
      const excelBuffer = await reportService.generateActivityLogExcel(data);

      const now = new Date().toISOString().split('T')[0];
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename="nhat-ky-hoat-dong-${now}.xlsx"`);
      res.setHeader('Content-Length', excelBuffer.length);
      res.end(excelBuffer);
    } catch (error) {
      next(error);
    }
  }

  async getReportData(req, res, next) {
    try {
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        return res.status(400).json({
          success: false,
          message: 'startDate và endDate là bắt buộc',
        });
      }

      const data = await reportService.generateReportData(startDate, endDate);
      res.json({
        success: true,
        message: 'Lấy dữ liệu báo cáo thành công',
        data,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReportController();
