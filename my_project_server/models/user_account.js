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
  },

  // ตรวจสอบ username + password พร้อมกัน (ใช้ตอน login)
  checkAuthenRequest: async (username, password) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      var sql = "SELECT user_id, role_id, citizen_id, full_name, phone, username, password "
              + "FROM user WHERE username = ?";

      var rows = await conn.query(sql, [username]);

      if (rows.length === 0) {
        result = {
          isError: true,
          errorMessage: "ไม่พบข้อมูลผู้ใช้ในระบบ"
        }
      } else {
        var user = rows[0];
        var isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
          result = {
            isError: true,
            errorMessage: "รหัสผ่านไม่ถูกต้อง"
          }
        } else {
          delete user.password; // ไม่ส่ง password กลับไปให้ client
          result = {
            isError: false,
            data: user
          };
        }
      }
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
}