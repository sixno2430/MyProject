const http = require('http');
const express = require('express');
const bp = require('body-parser');
const bcrypt = require('bcrypt');
const userAccount = require('./models/user_account');
const jwt = require('./libs/jwt');
// const dateUtil = require('./libs/date_util');
const dashboard = require('./models/dashboard');
const garden = require('./models/garden');
const db = require('./libs/db_pool');
const care = require('./models/care'); 
const harvest = require('./models/harvest');
const app = express();
app.use(bp.json());
app.use(bp.urlencoded({ extended: true }));
const cors = require('cors');
app.use(cors());

// แก้ปัญหา BigInt ไม่สามารถ serialize เป็น JSON ได้
BigInt.prototype.toJSON = function() {
  return Number(this);
};


const hostname = '0.0.0.0';  // แก้จาก '127.0.0.1'
// const hostname = '127.0.0.1';   
const port = 3000;


app.get("/api/users", (req, res) => {
    var response = {
      isEror: true,
      data: "You are unauthorized for this data"
    };

    res.json(JSON.stringify(response));
});

app.get('/api/gardens/:user_id', async (req, res) => {
  const userId = req.params.user_id;
  if (garden && typeof garden.getGardensByUserId === 'function') {
    const result = await garden.getGardensByUserId(userId);
    res.json(result);
  } else {
    res.json({ isError: true, data: [], errorMessage: "ยังไม่ได้สร้างไฟล์ models/garden.js หรือฟังก์ชัน getGardensByUserId" });
  }
});

app.post("/api/multiple_by_2", (req, res) => {
    var response = {
        isError: false,
        data: {
            no1: req.body.no_1 * 2,
            no2: req.body.no_2 * 2
        }
    };

    res.send(JSON.stringify(response));
});

app.get('/api/dashboard/:user_id', async (req, res) => {
  const userId = req.params.user_id;
  const result = await dashboard.getDashboardSummary(userId);
  res.json(result);
});

app.get('/api/user/:user_id', async (req, res) => {
  const userId = req.params.user_id;
  const response = await userAccount.getUserById(userId);
  res.send(JSON.stringify(response));
});

//ตอนสมัครสมาชิก
app.post('/api/register', async (req, res) => {
  const { role_id, full_name, id_card, phone, username, password } = req.body;

  const hashedPassword = await bcrypt.hash(password, 10);

  // gen user_id อัตโนมัติ เช่น U003 -> U004
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

//ตอน login
app.post('/api/authen_request', async (req, res) => {
  const { username, password } = req.body;

  const result = await userAccount.getUserByUsername(username);

  if (result.isError || result.data.length === 0) {
    return res.json({ isError: true, data: "", errorMessage: 'ไม่พบผู้ใช้งาน' });
  }

  const user = result.data[0];
  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    return res.json({ isError: true, data: "", errorMessage: 'รหัสผ่านไม่ถูกต้อง' });
  }
  
  // password ถูกต้อง -> ออก authenToken อายุสั้น (ยืนยันตัวตนชั่วคราว)
  const authenToken = jwt.sign(
    { user_id: user.user_id, username: user.username },
    '5m'
  );

  
  res.json({ isError: false, data: authenToken, errorMessage: "" });
});

// ขั้นที่ 2: เอา authenToken มาแลก accessToken (อายุยาวขึ้น 1 วัน)
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

app.get('/api/care-logs', async (req, res) => {
  const result = await care.getCareLogs();
  if (result.isError) {
    return res.status(500).json({ message: 'Error fetching care logs', error: result.errorMessage });
  }
  res.json(result.data);
});

// 2. ดึงรายชื่อแปลงสวนทั้งหมด (เรียกผ่าน garden model เดิม)
app.get('/api/gardens', async (req, res) => {
  if (garden && typeof garden.getGardensByUserId === 'function') {
    // กรณีถ้ามีดึงสวนทั้งหมด ให้เรียกใช้ function ของ garden model
    const result = await garden.getGardensByUserId('ALL'); 
    res.json(result);
  } else {
    res.json({ isError: true, data: [], errorMessage: "ไม่พบฟังก์ชันใน garden model" });
  }
});

// POST: บันทึกการดูแลสวนรายการใหม่
app.post('/api/care-logs', async (req, res) => {
  const result = await care.createCareLog(req.body);
  res.json(result);
});

// POST: เพิ่มแปลงสวนใหม่
app.post('/api/gardens', async (req, res) => {
  if (garden && typeof garden.createGarden === 'function') {
    const result = await garden.createGarden(req.body);
    if (result.isError) {
      return res.status(500).json(result);
    }
    res.status(201).json(result);
  } else {
    res.status(500).json({ isError: true, errorMessage: "ไม่พบฟังก์ชัน createGarden ใน models/garden.js" });
  }
});
// PUT: อัปเดตแปลงสวน
app.put('/api/gardens/:garden_id', async (req, res) => {
  const { garden_id } = req.params;
  const result = await garden.updateGarden(garden_id, req.body);
  res.json(result);
});

// DELETE: ลบแปลงสวน
app.delete('/api/gardens/:garden_id', async (req, res) => {
  const { garden_id } = req.params;
  const result = await garden.deleteGarden(garden_id);
  res.json(result);
});
// GET: ดึงพันธุ์ปาล์มของแปลงสวน
app.get('/api/gardens/:garden_id/varieties', async (req, res) => {
  const { garden_id } = req.params;
  const result = await garden.getGardenVarieties(garden_id);
  res.json(result);
});
const palmVariety = require('./models/palm_variety');

// GET: ดึงรายการพันธุ์ปาล์มทั้งหมด
app.get('/api/varieties', async (req, res) => {
  const result = await palmVariety.getAll();
  res.json(result);
});

app.get('/api/harvests', async (req, res) => {
  const gardenId = req.query.garden_id;
  const result = await harvest.getAllHarvests(gardenId);
  res.json(result);
});

// GET: /api/harvests/summary - ดึงข้อมูลสรุปผลรวม + กราฟ 12 เดือน
app.get('/api/harvests/summary', async (req, res) => {
  const gardenId = req.query.garden_id;
  const result = await harvest.getSummary(gardenId);
  res.json(result);
});

app.listen(port,  () => {
  console.log(`Server running at http://${hostname}:${port}`);
});


// app.post('/api/register', (req, res) => {
//   const { role, full_name, id_card, phone, username, password } = req.body;
  
//   // 1. ตรวจสอบข้อมูล
//   if (!username || !password) {
//     return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
//   }
  
//   // 2. บันทึกลงฐานข้อมูล
//   // INSERT INTO users ...
  
//   // 3. ตอบกลับ
//   res.status(201).json({ 
//     message: 'สมัครสมาชิกสำเร็จ',
//     user: { id: 1, username: username }
//   });
// });