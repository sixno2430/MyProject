const db = require('../libs/db_pool');

const careModel = {
  // 1. ดึงข้อมูลรายการทั้งหมด
  getCareLogs: async () => {
    try {
      const sql = `
        SELECT 
          c.care_id,
          c.garden_id,
          COALESCE(g.garden_name, 'ไม่ระบุแปลง') AS garden_name,
          c.fertilizer_id,
          COALESCE(f.fertilizer_name, 'ปุ๋ยบำรุง') AS fertilizer_name,
          c.action_type,
          c.quantity,
          c.quantity_type,
          c.cost,
          c.record_date,
          c.note
        FROM palm_care c
        LEFT JOIN garden g ON c.garden_id = g.garden_id
        LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id
        ORDER BY c.record_date DESC
      `;
      const result = await db.query(sql);
      let rows = (result && result.data !== undefined) ? result.data : (Array.isArray(result[0]) ? result[0] : result);
      return { isError: false, data: rows || [], errorMessage: "" };
    } catch (error) {
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // 2. บันทึกข้อมูลรายการใหม่ (เพิ่ม action_type และ note)
  createCareLog: async (careData) => {
    try {
      const { care_id, garden_id, fertilizer_id, action_type, quantity, quantity_type, cost, record_date, note } = careData;
      const sql = `
        INSERT INTO palm_care (care_id, garden_id, fertilizer_id, action_type, quantity, quantity_type, cost, record_date, note)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      const result = await db.query(sql, [
        care_id,
        garden_id,
        fertilizer_id || null,
        action_type || 'pruning',
        quantity,
        quantity_type,
        cost,
        record_date,
        note || ''
      ]);

      return { isError: false, data: result, errorMessage: "" };
    } catch (error) {
      console.error('Error in createCareLog:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  }
};

module.exports = careModel;