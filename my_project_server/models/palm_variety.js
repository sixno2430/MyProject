// ============================================================
// palm_variety.js — model พันธุ์ปาล์ม (ตาราง palm_variety)
//
// พันธุ์ปาล์มเป็นข้อมูลกลางที่ทุก user ใช้ร่วมกัน
// ============================================================

const db = require('../libs/db_pool');

const palmVariety = {
  // ดึงพันธุ์ทั้งหมด ถ้าส่ง userId มาด้วยจะแนบจำนวนต้น/จำนวนแปลงที่ user คนนั้นปลูก
  getAll: async (userId = null) => {
    try {
      const query = `
        SELECT v.variety_id, v.variety_name, v.scientific_name,
               COALESCE(u.plant_count, 0) AS plant_count,
               COALESCE(u.garden_count, 0) AS garden_count
        FROM palm_variety v
        LEFT JOIN (
          SELECT gv.variety_id,
                 SUM(gv.plant_count) AS plant_count,
                 COUNT(DISTINCT gv.garden_id) AS garden_count
          FROM garden_variety gv
          JOIN garden g ON gv.garden_id = g.garden_id
          WHERE g.user_id = ?
          GROUP BY gv.variety_id
        ) u ON u.variety_id = v.variety_id
        ORDER BY v.variety_id
      `;
      const rows = await db.query(query, [userId]);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error palmVariety.getAll:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดข้อมูลพันธุ์ปาล์มไม่สำเร็จ' };
    }
  },

  // เพิ่มพันธุ์ใหม่ รหัสต่อจากตัวล่าสุด เช่น V002 -> V003
  create: async ({ variety_name, scientific_name }) => {
    try {
      if (!variety_name || !variety_name.trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อพันธุ์' };
      }
      const dup = await db.query(
        `SELECT variety_id FROM palm_variety WHERE variety_name = ?`,
        [variety_name.trim()]
      );
      if (dup.length > 0) {
        return { isError: true, data: null, errorMessage: 'มีพันธุ์ชื่อนี้อยู่แล้ว' };
      }

      const maxRows = await db.query(`
        SELECT MAX(CAST(SUBSTRING(variety_id, 2) AS UNSIGNED)) AS max_num
        FROM palm_variety WHERE variety_id LIKE 'V%'
      `);
      const maxNum = maxRows[0].max_num !== null ? Number(maxRows[0].max_num) : 0;
      const newId = 'V' + String(maxNum + 1).padStart(3, '0');

      await db.query(
        `INSERT INTO palm_variety (variety_id, variety_name, scientific_name) VALUES (?, ?, ?)`,
        [newId, variety_name.trim(), (scientific_name || '').trim() || null]
      );
      return { isError: false, data: { variety_id: newId }, errorMessage: "" };
    } catch (error) {
      console.error('Error palmVariety.create:', error.message);
      return { isError: true, data: null, errorMessage: 'เพิ่มพันธุ์ปาล์มไม่สำเร็จ' };
    }
  },

  /**
   * แก้ไขชื่อพันธุ์ / ชื่อวิทยาศาสตร์
   */
  update: async (varietyId, { variety_name, scientific_name }) => {
    try {
      if (!variety_name || !variety_name.trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อพันธุ์' };
      }
      const result = await db.query(
        `UPDATE palm_variety SET variety_name = ?, scientific_name = ? WHERE variety_id = ?`,
        [variety_name.trim(), (scientific_name || '').trim() || null, varietyId]
      );
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบพันธุ์ปาล์มนี้' };
      }
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error palmVariety.update:', error.message);
      return { isError: true, data: null, errorMessage: 'แก้ไขพันธุ์ปาล์มไม่สำเร็จ' };
    }
  },

  // ลบได้เฉพาะพันธุ์ที่ยังไม่มีสวนไหนใช้ (กันข้อมูลสวนของคนอื่นเสีย)
  remove: async (varietyId) => {
    try {
      const used = await db.query(
        `SELECT COUNT(*) AS n FROM garden_variety WHERE variety_id = ?`,
        [varietyId]
      );
      if (Number(used[0].n) > 0) {
        return { isError: true, data: null, errorMessage: 'ลบไม่ได้ เพราะมีแปลงสวนที่ปลูกพันธุ์นี้อยู่' };
      }
      const result = await db.query(`DELETE FROM palm_variety WHERE variety_id = ?`, [varietyId]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบพันธุ์ปาล์มนี้' };
      }
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error palmVariety.remove:', error.message);
      return { isError: true, data: null, errorMessage: 'ลบพันธุ์ปาล์มไม่สำเร็จ' };
    }
  },
};

module.exports = palmVariety;
