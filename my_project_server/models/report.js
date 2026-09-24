const db = require('../libs/db_pool');

// รายรับ/รายจ่ายทั้งหมดของ user รวมจาก 3 แหล่ง (แบบเดียวกับหน้าการเงิน)
//   - ขายผลผลิต (harvest.total_price)       = รายรับ
//   - ค่าดูแลสวน (palm_care.cost)            = รายจ่าย
//   - รายการที่บันทึกเองในตาราง finance        = ตาม record_type
const MONEY_SOURCES = `
  SELECT h.harvest_date AS date, 'INCOME' AS type, h.total_price AS amount, g.user_id
  FROM harvest h JOIN garden g ON h.garden_id = g.garden_id
  UNION ALL
  SELECT c.record_date, 'EXPENSE', c.cost, g.user_id
  FROM palm_care c JOIN garden g ON c.garden_id = g.garden_id
  UNION ALL
  SELECT fn.record_date, UPPER(fn.record_type), fn.amount, fn.user_id
  FROM finance fn
  WHERE fn.ref_care_id IS NULL AND fn.ref_purchase_id IS NULL
`;

const report = {
  // สรุปรายงานประจำปีของ user คนเดียว
  getYearlyReport: async (userId, year) => {
    try {
      // 1) ผลผลิตรวมทั้งปี
      const productionRows = await db.query(`
        SELECT COALESCE(SUM(h.total_quantity), 0) AS totalKg
        FROM harvest h
        JOIN garden g ON h.garden_id = g.garden_id
        WHERE g.user_id = ? AND YEAR(h.harvest_date) = ?
      `, [userId, year]);

      // 2) รายรับ / รายจ่ายรวมทั้งปี
      const moneyRows = await db.query(`
        SELECT
          COALESCE(SUM(CASE WHEN type = 'INCOME'  THEN amount END), 0) AS totalIncome,
          COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount END), 0) AS totalExpense
        FROM (${MONEY_SOURCES}) AS m
        WHERE m.user_id = ? AND YEAR(m.date) = ?
      `, [userId, year]);

      // 3) ผลผลิตแยกตามแปลง (ใช้ทำกราฟวงกลม) — เอาเฉพาะแปลงที่มีผลผลิต
      const byGarden = await db.query(`
        SELECT g.garden_id AS gardenId, g.garden_name AS gardenName,
               SUM(h.total_quantity) AS totalKg
        FROM garden g
        JOIN harvest h ON h.garden_id = g.garden_id AND YEAR(h.harvest_date) = ?
        WHERE g.user_id = ?
        GROUP BY g.garden_id, g.garden_name
        HAVING totalKg > 0
        ORDER BY totalKg DESC
      `, [year, userId]);

      // 4) รายรับ-รายจ่ายรายเดือน (ใช้ทำกราฟเส้น)
      const monthlyRows = await db.query(`
        SELECT MONTH(m.date) AS month,
          COALESCE(SUM(CASE WHEN type = 'INCOME'  THEN amount END), 0) AS income,
          COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount END), 0) AS expense
        FROM (${MONEY_SOURCES}) AS m
        WHERE m.user_id = ? AND YEAR(m.date) = ?
        GROUP BY MONTH(m.date)
      `, [userId, year]);

      // เติมเดือนที่ไม่มีข้อมูลให้เป็น 0 จะได้ครบ 12 เดือนเสมอ
      const monthly = Array.from({ length: 12 }, (_, i) => {
        const row = monthlyRows.find(r => Number(r.month) === i + 1);
        return {
          month: i + 1,
          income: row ? parseFloat(row.income) : 0,
          expense: row ? parseFloat(row.expense) : 0,
        };
      });

      const totalIncome = parseFloat(moneyRows[0].totalIncome);
      const totalExpense = parseFloat(moneyRows[0].totalExpense);

      return {
        isError: false,
        data: {
          year: Number(year),
          totalKg: parseFloat(productionRows[0].totalKg),
          totalIncome,
          totalExpense,
          profit: totalIncome - totalExpense,
          byGarden: byGarden.map(r => ({
            gardenId: r.gardenId,
            gardenName: r.gardenName,
            totalKg: parseFloat(r.totalKg),
          })),
          monthly,
        },
        errorMessage: ''
      };
    } catch (error) {
      console.error('Error getYearlyReport:', error.message);
      return { isError: true, data: null, errorMessage: 'โหลดรายงานไม่สำเร็จ' };
    }
  },
};

module.exports = report;
