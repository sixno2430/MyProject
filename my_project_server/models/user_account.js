// ============================================================
// user_account.js — model บัญชีผู้ใช้ (ตาราง user)
//
// สมัครสมาชิก, ค้นหาผู้ใช้, เปลี่ยนรหัสผ่าน (รหัสผ่านเก็บแบบ bcrypt hash เสมอ)
// ============================================================

const pool = require('../libs/db_pool');
const bcrypt = require('bcrypt');

module.exports = {
  // ดึงข้อมูล user ทีละคนด้วย user_id
  getUserById: async (userId) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "SELECT user_id, role_id, citizen_id, full_name, phone, username, created_at FROM user "
              + "WHERE user_id = ?";

      var rows = await conn.query(sql, [userId]);

      result = {
        isError: false,
        data: rows
      };
    } catch (error) {
      result = {
        isError: true,
        errorMessage: error.message
      }
    } finally {
      if (conn) conn.release();
      return result;
    }
  },


  // ค้นหา user ด้วย username (ใช้ตอน login — ต้องได้ password มาด้วยเพื่อเทียบ hash)
  getUserByUsername: async (username) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "SELECT * FROM user WHERE username = ?";

      var rows = await conn.query(sql, [username]);

      result = {
        isError: false,
        data: rows
      };
    } catch (error) {
      result = {
        isError: true,
        errorMessage: error.message
      }
    } finally {
      if (conn) conn.release();
      return result;
    }
  },


  // หา user_id ตัวถัดไป เช่น U003 -> U004
  getNextUserId: async () => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "SELECT user_id FROM user ORDER BY user_id DESC LIMIT 1";
      var rows = await conn.query(sql);

      var nextId;
      if (rows.length === 0) {
        nextId = 'U001';
      } else {
        var lastId = rows[0].user_id;                    // เช่น "U003"
        var num = parseInt(lastId.substring(1)) + 1;      // 3 + 1 = 4
        nextId = 'U' + String(num).padStart(3, '0');      // "U004"
      }

      result = {
        isError: false,
        data: nextId
      };
    } catch (error) {
      result = {
        isError: true,
        errorMessage: error.message
      }
    } finally {
      if (conn) conn.release();
      return result;
    }
  },

  // สร้าง user ใหม่ (สมัครสมาชิก) — password ต้อง hash มาก่อนเรียกฟังก์ชันนี้
  createUser: async (userId, roleId, citizenId, fullName, phone, username, password) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "INSERT INTO user (user_id, role_id, citizen_id, full_name, phone, username, password) "
              + "VALUES (?, ?, ?, ?, ?, ?, ?)";

      var rows = await conn.query(sql, [userId, roleId, citizenId, fullName, phone, username, password]);

      result = {
        isError: false,
        data: rows
      };
    } catch (error) {
      // ไม่ส่ง error SQL ดิบกลับไป เพราะมี parameters (รวม password hash) ติดไปด้วย
      console.error('createUser error:', error.message);
      var message = 'สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่';
      if (error.errno === 1062) {
        // ดูจาก sqlMessage (เช่น "Duplicate entry 'x' for key 'user.username'") ไม่ใช่ error.message
        // เพราะ error.message มีคำสั่ง SQL ทั้งประโยคซึ่งมีคำว่า citizen_id อยู่เสมอ -> ชื่อซ้ำก็ขึ้นว่าเลขบัตรซ้ำ
        var dupKey = error.sqlMessage || '';
        if (dupKey.includes('citizen_id')) message = 'เลขบัตรประชาชนนี้ถูกลงทะเบียนแล้ว';
        else if (dupKey.includes('username')) message = 'Username นี้ถูกใช้แล้ว';
        else message = 'ข้อมูลนี้ถูกใช้ลงทะเบียนแล้ว';
      }
      result = {
        isError: true,
        errorMessage: message
      }
    } finally {
      if (conn) conn.release();
      return result;
    }
  },

  // เปลี่ยนรหัสผ่าน: ต้องยืนยันรหัสเดิมให้ถูกก่อน
  changePassword: async (userId, oldPassword, newPassword) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var rows = await conn.query("SELECT password FROM user WHERE user_id = ?", [userId]);
      if (rows.length === 0) {
        result = { isError: true, errorMessage: "ไม่พบข้อมูลผู้ใช้" };
      } else if (!(await bcrypt.compare(oldPassword, rows[0].password))) {
        result = { isError: true, errorMessage: "รหัสผ่านเดิมไม่ถูกต้อง" };
      } else {
        var hashed = await bcrypt.hash(newPassword, 10);
        await conn.query("UPDATE user SET password = ? WHERE user_id = ?", [hashed, userId]);
        result = { isError: false, data: null };
      }
    } catch (error) {
      console.error('changePassword error:', error.message);
      result = { isError: true, errorMessage: "เปลี่ยนรหัสผ่านไม่สำเร็จ" };
    } finally {
      if (conn) conn.release();
      return result;
    }
  },

  // อัปเดตข้อมูล user
  updateUser: async (userId, fullName, phone) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "UPDATE user SET full_name = ?, phone = ? WHERE user_id = ?";

      var rows = await conn.query(sql, [fullName, phone, userId]);

      result = {
        isError: false,
        data: rows
      };
    } catch (error) {
      result = {
        isError: true,
        errorMessage: error.message
      }
    } finally {
      if (conn) conn.release();
      return result;
    }
  },

  // บันทึกการใช้งานลงตาราง user_log (เช่น LOGIN) ให้หน้าแอดมินดูได้ว่าใครเข้าใช้ล่าสุดเมื่อไร
  // บันทึกไม่สำเร็จก็ไม่เป็นไร ไม่ให้กระทบการล็อกอิน
  logAction: async (userId, action, ipAddress) => {
    try {
      const rows = await pool.query(
        "SELECT MAX(CAST(SUBSTRING(log_id, 2) AS UNSIGNED)) AS max_num FROM user_log WHERE log_id LIKE 'L%'"
      );
      const maxNum = rows[0].max_num !== null ? Number(rows[0].max_num) : 0;
      const logId = 'L' + String(maxNum + 1).padStart(3, '0');
      await pool.query(
        "INSERT INTO user_log (log_id, user_id, action, ip_address) VALUES (?, ?, ?, ?)",
        [logId, userId, action, ipAddress || null]
      );
    } catch (error) {
      console.error('Error logAction:', error.message);
    }
  },
}