// ============================================================
// variety_routes.js — API พันธุ์ปาล์มของผู้ใช้
//
// GET/POST/PUT/DELETE /api/varieties
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const palmVariety = require('../models/palm_variety');
const { logIfOk } = require('../libs/log_action');

const router = express.Router();

// API สำหรับดึงข้อมูลพันธุ์ปาล์มน้ำมัน
router.get('/api/varieties', async (req, res) => {
  try {
    const result = await palmVariety.getAll(req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** เพิ่มพันธุ์ปาล์ม */
router.post('/api/varieties', async (req, res) => {
  try {
    const result = await palmVariety.create(req.body);
    logIfOk(result, req.body.user_id, 'ADD_VARIETY', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขพันธุ์ปาล์ม */
router.put('/api/varieties/:variety_id', async (req, res) => {
  try {
    const result = await palmVariety.update(req.params.variety_id, req.body);
    logIfOk(result, req.body.user_id, 'EDIT_VARIETY', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบพันธุ์ปาล์ม */
router.delete('/api/varieties/:variety_id', async (req, res) => {
  try {
    const result = await palmVariety.remove(req.params.variety_id, req.query.user_id);
    logIfOk(result, req.query.user_id, 'DELETE_VARIETY', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
