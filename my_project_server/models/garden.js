const db = require('../libs/db_pool'); // ดึง DB Pool ของโครงการ

const garden = {

  getGardensByUserId: async (userId) => {
    try {
      // 1. ดึงรายการสวน (ถ้าส่ง 'ALL' มา ดึงทุกสวน)
      let gardenQuery = `
        SELECT garden_id, user_id, garden_name, area_size, plant_count, plant_year, plant_age, address
        FROM garden
      `;
      const params = [];

      if (userId && userId !== 'ALL') {
        gardenQuery += ` WHERE user_id = ?`;
        params.push(userId);
      }

      const gardenResult = await db.query(gardenQuery, params);
      const gardens = Array.isArray(gardenResult[0]) ? gardenResult[0] : (gardenResult.data || gardenResult);

      // 2. ดึงพันธุ์ปาล์มของแต่ละสวน แล้วใส่เข้าไปใน object
      if (Array.isArray(gardens)) {
        for (let g of gardens) {
          const varietyQuery = `
            SELECT gv.variety_id, pv.variety_name, gv.plant_count 
            FROM garden_variety gv
            JOIN palm_variety pv ON gv.variety_id = pv.variety_id
            WHERE gv.garden_id = ?
          `;
          const vResult = await db.query(varietyQuery, [g.garden_id]);
          const varieties = Array.isArray(vResult[0]) ? vResult[0] : (vResult.data || vResult);
          g.varieties = varieties;
        }
      }

      return {
        isError: false,
        data: gardens || [],
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
  },

  createGarden: async (gardenData) => {
    try {
      const { user_id, garden_name, area_size, plant_count, plant_year, address, variety_id } = gardenData;

      // 1. Gen garden_id
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

      // 2. Insert garden
      const insertQuery = `
        INSERT INTO garden (garden_id, user_id, garden_name, area_size, plant_count, plant_year, address)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      await db.query(insertQuery, [
        newGardenId, user_id, garden_name, area_size, plant_count, plant_year, address || null
      ]);

      // 3. Insert garden_variety ถ้าเลือกพันธุ์มา
      if (variety_id) {
        const gvQuery = `
          INSERT INTO garden_variety (variety_id, garden_id, plant_count, note)
          VALUES (?, ?, ?, ?)
        `;
        await db.query(gvQuery, [variety_id, newGardenId, plant_count || 0, '']);
      }

      return { isError: false, data: { garden_id: newGardenId }, errorMessage: "" };
    } catch (error) {
      console.error("❌ Error in garden.js (createGarden):", error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  updateGarden: async (gardenId, gardenData) => {
    try {
      const { garden_name, address, area_size, plant_year, plant_count } = gardenData;

      const query = `
        UPDATE garden 
        SET garden_name = ?, address = ?, area_size = ?, 
            plant_year = ?, plant_count = ?
        WHERE garden_id = ?
      `;
      await db.query(query, [garden_name, address, area_size, plant_year, plant_count, gardenId]);

      return { isError: false, data: { garden_id: gardenId }, errorMessage: "" };
    } catch (error) {
      console.error("❌ Error in garden.js (updateGarden):", error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  deleteGarden: async (gardenId) => {
    try {
      await db.query("DELETE FROM garden_variety WHERE garden_id = ?", [gardenId]);
      await db.query("DELETE FROM harvest WHERE garden_id = ?", [gardenId]);
      await db.query("DELETE FROM palm_care WHERE garden_id = ?", [gardenId]);

      await db.query("DELETE FROM garden WHERE garden_id = ?", [gardenId]);

      return { isError: false, data: { garden_id: gardenId }, errorMessage: "" };
    } catch (error) {
      console.error("❌ Error in garden.js (deleteGarden):", error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  getGardenVarieties: async (gardenId) => {
    try {
      const query = `
        SELECT pv.variety_id, pv.variety_name, gv.plant_count, gv.note
        FROM garden_variety gv
        JOIN palm_variety pv ON gv.variety_id = pv.variety_id
        WHERE gv.garden_id = ?
      `;
      const result = await db.query(query, [gardenId]);
      const rows = Array.isArray(result[0]) ? result[0] : (result.data || result);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error("❌ Error in garden.js (getGardenVarieties):", error.message);
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // ✅ แก้ไขแล้ว: ตัดคำว่า static ออกสำหรับ Object Literal
  getAllGardens: async () => {
    try {
      const result = await db.query('SELECT garden_id, garden_name FROM garden ORDER BY garden_name ASC');
      const rows = Array.isArray(result[0]) ? result[0] : (result.data || result);
      return { isError: false, data: rows || [], errorMessage: "" };
    } catch (error) {
      console.error('Error getAllGardens:', error);
      return { isError: true, data: [], errorMessage: error.message };
    }
  }
};

module.exports = garden;