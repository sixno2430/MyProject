// ============================================================
// admin_routes.js — API ผู้ดูแลระบบ (role R001)
//
// ทุก route ผ่าน requireAdmin: ต้องส่ง admin_id (query หรือ body) และต้องเป็นบัญชี R001 จริง
// GET /api/admin/overview, /users (+ POST/PUT, PUT /users/:id/status), /logs, /report
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const userAccount = require('../models/user_account');
const report = require('../models/report');
const admin = require('../models/admin');

const router = express.Router();

async function requireAdmin(req, res, next) {
  try {
    const adminId = req.query.admin_id || (req.body && req.body.admin_id);
    if (!(await admin.isAdmin(adminId))) {
      return res.status(403).json({ isError: true, data: null, errorMessage: 'เฉพาะผู้ดูแลระบบเท่านั้น' });
    }
    next();
  } catch (error) {
    res.status(500).json({ isError: true, data: null, errorMessage: error.message });
  }
}

/** ตัวเลขภาพรวมระบบ */
router.get('/api/admin/overview', requireAdmin, async (req, res) => {
  res.json(await admin.getOverview());
});

/** รายชื่อผู้ใช้ทั้งหมด + เข้าสู่ระบบล่าสุด */
router.get('/api/admin/users', requireAdmin, async (req, res) => {
  res.json(await admin.getUsers());
});

/** แอดมินเพิ่มผู้ใช้ */
router.post('/api/admin/users', requireAdmin, async (req, res) => {
  const result = await admin.createUser(req.body);
  if (!result.isError) userAccount.logAction(req.body.admin_id, 'ADD_USER', req.ip);
  res.json(result);
});

/** แอดมินแก้ไขผู้ใช้ (รหัสผ่านว่าง = คงเดิม) */
router.put('/api/admin/users/:user_id', requireAdmin, async (req, res) => {
  const result = await admin.updateUser(req.params.user_id, req.body);
  if (!result.isError) userAccount.logAction(req.body.admin_id, 'EDIT_USER', req.ip);
  res.json(result);
});

/** ระงับ / เปิดใช้บัญชี  body: { admin_id, status: 'active' | 'suspended' } */
router.put('/api/admin/users/:user_id/status', requireAdmin, async (req, res) => {
  const { admin_id, status } = req.body;
  const result = await admin.setUserStatus(admin_id, req.params.user_id, status);
  if (!result.isError) {
    userAccount.logAction(admin_id, status === 'suspended' ? 'SUSPEND_USER' : 'ACTIVATE_USER', req.ip);
  }
  res.json(result);
});

/** ประวัติการใช้งาน ?action= &user_id= &limit= */
router.get('/api/admin/logs', requireAdmin, async (req, res) => {
  res.json(await admin.getLogs(req.query));
});

/** รายงานระบบ: ?months=12 = ย้อนหลัง 1 ปี, ไม่ส่ง = 6 เดือน */
router.get('/api/admin/report', requireAdmin, async (req, res) => {
  res.json(await admin.getReport(req.query.months === '12' ? 12 : 6));
});

module.exports = router;
