// ============================================================
// garden_routes.js — API แปลงสวน
//
// GET /api/gardens/:user_id, POST/PUT/DELETE /api/gardens, GET /api/gardens/:garden_id/varieties
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const garden = require('../models/garden');
const { logIfOk } = require('../libs/log_action');

const router = express.Router();

/** แปลงสวนของ user */
router.get('/api/gardens/:user_id', async (req, res) => {
  try {
    const userId = req.params.user_id;
    if (garden && typeof garden.getGardensByUserId === 'function') {
      const result = await garden.getGardensByUserId(userId);
      res.json(result);
    } else {
      res.json({ isError: true, data: [], errorMessage: "ยังไม่ได้สร้างฟังก์ชัน getGardensByUserId ใน models/garden.js" });
    }
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** เพิ่มแปลงสวน */
router.post('/api/gardens', async (req, res) => {
  try {
    if (garden && typeof garden.createGarden === 'function') {
      const result = await garden.createGarden(req.body);
      if (result.isError) return res.status(500).json(result);
      logIfOk(result, req.body.user_id, 'ADD_GARDEN', req);
      res.status(201).json(result);
    } else {
      res.status(500).json({ isError: true, errorMessage: "ไม่พบฟังก์ชัน createGarden ใน models/garden.js" });
    }
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขแปลงสวน (body ต้องมี user_id) */
router.put('/api/gardens/:garden_id', async (req, res) => {
  try {
    const { garden_id } = req.params;
    const result = await garden.updateGarden(garden_id, req.body);
    logIfOk(result, req.body.user_id, 'EDIT_GARDEN', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบแปลงสวน ?user_id= (ลบผลผลิต/การดูแล/รายการเงินที่ผูกกับแปลงนี้ด้วย) */
router.delete('/api/gardens/:garden_id', async (req, res) => {
  try {
    const { garden_id } = req.params;
    const result = await garden.deleteGarden(garden_id, req.query.user_id);
    logIfOk(result, req.query.user_id, 'DELETE_GARDEN', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** พันธุ์ปาล์มที่ปลูกในแปลง */
router.get('/api/gardens/:garden_id/varieties', async (req, res) => {
  try {
    const { garden_id } = req.params;
    const result = await garden.getGardenVarieties(garden_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
