// ============================================================
// care.js — model การดูแลสวน (ตาราง palm_care)
//
// ดึง/เพิ่ม/แก้ไข/ลบ รายการดูแลสวน ทุกคำสั่งเช็กว่าแปลงเป็นของ user นั้นจริง
// action_type: fertilizer, pruning, weeding, watering, spraying, other
// ============================================================

const db = require('../libs/db_pool');

const careModel = {
  // 1. ดึงข้อมูลรายการดูแลสวน (ส่ง userId มา = เฉพาะสวนของ user นั้น)
  getCareLogs: async (userId = null) => {
    try {
      const sql = `
        SELECT 
          c.care_id,
          c.garden_id,
          COALESCE(g.garden_name, 'ไม่ระบุแปลง') AS garden_name,
          c.fertilizer_id,
          f.fertilizer_name,
          c.action_type,
          c.quantity,
          c.quantity_type,
          c.cost,
          c.record_date,
          c.note
        FROM palm_care c
        LEFT JOIN garden g ON c.garden_id = g.garden_id
        LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id
        ${userId ? 'WHERE g.user_id = ?' : ''}
        ORDER BY c.record_date DESC
      `;
      const result = await db.query(sql, userId ? [userId] : []);
      let rows = (result && result.data !== undefined) ? result.data : (Array.isArray(result[0]) ? result[0] : result);
      return { isError: false, data: rows || [], errorMessage: "" };
    } catch (error) {
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // 2. บันทึกข้อมูลรายการใหม่
  //    - เช็กก่อนว่าแปลงที่เลือกเป็นของ user คนนี้จริง
  //    - สร้าง care_id ที่ฝั่งเซิร์ฟเวอร์ (ต่อจากเลขล่าสุด) ไม่ใช้ค่าที่แอปส่งมา กันรหัสชนกัน
  createCareLog: async (careData) => {
    try {
      const { user_id, garden_id, fertilizer_id, action_type, quantity, quantity_type, cost, record_date, note } = careData;

      const owned = await db.query(
        `SELECT garden_id FROM garden WHERE garden_id = ? AND user_id = ?`,
        [garden_id, user_id]
      );
      if (owned.length === 0) {
        return { isError: true, data: null, errorMessage: 'ไม่พบแปลงสวนนี้ในบัญชีของคุณ' };
      }

      const maxRows = await db.query(`
        SELECT MAX(CAST(SUBSTRING(care_id, 2) AS UNSIGNED)) AS max_num
        FROM palm_care WHERE care_id LIKE 'C%'
      `);
      const maxNum = maxRows[0].max_num !== null ? Number(maxRows[0].max_num) : 0;
      const care_id = 'C' + String(maxNum + 1).padStart(3, '0');

      const sql = `
        INSERT INTO palm_care (care_id, garden_id, fertilizer_id, action_type, quantity, quantity_type, cost, record_date, note)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      const result = await db.query(sql, [
        care_id,
        garden_id,
        fertilizer_id || null,
        action_type || 'other',
        quantity || 0,
        quantity_type,
        cost || 0,
        record_date,
        note || ''
      ]);

      return { isError: false, data: { care_id }, errorMessage: "" };
    } catch (error) {
      console.error('Error in createCareLog:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  // 3. แก้ไขรายการ (แก้ได้เฉพาะรายการในสวนของ userId เท่านั้น)
  updateCareLog: async (careId, userId, careData) => {
    try {
      const { garden_id, fertilizer_id, action_type, quantity, quantity_type, cost, record_date, note } = careData;
      const sql = `
        UPDATE palm_care
        SET garden_id = ?, fertilizer_id = ?, action_type = ?, quantity = ?, quantity_type = ?,
            cost = ?, record_date = ?, note = ?
        WHERE care_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?) AND ? IN (SELECT garden_id FROM garden WHERE user_id = ?)
      `;
      const result = await db.query(sql, [
        garden_id, fertilizer_id || null, action_type || 'other', quantity || 0, quantity_type,
        cost || 0, record_date, note || '',
        careId, userId, garden_id, userId
      ]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์แก้ไข' };
      }
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error in updateCareLog:', error.message);
      return { isError: true, data: null, errorMessage: 'แก้ไขรายการไม่สำเร็จ' };
    }
  },

  // 4. ลบรายการ (ลบได้เฉพาะรายการในสวนของ userId เท่านั้น)
  deleteCareLog: async (careId, userId) => {
    try {
      const sql = `DELETE FROM palm_care WHERE care_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)`;
      const result = await db.query(sql, [careId, userId]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์ลบ' };
      }
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error in deleteCareLog:', error.message);
      return { isError: true, data: null, errorMessage: 'ลบรายการไม่สำเร็จ' };
    }
  }
};

module.exports = careModel;