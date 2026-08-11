const db = require('../libs/db_pool'); // เรียกใช้ไฟล์เชื่อมต่อ Database ของคุณ

const careModel = {
  // 1. ดึงข้อมูลรายการดูแลรักษาสวนทั้งหมด (JOIN ตาราง palm_care, garden, fertilizer)
  getCareLogs: async () => {
    try {
      const sql = `
        SELECT 
          c.care_id,
          c.garden_id,
          COALESCE(g.garden_name, 'ไม่ระบุแปลง') AS garden_name,
          c.fertilizer_id,
          COALESCE(f.fertilizer_name, 'ปุ๋ยบำรุง') AS fertilizer_name,
          f.formula,
          c.quantity,
          c.quantity_type,
          c.cost,
          c.record_date
        FROM palm_care c
        LEFT JOIN garden g ON c.garden_id = g.garden_id
        LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id
        ORDER BY c.record_date DESC
      `;
      
      const result = await db.query(sql); // 👈 แก้ตรงนี้: ไม่ใช้ [rows]

      // ป้องกัน Error โดยรองรับทั้งสไตล์ db_pool และ mysql2
      let rows = [];
      if (result && result.data !== undefined) {
        rows = result.data;
      } else {
        rows = Array.isArray(result[0]) ? result[0] : result;
      }

      

      return { isError: false, data: rows || [], errorMessage: "" };
    } catch (error) {
      console.error('❌ Error in getCareLogs:', error.message);
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // 2. บันทึกข้อมูลการดูแลสวนรายการใหม่
  createCareLog: async (careData) => {
    try {
      const { care_id, garden_id, fertilizer_id, quantity, quantity_type, cost, record_date } = careData;
      const sql = `
        INSERT INTO palm_care (care_id, garden_id, fertilizer_id, quantity, quantity_type, cost, record_date)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      
      const result = await db.query(sql, [
        care_id,
        garden_id,
        fertilizer_id || null,
        quantity,
        quantity_type,
        cost,
        record_date
      ]);

      return { isError: false, data: result, errorMessage: "" };
    } catch (error) {
      console.error('❌ Error in createCareLog:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  }
};

module.exports = careModel;