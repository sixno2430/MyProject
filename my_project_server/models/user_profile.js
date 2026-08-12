const dbPool = require('../libs/db_pool');

class UserProfile {
  // ดึงข้อมูลโปรไฟล์ตาม user_id
  static async getProfile(userId) {
    const query = `
      SELECT 
        u.user_id,
        u.full_name,
        u.username,
        u.phone,
        u.citizen_id,
        u.created_at,
        r.role_id,
        r.role_name,
        r.role_description
      FROM \`user\` u
      JOIN \`role\` r ON u.role_id = r.role_id
      WHERE u.user_id = ?
    `;

    const [rows] = await dbPool.execute(query, [userId]);
    return rows[0] || null;
  }

  // ดึงจำนวนสวนของผู้ใช้
  static async getGardenCount(userId) {
    const query = `SELECT COUNT(*) as count FROM garden WHERE user_id = ?`;
    const [rows] = await dbPool.execute(query, [userId]);
    return rows[0].count;
  }

  // อัปเดตข้อมูลโปรไฟล์
  static async updateProfile(userId, data) {
    const { full_name, phone, citizen_id } = data;
    const query = `
      UPDATE \`user\` 
      SET full_name = ?, phone = ?, citizen_id = ?
      WHERE user_id = ?
    `;
    const [result] = await dbPool.execute(query, [full_name, phone, citizen_id, userId]);
    return result.affectedRows > 0;
  }
}

module.exports = UserProfile;