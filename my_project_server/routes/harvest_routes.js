// ============================================================
// harvest_routes.js — API การเก็บเกี่ยว
//
// GET /api/harvests, GET /api/harvests/summary, POST/PUT/DELETE /api/harvests,
// PUT /api/harvests/:harvest_id/sell (ขายนอกระบบ)
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const userAccount = require('../models/user_account');
const harvest = require('../models/harvest');
const { logIfOk } = require('../libs/log_action');

const router = express.Router();

/** รายการเก็บเกี่ยว ?user_id= &garden_id= &year= (ไม่ส่ง year = ปีนี้) */
router.get('/api/harvests', async (req, res) => {
  try {
    const { garden_id: gardenId, user_id: userId, year } = req.query;
    const result = await harvest.getAllHarvests(gardenId, userId, parseInt(year, 10) || null);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** สรุปการเก็บเกี่ยว ?user_id= &garden_id= &year= (ไม่ส่ง year = ปีนี้) */
router.get('/api/harvests/summary', async (req, res) => {
  try {
    const { garden_id: gardenId, user_id: userId, year } = req.query;
    const result = await harvest.getSummary(gardenId, userId, parseInt(year, 10) || null);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** บันทึกการเก็บเกี่ยว */
router.post('/api/harvests', async (req, res) => {
  try {
    const result = await harvest.createHarvest(req.body);
    if (result.isError) {
      return res.status(500).json(result);
    }
    userAccount.logAction(req.body.user_id, 'ADD_HARVEST', req.ip);
    res.status(201).json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// เปลี่ยนสถานะ "รอขาย" -> "ขายแล้ว" body: { user_id, price_per_kg, shop_id? }
router.put('/api/harvests/:harvest_id/sell', async (req, res) => {
  try {
    const result = await harvest.sellHarvest(req.params.harvest_id, req.body.user_id, req.body.price_per_kg, req.body.buyer_name, req.body.sold_date, req.body.quality_grade);
    logIfOk(result, req.body.user_id, 'SELL_HARVEST', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขการเก็บเกี่ยว (body ต้องมี user_id) */
router.put('/api/harvests/:harvest_id', async (req, res) => {
  try {
    const result = await harvest.updateHarvest(req.params.harvest_id, req.body.user_id, req.body);
    logIfOk(result, req.body.user_id, 'EDIT_HARVEST', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบการเก็บเกี่ยว ?user_id= */
router.delete('/api/harvests/:harvest_id', async (req, res) => {
  try {
    const result = await harvest.deleteHarvest(req.params.harvest_id, req.query.user_id);
    logIfOk(result, req.query.user_id, 'DELETE_HARVEST', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
