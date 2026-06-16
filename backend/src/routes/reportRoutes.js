const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);
router.use(authorize('admin'));

router.get('/export-report/pdf', reportController.exportReportPDF);
router.get('/export-report/excel', reportController.exportReportExcel);

router.get('/export-activity-log/pdf', reportController.exportActivityLogPDF);
router.get('/export-activity-log/excel', reportController.exportActivityLogExcel);

router.get('/data', reportController.getReportData);

module.exports = router;
