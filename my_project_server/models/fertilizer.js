// ============================================================
// fertilizer.js — model รายชื่อปุ๋ย
//
// - getUsedByUser: ชื่อปุ๋ยที่ผู้ใช้คนนี้เคยบันทึก (ตาราง care_fertilizer) ใช้เป็นรายการแนะนำในฟอร์มใส่ปุ๋ย
//   ผู้ใช้ใหม่จึงยังไม่มีรายการแนะนำ พอบันทึกปุ๋ยครั้งแรก ชื่อนั้นจะขึ้นแนะนำครั้งต่อไปเฉพาะของคนนั้น
// ============================================================

const db = require('../libs/db_pool');

const fertilizer = {
  // ชื่อปุ๋ยที่ user นี้เคยใช้ เรียงจากที่ใช้ล่าสุด (ชื่อซ้ำนับเป็นชื่อเดียว)
  getUsedByUser: async (userId) => {
    try {
      const rows = await db.query(
        `SELECT cf.fertilizer_name, MAX(c.record_date) AS last_used, COUNT(*) AS times
         FROM care_fertilizer cf
         JOIN palm_care c ON c.care_id = cf.care_id
         JOIN garden g ON g.garden_id = c.garden_id
         WHERE g.user_id = ?
         GROUP BY cf.fertilizer_name
         ORDER BY last_used DESC, times DESC`,
        [userId]
      );
      return { isError: false, data: rows.map((r) => r.fertilizer_name), errorMessage: "" };
    } catch (error) {
      console.error('Error fertilizer.getUsedByUser:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดรายชื่อปุ๋ยไม่สำเร็จ' };
    }
  },
};

module.exports = fertilizer;
