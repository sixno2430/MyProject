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

const app = express();
app.use(cors());
app.use(bp.json());
app.use(bp.urlencoded({ extended: true }));

// แก้ปัญหา BigInt ไม่สามารถ serialize เป็น JSON ได้
BigInt.prototype.toJSON = function() {
  return Number(this);
};

const hostname = '0.0.0.0'; 
const port = 3000;

// ==========================================
// USER & AUTHENTICATION API
// ==========================================

app.get("/api/users", (req, res) => {
  res.status(401).json({
    isError: true,
    data: "You are unauthorized for this data"
  });
});

app.get('/api/user/:user_id', async (req, res) => {
  const userId = req.params.user_id;
  const response = await userAccount.getUserById(userId);
  res.json(response);
});

// ตอนสมัครสมาชิก
app.post('/api/register', async (req, res) => {
  const { role_id, full_name, id_card, phone, username, password } = req.body;
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
});

// ตอน login
app.post('/api/authen_request', async (req, res) => {
  const { username, password } = req.body;
  const result = await userAccount.getUserByUsername(username);

  if (result.isError || !result.data || result.data.length === 0) {
    return res.json({ isError: true, data: "", errorMessage: 'ไม่พบผู้ใช้งาน' });
  }

  const user = result.data[0];
  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    return res.json({ isError: true, data: "", errorMessage: 'รหัสผ่านไม่ถูกต้อง' });
  }
  
  const authenToken = jwt.sign(
    { user_id: user.user_id, username: user.username },
    '5m'
  );

  res.json({ isError: false, data: authenToken, errorMessage: "" });
});

// แลก accessToken
app.post('/api/access_request', async (req, res) => {
  const { token } = req.body;
  try {
    const decoded = await jwt.verify(token);
    const accessToken = jwt.sign(
      { user_id: decoded.user_id, username: decoded.username },
      '1d'
    );
    res.json({ isError: false, data: accessToken, errorMessage: "" });
  } catch (error) {
    res.json({ isError: true, data: "", errorMessage: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
});

// ==========================================
// DASHBOARD API
// ==========================================

app.get('/api/dashboard/:user_id', async (req, res) => {
  const userId = req.params.user_id;
  const result = await dashboard.getDashboardSummary(userId);
  res.json(result);
});

// ==========================================
// GARDEN API
// ==========================================

// GET: ดึงรายชื่อแปลงสวนทั้งหมด (ปรับปรุงไม่ให้ซ้ำ)
app.get('/api/gardens', async (req, res) => {
  try {
    if (garden && typeof garden.getGardensByUserId === 'function') {
      const result = await garden.getGardensByUserId('ALL'); 
      return res.json(result);
    }
    
    const [rows] = await db.query(`SELECT garden_id AS id, garden_name AS name FROM garden`);
    res.json({ isError: false, data: rows });
  } catch (error) {
    console.error('Error fetching gardens:', error);
    res.status(500).json({ isError: true, data: [], errorMessage: error.message });
  }
});

app.get('/api/gardens/:user_id', async (req, res) => {
  const userId = req.params.user_id;
  if (garden && typeof garden.getGardensByUserId === 'function') {
    const result = await garden.getGardensByUserId(userId);
    res.json(result);
  } else {
    res.json({ isError: true, data: [], errorMessage: "ยังไม่ได้สร้างไฟล์ models/garden.js" });
  }
});

app.post('/api/gardens', async (req, res) => {
  if (garden && typeof garden.createGarden === 'function') {
    const result = await garden.createGarden(req.body);
    if (result.isError) return res.status(500).json(result);
    res.status(201).json(result);
  } else {
    res.status(500).json({ isError: true, errorMessage: "ไม่พบฟังก์ชัน createGarden ใน models/garden.js" });
  }
});

app.put('/api/gardens/:garden_id', async (req, res) => {
  const { garden_id } = req.params;
  const result = await garden.updateGarden(garden_id, req.body);
  res.json(result);
});

app.delete('/api/gardens/:garden_id', async (req, res) => {
  const { garden_id } = req.params;
  const result = await garden.deleteGarden(garden_id);
  res.json(result);
});

app.get('/api/gardens/:garden_id/varieties', async (req, res) => {
  const { garden_id } = req.params;
  const result = await garden.getGardenVarieties(garden_id);
  res.json(result);
});

// ==========================================
// PALM CARE & VARIETIES API
// ==========================================

app.get('/api/care-logs', async (req, res) => {
  const result = await care.getCareLogs();
  if (result.isError) {
    return res.status(500).json({ message: 'Error fetching care logs', error: result.errorMessage });
  }
  res.json(result.data);
});

app.post('/api/care-logs', async (req, res) => {
  const result = await care.createCareLog(req.body);
  res.json(result);
});

app.get('/api/varieties', async (req, res) => {
  const result = await palmVariety.getAll();
  res.json(result);
});

// ==========================================
// HARVEST API
// ==========================================

app.get('/api/harvests', async (req, res) => {
  const gardenId = req.query.garden_id;
  const result = await harvest.getAllHarvests(gardenId);
  res.json(result);
});

app.get('/api/harvests/summary', async (req, res) => {
  const gardenId = req.query.garden_id;
  const result = await harvest.getSummary(gardenId);
  res.json(result);
});

app.post('/api/harvests', async (req, res) => {
  const result = await harvest.createHarvest(req.body);
  if (result.isError) {
    return res.status(500).json(result);
  }
  res.status(201).json(result);
});

// ==========================================
// FINANCE API (รายรับ - รายจ่าย)
// ==========================================

// GET: /api/finance/summary - ดึงสรุปยอดเงินรายรับ-รายจ่าย
app.get('/api/finance/summary', async (req, res) => {
  const { month, user_id } = req.query;
  const result = await finance.getSummary(month, user_id);
  res.json(result);
});

// GET: /api/finance/transactions - ดึงรายการธุรกรรมประจำเดือน
app.get('/api/finance/transactions', async (req, res) => {
  const { month, type, user_id } = req.query;
  const result = await finance.getTransactions(month, type, user_id);
  res.json(result);
});

// POST: /api/finance/add - บันทึกธุรกรรมใหม่
app.post('/api/finance/add', async (req, res) => {
  const result = await finance.createTransaction(req.body);
  res.json(result);
});

// ==========================================

app.listen(port, () => {
  console.log(`Server running at http://${hostname}:${port}`);
});