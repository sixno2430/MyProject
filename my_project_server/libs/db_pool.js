// ============================================================
// db_pool.js — การเชื่อมต่อฐานข้อมูล MariaDB (palm_oil_db)
//
// สร้าง connection pool ไว้ให้ทุก model ใช้ร่วมกัน (เปิดพร้อมกันได้สูงสุด 5 connection)
// หมายเหตุ: db.query() ของ mariadb คืนค่าเป็น array ของแถวโดยตรง
//   -> ใช้ const rows = await db.query(...) ห้ามเขียน const [rows] = ... (จะได้แค่แถวแรก)
// ============================================================

const mariadb = require('mariadb');
const config = require('./config');

// ค่าการเชื่อมต่ออ่านจาก .env (ผ่าน config.js) ไม่เขียนรหัสผ่านไว้ในโค้ด
const pool = mariadb.createPool({
  ...config.db,
  connectionLimit: 5
});

module.exports = pool;