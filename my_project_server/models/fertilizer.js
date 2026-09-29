// ============================================================
// fertilizer.js — model รายชื่อปุ๋ย (ตาราง fertilizer)
// ============================================================

const db = require('../libs/db_pool');

const fertilizer = {
  // รายชื่อปุ๋ยทั้งหมด (ใช้ทำ dropdown ตอนบันทึก "ใส่ปุ๋ย")
  getAll: async () => {
    try {
      const rows = await db.query(
        `SELECT fertilizer_id, fertilizer_name, fertilizer_type, formula
         FROM fertilizer ORDER BY fertilizer_id`
      );
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error fertilizer.getAll:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดรายชื่อปุ๋ยไม่สำเร็จ' };
    }
  },
};

module.exports = fertilizer;
