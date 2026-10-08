// ============================================================
// server.js — เซิร์ฟเวอร์ API ของ PalmTrack (Express, พอร์ต 3000)
//
// รวมทุก route ของแอป แบ่งเป็นหมวด: ผู้ใช้/ล็อกอิน, Dashboard, แปลงสวน, ดูแลสวน,
// พันธุ์ปาล์ม, เก็บเกี่ยว, การเงิน, ร้านรับซื้อ/รายงาน, โปรไฟล์
// การคำนวณและ SQL อยู่ในโฟลเดอร์ models/ — ไฟล์นี้แค่รับ request แล้วเรียก model
//
// วิธีรัน: node server.js  (แก้ไฟล์แล้วต้องปิดตัวเก่าก่อนเปิดใหม่ ไม่งั้นตัวเก่ายังถือพอร์ตอยู่)
// ============================================================

const http = require('http');
const express = require('express');
const bp = require('body-parser');
const bcrypt = require('bcrypt');
const cors = require('cors');

// Import Models & Libs
const userAccount = require('./models/user_account');
const jwt = require('./libs/jwt');
const dashboard = require('./models/dashboard');
const garden = require('./models/garden');
const db = require('./libs/db_pool');
const care = require('./models/care'); 
const harvest = require('./models/harvest');
const finance = require('./models/finance');
const palmVariety = require('./models/palm_variety');
const report = require('./models/report');
const shop = require('./models/shop');
const fertilizer = require('./models/fertilizer');

const app = express();
app.use(cors());
app.use(bp.json());
app.use(bp.urlencoded({ extended: true }));

// แก้ปัญหา BigInt ไม่สามารถ serialize เป็น JSON ได้
BigInt.prototype.toJSON = function() {
  return Number(this);
};

const hostname = '0.0.0.0'; 
const port = require('./libs/config').port; // ตั้งใน .env (PORT) ไม่ตั้ง = 3000

// ==========================================
// USER & AUTHENTICATION API
// ==========================================

/** ปิดไว้: ไม่อนุญาตให้ดึงรายชื่อผู้ใช้ทั้งหมด */
app.get("/api/users", (req, res) => {
  res.status(401).json({
    isError: true,
    data: "You are unauthorized for this data"
  });
});

/** ข้อมูลผู้ใช้ 1 คน */
app.get('/api/user/:user_id', async (req, res) => {
  try {
    const userId = req.params.user_id;
    const response = await userAccount.getUserById(userId);
    res.json(response);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

// ตอนสมัครสมาชิก
app.post('/api/register', async (req, res) => {
  const { role_id, full_name, id_card, phone, username, password } = req.body;

  // สมัครเองได้แค่ เกษตรกร (R002) หรือ ร้านรับซื้อ (R003) — กันการยิง API สมัครเป็นแอดมิน (R001)
  if (role_id && !['R002', 'R003'].includes(role_id)) {
    return res.json({ isError: true, errorMessage: 'ประเภทผู้ใช้ไม่ถูกต้อง', data: null });
  }

  if (!role_id || !full_name || !id_card || !phone || !username || !password) {
    return res.json({
      isError: true,
      errorMessage: 'กรุณากรอกข้อมูลให้ครบถ้วน',
      data: null
    });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    const idResult = await userAccount.getNextUserId();
    if (idResult.isError) {
      return res.json(idResult);
    }
    const userId = idResult.data;

    const result = await userAccount.createUser(
      userId, role_id, id_card, full_name, phone, username, hashedPassword
    );

    res.json(result);
  } catch (error) {
    console.error('Register error:', error);
    res.json({
      isError: true,
      errorMessage: 'เกิดข้อผิดพลาด: ' + error.message,
      data: null
    });
  }
});

// ตอน login
// body: { username, password, role_id? }
//   role_id = บทบาทที่ผู้ใช้เลือกในหน้าล็อกอิน (R002 ชาวสวน / R003 ร้านรับซื้อ)
//   ถ้าไม่ตรงกับบทบาทจริงของบัญชี จะไม่ให้เข้าสู่ระบบ (บัญชีชาวสวนเข้าฝั่งร้านไม่ได้ และกลับกัน)
const ROLE_LABELS = { R001: 'ผู้ดูแลระบบ', R002: 'ชาวสวน', R003: 'ร้านรับซื้อ' };

app.post('/api/authen_request', async (req, res) => {
  try {
    const { username, password, role_id: requestedRole } = req.body;
    const result = await userAccount.getUserByUsername(username);

    if (result.isError || !result.data || result.data.length === 0) {
      return res.json({ isError: true, data: "", errorMessage: 'ไม่พบผู้ใช้งาน' });
    }

    const user = result.data[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.json({ isError: true, data: "", errorMessage: 'รหัสผ่านไม่ถูกต้อง' });
    }

    // ตรวจบทบาทหลังรหัสผ่านถูกแล้วเท่านั้น (ไม่บอกคนที่เดารหัสว่าบัญชีนี้เป็นบทบาทอะไร)
    if (requestedRole && requestedRole !== user.role_id) {
      const actual = ROLE_LABELS[user.role_id] || 'บทบาทอื่น';
      return res.json({
        isError: true,
        data: "",
        errorMessage: `บัญชีนี้เป็นบัญชี${actual} กรุณาเลือกบทบาท "${actual}" แล้วเข้าสู่ระบบใหม่`
      });
    }

    // ใส่ role_id ไว้ใน token ด้วย วันหลังจะใช้ตรวจสิทธิ์ API เฉพาะร้านรับซื้อ/ชาวสวนได้
    const authenToken = jwt.sign(
      { user_id: user.user_id, username: user.username, role_id: user.role_id },
      '5m'
    );

    res.json({ 
      isError: false, 
      data: authenToken, 
      user_id: user.user_id,
      role_id: user.role_id, 
      errorMessage: "" 
    });
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: "" });
  }
});

// แลก accessToken
app.post('/api/access_request', async (req, res) => {
  const { token } = req.body;
  try {
    const decoded = await jwt.verify(token);
    const accessToken = jwt.sign(
      { user_id: decoded.user_id, username: decoded.username, role_id: decoded.role_id },
      '1d'
    );
    res.json({ isError: false, data: accessToken, errorMessage: "" });
  } catch (error) {
    res.json({ isError: true, data: "", errorMessage: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
});

// ==========================================
// DASHBOARD API (เกษตรกร)
// ==========================================

/** ข้อมูลสรุปหน้า Dashboard */
app.get('/api/dashboard/:user_id', async (req, res) => {
  try {
    const userId = req.params.user_id;
    const result = await dashboard.getDashboardSummary(userId);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

/** ประวัติกิจกรรมทั้งหมด ?limit= จำกัดจำนวนได้ */
app.get('/api/activities/:user_id', async (req, res) => {
  try {
    const result = await dashboard.getActivities(req.params.user_id, req.query.limit);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// ==========================================
// GARDEN API
// ==========================================

/** แปลงสวนของ user (?user_id=) — เดิมส่งแปลงของทุก user ออกไป ไม่ส่ง user_id = ได้รายการว่าง */
app.get('/api/gardens', async (req, res) => {
  try {
    const userId = req.query.user_id;
    if (!userId) return res.json({ isError: false, data: [], errorMessage: '' });
    if (garden && typeof garden.getGardensByUserId === 'function') {
      const result = await garden.getGardensByUserId(userId);
      return res.json(result);
    }
    
    const rows = await db.query(`SELECT garden_id AS id, garden_name AS name FROM garden WHERE user_id = ?`, [userId]);
    res.json({ isError: false, data: rows });
  } catch (error) {
    console.error('Error fetching gardens:', error);
    res.status(500).json({ isError: true, data: [], errorMessage: error.message });
  }
});

/** แปลงสวนของ user */
app.get('/api/gardens/:user_id', async (req, res) => {
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
app.post('/api/gardens', async (req, res) => {
  try {
    if (garden && typeof garden.createGarden === 'function') {
      const result = await garden.createGarden(req.body);
      if (result.isError) return res.status(500).json(result);
      res.status(201).json(result);
    } else {
      res.status(500).json({ isError: true, errorMessage: "ไม่พบฟังก์ชัน createGarden ใน models/garden.js" });
    }
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขแปลงสวน (body ต้องมี user_id) */
app.put('/api/gardens/:garden_id', async (req, res) => {
  try {
    const { garden_id } = req.params;
    const result = await garden.updateGarden(garden_id, req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบแปลงสวน ?user_id= (ลบผลผลิต/การดูแล/รายการเงินที่ผูกกับแปลงนี้ด้วย) */
app.delete('/api/gardens/:garden_id', async (req, res) => {
  try {
    const { garden_id } = req.params;
    const result = await garden.deleteGarden(garden_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** พันธุ์ปาล์มที่ปลูกในแปลง */
app.get('/api/gardens/:garden_id/varieties', async (req, res) => {
  try {
    const { garden_id } = req.params;
    const result = await garden.getGardenVarieties(garden_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// ==========================================
// PALM CARE & VARIETIES API
// ==========================================

/** รายการดูแลสวน ?user_id= (คืนเป็น array ตรงๆ) */
app.get('/api/care-logs', async (req, res) => {
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

// รายชื่อปุ๋ย สำหรับ dropdown ตอนบันทึก "ใส่ปุ๋ย"
app.get('/api/fertilizers', async (req, res) => {
  try {
    const result = await fertilizer.getAll();
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** เพิ่มรายการดูแลสวน (body ต้องมี user_id) */
app.post('/api/care-logs', async (req, res) => {
  try {
    const result = await care.createCareLog(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขรายการดูแลสวน (body ต้องมี user_id) */
app.put('/api/care-logs/:care_id', async (req, res) => {
  try {
    const result = await care.updateCareLog(req.params.care_id, req.body.user_id, req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบรายการดูแลสวน ?user_id= */
app.delete('/api/care-logs/:care_id', async (req, res) => {
  try {
    const result = await care.deleteCareLog(req.params.care_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// API สำหรับดึงข้อมูลพันธุ์ปาล์มน้ำมัน
app.get('/api/varieties', async (req, res) => {
  try {
    const result = await palmVariety.getAll(req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** เพิ่มพันธุ์ปาล์ม */
app.post('/api/varieties', async (req, res) => {
  try {
    const result = await palmVariety.create(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขพันธุ์ปาล์ม */
app.put('/api/varieties/:variety_id', async (req, res) => {
  try {
    const result = await palmVariety.update(req.params.variety_id, req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบพันธุ์ปาล์ม */
app.delete('/api/varieties/:variety_id', async (req, res) => {
  try {
    const result = await palmVariety.remove(req.params.variety_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// ==========================================
// HARVEST API
// ==========================================

/** รายการเก็บเกี่ยว ?user_id= &garden_id= &year= (ไม่ส่ง year = ปีนี้) */
app.get('/api/harvests', async (req, res) => {
  try {
    const { garden_id: gardenId, user_id: userId, year } = req.query;
    const result = await harvest.getAllHarvests(gardenId, userId, parseInt(year, 10) || null);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** สรุปการเก็บเกี่ยว ?user_id= &garden_id= &year= (ไม่ส่ง year = ปีนี้) */
app.get('/api/harvests/summary', async (req, res) => {
  try {
    const { garden_id: gardenId, user_id: userId, year } = req.query;
    const result = await harvest.getSummary(gardenId, userId, parseInt(year, 10) || null);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** บันทึกการเก็บเกี่ยว */
app.post('/api/harvests', async (req, res) => {
  try {
    const result = await harvest.createHarvest(req.body);
    if (result.isError) {
      return res.status(500).json(result);
    }
    res.status(201).json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// เปลี่ยนสถานะ "รอขาย" -> "ขายแล้ว" body: { user_id, price_per_kg, shop_id? }
app.put('/api/harvests/:harvest_id/sell', async (req, res) => {
  try {
    const result = await harvest.sellHarvest(req.params.harvest_id, req.body.user_id, req.body.price_per_kg, req.body.buyer_name, req.body.sold_date, req.body.quality_grade);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขการเก็บเกี่ยว (body ต้องมี user_id) */
app.put('/api/harvests/:harvest_id', async (req, res) => {
  try {
    const result = await harvest.updateHarvest(req.params.harvest_id, req.body.user_id, req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบการเก็บเกี่ยว ?user_id= */
app.delete('/api/harvests/:harvest_id', async (req, res) => {
  try {
    const result = await harvest.deleteHarvest(req.params.harvest_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// ==========================================
// FINANCE API (รายรับ - รายจ่าย)
// ==========================================

/** ยอดรวมรายรับ-รายจ่าย ?month=yyyy-MM &user_id= */
app.get('/api/finance/summary', async (req, res) => {
  try {
    const { month, user_id } = req.query;
    const result = await finance.getSummary(month, user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** รายการเงิน ?month= &type=income|expense|all &user_id= */
app.get('/api/finance/transactions', async (req, res) => {
  try {
    const { month, type, user_id } = req.query;
    const result = await finance.getTransactions(month, type, user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** บันทึกรายการเงินใหม่ */
app.post('/api/finance/add', async (req, res) => {
  try {
    const result = await finance.createTransaction(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขรายการเงิน (เฉพาะ FN...) */
app.put('/api/finance/:finance_id', async (req, res) => {
  try {
    const result = await finance.updateTransaction(req.params.finance_id, req.body.user_id, req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบรายการเงิน (เฉพาะ FN...) ?user_id= */
app.delete('/api/finance/:finance_id', async (req, res) => {
  try {
    const result = await finance.deleteTransaction(req.params.finance_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// ==========================================
// PASSWORD / REPORT / เกษตรกรดูร้านค้า
// ==========================================

/** เปลี่ยนรหัสผ่าน body: { old_password, new_password } */
app.put('/api/user/:user_id/password', async (req, res) => {
  try {
    const { old_password, new_password } = req.body;
    if (!old_password || !new_password) {
      return res.json({ isError: true, errorMessage: 'กรุณากรอกรหัสผ่านให้ครบ' });
    }
    if (new_password.length < 8) {
      return res.json({ isError: true, errorMessage: 'รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัว' });
    }
    const result = await userAccount.changePassword(req.params.user_id, old_password, new_password);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** รายชื่อร้านรับซื้อ + ราคาล่าสุด สำหรับเกษตรกร ?user_id= */
app.get('/api/shops', async (req, res) => {
  try {
    const result = await shop.getShops(req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** รายงานสรุปประจำปี ?year= */
app.get('/api/report/:user_id', async (req, res) => {
  try {
    const year = parseInt(req.query.year, 10) || new Date().getFullYear();
    const result = await report.getYearlyReport(req.params.user_id, year);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

// ==========================================
// SHOP OWNER API (ฝั่งร้านรับซื้อ - ภาพ 4.3.1 ถึง 4.3.5)
// ==========================================

/** 1. ภาพ 4.3.2 ข้อมูลร้านของฉัน: ดึงข้อมูลร้านตาม user_id ที่ล็อกอิน */
app.get('/api/shop/profile/:user_id', async (req, res) => {
  try {
    const result = await shop.getShopByUserId(req.params.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

/** สร้างร้าน (บัญชีร้านรับซื้อที่ยังไม่มีร้าน) body: { user_id, shop_name, location, phone, open_schedule } */
app.post('/api/shop/profile', async (req, res) => {
  try {
    const result = await shop.createShop(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขข้อมูลร้าน / เปิด-ปิดร้าน (body ต้องมี user_id ของเจ้าของร้าน) */
app.put('/api/shop/profile/:shop_id', async (req, res) => {
  try {
    const result = await shop.updateShopProfile(req.params.shop_id, req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** 2. ภาพ 4.3.3 กำหนดและจัดการราคารับซื้อ: ดึงรายการราคาตาม shop_id */
app.get('/api/shop/:shop_id/prices', async (req, res) => {
  try {
    const result = await shop.getPriceRates(req.params.shop_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** ลบราคา 1 รายการ ?user_id= */
app.delete('/api/shop/prices/:price_rate_id', async (req, res) => {
  try {
    const result = await shop.deletePriceRate(req.params.price_rate_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** บันทึก/อัปเดตราคาปาล์มตามเกรด (body ต้องมี user_id ของเจ้าของร้าน) */
app.post('/api/shop/prices', async (req, res) => {
  try {
    const result = await shop.savePriceRate(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** 3. ภาพ 4.3.4 บันทึกการรับซื้อผลผลิต: ดึงประวัติการรับซื้อของร้าน */
app.get('/api/shop/:shop_id/purchases', async (req, res) => {
  try {
    const result = await shop.getPurchasesByShop(req.params.shop_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** บันทึกการรับซื้อ แล้วผลผลิตฝั่งเกษตรกรเปลี่ยนเป็น "ขายแล้ว" อัตโนมัติ (body ต้องมี user_id เจ้าของร้าน) */
app.post('/api/shop/purchases', async (req, res) => {
  try {
    const result = await shop.createPurchase(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ยกเลิกการรับซื้อ (บันทึกผิด) -> ผลผลิตฝั่งเกษตรกรกลับเป็น "รอขาย" */
app.delete('/api/shop/purchases/:purchase_id', async (req, res) => {
  try {
    const result = await shop.cancelPurchase(req.params.purchase_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ร้านไม่รับล็อตที่เกษตรกรส่งมา: body { user_id (เจ้าของร้าน), shop_id, reason } */
app.post('/api/shop/harvests/:harvest_id/reject', async (req, res) => {
  try {
    const result = await shop.rejectHarvest({ ...req.body, harvest_id: req.params.harvest_id });
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ล็อตที่เกษตรกรเลือกขายให้ร้านนี้ และยังรอร้านยืนยันรับซื้อ: ?user_id=เจ้าของร้าน */
app.get('/api/shop/:shop_id/incoming', async (req, res) => {
  try {
    const result = await shop.getIncomingHarvests(req.params.shop_id, req.query.user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** ค้นหาเกษตรกร (ชื่อ / เบอร์โทร / เลขบัตร) สำหรับหน้ารับซื้อ: ?user_id=เจ้าของร้าน&q=คำค้น */
app.get('/api/shop/farmers/search', async (req, res) => {
  try {
    const result = await shop.searchFarmers(req.query.user_id, req.query.q);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** ผลผลิตที่รอขายของเกษตรกร 1 คน: ?user_id=เจ้าของร้าน */
app.get('/api/shop/farmers/:farmer_id/harvests', async (req, res) => {
  try {
    const result = await shop.getPendingHarvests(req.query.user_id, req.params.farmer_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: [] });
  }
});

/** 4. ภาพ 4.3.1 แดชบอร์ดสรุปภาพรวมร้านรับซื้อ */
app.get('/api/shop/:shop_id/dashboard', async (req, res) => {
  try {
    const result = await shop.getShopDashboard(req.params.shop_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

/** 5. ภาพ 4.3.5 รายงานสรุปการรับซื้อ (ยอดรับซื้อรายเดือน + Top เกษตรกร) */
app.get('/api/shop/:shop_id/reports', async (req, res) => {
  try {
    const result = await shop.getShopReports(req.params.shop_id, req.query.year);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: null });
  }
});

// ==========================================
// USER PROFILE ROUTER
// ==========================================

app.use('/api/profile', require('./routes/profile_routes'));

// Start Server
app.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}`);
});