// ============================================================
// care_routes.js — API การดูแลสวน (ใส่ปุ๋ยหลายชนิด, ให้น้ำ, ตัดแต่ง ...)
//
// GET/POST/PUT/DELETE /api/care-logs, GET /api/care-logs/:care_id (รายการเดียวพร้อมปุ๋ยทุกชนิด),
// GET /api/fertilizers/used (ชื่อปุ๋ยที่ผู้ใช้เคยบันทึก)
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const userAccount = require('../models/user_account');
const care = require('../models/care');
const fertilizer = require('../models/fertilizer');
const { logIfOk } = require('../libs/log_action');

const router = express.Router();

/** รายการดูแลสวน ?user_id= (คืนเป็น array ตรงๆ) */
router.get('/api/care-logs', async (req, res) => {
  try {
    const result = await care.getCareLogs(req.query.user_id);
    if (result.isError) {
      return res.status(500).json({ message: 'Error fetching care logs', error: result.errorMessage });
    }
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching care logs', error: error.message });
  }
});

/** ชื่อปุ๋ยที่ผู้ใช้เคยบันทึก (รายการแนะนำในฟอร์มใส่ปุ๋ย) ?user_id= */
router.get('/api/fertilizers/used', async (req, res) => {
  try {
    res.json(await fertilizer.getUsedByUser(req.query.user_id));
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** เพิ่มรายการดูแลสวน (body ต้องมี user_id) */
router.post('/api/care-logs', async (req, res) => {
  try {
    const result = await care.createCareLog(req.body);
    if (!result.isError) userAccount.logAction(req.body.user_id, 'ADD_CARE', req.ip);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขรายการดูแลสวน (body ต้องมี user_id) */
router.put('/api/care-logs/:care_id', async (req, res) => {
  try {
    const result = await care.updateCareLog(req.params.care_id, req.body.user_id, req.body);
    logIfOk(result, req.body.user_id, 'EDIT_CARE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** รายการดูแลสวน 1 รายการ พร้อมปุ๋ยทุกชนิด (ใช้เปิดฟอร์มแก้ไข) ?user_id= */
router.get('/api/care-logs/:care_id', async (req, res) => {
  try {
    const result = await care.getCareLog(req.params.care_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบรายการดูแลสวน ?user_id= */
router.delete('/api/care-logs/:care_id', async (req, res) => {
  try {
    const result = await care.deleteCareLog(req.params.care_id, req.query.user_id);
    logIfOk(result, req.query.user_id, 'DELETE_CARE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
