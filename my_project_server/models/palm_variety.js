// models/palm_variety.js
const db = require('../libs/db_pool');

async function getAll() {
  try {
    const [rows] = await db.query('SELECT * FROM palm_variety');
    // ต้อง return เป็น { isError: false, data: rows }
    return { isError: false, data: rows };
  } catch (error) {
    console.error('Error in getAll varieties:', error);
    return { isError: true, errorMessage: error.message, data: [] };
  }
}

module.exports = { getAll };