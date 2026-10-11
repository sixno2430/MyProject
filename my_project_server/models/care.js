// ============================================================
// care.js — model การดูแลสวน (ตาราง palm_care)
//
// ดึง/เพิ่ม/แก้ไข/ลบ รายการดูแลสวน ทุกคำสั่งเช็กว่าแปลงเป็นของ user นั้นจริง
// action_type: fertilizer, pruning, weeding, watering, spraying, other
// ใส่ปุ๋ย 1 ครั้งใส่ได้หลายชนิด -> เก็บแต่ละชนิดในตาราง care_fertilizer (palm_care เก็บแค่ยอดสรุป)
// detail = รายละเอียดตามประเภท เช่น วิธีให้น้ำ / ชื่อสารที่พ่น / วิธีกำจัดวัชพืช / กิจกรรมอื่นที่ทำ
// ============================================================

const db = require('../libs/db_pool');

// ชื่อปุ๋ยทุกชนิดในรายการ คั่นด้วย comma (ใช้แสดงในรายการ/กิจกรรม/การเงิน) ไม่มีปุ๋ยในตารางใหม่ = ใช้ชื่อจากตาราง fertilizer แบบเดิม
const FERTILIZER_SUMMARY_SQL = `COALESCE(
  (SELECT GROUP_CONCAT(cf.fertilizer_name ORDER BY cf.line_no SEPARATOR ', ')
   FROM care_fertilizer cf WHERE cf.care_id = c.care_id),
  f.fertilizer_name)`;

/**
 * ตรวจและจัดรูปรายการปุ๋ยที่แอปส่งมา [{ fertilizer_name, quantity, unit }]
 * คืน { items } หรือ { error } — ต้องมีอย่างน้อย 1 ชนิด, ชื่อไม่ว่าง, ปริมาณมากกว่า 0
 */
function cleanFertilizerItems(raw) {
  if (!Array.isArray(raw) || raw.length === 0) return { error: 'กรุณาเพิ่มปุ๋ยอย่างน้อย 1 ชนิด' };
  const items = [];
  for (const it of raw) {
    const name = String(it.fertilizer_name || '').trim().slice(0, 100);
    const qty = parseFloat(it.quantity);
    if (!name) return { error: 'กรุณาระบุชื่อปุ๋ยให้ครบทุกรายการ' };
    if (!(qty > 0)) return { error: `กรุณาระบุปริมาณของ "${name}"` };
    items.push({ name, qty, unit: String(it.unit || 'กก.').trim().slice(0, 20) || 'กก.' });
  }
  return { items };
}

/**
 * บันทึกรายการปุ๋ยของ care_id นี้ใหม่ทั้งหมด (ลบของเดิมแล้วใส่ใหม่) ภายใน transaction ที่เปิดไว้
 * ชื่อที่ตรงกับตาราง fertilizer จะผูก fertilizer_id ให้ด้วย
 * คืนค่าสรุปไว้เก็บที่ palm_care: fertilizer_id ตัวแรก, ปริมาณรวม (เฉพาะกรณีทุกชนิดใช้หน่วยเดียวกัน), หน่วย
 */
async function saveFertilizerItems(conn, careId, items) {
  await conn.query(`DELETE FROM care_fertilizer WHERE care_id = ?`, [careId]);
  const known = await conn.query(`SELECT fertilizer_id, fertilizer_name FROM fertilizer`);
  let firstId = null;
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    const match = known.find((f) => f.fertilizer_name === it.name);
    if (match && !firstId) firstId = match.fertilizer_id;
    await conn.query(
      `INSERT INTO care_fertilizer (care_id, line_no, fertilizer_id, fertilizer_name, quantity, unit)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [careId, i + 1, match ? match.fertilizer_id : null, it.name, it.qty, it.unit]
    );
  }
  const sameUnit = items.every((it) => it.unit === items[0].unit);
  return {
    fertilizer_id: firstId,
    quantity: sameUnit ? items.reduce((s, it) => s + it.qty, 0) : 0,
    quantity_type: sameUnit ? items[0].unit : 'รายการ',
  };
}

/** ค่าที่จะเก็บใน palm_care จากข้อมูลที่แอปส่งมา (ไม่รวมปุ๋ย) */
function careFields(data) {
  return {
    action_type: data.action_type || 'other',
    quantity: parseFloat(data.quantity) || 0,
    quantity_type: data.quantity_type || null,
    detail: String(data.detail || '').trim().slice(0, 200) || null,
    cost: parseFloat(data.cost) || 0,
    note: data.note || '',
  };
}

const careModel = {
  // 1. ดึงข้อมูลรายการดูแลสวน (ส่ง userId มา = เฉพาะสวนของ user นั้น)
  //    fertilizer_name = ชื่อปุ๋ยทุกชนิดในรายการ, detail = รายละเอียดตามประเภท (วิธีให้น้ำ, สารที่พ่น ฯลฯ)
  getCareLogs: async (userId = null) => {
    try {
      const sql = `
        SELECT 
          c.care_id,
          c.garden_id,
          COALESCE(g.garden_name, 'ไม่ระบุแปลง') AS garden_name,
          c.fertilizer_id,
          ${FERTILIZER_SUMMARY_SQL} AS fertilizer_name,
          c.action_type,
          c.quantity,
          c.quantity_type,
          c.detail,
          c.cost,
          c.record_date,
          c.note
        FROM palm_care c
        LEFT JOIN garden g ON c.garden_id = g.garden_id
        LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id
        ${userId ? 'WHERE g.user_id = ?' : ''}
        ORDER BY c.record_date DESC
      `;
      const result = await db.query(sql, userId ? [userId] : []);
      let rows = (result && result.data !== undefined) ? result.data : (Array.isArray(result[0]) ? result[0] : result);
      return { isError: false, data: rows || [], errorMessage: "" };
    } catch (error) {
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // 1.1 รายการเดียวพร้อมปุ๋ยทุกชนิด (ใช้ตอนเปิดฟอร์มแก้ไข)
  //     รายการเก่าก่อนมีตาราง care_fertilizer: แปลงปุ๋ยตัวเดิมเป็นรายการปุ๋ย 1 ชนิดให้
  getCareLog: async (careId, userId) => {
    try {
      const rows = await db.query(
        `SELECT c.care_id, c.garden_id, c.fertilizer_id, f.fertilizer_name, c.action_type, c.quantity,
                c.quantity_type, c.detail, c.cost, DATE_FORMAT(c.record_date, '%Y-%m-%d') AS record_date, c.note
         FROM palm_care c
         JOIN garden g ON c.garden_id = g.garden_id
         LEFT JOIN fertilizer f ON c.fertilizer_id = f.fertilizer_id
         WHERE c.care_id = ? AND g.user_id = ?`,
        [careId, userId]
      );
      if (rows.length === 0) return { isError: true, data: null, errorMessage: 'ไม่พบรายการนี้' };
      const care = rows[0];
      let items = await db.query(
        `SELECT fertilizer_name, quantity, unit FROM care_fertilizer WHERE care_id = ? ORDER BY line_no`,
        [careId]
      );
      if (items.length === 0 && care.fertilizer_name) {
        items = [{ fertilizer_name: care.fertilizer_name, quantity: care.quantity, unit: care.quantity_type || 'กก.' }];
      }
      care.fertilizer_items = items;
      return { isError: false, data: care, errorMessage: "" };
    } catch (error) {
      console.error('Error in getCareLog:', error.message);
      return { isError: true, data: null, errorMessage: 'โหลดรายการไม่สำเร็จ' };
    }
  },

  // 2. บันทึกข้อมูลรายการใหม่
  //    - เช็กก่อนว่าแปลงที่เลือกเป็นของ user คนนี้จริง
  //    - สร้าง care_id ที่ฝั่งเซิร์ฟเวอร์ (ต่อจากเลขล่าสุด) ไม่ใช้ค่าที่แอปส่งมา กันรหัสชนกัน
  //    - ใส่ปุ๋ย: บันทึกปุ๋ยทุกชนิด (fertilizer_items) ใน transaction เดียวกับ palm_care
  createCareLog: async (careData) => {
    let conn;
    try {
      const { user_id, garden_id, record_date } = careData;
      const fields = careFields(careData);
      const isFertilizer = fields.action_type === 'fertilizer';
      let items = [];
      if (isFertilizer) {
        const checked = cleanFertilizerItems(careData.fertilizer_items);
        if (checked.error) return { isError: true, data: null, errorMessage: checked.error };
        items = checked.items;
      }

      const owned = await db.query(
        `SELECT garden_id FROM garden WHERE garden_id = ? AND user_id = ?`,
        [garden_id, user_id]
      );
      if (owned.length === 0) {
        return { isError: true, data: null, errorMessage: 'ไม่พบแปลงสวนนี้ในบัญชีของคุณ' };
      }

      conn = await db.getConnection();
      await conn.beginTransaction();
      const maxRows = await conn.query(`
        SELECT MAX(CAST(SUBSTRING(care_id, 2) AS UNSIGNED)) AS max_num
        FROM palm_care WHERE care_id LIKE 'C%'
      `);
      const maxNum = maxRows[0].max_num !== null ? Number(maxRows[0].max_num) : 0;
      const care_id = 'C' + String(maxNum + 1).padStart(3, '0');

      await conn.query(
        `INSERT INTO palm_care (care_id, garden_id, fertilizer_id, action_type, quantity, quantity_type, detail, cost, record_date, note)
         VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?)`,
        [care_id, garden_id, fields.action_type, fields.quantity, fields.quantity_type, fields.detail,
          fields.cost, record_date, fields.note]
      );
      if (isFertilizer) {
        const sum = await saveFertilizerItems(conn, care_id, items);
        await conn.query(
          `UPDATE palm_care SET fertilizer_id = ?, quantity = ?, quantity_type = ? WHERE care_id = ?`,
          [sum.fertilizer_id, sum.quantity, sum.quantity_type, care_id]
        );
      }
      await conn.commit();
      return { isError: false, data: { care_id }, errorMessage: "" };
    } catch (error) {
      if (conn) await conn.rollback().catch(() => {});
      console.error('Error in createCareLog:', error.message);
      return { isError: true, data: null, errorMessage: 'บันทึกรายการไม่สำเร็จ' };
    } finally {
      if (conn) conn.release();
    }
  },

  // 3. แก้ไขรายการ (แก้ได้เฉพาะรายการในสวนของ userId เท่านั้น)
  //    เปลี่ยนจากใส่ปุ๋ยเป็นกิจกรรมอื่น -> ลบรายการปุ๋ยเดิมทิ้ง
  updateCareLog: async (careId, userId, careData) => {
    let conn;
    try {
      const { garden_id, record_date } = careData;
      const fields = careFields(careData);
      const isFertilizer = fields.action_type === 'fertilizer';
      let items = [];
      if (isFertilizer) {
        const checked = cleanFertilizerItems(careData.fertilizer_items);
        if (checked.error) return { isError: true, data: null, errorMessage: checked.error };
        items = checked.items;
      }

      conn = await db.getConnection();
      await conn.beginTransaction();
      const result = await conn.query(
        `UPDATE palm_care
         SET garden_id = ?, fertilizer_id = NULL, action_type = ?, quantity = ?, quantity_type = ?, detail = ?,
             cost = ?, record_date = ?, note = ?
         WHERE care_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)
           AND ? IN (SELECT garden_id FROM garden WHERE user_id = ?)`,
        [garden_id, fields.action_type, fields.quantity, fields.quantity_type, fields.detail,
          fields.cost, record_date, fields.note, careId, userId, garden_id, userId]
      );
      if (!result.affectedRows) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์แก้ไข' };
      }
      if (isFertilizer) {
        const sum = await saveFertilizerItems(conn, careId, items);
        await conn.query(
          `UPDATE palm_care SET fertilizer_id = ?, quantity = ?, quantity_type = ? WHERE care_id = ?`,
          [sum.fertilizer_id, sum.quantity, sum.quantity_type, careId]
        );
      } else {
        await conn.query(`DELETE FROM care_fertilizer WHERE care_id = ?`, [careId]);
      }
      await conn.commit();
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      if (conn) await conn.rollback().catch(() => {});
      console.error('Error in updateCareLog:', error.message);
      return { isError: true, data: null, errorMessage: 'แก้ไขรายการไม่สำเร็จ' };
    } finally {
      if (conn) conn.release();
    }
  },

  // 4. ลบรายการ (ลบได้เฉพาะรายการในสวนของ userId เท่านั้น)
  //    ลบรายการเงินที่ผูกกับรายการนี้ (ref_care_id) ด้วย ไม่งั้นจะโผล่เป็น "รายการที่บันทึกเอง"
  deleteCareLog: async (careId, userId) => {
    let conn;
    try {
      conn = await db.getConnection();
      await conn.beginTransaction();
      await conn.query(`
        DELETE fn FROM finance fn
        JOIN palm_care c ON fn.ref_care_id = c.care_id
        JOIN garden g ON c.garden_id = g.garden_id
        WHERE c.care_id = ? AND g.user_id = ?
      `, [careId, userId]);
      const result = await conn.query(
        `DELETE FROM palm_care WHERE care_id = ? AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)`,
        [careId, userId]
      );
      if (!result.affectedRows) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์ลบ' };
      }
      await conn.commit();
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      if (conn) await conn.rollback().catch(() => {});
      console.error('Error in deleteCareLog:', error.message);
      return { isError: true, data: null, errorMessage: 'ลบรายการไม่สำเร็จ' };
    } finally {
      if (conn) conn.release();
    }
  }
};

module.exports = careModel;