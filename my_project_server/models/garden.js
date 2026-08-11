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
      console.error("❌ Error in garden.js:", error.message);
      return {
        isError: true,
        data: [],
        errorMessage: error.message
      };
    }
  }
};

module.exports = garden;