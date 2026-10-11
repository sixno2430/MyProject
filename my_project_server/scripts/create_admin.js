// ============================================================
// create_admin.js — เตรียมฐานข้อมูลฝั่งแอดมิน + สร้าง/รีเซ็ตบัญชีผู้ดูแลระบบ (role R001)
//
// 1) เพิ่มคอลัมน์ user.status ถ้ายังไม่มี ('active' ใช้งาน / 'suspended' ถูกระงับ)
// 2) สร้างหรือรีเซ็ตบัญชีแอดมิน
//
// สมัครผ่านแอปเป็นแอดมินไม่ได้ (server กันไว้) จึงสร้างด้วยสคริปต์นี้ครั้งเดียว
// รหัสผ่านเก็บแบบ bcrypt เหมือนผู้ใช้ทั่วไป ไม่ได้เขียนรหัสไว้ในโค้ดของ server
//
// วิธีรัน (ในโฟลเดอร์ my_project_server):
//   node scripts/create_admin.js                    -> admin / admin1234
//   node scripts/create_admin.js myadmin mypass     -> กำหนดเอง
// ถ้ามี username นี้อยู่แล้ว จะตั้งเป็นแอดมินและเปลี่ยนรหัสผ่านให้ใหม่
// ============================================================

const bcrypt = require('bcrypt');
const db = require('../libs/db_pool');
const userAccount = require('../models/user_account');

const username = process.argv[2] || 'admin';
const password = process.argv[3] || 'admin1234';

(async () => {
  try {
    // รันซ้ำได้: เช็กก่อนว่ามีคอลัมน์หรือยัง (MySQL ไม่รองรับ ADD COLUMN IF NOT EXISTS)
    const col = await db.query(
      `SELECT COUNT(*) AS n FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user' AND COLUMN_NAME = 'status'`
    );
    if (Number(col[0].n) === 0) {
      await db.query(`ALTER TABLE user ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active'`);
      console.log('✅ เพิ่มคอลัมน์ user.status แล้ว');
    }

    const hashed = await bcrypt.hash(password, 10);
    const found = await db.query(`SELECT user_id FROM user WHERE username = ?`, [username]);

    if (found.length > 0) {
      await db.query(`UPDATE user SET role_id = 'R001', status = 'active', password = ? WHERE user_id = ?`, [hashed, found[0].user_id]);
      console.log(`✅ อัปเดต ${username} (${found[0].user_id}) เป็นแอดมิน และตั้งรหัสผ่านใหม่แล้ว`);
    } else {
      const idResult = await userAccount.getNextUserId();
      if (idResult.isError) throw new Error(idResult.errorMessage);
      await db.query(
        `INSERT INTO user (user_id, role_id, full_name, username, password) VALUES (?, 'R001', 'ผู้ดูแลระบบ', ?, ?)`,
        [idResult.data, username, hashed]
      );
      console.log(`✅ สร้างแอดมิน ${username} (${idResult.data}) แล้ว`);
    }
  } catch (error) {
    console.error('❌ สร้างแอดมินไม่สำเร็จ:', error.message);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
