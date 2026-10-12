// ============================================================
// shop_routes.js — API ร้านรับซื้อ
//
// GET /api/shops (เกษตรกรดูรายชื่อร้าน + ราคา) และ /api/shop/... ของฝั่งร้าน:
// ข้อมูลร้าน, ราคา, รับซื้อ / แก้ / ยกเลิก, ไม่รับล็อต, ล็อตที่ส่งมา, ค้นหาเกษตรกร, หน้าแรก, รายงาน
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const userAccount = require('../models/user_account');
const dashboard = require('../models/dashboard');
const shop = require('../models/shop');
const { logIfOk } = require('../libs/log_action');

const router = express.Router();

/** รายชื่อร้านรับซื้อ + ราคาล่าสุด สำหรับเกษตรกร ?user_id= */
router.get('/api/shops', async (req, res) => {
  try {
    const result = await shop.getShops(req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** 1. ภาพ 4.3.2 ข้อมูลร้านของฉัน: ดึงข้อมูลร้านตาม user_id ที่ล็อกอิน */
router.get('/api/shop/profile/:user_id', async (req, res) => {
  try {
    const result = await shop.getShopByUserId(req.params.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

/** สร้างร้าน (บัญชีร้านรับซื้อที่ยังไม่มีร้าน) body: { user_id, shop_name, location, phone, open_schedule } */
router.post('/api/shop/profile', async (req, res) => {
  try {
    const result = await shop.createShop(req.body);
    logIfOk(result, req.body.user_id, 'ADD_SHOP', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขข้อมูลร้าน / เปิด-ปิดร้าน (body ต้องมี user_id ของเจ้าของร้าน) */
router.put('/api/shop/profile/:shop_id', async (req, res) => {
  try {
    const result = await shop.updateShopProfile(req.params.shop_id, req.body);
    logIfOk(result, req.body.user_id, 'EDIT_SHOP', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** 2. ภาพ 4.3.3 กำหนดและจัดการราคารับซื้อ: ดึงรายการราคาตาม shop_id */
router.get('/api/shop/:shop_id/prices', async (req, res) => {
  try {
    const result = await shop.getPriceRates(req.params.shop_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** ลบราคา 1 รายการ ?user_id= */
router.delete('/api/shop/prices/:price_rate_id', async (req, res) => {
  try {
    const result = await shop.deletePriceRate(req.params.price_rate_id, req.query.user_id);
    logIfOk(result, req.query.user_id, 'DELETE_PRICE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** บันทึก/อัปเดตราคาปาล์มตามเกรด (body ต้องมี user_id ของเจ้าของร้าน) */
router.post('/api/shop/prices', async (req, res) => {
  try {
    const result = await shop.savePriceRate(req.body);
    if (!result.isError) userAccount.logAction(req.body.user_id, 'UPDATE_PRICE', req.ip);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** 3. ภาพ 4.3.4 บันทึกการรับซื้อผลผลิต: ดึงประวัติการรับซื้อของร้าน */
router.get('/api/shop/:shop_id/purchases', async (req, res) => {
  try {
    const result = await shop.getPurchasesByShop(req.params.shop_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** บันทึกการรับซื้อ แล้วผลผลิตฝั่งเกษตรกรเปลี่ยนเป็น "ขายแล้ว" อัตโนมัติ (body ต้องมี user_id เจ้าของร้าน) */
router.post('/api/shop/purchases', async (req, res) => {
  try {
    const result = await shop.createPurchase(req.body);
    if (!result.isError) userAccount.logAction(req.body.user_id, 'ADD_PURCHASE', req.ip);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขการรับซื้อ body: { user_id (เจ้าของร้าน), quantity, price_per_kg, purchase_date } */
router.put('/api/shop/purchases/:purchase_id', async (req, res) => {
  try {
    const result = await shop.updatePurchase(req.params.purchase_id, req.body);
    logIfOk(result, req.body.user_id, 'EDIT_PURCHASE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ยกเลิกการรับซื้อ (บันทึกผิด) -> ผลผลิตฝั่งเกษตรกรกลับเป็น "รอขาย" */
router.delete('/api/shop/purchases/:purchase_id', async (req, res) => {
  try {
    const result = await shop.cancelPurchase(req.params.purchase_id, req.query.user_id);
    logIfOk(result, req.query.user_id, 'CANCEL_PURCHASE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ร้านไม่รับล็อตที่เกษตรกรส่งมา: body { user_id (เจ้าของร้าน), shop_id, reason } */
router.post('/api/shop/harvests/:harvest_id/reject', async (req, res) => {
  try {
    const result = await shop.rejectHarvest({ ...req.body, harvest_id: req.params.harvest_id });
    logIfOk(result, req.body.user_id, 'REJECT_HARVEST', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ล็อตที่เกษตรกรเลือกขายให้ร้านนี้ และยังรอร้านยืนยันรับซื้อ: ?user_id=เจ้าของร้าน */
router.get('/api/shop/:shop_id/incoming', async (req, res) => {
  try {
    const result = await shop.getIncomingHarvests(req.params.shop_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** ค้นหาเกษตรกร (ชื่อ / เบอร์โทร / เลขบัตร) สำหรับหน้ารับซื้อ: ?user_id=เจ้าของร้าน&q=คำค้น */
router.get('/api/shop/farmers/search', async (req, res) => {
  try {
    const result = await shop.searchFarmers(req.query.user_id, req.query.q);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** ผลผลิตที่รอขายของเกษตรกร 1 คน: ?user_id=เจ้าของร้าน */
router.get('/api/shop/farmers/:farmer_id/harvests', async (req, res) => {
  try {
    const result = await shop.getPendingHarvests(req.query.user_id, req.params.farmer_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** 4. ภาพ 4.3.1 แดชบอร์ดสรุปภาพรวมร้านรับซื้อ */
router.get('/api/shop/:shop_id/dashboard', async (req, res) => {
  try {
    const result = await shop.getShopDashboard(req.params.shop_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

/** 5. ภาพ 4.3.5 รายงานสรุปการรับซื้อ (ยอดรับซื้อรายเดือน + Top เกษตรกร) */
router.get('/api/shop/:shop_id/reports', async (req, res) => {
  try {
    const result = await shop.getShopReports(req.params.shop_id, req.query.year);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

module.exports = router;
