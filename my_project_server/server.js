// ============================================================
// server.js — เซิร์ฟเวอร์ API ของ PalmTrack (Express)
//
// ไฟล์นี้แค่ตั้งค่า express แล้วผูก route ของแต่ละหมวด (โฟลเดอร์ routes/) เข้ากับแอป
//   routes/auth_routes.js       สมัคร / เข้าสู่ระบบ / เปลี่ยนรหัสผ่าน
//   routes/dashboard_routes.js  หน้าหลักเกษตรกร + กิจกรรม
//   routes/garden_routes.js     แปลงสวน
//   routes/care_routes.js       การดูแลสวน + ปุ๋ยที่เคยใช้
//   routes/variety_routes.js    พันธุ์ปาล์ม
//   routes/harvest_routes.js    การเก็บเกี่ยว
//   routes/finance_routes.js    รายรับ-รายจ่าย
//   routes/report_routes.js     รายงานเกษตรกร
//   routes/shop_routes.js       ร้านรับซื้อ
//   routes/admin_routes.js      ผู้ดูแลระบบ
//   routes/profile_routes.js    โปรไฟล์ผู้ใช้ (/api/profile)
// การคำนวณและ SQL อยู่ในโฟลเดอร์ models/ — route แค่รับ request แล้วเรียก model
//
// วิธีรัน: node server.js  (แก้ไฟล์แล้วต้องปิดตัวเก่าก่อนเปิดใหม่ ไม่งั้นตัวเก่ายังถือพอร์ตอยู่)
// ============================================================

const express = require('express');
const bp = require('body-parser');
const cors = require('cors');
const { port } = require('./libs/config'); // ตั้งใน .env (PORT) ไม่ตั้ง = 3000

const app = express();
app.use(cors());
app.use(bp.json());
app.use(bp.urlencoded({ extended: true }));

// แก้ปัญหา BigInt ไม่สามารถ serialize เป็น JSON ได้ (COUNT(*) ของ mariadb คืนเป็น BigInt)
BigInt.prototype.toJSON = function () {
  return Number(this);
};

// route แต่ละหมวด (ลำดับเดียวกับเดิมใน server.js)
app.use(require('./routes/auth_routes'));
app.use(require('./routes/dashboard_routes'));
app.use(require('./routes/garden_routes'));
app.use(require('./routes/care_routes'));
app.use(require('./routes/variety_routes'));
app.use(require('./routes/harvest_routes'));
app.use(require('./routes/finance_routes'));
app.use(require('./routes/report_routes'));
app.use(require('./routes/shop_routes'));
app.use(require('./routes/admin_routes'));
app.use('/api/profile', require('./routes/profile_routes'));

const hostname = '0.0.0.0';
app.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}`);
});
