const db = require('../libs/db_pool');

class FinanceModel {
  // 1. ดึงสรุปยอดเงินรายรับ-รายจ่ายประจำเดือน
  static async getSummary(month) {
    try {
      let whereClause = '';
      const params = [];

      if (month) {
        whereClause = `WHERE DATE_FORMAT(record_date, '%Y-%m') = ?`;
        params.push(month);
      }

      const query = `
        SELECT 
          COALESCE(SUM(CASE WHEN UPPER(record_type) = 'INCOME' THEN amount ELSE 0 END), 0) AS totalIncome,
          COALESCE(SUM(CASE WHEN UPPER(record_type) = 'EXPENSE' THEN amount ELSE 0 END), 0) AS totalExpense
        FROM finance
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

  // 2. ดึงรายการธุรกรรมประจำเดือนแบบละเอียด (JOIN ตาราง garden เพื่อดึงชื่อสวน)
  static async getTransactions(month, type) {
    try {
      let conditions = [];
      const params = [];

      if (month) {
        conditions.push(`DATE_FORMAT(f.record_date, '%Y-%m') = ?`);
        params.push(month);
      }

      // รองรับการกรองตามประเภท หรือแสดงทั้งหมดกรณี type = 'all'
      if (type && type !== 'all') {
        conditions.push(`UPPER(f.record_type) = ?`);
        params.push(type.toUpperCase());
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
      
      const query = `
        SELECT 
          f.finance_id AS id,
          COALESCE(f.description, f.expense_category, 'รายการทั่วไป') AS title,
          LOWER(f.record_type) AS type,
          f.amount,
          COALESCE(f.expense_category, '') AS category,
          COALESCE(g.garden_name, '') AS gardenName,
          DATE_FORMAT(f.record_date, '%Y-%m-%d') AS date
        FROM finance f
        LEFT JOIN garden g ON f.garden_id = g.garden_id
        ${whereClause}
        ORDER BY f.record_date DESC, f.finance_id DESC
      `;

      const result = await db.query(query, params);
      const rows = Array.isArray(result[0]) ? result[0] : (Array.isArray(result) ? result : []);

      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error in FinanceModel.getTransactions:', error);
      return { isError: true, data: [], errorMessage: error.message };
    }
  }

  // 3. ฟังก์ชันบันทึกการซื้อขายใหม่
  static async createTransaction(data) {
    try {
      const { user_id, garden_id, record_type, amount, expense_category, description, record_date } = data;

      // Gen รหัส finance_id ถัดไป เช่น FN001, FN002
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
        user_id || 'U002', // Default User ID
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