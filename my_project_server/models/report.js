// ============================================================
// report.js — model รายงานสรุปประจำปี (หน้า "รายงาน" ของเกษตรกร)
//
// - ตัวเลขรวมทั้งปี: ผลผลิต, รายรับ, รายจ่าย, กำไร
// - สรุปรายแปลง: ผลผลิต (+ ต่อไร่), รายรับ, รายจ่าย, กำไร ของแต่ละแปลง + "ส่วนกลาง" (รายการเงินที่ไม่ผูกแปลง)
// - รายรับ-รายจ่ายรายเดือน
// - ผลผลิตรายเดือนเทียบกับปีก่อน
// ============================================================

const db = require('../libs/db_pool');

// รายรับ/รายจ่ายทั้งหมดของ user รวมจาก 3 แหล่ง (แบบเดียวกับหน้าการเงิน)
//   - ขายผลผลิต (harvest.total_price)       = รายรับ (เฉพาะที่ขายแล้ว ไม่นับรอขาย)
//     วันที่ = วันที่ขาย (ร้านรับซื้อ / ขายนอกระบบ) ข้อมูลเก่าที่ไม่มีวันที่ขายใช้วันเก็บเกี่ยว
//   - ค่าดูแลสวน (palm_care.cost)            = รายจ่าย
//   - รายการที่บันทึกเองในตาราง finance        = ตาม record_type (garden_id ว่าง = ส่วนกลาง)
const MONEY_SOURCES = `
  SELECT COALESCE(p.purchase_date, h.sold_date, h.harvest_date) AS date, 'INCOME' AS type, h.total_price AS amount,
         g.user_id, h.garden_id
  FROM harvest h JOIN garden g ON h.garden_id = g.garden_id
  LEFT JOIN purchase p ON p.harvest_id = h.harvest_id
  WHERE COALESCE(h.status, 'sold') = 'sold'
  UNION ALL
  SELECT c.record_date, 'EXPENSE', c.cost, g.user_id, c.garden_id
  FROM palm_care c JOIN garden g ON c.garden_id = g.garden_id
  UNION ALL
  SELECT fn.record_date, UPPER(fn.record_type), fn.amount, fn.user_id, fn.garden_id
  FROM finance fn
  WHERE fn.ref_care_id IS NULL AND fn.ref_purchase_id IS NULL
`;

// ผลผลิตรายเดือน (กก.) ของปีที่ระบุ ครบ 12 เดือน (เดือนที่ไม่มี = 0)
async function productionByMonth(userId, year) {
  const rows = await db.query(`
    SELECT MONTH(h.harvest_date) AS month, SUM(h.total_quantity) AS kg
    FROM harvest h JOIN garden g ON h.garden_id = g.garden_id
    WHERE g.user_id = ? AND YEAR(h.harvest_date) = ?
    GROUP BY MONTH(h.harvest_date)
  `, [userId, year]);
  return Array.from({ length: 12 }, (_, i) => {
    const row = rows.find((r) => Number(r.month) === i + 1);
    return row ? parseFloat(row.kg) : 0;
  });
}

const report = {
  // สรุปรายงานประจำปีของ user คนเดียว
  //   month (1-12) = ดูรายเดือน: ตัวเลขสรุป + สรุปรายแปลง คิดเฉพาะเดือนนั้น
  //   (กราฟรายเดือนและตารางเทียบปีก่อนยังเป็นของทั้งปี หน้าแอปเลือกใช้เดือนที่ต้องการเอง)
  getYearlyReport: async (userId, year, month = null) => {
    try {
      // เงื่อนไขเดือนเพิ่มเติม (ไม่ส่ง month = ทั้งปี)
      const monthOf = (col) => (month ? `AND MONTH(${col}) = ?` : '');
      const monthParam = month ? [month] : [];

      // 1) ผลผลิตรวมทั้งปี
      const productionRows = await db.query(`
        SELECT COALESCE(SUM(h.total_quantity), 0) AS totalKg
        FROM harvest h
        JOIN garden g ON h.garden_id = g.garden_id
        WHERE g.user_id = ? AND YEAR(h.harvest_date) = ? ${monthOf('h.harvest_date')}
      `, [userId, year, ...monthParam]);

      // 2) รายรับ / รายจ่ายรวมทั้งปี
      const moneyRows = await db.query(`
        SELECT
          COALESCE(SUM(CASE WHEN type = 'INCOME'  THEN amount END), 0) AS totalIncome,
          COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount END), 0) AS totalExpense
        FROM (${MONEY_SOURCES}) AS m
        WHERE m.user_id = ? AND YEAR(m.date) = ? ${monthOf('m.date')}
      `, [userId, year, ...monthParam]);

      // 3) สรุปรายแปลง: ทุกแปลงของ user (แปลงที่ยังไม่มีข้อมูลก็แสดงเป็น 0) + ส่วนกลาง
      const gardens = await db.query(
        `SELECT garden_id, garden_name, area_size FROM garden WHERE user_id = ? ORDER BY garden_id`,
        [userId]
      );
      const kgRows = await db.query(`
        SELECT h.garden_id, SUM(h.total_quantity) AS kg
        FROM harvest h JOIN garden g ON h.garden_id = g.garden_id
        WHERE g.user_id = ? AND YEAR(h.harvest_date) = ? ${monthOf('h.harvest_date')}
        GROUP BY h.garden_id
      `, [userId, year, ...monthParam]);
      const moneyByGarden = await db.query(`
        SELECT m.garden_id,
          COALESCE(SUM(CASE WHEN type = 'INCOME'  THEN amount END), 0) AS income,
          COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount END), 0) AS expense
        FROM (${MONEY_SOURCES}) AS m
        WHERE m.user_id = ? AND YEAR(m.date) = ? ${monthOf('m.date')}
        GROUP BY m.garden_id
      `, [userId, year, ...monthParam]);
      const moneyOf = (gardenId) => moneyByGarden.find((r) => r.garden_id === gardenId) || { income: 0, expense: 0 };
      const byGarden = gardens.map((g) => {
        const kgRow = kgRows.find((r) => r.garden_id === g.garden_id);
        const money = moneyOf(g.garden_id);
        const income = parseFloat(money.income);
        const expense = parseFloat(money.expense);
        return {
          gardenId: g.garden_id,
          gardenName: g.garden_name,
          areaRai: parseFloat(g.area_size || 0),
          totalKg: kgRow ? parseFloat(kgRow.kg) : 0,
          income,
          expense,
          profit: income - expense,
        };
      }).sort((a, b) => b.totalKg - a.totalKg || b.income - a.income);
      const commonMoney = moneyOf(null); // รายการเงินที่ไม่ผูกกับแปลง
      const common = {
        income: parseFloat(commonMoney.income),
        expense: parseFloat(commonMoney.expense),
      };

      // 3.1) ผลผลิตรายเดือน ปีนี้ เทียบปีก่อน
      const [kgThisYear, kgLastYear] = await Promise.all([
        productionByMonth(userId, year),
        productionByMonth(userId, Number(year) - 1),
      ]);

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
          month: month ? Number(month) : null,
          totalKg: parseFloat(productionRows[0].totalKg),
          totalIncome,
          totalExpense,
          profit: totalIncome - totalExpense,
          byGarden,
          common: { ...common, profit: common.income - common.expense },
          monthly,
          // ผลผลิตรายเดือนเทียบปีก่อน [{ month, kg, prevKg }] + ยอดรวมปีก่อน
          production: kgThisYear.map((kg, i) => ({ month: i + 1, kg, prevKg: kgLastYear[i] })),
          prevTotalKg: kgLastYear.reduce((s, v) => s + v, 0),
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
