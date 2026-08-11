const db = require('../libs/db_pool'); // ดึง DB Pool ของโครงการ

const garden = {
  getGardensByUserId: async (userId) => {
    try {
      const query = `
        SELECT 
          garden_id, 
          user_id, 
          garden_name, 
          area_size, 
          plant_count, 
          plant_year,
          plant_age
        FROM garden_with_age
        WHERE user_id = ?
      `;

      // ลองดึงข้อมูลจาก DB (รองรับทั้ง mysql2/promise และ mysql2 แบบปกติ)
      const result = await db.query(query, [userId]);

      // หาก db_pool ส่งก้อน { isError: false, data: [...] } กลับมาแล้ว
      if (result && result.data !== undefined) {
        return result;
      }

      // หาก db_pool ส่ง [rows, fields] กลับมาแบบ standard promise
      const rows = Array.isArray(result[0]) ? result[0] : result;
      return {
        isError: false,
        data: rows,
        errorMessage: ""
      };

    } catch (error) {
      console.error("❌ Error in garden.js (getGardensByUserId):", error.message);
      return {
        isError: true,
        data: [],
        errorMessage: error.message
      };
    }
  }, // 👈 ใส่จุลภาค (,) คั่นระหว่างฟังก์ชันตรงนี้

  createGarden: async (gardenData) => {
    try {
      const { user_id, garden_name, area_size, plant_count, plant_year, address } = gardenData;

      // 1. ดึง ID ล่าสุดเพื่อ Gen รหัสสวนอัตโนมัติ (เช่น G002 -> G003)
      const selectQuery = `SELECT garden_id FROM garden ORDER BY garden_id DESC LIMIT 1`;
      const selectResult = await db.query(selectQuery);

      let rows = selectResult && selectResult.data !== undefined 
        ? selectResult.data 
        : (Array.isArray(selectResult[0]) ? selectResult[0] : selectResult);

      let newGardenId = 'G001';
      if (rows && rows.length > 0) {
        const lastIdNum = parseInt(rows[0].garden_id.replace('G', ''), 10);
        newGardenId = 'G' + String(lastIdNum + 1).padStart(3, '0');
      }

      // 2. บันทึกข้อมูลสวนใหม่ลงฐานข้อมูล
      const insertQuery = `
        INSERT INTO garden (garden_id, user_id, garden_name, area_size, plant_count, plant_year, address)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      const insertParams = [
        newGardenId,
        user_id,
        garden_name,
        area_size,
        plant_count,
        plant_year,
        address || null
      ];

      const insertResult = await db.query(insertQuery, insertParams);

      if (insertResult && insertResult.data !== undefined) {
        return { isError: false, data: { garden_id: newGardenId }, errorMessage: "" };
      }

      return {
        isError: false,
        data: { garden_id: newGardenId },
        errorMessage: ""
      };

    } catch (error) {
      console.error("❌ Error in garden.js (createGarden):", error.message);
      return {
        isError: true,
        data: null,
        errorMessage: error.message
      };
    }
  }
};



module.exports = garden;