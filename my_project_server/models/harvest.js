// ============================================================
// harvest.js — model การเก็บเกี่ยว (ตาราง harvest)
//
// status: 'sold' = ขายแล้ว, 'pending' = รอขาย (รายได้นับเฉพาะ sold)
//
// กติกาการขาย (ให้ข้อมูลเกษตรกรกับร้านตรงกันเสมอ):
//   - ขายให้ร้านในระบบ: ร้านบันทึกรับซื้อเอง หรือเกษตรกรกดขายแล้วโดยเลือกร้าน
//     ทั้งสองทางสร้างแถวใน purchase ด้วย (shop.recordSaleTx) ร้านจึงเห็นในประวัติ/รายงานของร้าน
//   - ขายร้านนอกระบบ: เกษตรกรกดขายแล้วโดยไม่เลือกร้าน (shop_id = NULL ไม่มี purchase)
//   ดังนั้น shop_id ที่มีค่า = มีแถวใน purchase คู่กันเสมอ
// ทุกคำสั่งแก้ไข/ลบ เช็กว่าแปลงเป็นของ user นั้นจริง
// ============================================================

const db = require('../libs/db_pool');
const shop = require('./shop');

/** วันนี้ตามเวลาเครื่อง (yyyy-mm-dd) */
const today = () => new Date().toLocaleDateString('sv-SE');

/**
 * เกษตรกรขายให้ร้านในระบบ (ต้องเรียกใน transaction conn)
 * ตรวจร้านมีจริง + ล็อกผลผลิตที่ยังรอขายของ userId แล้วบันทึก purchase ผ่าน shop.recordSaleTx
 * quantity ไม่ส่งมา = ใช้น้ำหนักที่บันทึกไว้ในผลผลิต
 * คืนข้อความ error (ภาษาไทย) หรือ null ถ้าสำเร็จ
 */
async function sellToShopTx(conn, { harvestId, userId, shopId, price, quantity, date }) {
  const shops = await conn.query(`SELECT shop_id FROM shop WHERE shop_id = ?`, [shopId]);
  if (shops.length === 0) return 'ไม่พบร้านรับซื้อที่เลือก';
  const found = await conn.query(`
    SELECT h.status, CAST(h.total_quantity AS DOUBLE) AS qty
    FROM harvest h JOIN garden g ON h.garden_id = g.garden_id
    WHERE h.harvest_id = ? AND g.user_id = ? FOR UPDATE
  `, [harvestId, userId]);
  if (found.length === 0) return 'ไม่พบรายการ หรือไม่มีสิทธิ์แก้ไข';
  if (found[0].status !== 'pending') return 'รายการนี้ขายไปแล้ว';
  const qty = parseFloat(quantity ?? found[0].qty);
  if (!(qty > 0)) return 'กรุณาใส่น้ำหนักผลผลิตก่อนบันทึกการขาย';
  await shop.recordSaleTx(conn, {
    harvest_id: harvestId, shop_id: shopId, farmer_id: userId,
    purchase_date: date || today(), quantity: qty, price_per_kg: price,
  });
  return null;
}

const harvest = {

  // ผลผลิตที่ร้านรับซื้อบันทึกแล้ว (มีแถวใน purchase) ห้ามเกษตรกรแก้/ลบเอง
  // ไม่งั้นข้อมูลร้านกับเกษตรกรไม่ตรงกัน หรือประวัติรับซื้อของร้านหาย (purchase ถูกลบตาม CASCADE)
  isPurchasedByShop: async (harvestId) => {
    const rows = await db.query(`SELECT purchase_id FROM purchase WHERE harvest_id = ? LIMIT 1`, [harvestId]);
    return rows.length > 0;
  },
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
          CASE
            WHEN s.shop_name IS NOT NULL THEN s.shop_name
            WHEN COALESCE(h.status, 'sold') = 'pending' THEN 'รอร้านรับซื้อ'
            ELSE 'ขายร้านนอกระบบ'
          END AS buyer,
          CAST(h.total_quantity AS DOUBLE) AS quantityKg,
          CAST(h.price_per_kg AS DOUBLE) AS pricePerKg,
          CAST(h.total_price AS DOUBLE) AS totalPrice,
          DATE_FORMAT(h.harvest_date, '%Y-%m-%d') AS date,
          DATE_FORMAT(p.purchase_date, '%Y-%m-%d') AS soldDate, -- วันที่ร้านรับซื้อ (null = ยังไม่ขาย/ขายนอกระบบ)
          COALESCE(h.status, 'sold') AS status
        FROM harvest h
        LEFT JOIN garden g ON h.garden_id = g.garden_id
        LEFT JOIN shop s ON h.shop_id = s.shop_id
        LEFT JOIN purchase p ON p.harvest_id = h.harvest_id
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
      // ขายแล้ว + เลือกร้านในระบบ -> บันทึกเป็นรอขายก่อน แล้วขายให้ร้านใน transaction เดียวกัน
      const toShop = status === 'sold' && shop_id;
      if (toShop && !(parseFloat(price_per_kg) > 0)) {
        return { isError: true, data: null, errorMessage: 'กรุณาใส่ราคาขายต่อกิโลกรัม' };
      }

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
        null, // shop_id ใส่ผ่าน sellToShopTx เท่านั้น (คู่กับแถวใน purchase)
        harvest_date,
        total_quantity || 0,
        price_per_kg || 0,
        total_price || 0,
        status === 'sold' && !toShop ? 'sold' : 'pending' // ค่าเริ่มต้น = รอขาย
      ];

      if (!toShop) {
        await db.query(query, params);
        return { isError: false, data: { harvest_id: newHarvestId }, errorMessage: "" };
      }

      let conn;
      try {
        conn = await db.getConnection();
        await conn.beginTransaction();
        await conn.query(query, params);
        const err = await sellToShopTx(conn, {
          harvestId: newHarvestId, userId: user_id, shopId: shop_id,
          price: parseFloat(price_per_kg), quantity: total_quantity, date: harvest_date,
        });
        if (err) {
          await conn.rollback();
          return { isError: true, data: null, errorMessage: err };
        }
        await conn.commit();
        return { isError: false, data: { harvest_id: newHarvestId }, errorMessage: "" };
      } catch (e) {
        if (conn) await conn.rollback().catch(() => {});
        throw e;
      } finally {
        if (conn) conn.release();
      }
    } catch (error) {
      console.error('Error createHarvest:', error);
      return { isError: true, data: null, errorMessage: 'บันทึกการเก็บเกี่ยวไม่สำเร็จ' };
    }
  },

  // 4. แก้ไขบันทึกการเก็บเกี่ยว (เฉพาะสวนของ userId)
  updateHarvest: async (harvestId, userId, data) => {
    let conn;
    try {
      const { garden_id, shop_id, harvest_date, total_quantity, price_per_kg, total_price, status } = data;
      if (await harvest.isPurchasedByShop(harvestId)) {
        return { isError: true, data: null, errorMessage: 'ร้านรับซื้อบันทึกการรับซื้อรายการนี้แล้ว แก้ไขหรือลบไม่ได้ หากผิดพลาดให้ร้านยกเลิกการรับซื้อ' };
      }
      // ขายแล้ว + เลือกร้านในระบบ -> แก้ข้อมูลเป็นรอขายก่อน แล้วขายให้ร้านใน transaction เดียวกัน
      const toShop = status === 'sold' && shop_id;
      if (toShop && !(parseFloat(price_per_kg) > 0)) {
        return { isError: true, data: null, errorMessage: 'กรุณาใส่ราคาขายต่อกิโลกรัม' };
      }
      conn = await db.getConnection();
      await conn.beginTransaction();
      const query = `
        UPDATE harvest
        SET garden_id = ?, shop_id = NULL, harvest_date = ?, total_quantity = ?, price_per_kg = ?, total_price = ?, status = ?
        WHERE harvest_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?) AND ? IN (SELECT garden_id FROM garden WHERE user_id = ?)
      `;
      const result = await conn.query(query, [
        garden_id, harvest_date, total_quantity || 0, price_per_kg || 0, total_price || 0,
        status === 'sold' && !toShop ? 'sold' : 'pending',
        harvestId, userId, garden_id, userId
      ]);
      if (!result.affectedRows) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์แก้ไข' };
      }
      if (toShop) {
        const err = await sellToShopTx(conn, {
          harvestId, userId, shopId: shop_id,
          price: parseFloat(price_per_kg), quantity: total_quantity, date: harvest_date,
        });
        if (err) {
          await conn.rollback();
          return { isError: true, data: null, errorMessage: err };
        }
      }
      await conn.commit();
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      if (conn) await conn.rollback().catch(() => {});
      console.error('Error updateHarvest:', error);
      return { isError: true, data: null, errorMessage: 'แก้ไขรายการไม่สำเร็จ' };
    } finally {
      if (conn) conn.release();
    }
  },

  // 4.1 เกษตรกรทำเครื่องหมายว่า "ขายแล้ว" (เฉพาะรายการที่ยังรอขาย)
  //     shopId = ร้านในระบบ -> บันทึก purchase ให้ร้านด้วย (ร้านเห็นในประวัติรับซื้อ) วันที่ขาย = วันนี้
  //     ไม่ส่ง shopId = ขายร้านนอกระบบ ไม่ผูกร้าน
  //     ราคารวมคำนวณจากน้ำหนักในฐานข้อมูล (total_quantity × ราคา) กันตัวเลขไม่ตรงกัน
  sellHarvest: async (harvestId, userId, pricePerKg, shopId = null) => {
    try {
      const price = parseFloat(pricePerKg);
      if (!(price > 0)) {
        return { isError: true, data: null, errorMessage: 'กรุณาใส่ราคาขายต่อกิโลกรัม' };
      }
      if (shopId) {
        let conn;
        try {
          conn = await db.getConnection();
          await conn.beginTransaction();
          const err = await sellToShopTx(conn, { harvestId, userId, shopId, price });
          if (err) {
            await conn.rollback();
            return { isError: true, data: null, errorMessage: err };
          }
          await conn.commit();
          return { isError: false, data: null, errorMessage: "" };
        } catch (e) {
          if (conn) await conn.rollback().catch(() => {});
          throw e;
        } finally {
          if (conn) conn.release();
        }
      }
      const result = await db.query(`
        UPDATE harvest
        SET status = 'sold', price_per_kg = ?, total_price = total_quantity * ?, shop_id = NULL
        WHERE harvest_id = ? AND status = 'pending'
          AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)
      `, [price, price, harvestId, userId]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการที่รอขาย หรือรายการนี้ขายไปแล้ว' };
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
      if (await harvest.isPurchasedByShop(harvestId)) {
        return { isError: true, data: null, errorMessage: 'ร้านรับซื้อบันทึกการรับซื้อรายการนี้แล้ว แก้ไขหรือลบไม่ได้ หากผิดพลาดให้ร้านยกเลิกการรับซื้อ' };
      }
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