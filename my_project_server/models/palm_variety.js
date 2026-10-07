// ============================================================
// palm_variety.js — model พันธุ์ปาล์ม (ตาราง palm_variety)
//
// พันธุ์ปาล์มแยกเป็นของแต่ละ user (คอลัมน์ user_id) ไม่ใช้ร่วมกัน
// แต่ละคนเห็น/เพิ่ม/แก้/ลบได้เฉพาะพันธุ์ของตัวเอง (userId มาจาก token ผ่าน libs/auth.js)
// ============================================================

const db = require('../libs/db_pool');

const palmVariety = {
  // ดึงพันธุ์ของ user คนนี้ พร้อมจำนวนต้น/จำนวนแปลงที่ปลูก
  getAll: async (userId) => {
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
        WHERE v.user_id = ?
        ORDER BY v.variety_id
      `;
      const rows = await db.query(query, [userId, userId]);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error palmVariety.getAll:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดข้อมูลพันธุ์ปาล์มไม่สำเร็จ' };
    }
  },

  // เพิ่มพันธุ์ใหม่ของ user รหัสต่อจากตัวล่าสุดของทั้งตาราง เช่น V002 -> V003
  create: async ({ user_id, variety_name, scientific_name }) => {
    try {
      if (!variety_name || !variety_name.trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อพันธุ์' };
      }
      // ชื่อซ้ำเช็กเฉพาะในรายการของตัวเอง (คนอื่นมีชื่อเดียวกันได้)
      const dup = await db.query(
        `SELECT variety_id FROM palm_variety WHERE variety_name = ? AND user_id = ?`,
        [variety_name.trim(), user_id]
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
        `INSERT INTO palm_variety (variety_id, user_id, variety_name, scientific_name) VALUES (?, ?, ?, ?)`,
        [newId, user_id, variety_name.trim(), (scientific_name || '').trim() || null]
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
  update: async (varietyId, { user_id, variety_name, scientific_name }) => {
    try {
      if (!variety_name || !variety_name.trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อพันธุ์' };
      }
      const dup = await db.query(
        `SELECT variety_id FROM palm_variety WHERE variety_name = ? AND user_id = ? AND variety_id <> ?`,
        [variety_name.trim(), user_id, varietyId]
      );
      if (dup.length > 0) {
        return { isError: true, data: null, errorMessage: 'มีพันธุ์ชื่อนี้อยู่แล้ว' };
      }
      const result = await db.query(
        `UPDATE palm_variety SET variety_name = ?, scientific_name = ? WHERE variety_id = ? AND user_id = ?`,
        [variety_name.trim(), (scientific_name || '').trim() || null, varietyId, user_id]
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

  // ลบได้เฉพาะพันธุ์ของตัวเองที่ยังไม่มีแปลงไหนใช้ (กันข้อมูลแปลงหาย เพราะ garden_variety ลบตาม CASCADE)
  remove: async (varietyId, userId) => {
    try {
      const used = await db.query(
        `SELECT COUNT(*) AS n FROM garden_variety WHERE variety_id = ?`,
        [varietyId]
      );
      if (Number(used[0].n) > 0) {
        return { isError: true, data: null, errorMessage: 'ลบไม่ได้ เพราะมีแปลงสวนที่ปลูกพันธุ์นี้อยู่' };
      }
      const result = await db.query(`DELETE FROM palm_variety WHERE variety_id = ? AND user_id = ?`, [varietyId, userId]);
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
