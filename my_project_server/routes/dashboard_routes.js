// ============================================================
// dashboard_routes.js — API หน้าหลักของเกษตรกร
//
// GET /api/dashboard/:user_id (ตัวเลขสรุป + กิจกรรมล่าสุด), GET /api/activities/:user_id (กิจกรรมทั้งหมด)
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const dashboard = require('../models/dashboard');

const router = express.Router();

/** ข้อมูลสรุปหน้า Dashboard */
router.get('/api/dashboard/:user_id', async (req, res) => {
  try {
    const userId = req.params.user_id;
    const result = await dashboard.getDashboardSummary(userId);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

/** ประวัติกิจกรรมทั้งหมด ?limit= จำกัดจำนวนได้ */
router.get('/api/activities/:user_id', async (req, res) => {
  try {
    const result = await dashboard.getActivities(req.params.user_id, req.query.limit);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
