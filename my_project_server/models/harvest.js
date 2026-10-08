// ============================================================
// harvest.js — model การเก็บเกี่ยว (ตาราง harvest)
//
// status: 'sold' = ขายแล้ว, 'pending' = รอขาย (รายได้นับเฉพาะ sold)
//
// กติกาการขาย (แบบผสม):
//   - รอขาย: เกษตรกรเลือกร้านในแอปที่จะขายให้ได้ (shop_id ไม่บังคับ)
//       เลือกร้านแล้ว -> ร้านนั้นคนเดียวที่กดยืนยันรับซื้อได้ (models/shop.js createPurchase)
//       ยังไม่เลือก   -> ร้านไหนก็ค้นหาแล้วรับซื้อได้
//   - ขายแล้ว ผ่านร้านในแอป: มีแถวใน purchase คู่กันเสมอ เกษตรกรแก้/ลบเองไม่ได้
//   - ขายนอกระบบ: เกษตรกรบันทึกเอง (เฉพาะล็อตที่ไม่ได้เลือกร้านในแอป)
//       shop_id = NULL, buyer_name = ชื่อร้านที่พิมพ์เอง (ไม่บังคับ), sold_date = วันที่ขาย,
//       quality_grade = เกรดที่ขาย (ไม่บังคับ) — ขายผ่านร้านในแอปใช้เกรดที่ร้านเลือกใน purchase แทน
//   เกษตรกรสร้างแถวใน purchase เองไม่ได้ ร้านเท่านั้นที่บันทึกการรับซื้อ
// ทุกคำสั่งแก้ไข/ลบ เช็กว่าแปลงเป็นของ user นั้นจริง
// ============================================================

const db = require('../libs/db_pool');

/** วันนี้ตามเวลาเครื่อง (yyyy-mm-dd) */
const today = () => new Date().toLocaleDateString('sv-SE');

/**
 * ตรวจวันที่ขาย: ต้องไม่ก่อนวันเก็บเกี่ยว และไม่เกินวันนี้ (รูปแบบ yyyy-mm-dd เทียบเป็นข้อความได้เลย)
 * คืนข้อความ error หรือ null
 */
function soldDateError(soldDate, harvestDate) {
  const sold = String(soldDate || '').slice(0, 10);
  const harvested = String(harvestDate || '').slice(0, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(sold)) return 'วันที่ขายไม่ถูกต้อง';
  if (harvested && sold < harvested) return 'วันที่ขายต้องไม่ก่อนวันเก็บเกี่ยว';
  if (sold > today()) return 'วันที่ขายต้องไม่เกินวันนี้';
  return null;
}

/** เกรดจากฟอร์ม: ตัดช่องว่าง ไม่เกิน 100 ตัว (ตามคอลัมน์) ว่าง = NULL */
const cleanGrade = (v) => String(v || '').trim().slice(0, 100) || null;

/** หมายเหตุจากฟอร์ม: ตัดช่องว่าง จำกัด 500 ตัวอักษร (ตามขนาดคอลัมน์) ว่าง = NULL */
const cleanNote = (v) => String(v || '').trim().slice(0, 500) || null;

const PURCHASED_MSG = 'ร้านรับซื้อบันทึกการรับซื้อรายการนี้แล้ว แก้ไขหรือลบไม่ได้ หากผิดพลาดให้ร้านยกเลิกการรับซื้อ';

/**
 * แปลงข้อมูลการขายจากฟอร์มให้ตรงกติกา
 *   รอขาย      -> shop_id = ร้านในแอปที่จะขายให้ (ไม่บังคับ) ไม่มีชื่อร้าน/วันที่ขาย
 *   ขายนอกระบบ -> shop_id = NULL, buyer_name (ไม่บังคับ), sold_date, ราคาต้องมากกว่า 0
 * คืน { error } หรือ { fields }
 */
async function saleFields(data) {
  if (data.status !== 'sold') {
    const shopId = data.shop_id || null;
    if (shopId) {
      const found = await db.query(`SELECT shop_id FROM shop WHERE shop_id = ?`, [shopId]);
      if (found.length === 0) return { error: 'ไม่พบร้านรับซื้อที่เลือก' };
    }
    return { fields: { status: 'pending', shop_id: shopId, buyer_name: null, sold_date: null, quality_grade: null } };
  }
  if (!(parseFloat(data.price_per_kg) > 0)) return { error: 'กรุณาใส่ราคาขายต่อกิโลกรัม' };
  const dateError = soldDateError(data.sold_date || today(), data.harvest_date);
  if (dateError) return { error: dateError };
  return {
    fields: {
      status: 'sold',
      shop_id: null,
      buyer_name: String(data.buyer_name || '').trim().slice(0, 100) || null,
      quality_grade: cleanGrade(data.quality_grade),
      sold_date: data.sold_date || today(),
    },
  };
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
          -- ข้อความผู้ซื้อที่แสดงบนการ์ด
          CASE
            WHEN p.purchase_id IS NOT NULL THEN s.shop_name
            WHEN COALESCE(h.status, 'sold') = 'sold'
              THEN CONCAT(COALESCE(NULLIF(h.buyer_name, ''), 'ร้าน'), ' (นอกระบบ)')
            WHEN s.shop_name IS NOT NULL THEN CONCAT('รอ ', s.shop_name, ' รับซื้อ')
            ELSE 'ยังไม่เลือกร้าน'
          END AS buyer,
          h.buyer_name AS buyerName,
          h.note,
          -- เกรด: ขายผ่านร้านในแอป = เกรดที่ร้านเลือก, ขายนอกระบบ = เกรดที่เกษตรกรใส่เอง
          COALESCE(p.quality_grade, h.quality_grade) AS grade,
          (p.purchase_id IS NOT NULL) AS purchasedByShop, -- 1 = ร้านในแอปรับซื้อแล้ว (ล็อกการแก้ไข)
          CAST(h.total_quantity AS DOUBLE) AS quantityKg,
          CAST(h.price_per_kg AS DOUBLE) AS pricePerKg,
          CAST(h.total_price AS DOUBLE) AS totalPrice,
          DATE_FORMAT(h.harvest_date, '%Y-%m-%d') AS date,
          DATE_FORMAT(COALESCE(p.purchase_date, h.sold_date), '%Y-%m-%d') AS soldDate, -- วันที่ขาย (null = ยังไม่ขาย)
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

  // 3. สร้างบันทึกการเก็บเกี่ยวใหม่ (รอขาย หรือขายนอกระบบไปแล้ว)
  createHarvest: async (data) => {
    try {
      const { user_id, garden_id, harvest_date, total_quantity, price_per_kg, total_price } = data;
      const sale = await saleFields({ ...data, sold_date: data.sold_date || harvest_date });
      if (sale.error) return { isError: true, data: null, errorMessage: sale.error };
      const f = sale.fields;

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

      await db.query(`
        INSERT INTO harvest
        (harvest_id, garden_id, shop_id, buyer_name, quality_grade, harvest_date, total_quantity, price_per_kg, total_price, status, sold_date, note)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        newHarvestId, garden_id || null, f.shop_id, f.buyer_name, f.quality_grade, harvest_date,
        total_quantity || 0, price_per_kg || 0, total_price || 0, f.status, f.sold_date, cleanNote(data.note),
      ]);

      return { isError: false, data: { harvest_id: newHarvestId }, errorMessage: "" };
    } catch (error) {
      console.error('Error createHarvest:', error);
      return { isError: true, data: null, errorMessage: 'บันทึกการเก็บเกี่ยวไม่สำเร็จ' };
    }
  },

  // 4. แก้ไขบันทึกการเก็บเกี่ยว (เฉพาะสวนของ userId และร้านยังไม่ได้รับซื้อ)
  //    เปลี่ยนร้านที่จะขายให้ / ย้อนรายการขายนอกระบบกลับเป็นรอขาย ทำได้ที่นี่
  updateHarvest: async (harvestId, userId, data) => {
    try {
      const { garden_id, harvest_date, total_quantity, price_per_kg, total_price } = data;
      if (await harvest.isPurchasedByShop(harvestId)) {
        return { isError: true, data: null, errorMessage: PURCHASED_MSG };
      }
      const sale = await saleFields({ ...data, sold_date: data.sold_date || harvest_date });
      if (sale.error) return { isError: true, data: null, errorMessage: sale.error };
      const f = sale.fields;

      // NOT IN purchase อยู่ใน WHERE ด้วย กันกรณีร้านกดรับซื้อพอดีระหว่างที่เกษตรกรกำลังแก้
      const result = await db.query(`
        UPDATE harvest
        SET garden_id = ?, shop_id = ?, buyer_name = ?, quality_grade = ?, harvest_date = ?, total_quantity = ?,
            price_per_kg = ?, total_price = ?, status = ?, sold_date = ?, note = ?
        WHERE harvest_id = ?
          AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)
          AND ? IN (SELECT garden_id FROM garden WHERE user_id = ?)
          AND harvest_id NOT IN (SELECT harvest_id FROM purchase)
      `, [
        garden_id, f.shop_id, f.buyer_name, f.quality_grade, harvest_date, total_quantity || 0,
        price_per_kg || 0, total_price || 0, f.status, f.sold_date, cleanNote(data.note),
        harvestId, userId, garden_id, userId,
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

  // 4.1 เกษตรกรบันทึก "ขายนอกระบบ" จากรายการรอขาย
  //     ทำได้เฉพาะล็อตที่ไม่ได้เลือกร้านในแอปไว้ (เลือกไว้แล้ว = รอร้านนั้นยืนยันรับซื้อ)
  //     ราคารวมคำนวณจากน้ำหนักในฐานข้อมูล (total_quantity × ราคา) กันตัวเลขไม่ตรงกัน
  sellHarvest: async (harvestId, userId, pricePerKg, buyerName = null, soldDate = null, grade = null) => {
    try {
      const price = parseFloat(pricePerKg);
      if (!(price > 0)) {
        return { isError: true, data: null, errorMessage: 'กรุณาใส่ราคาขายต่อกิโลกรัม' };
      }
      const date = soldDate || today();
      const found = await db.query(`
        SELECT DATE_FORMAT(h.harvest_date, '%Y-%m-%d') AS d FROM harvest h
        JOIN garden g ON h.garden_id = g.garden_id
        WHERE h.harvest_id = ? AND g.user_id = ?
      `, [harvestId, userId]);
      const dateError = found.length ? soldDateError(date, found[0].d) : null;
      if (dateError) return { isError: true, data: null, errorMessage: dateError };

      const result = await db.query(`
        UPDATE harvest
        SET status = 'sold', price_per_kg = ?, total_price = total_quantity * ?,
            buyer_name = ?, sold_date = ?, quality_grade = ?
        WHERE harvest_id = ? AND status = 'pending' AND shop_id IS NULL
          AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)
      `, [price, price, String(buyerName || '').trim().slice(0, 100) || null, date, cleanGrade(grade), harvestId, userId]);
      if (!result.affectedRows) {
        // บอกเหตุผลให้ชัด: รอร้านในแอปอยู่ / ขายไปแล้ว / ไม่ใช่ของเรา
        const rows = await db.query(`
          SELECT h.status, s.shop_name FROM harvest h
          JOIN garden g ON h.garden_id = g.garden_id
          LEFT JOIN shop s ON h.shop_id = s.shop_id
          WHERE h.harvest_id = ? AND g.user_id = ?
        `, [harvestId, userId]);
        let msg = 'ไม่พบรายการ หรือไม่มีสิทธิ์แก้ไข';
        if (rows.length && rows[0].status !== 'pending') msg = 'รายการนี้ขายไปแล้ว';
        else if (rows.length && rows[0].shop_name) {
          msg = `ล็อตนี้รอ ${rows[0].shop_name} รับซื้ออยู่ ถ้าจะขายนอกระบบ ให้แก้ไขรายการเป็น "ยังไม่เลือกร้าน" ก่อน`;
        }
        return { isError: true, data: null, errorMessage: msg };
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
        return { isError: true, data: null, errorMessage: PURCHASED_MSG };
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