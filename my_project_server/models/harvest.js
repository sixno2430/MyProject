// ============================================================
// harvest.js — model การเก็บเกี่ยว (ตาราง harvest)
//
// status: 'sold' = ขายแล้ว, 'pending' = รอขาย (รายได้นับเฉพาะ sold)
// ทุกคำสั่งแก้ไข/ลบ เช็กว่าแปลงเป็นของ user นั้นจริง
// ============================================================

const db = require('../libs/db_pool');

const harvest = {
  // 1. ดึงรายการเก็บเกี่ยวทั้งหมด
  getAllHarvests: async (gardenId = null, userId = null, year = null) => {
    try {
      let query = `
        SELECT 
          h.harvest_id AS id,
          h.garden_id AS gardenId,
          h.shop_id AS shopId,
          COALESCE(h.code, CAST(h.harvest_id AS CHAR)) AS code,
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

      // ปีที่ต้องการดู (ไม่ส่งมา = ปีปัจจุบัน) เดิมล็อกไว้แค่ปีนี้ ทำให้ข้อมูลปีก่อนหายจากหน้าจอ
      const params = [year || new Date().getFullYear()];
      query += ` WHERE YEAR(h.harvest_date) = ?`;
      if (gardenId && gardenId !== 'ALL') {
        query += ` AND h.garden_id = ?`;
        params.push(gardenId);
      }

      if (userId) {
        query += ` AND g.user_id = ?`;
        params.push(userId);
      }

      query += ` ORDER BY h.harvest_date DESC`;

      const rows = await db.query(query, params);
      const result = Array.isArray(rows) ? rows : (rows ? (rows.data || []) : []);

      return { isError: false, data: result, errorMessage: "" };
    } catch (error) {
      console.error('Error getAllHarvests:', error);
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // 2. ดึงข้อมูลสรุปผลรวม + กราฟ
  getSummary: async (gardenId = null, userId = null, year = null) => {
    try {
      const targetYear = year || new Date().getFullYear();
      let whereClause = `WHERE YEAR(harvest_date) = ?`;
      const params = [targetYear];

      if (gardenId && gardenId !== 'ALL') {
        whereClause += ` AND garden_id = ?`;
        params.push(gardenId);
      }

      if (userId) {
        whereClause += ` AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)`;
        params.push(userId);
      }

      const summaryQuery = `
        SELECT 
          COALESCE(SUM(total_quantity), 0) AS totalQuantityKg,
          -- รายได้และราคาเฉลี่ย นับเฉพาะที่ขายแล้ว (น้ำหนักยังนับทุกรายการ)
          COALESCE(SUM(CASE WHEN COALESCE(status, 'sold') = 'sold' THEN total_price END), 0) AS totalRevenue,
          COALESCE(AVG(CASE WHEN COALESCE(status, 'sold') = 'sold' THEN price_per_kg END), 0) AS averagePrice
        FROM harvest
        ${whereClause}
      `;

      const monthlyQuery = `
        SELECT 
          DATE_FORMAT(harvest_date, '%Y-%m') AS month_key,
          SUM(total_quantity) AS total_kg
        FROM harvest
        ${whereClause}
        GROUP BY DATE_FORMAT(harvest_date, '%Y-%m')
        ORDER BY month_key ASC
      `;

      const summaryRes = await db.query(summaryQuery, params);
      const monthlyRes = await db.query(monthlyQuery, params);

      const summaryRows = Array.isArray(summaryRes) ? summaryRes : (summaryRes ? (summaryRes.data || []) : []);
      const monthlyRows = Array.isArray(monthlyRes) ? monthlyRes : (monthlyRes ? (monthlyRes.data || []) : []);

      const summaryResult = summaryRows.length > 0 
        ? summaryRows[0] 
        : { totalQuantityKg: 0, totalRevenue: 0, averagePrice: 0 };

      const dbDataMap = {};
      monthlyRows.forEach(row => {
        if (row && row.month_key) {
          dbDataMap[row.month_key] = parseFloat(row.total_kg || 0);
        }
      });

      const last12MonthsProduction = {};
      const currentYear = targetYear;
      const thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

      for (let monthIndex = 0; monthIndex < 12; monthIndex++) {
        const monthStr = String(monthIndex + 1).padStart(2, '0');
        const monthKey = `${currentYear}-${monthStr}`;

        const monthLabel = thaiMonths[monthIndex];
        last12MonthsProduction[monthLabel] = dbDataMap[monthKey] || 0;
      }

      return {
        isError: false,
        data: {
          totalQuantityKg: parseFloat(summaryResult.totalQuantityKg || 0),
          totalRevenue: parseFloat(summaryResult.totalRevenue || 0),
          averagePrice: parseFloat(summaryResult.averagePrice || 0),
          last12MonthsProduction
        },
        errorMessage: ""
      };
    } catch (error) {
      console.error('Error getSummary:', error);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  // 3. ฟังก์ชันสร้างบันทึกการเก็บเกี่ยวใหม่
  createHarvest: async (data) => {
    try {
      const { user_id, garden_id, shop_id, harvest_date, total_quantity, price_per_kg, total_price, status } = data;

      // บันทึกได้เฉพาะแปลงของตัวเอง
      const owned = await db.query(
        `SELECT garden_id FROM garden WHERE garden_id = ? AND user_id = ?`,
        [garden_id, user_id]
      );
      if (owned.length === 0) {
        return { isError: true, data: null, errorMessage: 'ไม่พบแปลงสวนนี้ในบัญชีของคุณ' };
      }

      const maxRows = await db.query(`
        SELECT MAX(CAST(SUBSTRING(harvest_id, 2) AS UNSIGNED)) AS max_num 
        FROM harvest 
        WHERE harvest_id LIKE 'H%'
      `);

      const rows = Array.isArray(maxRows) ? maxRows : (maxRows ? (maxRows.data || []) : []);
      const maxNum = (rows.length > 0 && rows[0].max_num !== null) ? parseInt(rows[0].max_num, 10) : 0;

      const newHarvestId = 'H' + String(maxNum + 1).padStart(3, '0');

      const query = `
        INSERT INTO harvest 
        (harvest_id, garden_id, shop_id, harvest_date, total_quantity, price_per_kg, total_price, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;

      const params = [
        newHarvestId,
        garden_id || null,
        shop_id || null, // ร้านที่ขายให้ (ไม่ระบุได้)
        harvest_date,
        total_quantity || 0,
        price_per_kg || 0,
        total_price || 0,
        status || 'sold'
      ];

      await db.query(query, params);

      return { isError: false, data: { harvest_id: newHarvestId }, errorMessage: "" };
    } catch (error) {
      console.error('Error createHarvest:', error);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  // 4. แก้ไขบันทึกการเก็บเกี่ยว (เฉพาะสวนของ userId)
  updateHarvest: async (harvestId, userId, data) => {
    try {
      const { garden_id, shop_id, harvest_date, total_quantity, price_per_kg, total_price, status } = data;
      const query = `
        UPDATE harvest
        SET garden_id = ?, shop_id = ?, harvest_date = ?, total_quantity = ?, price_per_kg = ?, total_price = ?, status = ?
        WHERE harvest_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?) AND ? IN (SELECT garden_id FROM garden WHERE user_id = ?)
      `;
      const result = await db.query(query, [
        garden_id, shop_id || null, harvest_date, total_quantity || 0, price_per_kg || 0, total_price || 0, status || 'sold',
        harvestId, userId, garden_id, userId
      ]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์แก้ไข' };
      }
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error updateHarvest:', error);
      return { isError: true, data: null, errorMessage: 'แก้ไขรายการไม่สำเร็จ' };
    }
  },

  // 4.1 ทำเครื่องหมายว่า "ขายแล้ว" พร้อมราคาที่ขายได้จริง
  //     ราคารวมคำนวณใหม่จากน้ำหนักในฐานข้อมูล (total_quantity × ราคา) กันตัวเลขไม่ตรงกัน
  //     shopId = ร้านที่ขายให้ (ไม่ส่งมา = คงร้านเดิมไว้)
  sellHarvest: async (harvestId, userId, pricePerKg, shopId = null) => {
    try {
      const price = parseFloat(pricePerKg);
      if (!(price > 0)) {
        return { isError: true, data: null, errorMessage: 'กรุณาใส่ราคาขายต่อกิโลกรัม' };
      }
      const result = await db.query(`
        UPDATE harvest
        SET status = 'sold', price_per_kg = ?, total_price = total_quantity * ?,
            shop_id = COALESCE(?, shop_id)
        WHERE harvest_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)
      `, [price, price, shopId || null, harvestId, userId]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์แก้ไข' };
      }
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error sellHarvest:', error);
      return { isError: true, data: null, errorMessage: 'บันทึกการขายไม่สำเร็จ' };
    }
  },

  // 5. ลบบันทึกการเก็บเกี่ยว (เฉพาะสวนของ userId)
  //    ลบรายการเงินที่ผูกกับการขาย (purchase) ของผลผลิตนี้ก่อน ไม่งั้นพอ purchase ถูกลบตาม (CASCADE)
  //    ช่อง ref_purchase_id จะกลายเป็น NULL แล้วรายการเงินนั้นจะโผล่เป็น "รายการที่บันทึกเอง"
  deleteHarvest: async (harvestId, userId) => {
    let conn;
    try {
      conn = await db.getConnection();
      await conn.beginTransaction();
      await conn.query(`
        DELETE fn FROM finance fn
        JOIN purchase p ON fn.ref_purchase_id = p.purchase_id
        JOIN harvest h ON p.harvest_id = h.harvest_id
        JOIN garden g ON h.garden_id = g.garden_id
        WHERE h.harvest_id = ? AND g.user_id = ?
      `, [harvestId, userId]);
      const result = await conn.query(
        `DELETE FROM harvest WHERE harvest_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)`,
        [harvestId, userId]
      );
      if (!result.affectedRows) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์ลบ' };
      }
      await conn.commit();
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      if (conn) await conn.rollback().catch(() => {});
      console.error('Error deleteHarvest:', error);
      return { isError: true, data: null, errorMessage: 'ลบรายการไม่สำเร็จ' };
    } finally {
      if (conn) conn.release();
    }
  }
};

module.exports = harvest;