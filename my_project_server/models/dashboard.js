const pool = require('../libs/db_pool');

// กิจกรรมทั้งหมดของ user รวม 4 แหล่ง เรียงวันที่ล่าสุดก่อน
// คอลัมน์ต้องเหมือนกันทุกส่วนของ UNION จึงเติม NULL ในช่องที่แหล่งนั้นไม่มี
// ช่องเสริม (price_per_kg, action_type ฯลฯ) มีไว้ให้หน้ารายละเอียดเปิดฟอร์มแก้ไขได้
const ACTIVITY_SQL =
    "(SELECT 'harvest' AS type, h.harvest_id AS id, h.garden_id, g.garden_name, " +
    "   NULL AS description, h.total_quantity AS quantity, h.total_price AS amount, " +
    "   h.harvest_date AS record_date, h.price_per_kg, h.status, h.code, " +
    "   NULL AS fertilizer_id, NULL AS action_type, NULL AS quantity_type, NULL AS note, NULL AS category " +
    " FROM harvest h JOIN garden g ON h.garden_id = g.garden_id " +
    " WHERE g.user_id = ?) " +
    "UNION ALL " +
    "(SELECT 'care', c.care_id, c.garden_id, g.garden_name, " +
    "   COALESCE(f.fertilizer_name, NULLIF(c.note, '')), c.quantity, c.cost, " +
    "   c.record_date, NULL, NULL, NULL, " +
    "   c.fertilizer_id, c.action_type, c.quantity_type, c.note, NULL " +
    " FROM palm_care c JOIN garden g ON c.garden_id = g.garden_id " +
    " LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id " +
    " WHERE g.user_id = ?) " +
    "UNION ALL " +
    "(SELECT LOWER(fn.record_type), fn.finance_id, fn.garden_id, COALESCE(g.garden_name, 'ไม่ระบุแปลง'), " +
    "   fn.description, NULL, fn.amount, " +
    "   fn.record_date, NULL, NULL, NULL, " +
    "   NULL, NULL, NULL, NULL, fn.expense_category " +
    " FROM finance fn LEFT JOIN garden g ON fn.garden_id = g.garden_id " +
    " WHERE fn.user_id = ? AND fn.ref_care_id IS NULL AND fn.ref_purchase_id IS NULL) " +
    "ORDER BY record_date DESC, id DESC";

module.exports = {
  // กิจกรรมทั้งหมด (หน้า "ประวัติกิจกรรม") — limit = null คือเอาทั้งหมด
  getActivities: async (userId, limit = null) => {
    try {
      var sql = ACTIVITY_SQL + (limit ? " LIMIT " + Number(limit) : "");
      var rows = await pool.query(sql, [userId, userId, userId]);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error getActivities:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดกิจกรรมไม่สำเร็จ' };
    }
  },

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

      // 3) รายรับรวมเดือนนี้ (บาท) — ขายผลผลิต + รายรับที่บันทึกเอง (ให้ตรงกับหน้าการเงิน)
      var incomeSql =
          "SELECT COALESCE(SUM(amount), 0) AS total_income FROM (" +
          "  SELECT h.total_price AS amount, h.harvest_date AS d " +
          "  FROM harvest h JOIN garden g ON h.garden_id = g.garden_id WHERE g.user_id = ? " +
          "  UNION ALL " +
          "  SELECT fn.amount, fn.record_date FROM finance fn " +
          "  WHERE fn.user_id = ? AND fn.record_type = 'INCOME' " +
          "    AND fn.ref_care_id IS NULL AND fn.ref_purchase_id IS NULL" +
          ") AS m " +
          "WHERE MONTH(d) = MONTH(CURDATE()) AND YEAR(d) = YEAR(CURDATE())";
      var incomeRows = await conn.query(incomeSql, [userId, userId]);
      var monthlyIncome = Number(incomeRows[0].total_income);

      // 4) กิจกรรมล่าสุด 5 รายการ (ใช้ query เดียวกับหน้าประวัติกิจกรรม)
      var activityRows = await conn.query(ACTIVITY_SQL + " LIMIT 5", [userId, userId, userId]);

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
      
    }
    return result;
  },
};