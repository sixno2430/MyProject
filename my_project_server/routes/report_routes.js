// ============================================================
// report_routes.js — API รายงานสรุปของเกษตรกร
//
// GET /api/report/:user_id?year=&month=
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const report = require('../models/report');

const router = express.Router();

/** รายงานสรุปประจำปี ?year= */
router.get('/api/report/:user_id', async (req, res) => {
  try {
    const year = parseInt(req.query.year, 10) || new Date().getFullYear();
    // ?month=1-12 = รายงานรายเดือน, ไม่ส่ง = รายปี
    const month = parseInt(req.query.month, 10);
    const result = await report.getYearlyReport(req.params.user_id, year, month >= 1 && month <= 12 ? month : null);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
