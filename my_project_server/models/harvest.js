const db = require('../libs/db_pool');

class HarvestModel {
  // ดึงรายการเก็บเกี่ยวทั้งหมด (ดึงชื่อแปลงจากตาราง garden และชื่อร้านจากตาราง shop)
  static async getAllHarvests(gardenId = null) {
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
    if (gardenId) {
      query += ` WHERE h.garden_id = ?`;
      params.push(gardenId);
    }

    query += ` ORDER BY h.harvest_date DESC`;

    const [rows] = await db.query(query, params);
    return rows;
  }

  // ดึงข้อมูลสรุปภาพรวม + ผลผลิตย้อนหลัง 6 เดือน
  static async getSummary(gardenId = null) {
    let whereClause = gardenId ? `WHERE garden_id = ${db.escape(gardenId)}` : '';

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
        DATE_FORMAT(harvest_date, '%b') AS month_name,
        SUM(total_quantity) AS total_kg
      FROM harvest
      WHERE harvest_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
      ${gardenId ? `AND garden_id = ${db.escape(gardenId)}` : ''}
      GROUP BY YEAR(harvest_date), MONTH(harvest_date), DATE_FORMAT(harvest_date, '%b')
      ORDER BY harvest_date ASC
    `;

    const [[summaryResult]] = await db.query(summaryQuery);
    const [monthlyResult] = await db.query(monthlyQuery);

    const last6MonthsProduction = {};
    monthlyResult.forEach(row => {
      last6MonthsProduction[row.month_name] = parseFloat(row.total_kg);
    });

    return {
      totalQuantityKg: parseFloat(summaryResult.totalQuantityKg),
      totalRevenue: parseFloat(summaryResult.totalRevenue),
      averagePrice: parseFloat(summaryResult.averagePrice),
      last6MonthsProduction
    };
  }
}

module.exports = HarvestModel;