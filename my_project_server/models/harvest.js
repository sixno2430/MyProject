const db = require('../libs/db_pool');

class HarvestModel {
  // 1. ดึงรายการเก็บเกี่ยวทั้งหมดย้อนหลัง 1 ปี
  static async getAllHarvests(gardenId = null) {
    try {
      let query = `
        SELECT 
          h.harvest_id AS id,
          COALESCE(h.code, h.harvest_id) AS code,
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
        query += ` WHERE h.garden_id = ? AND h.harvest_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)`;
        params.push(gardenId);
      } else {
        query += ` WHERE h.harvest_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)`;
      }

      query += ` ORDER BY h.harvest_date DESC`;

      const [rows] = await db.query(query, params);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error getAllHarvests:', error);
      return { isError: true, data: [], errorMessage: error.message };
    }
  }

  // 2. ดึงข้อมูลสรุปผลรวม + กราฟ 12 เดือนย้อนหลัง
  static async getSummary(gardenId = null) {
    try {
      let whereClause = `WHERE harvest_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)`;
      if (gardenId && gardenId !== 'ALL') {
        whereClause += ` AND garden_id = ${db.escape(gardenId)}`;
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

      const [[summaryResult]] = await db.query(summaryQuery);
      const [monthlyResult] = await db.query(monthlyQuery);

      const dbDataMap = {};
      monthlyResult.forEach(row => {
        dbDataMap[row.month_key] = parseFloat(row.total_kg);
      });

      const last12MonthsProduction = {};
      const now = new Date();
      
      for (let i = 11; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const monthKey = d.toISOString().slice(0, 7); // Format: YYYY-MM
        
        const thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
        const monthLabel = thaiMonths[d.getMonth()];

        last12MonthsProduction[monthLabel] = dbDataMap[monthKey] || 0;
      }

      return {
        isError: false,
        data: {
          totalQuantityKg: parseFloat(summaryResult.totalQuantityKg),
          totalRevenue: parseFloat(summaryResult.totalRevenue),
          averagePrice: parseFloat(summaryResult.averagePrice),
          last12MonthsProduction
        },
        errorMessage: ""
      };
    } catch (error) {
      console.error('Error getSummary:', error);
      return { isError: true, data: null, errorMessage: error.message };
    }
  }
}

module.exports = HarvestModel;