const db = require('../libs/db_pool');

const harvest = {
  // 1. ดึงรายการเก็บเกี่ยวทั้งหมด
  getAllHarvests: async (gardenId = null) => {
    try {
      let query = `
        SELECT 
          h.harvest_id AS id,
          COALESCE(h.code, CAST(h.harvest_id AS CHAR)) AS code,
          COALESCE(g.garden_name, 'แปลงปาล์ม') AS plotName,
          COALESCE(s.shop_name, 'ไม่ระบุร้านรับซื้อ') AS buyer,
          CAST(h.total_quantity AS DOUBLE) AS quantityKg,
          CAST(h.price_per_kg AS DOUBLE) AS pricePerKg,
          CAST(h.total_price AS DOUBLE) AS totalPrice,
          DATE_FORMAT(h.harvest_date, '%Y-%m-%d') AS date,
          COALESCE(h.status, 'sold') AS status
        FROM harvest h
        LEFT JOIN garden g ON h.garden_id = g.garden_id
        LEFT JOIN shop s ON h.shop_id = s.shop_id
      `;

      const params = [];
      if (gardenId && gardenId !== 'ALL') {
        query += ` WHERE h.garden_id = ? AND YEAR(h.harvest_date) = YEAR(CURDATE())`;
        params.push(gardenId);
      } else {
        query += ` WHERE YEAR(h.harvest_date) = YEAR(CURDATE())`;
      }

      query += ` ORDER BY h.harvest_date DESC`;

      const rows = await db.query(query, params);
      const result = Array.isArray(rows) ? rows : (rows ? (rows.data || []) : []);

      return { isError: false, data: result, errorMessage: "" };
    } catch (error) {
      console.error('Error getAllHarvests:', error);
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // 2. ดึงข้อมูลสรุปผลรวม + กราฟ
  getSummary: async (gardenId = null) => {
    try {
      let whereClause = `WHERE YEAR(harvest_date) = YEAR(CURDATE())`;
      const params = [];

      if (gardenId && gardenId !== 'ALL') {
        whereClause += ` AND garden_id = ?`;
        params.push(gardenId);
      }

      const summaryQuery = `
        SELECT 
          COALESCE(SUM(total_quantity), 0) AS totalQuantityKg,
          COALESCE(SUM(total_price), 0) AS totalRevenue,
          COALESCE(AVG(price_per_kg), 0) AS averagePrice
        FROM harvest
        ${whereClause}
      `;

      const monthlyQuery = `
        SELECT 
          DATE_FORMAT(harvest_date, '%Y-%m') AS month_key,
          SUM(total_quantity) AS total_kg
        FROM harvest
        ${whereClause}
        GROUP BY DATE_FORMAT(harvest_date, '%Y-%m')
        ORDER BY month_key ASC
      `;

      const summaryRes = await db.query(summaryQuery, params);
      const monthlyRes = await db.query(monthlyQuery, params);

      const summaryRows = Array.isArray(summaryRes) ? summaryRes : (summaryRes ? (summaryRes.data || []) : []);
      const monthlyRows = Array.isArray(monthlyRes) ? monthlyRes : (monthlyRes ? (monthlyRes.data || []) : []);

      const summaryResult = summaryRows.length > 0 
        ? summaryRows[0] 
        : { totalQuantityKg: 0, totalRevenue: 0, averagePrice: 0 };

      const dbDataMap = {};
      monthlyRows.forEach(row => {
        if (row && row.month_key) {
          dbDataMap[row.month_key] = parseFloat(row.total_kg || 0);
        }
      });

      const last12MonthsProduction = {};
      const currentYear = new Date().getFullYear();
      const thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

      for (let monthIndex = 0; monthIndex < 12; monthIndex++) {
        const monthStr = String(monthIndex + 1).padStart(2, '0');
        const monthKey = `${currentYear}-${monthStr}`;

        const monthLabel = thaiMonths[monthIndex];
        last12MonthsProduction[monthLabel] = dbDataMap[monthKey] || 0;
      }

      return {
        isError: false,
        data: {
          totalQuantityKg: parseFloat(summaryResult.totalQuantityKg || 0),
          totalRevenue: parseFloat(summaryResult.totalRevenue || 0),
          averagePrice: parseFloat(summaryResult.averagePrice || 0),
          last12MonthsProduction
        },
        errorMessage: ""
      };
    } catch (error) {
      console.error('Error getSummary:', error);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  // 3. ฟังก์ชันสร้างบันทึกการเก็บเกี่ยวใหม่
  createHarvest: async (data) => {
    try {
      const { garden_id, harvest_date, total_quantity, price_per_kg, total_price, status } = data;

      const maxRows = await db.query(`
        SELECT MAX(CAST(SUBSTRING(harvest_id, 2) AS UNSIGNED)) AS max_num 
        FROM harvest 
        WHERE harvest_id LIKE 'H%'
      `);

      const rows = Array.isArray(maxRows) ? maxRows : (maxRows ? (maxRows.data || []) : []);
      const maxNum = (rows.length > 0 && rows[0].max_num !== null) ? parseInt(rows[0].max_num, 10) : 0;

      const newHarvestId = 'H' + String(maxNum + 1).padStart(3, '0');

      const query = `
        INSERT INTO harvest 
        (harvest_id, garden_id, harvest_date, total_quantity, price_per_kg, total_price, status)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;

      const params = [
        newHarvestId,
        garden_id || null,
        harvest_date,
        total_quantity || 0,
        price_per_kg || 0,
        total_price || 0,
        status || 'sold'
      ];

      await db.query(query, params);

      return { isError: false, data: { harvest_id: newHarvestId }, errorMessage: "" };
    } catch (error) {
      console.error('Error createHarvest:', error);
      return { isError: true, data: null, errorMessage: error.message };
    }
  }
};

module.exports = harvest;