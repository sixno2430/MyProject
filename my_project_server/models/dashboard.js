const pool = require('../libs/db_pool');

module.exports = {
  // ดึงข้อมูลสรุปทั้งหมดสำหรับหน้า Dashboard ในครั้งเดียว
  // - จำนวนแปลงสวน
  // - ผลผลิตรวมเดือนนี้ (กก.)
  // - รายรับรวมเดือนนี้ (บาท)
  // - กิจกรรมล่าสุด 5 รายการ (เก็บเกี่ยว / ใส่ปุ๋ย / รับเงิน)
  getDashboardSummary: async (userId) => {
    let conn;
    let result;
    try {
      conn = await pool.getConnection();

      // 1) จำนวนแปลงสวน
      var gardenCountSql = "SELECT COUNT(*) AS garden_count FROM garden WHERE user_id = ?";
      var gardenCountRows = await conn.query(gardenCountSql, [userId]);
      var gardenCount = Number(gardenCountRows[0].garden_count);

      // 2) ผลผลิตรวมเดือนนี้ (กก.) — join harvest กับ garden เพื่อกรองด้วย user_id
      var productionSql =
          "SELECT COALESCE(SUM(h.total_quantity), 0) AS total_production " +
          "FROM harvest h " +
          "JOIN garden g ON h.garden_id = g.garden_id " +
          "WHERE g.user_id = ? " +
          "AND MONTH(h.harvest_date) = MONTH(CURDATE()) " +
          "AND YEAR(h.harvest_date) = YEAR(CURDATE())";
      var productionRows = await conn.query(productionSql, [userId]);
      var monthlyProduction = Number(productionRows[0].total_production);

      // 3) รายรับรวมเดือนนี้ (บาท) — เฉพาะ record_type = 'INCOME'
      var incomeSql =
          "SELECT COALESCE(SUM(amount), 0) AS total_income " +
          "FROM finance " +
          "WHERE user_id = ? AND record_type = 'INCOME' " +
          "AND MONTH(record_date) = MONTH(CURDATE()) " +
          "AND YEAR(record_date) = YEAR(CURDATE())";
      var incomeRows = await conn.query(incomeSql, [userId]);
      var monthlyIncome = Number(incomeRows[0].total_income);

      // 4) กิจกรรมล่าสุด — รวม 3 แหล่ง แล้วเรียงตามวันที่ล่าสุด จำกัด 5 รายการ
      var activitySql =
          "(SELECT 'harvest' AS type, g.garden_name AS garden_name, " +
          "   NULL AS description, h.total_quantity AS quantity, " +
          "   NULL AS amount, h.harvest_date AS record_date " +
          " FROM harvest h " +
          " JOIN garden g ON h.garden_id = g.garden_id " +
          " WHERE g.user_id = ?) " +
          "UNION ALL " +
          "(SELECT 'care' AS type, g.garden_name AS garden_name, " +
          "   f.fertilizer_name AS description, c.quantity AS quantity, " +
          "   c.cost AS amount, c.record_date AS record_date " +
          " FROM palm_care c " +
          " JOIN garden g ON c.garden_id = g.garden_id " +
          " LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id " +
          " WHERE g.user_id = ?) " +
          "UNION ALL " +
          "(SELECT 'income' AS type, g.garden_name AS garden_name, " +
          "   fn.description AS description, NULL AS quantity, " +
          "   fn.amount AS amount, fn.record_date AS record_date " +
          " FROM finance fn " +
          " LEFT JOIN garden g ON fn.garden_id = g.garden_id " +
          " WHERE fn.user_id = ? AND fn.record_type = 'INCOME') " +
          "ORDER BY record_date DESC " +
          "LIMIT 5";
      var activityRows = await conn.query(activitySql, [userId, userId, userId]);

      result = {
        isError: false,
        data: {
          garden_count: gardenCount,
          monthly_production: monthlyProduction,
          monthly_income: monthlyIncome,
          activities: activityRows,
        },
      };
    } catch (error) {
      result = {
        isError: true,
        errorMessage: error.message,
      };
    } finally {
      if (conn) conn.release();
      return result;
    }
  },
};