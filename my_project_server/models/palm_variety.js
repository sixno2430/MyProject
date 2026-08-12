const db = require('../libs/db_pool');

const palmVariety = {
  getAll: async () => {
    try {
      const query = `SELECT variety_id, variety_name, scientific_name FROM palm_variety ORDER BY variety_id`;
      const result = await db.query(query);
      const rows = Array.isArray(result[0]) ? result[0] : (result.data || result);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      return { isError: true, data: [], errorMessage: error.message };
    }
  }
};

module.exports = palmVariety;