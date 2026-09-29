// ============================================================
// db_pool.js — การเชื่อมต่อฐานข้อมูล MariaDB (palm_oil_db)
//
// สร้าง connection pool ไว้ให้ทุก model ใช้ร่วมกัน (เปิดพร้อมกันได้สูงสุด 5 connection)
// หมายเหตุ: db.query() ของ mariadb คืนค่าเป็น array ของแถวโดยตรง
//   -> ใช้ const rows = await db.query(...) ห้ามเขียน const [rows] = ... (จะได้แค่แถวแรก)
// ============================================================

const mariadb = require('mariadb');
const pool = mariadb.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  port: 3306,
  database: 'palm_oil_db',
  connectionLimit: 5
});

module.exports = pool;