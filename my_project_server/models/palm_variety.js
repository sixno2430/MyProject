const db = require('../libs/db_pool');

async function getAll() {
  try {
    const result = await db.query('SELECT * FROM palm_variety');

    // กรณี db.query คืนค่าเป็น [rows, fields] ตามปกติของ mysql2/promise
    let rows = Array.isArray(result) && Array.isArray(result[0]) ? result[0] : result;

    // ป้องกันกรณี result ถูกหุ้มเป็น Object หรือไม่มีข้อมูล
    if (!Array.isArray(rows)) {
      rows = rows ? [rows] : [];
    }

    return {
      isError: false,
      data: rows
    };
  } catch (error) {
    console.error('Error in getAll palm_variety:', error);
    return {
      isError: true,
      errorMessage: error.message,
      data: []
    };
  }
}

module.exports = { getAll };