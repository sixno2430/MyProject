const db = require('../libs/db_pool');

class FinanceModel {
  // 1. ดึงสรุปยอดเงินรายรับ-รายจ่ายประจำเดือน (รวมจาก harvest + palm_care + finance)
  static async getSummary(month, userId = 'U002') {
    try {
      let whereClause = '';
      const params = [];

      // ถ้าระบุ month เช่น '2026-08'
      if (month) {
        whereClause = `WHERE DATE_FORMAT(date, '%Y-%m') = ?`;
        params.push(month);
      }

      // ดึง UNION รวมข้อมูล 3 ตารางสดๆ จาก Database
      const query = `
        SELECT 
          COALESCE(SUM(CASE WHEN UPPER(type) = 'INCOME' THEN amount ELSE 0 END), 0) AS totalIncome,
          COALESCE(SUM(CASE WHEN UPPER(type) = 'EXPENSE' THEN amount ELSE 0 END), 0) AS totalExpense
        FROM (
          -- 1. รายรับจากตาราง harvest (เก็บเกี่ยว/ขายผลผลิต)
          SELECT 
            total_price AS amount, 
            'INCOME' AS type, 
            harvest_date AS date 
          FROM harvest 
          WHERE total_price > 0 AND (status = 'sold' OR status IS NULL)

          UNION ALL

          -- 2. รายจ่ายจากตาราง palm_care (ดูแลรักษา/ใส่ปุ๋ย)
          SELECT 
            cost AS amount, 
            'EXPENSE' AS type, 
            record_date AS date 
          FROM palm_care 
          WHERE cost > 0

          UNION ALL

          -- 3. รายรับ-รายจ่ายทั่วไปจากตาราง finance
          SELECT 
            amount, 
            record_type AS type, 
            record_date AS date 
          FROM finance
        ) AS all_transactions
        ${whereClause}
      `;

      const result = await db.query(query, params);
      const rows = Array.isArray(result[0]) ? result[0] : (Array.isArray(result) ? result : []);
      const data = rows.length > 0 ? rows[0] : { totalIncome: 0, totalExpense: 0 };

      const totalIncome = parseFloat(data.totalIncome || 0);
      const totalExpense = parseFloat(data.totalExpense || 0);

      return {
        isError: false,
        data: {
          balance: totalIncome - totalExpense,
          totalIncome,
          totalExpense
        },
        errorMessage: ""
      };
    } catch (error) {
      console.error('Error in FinanceModel.getSummary:', error);
      return {
        isError: true,
        data: { balance: 0, totalIncome: 0, totalExpense: 0 },
        errorMessage: error.message
      };
    }
  }

  // 2. ดึงรายการธุรกรรมประจำเดือนแบบละเอียด (รวมจาก harvest + palm_care + finance)
  static async getTransactions(month, type, userId = 'U002') {
    try {
      let conditions = [];
      const params = [];

      if (month) {
        conditions.push(`DATE_FORMAT(t.date, '%Y-%m') = ?`);
        params.push(month);
      }

      if (type && type !== 'all') {
        conditions.push(`UPPER(t.type) = ?`);
        params.push(type.toUpperCase());
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
      
      const query = `
        SELECT 
          t.id,
          t.title,
          LOWER(t.type) AS type,
          t.amount,
          t.category,
          COALESCE(g.garden_name, 'ไม่ระบุสวน') AS gardenName,
          DATE_FORMAT(t.date, '%Y-%m-%d') AS date
        FROM (
          -- 1. ดึงจากตาราง harvest
          SELECT 
            h.harvest_id AS id,
            CONCAT('ขายผลผลิตปาล์ม (', FORMAT(h.total_quantity, 0), ' กก.)') AS title,
            'INCOME' AS type,
            h.total_price AS amount,
            'ขายผลผลิต' AS category,
            h.garden_id,
            h.harvest_date AS date
          FROM harvest h
          WHERE h.total_price > 0 AND (h.status = 'sold' OR h.status IS NULL)

          UNION ALL

          -- 2. ดึงจากตาราง palm_care
          SELECT 
            c.care_id AS id,
            CASE 
              WHEN f.fertilizer_name IS NOT NULL THEN CONCAT('ใส่ปุ๋ย: ', f.fertilizer_name)
              WHEN c.action_type IS NOT NULL THEN CONCAT('ดูแลสวน: ', c.action_type)
              WHEN c.note IS NOT NULL AND c.note != '' THEN CONCAT('ดูแลสวน: ', c.note)
              ELSE 'ดูแลรักษา/บำรุงสวน'
            END AS title,
            'EXPENSE' AS type,
            c.cost AS amount,
            IF(c.fertilizer_id IS NOT NULL, 'ค่าปุ๋ย', 'ค่าดูแลรักษา') AS category,
            c.garden_id,
            c.record_date AS date
          FROM palm_care c
          LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id
          WHERE c.cost > 0

          UNION ALL

          -- 3. ดึงจากตาราง finance
          SELECT 
            fn.finance_id AS id,
            COALESCE(fn.description, fn.expense_category, 'รายการทั่วไป') AS title,
            fn.record_type AS type,
            fn.amount,
            COALESCE(fn.expense_category, 'ทั่วไป') AS category,
            fn.garden_id,
            fn.record_date AS date
          FROM finance fn
        ) AS t
        LEFT JOIN garden g ON t.garden_id = g.garden_id
        ${whereClause}
        ORDER BY t.date DESC, t.id DESC
      `;

      const result = await db.query(query, params);
      const rows = Array.isArray(result[0]) ? result[0] : (Array.isArray(result) ? result : []);

      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error in FinanceModel.getTransactions:', error);
      return { isError: true, data: [], errorMessage: error.message };
    }
  }

  // 3. ฟังก์ชันบันทึกการซื้อขาย/รายรับ-รายจ่ายทั่วไปเข้าตาราง finance
  static async createTransaction(data) {
    try {
      const { user_id, garden_id, record_type, amount, expense_category, description, record_date } = data;

      const maxRows = await db.query(`
        SELECT MAX(CAST(SUBSTRING(finance_id, 3) AS UNSIGNED)) AS max_num 
        FROM finance 
        WHERE finance_id LIKE 'FN%'
      `);

      const rows = Array.isArray(maxRows) ? maxRows : (maxRows ? (maxRows.data || []) : []);
      const maxNum = (rows.length > 0 && rows[0].max_num !== null) ? parseInt(rows[0].max_num, 10) : 0;
      const newFinanceId = 'FN' + String(maxNum + 1).padStart(3, '0');

      const query = `
        INSERT INTO finance 
        (finance_id, user_id, garden_id, record_type, amount, expense_category, description, record_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;

      const params = [
        newFinanceId,
        user_id || 'U002',
        garden_id || null,
        (record_type || 'INCOME').toUpperCase(),
        parseFloat(amount) || 0,
        expense_category || 'ทั่วไป',
        description || '',
        record_date || new Date().toISOString().split('T')[0]
      ];

      await db.query(query, params);

      return { isError: false, data: { finance_id: newFinanceId }, errorMessage: "" };
    } catch (error) {
      console.error('Error createTransaction:', error);
      return { isError: true, data: null, errorMessage: error.message };
    }
  }
}

module.exports = FinanceModel;