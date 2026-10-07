// ============================================================
// config.js — อ่านค่าตั้งค่าจากไฟล์ .env (รหัสผ่าน DB, JWT secret, พอร์ต)
//
// ค่าลับไม่เขียนไว้ในโค้ดแล้ว เพราะโค้ดถูก push ขึ้น GitHub ใครก็เห็น
// เครื่องใหม่: คัดลอก .env.example เป็น .env แล้วใส่ค่าของเครื่องตัวเอง
// โหลดจาก path ของโฟลเดอร์ server เสมอ จะรัน node จากโฟลเดอร์ไหนก็หาไฟล์เจอ
// ============================================================

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env'), quiet: true });

// ค่าที่ขาดไม่ได้ ไม่มี = หยุดเซิร์ฟเวอร์พร้อมบอกวิธีแก้ (ดีกว่ารันไปแล้วพังทีหลังแบบงงๆ)
if (!process.env.JWT_SECRET) {
  console.error('❌ ไม่พบ JWT_SECRET ในไฟล์ .env — คัดลอก .env.example เป็น .env แล้วใส่ค่าก่อนรันเซิร์ฟเวอร์');
  process.exit(1);
}

module.exports = {
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD ?? '', // root ไม่มีรหัสผ่านได้ จึงยอมให้ว่าง
    database: process.env.DB_NAME || 'palm_oil_db',
  },
  jwtSecret: process.env.JWT_SECRET,
  port: Number(process.env.PORT) || 3000,
};
