const db = require('../libs/db_pool'); // เรียกใช้ไฟล์เชื่อมต่อ Database ของคุณ

const careModel = {
  // 1. ดึงข้อมูลรายการดูแลรักษาสวนทั้งหมด (JOIN ตาราง palm_care, garden, fertilizer)
  getCareLogs: async () => {
    try {
      const sql = `
        SELECT 
          c.care_id,
          g.garden_id,
          g.garden_name,
          c.fertilizer_id,
          f.fertilizer_name,
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
      const [rows] = await db.query(sql);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error in getCareLogs:', error);
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // 2. บันทึกข้อมูลการดูแลสวนรายการใหม่ (สำหรับรองรับหน้า AddGardenCareScreen ในอนาคต)
  createCareLog: async (careData) => {
    try {
      const { care_id, garden_id, fertilizer_id, quantity, quantity_type, cost, record_date } = careData;
      const sql = `
        INSERT INTO palm_care (care_id, garden_id, fertilizer_id, quantity, quantity_type, cost, record_date)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      const [result] = await db.query(sql, [
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
      console.error('Error in createCareLog:', error);
      return { isError: true, data: null, errorMessage: error.message };
    }
  }
};

module.exports = careModel;