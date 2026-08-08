const pool = require('../libs/db_pool');

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

  // ดึงรายชื่อ user ทั้งหมด
  getUsers: async () => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "SELECT user_id, role_id, citizen_id, full_name, phone, username, created_at FROM user";

      var rows = await conn.query(sql);

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
      result = {
        isError: true,
        errorMessage: error.message
      }
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

  // ลบ user
  deleteUser: async (userId) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "DELETE FROM user WHERE user_id = ?";

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
  }
}