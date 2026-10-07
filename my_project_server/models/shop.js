// ============================================================
// shop.js — model ร้านรับซื้อ (ตาราง shop + price_rate + purchase)
// ============================================================

const db = require('../libs/db_pool');

const shop = {
  // ------------------------------------------------------------
  // ส่วนเดิมของฝั่งเกษตรกร: ดึงร้านรับซื้อทั้งหมด + ราคาล่าสุด
  // ------------------------------------------------------------
  getShops: async (userId = null) => {
    try {
      const shops = await db.query(`
        SELECT s.shop_id, s.shop_name, s.location, s.phone, s.status, s.open_schedule,
               COUNT(p.purchase_id) AS sold_count,
               COALESCE(SUM(p.quantity), 0) AS sold_kg,
               COALESCE(SUM(p.total_price), 0) AS sold_total,
               MAX(p.purchase_date) AS last_sold_date
        FROM shop s
        LEFT JOIN purchase p ON p.shop_id = s.shop_id AND p.user_id = ?
        GROUP BY s.shop_id, s.shop_name, s.location, s.phone, s.status, s.open_schedule
        ORDER BY s.shop_name
      `, [userId]);

      const rates = await db.query(`
        SELECT r.shop_id, r.quality_grade, r.price_per_kg,
               DATE_FORMAT(r.effective_date, '%Y-%m-%d') AS effective_date,
               DATE_FORMAT(r.end_date, '%Y-%m-%d') AS end_date,
               (r.end_date IS NULL OR r.end_date >= CURDATE()) AS is_current
        FROM price_rate r
        JOIN (
          SELECT shop_id, quality_grade, MAX(effective_date) AS latest
          FROM price_rate
          WHERE effective_date <= CURDATE()
          GROUP BY shop_id, quality_grade
        ) last ON last.shop_id = r.shop_id
              AND last.quality_grade = r.quality_grade
              AND last.latest = r.effective_date
        ORDER BY r.price_per_kg DESC
      `);

      const data = shops.map(s => ({
        shop_id: s.shop_id,
        shop_name: s.shop_name,
        location: s.location,
        phone: s.phone,
        status: s.status,
        open_schedule: s.open_schedule,
        sold_count: Number(s.sold_count),
        sold_kg: parseFloat(s.sold_kg),
        sold_total: parseFloat(s.sold_total),
        last_sold_date: s.last_sold_date,
        rates: rates
          .filter(r => r.shop_id === s.shop_id)
          .map(r => ({
            quality_grade: r.quality_grade,
            price_per_kg: parseFloat(r.price_per_kg),
            effective_date: r.effective_date,
            end_date: r.end_date,
            is_current: Boolean(Number(r.is_current)),
          })),
      }));

      return { isError: false, data, errorMessage: "" };
    } catch (error) {
      console.error('Error getShops:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดข้อมูลร้านรับซื้อไม่สำเร็จ' };
    }
  },

  // ------------------------------------------------------------
  // ฟังก์ชันฝั่งร้านรับซื้อ: ภาพ 4.3.2 ข้อมูลร้านของฉัน
  // ------------------------------------------------------------
  getShopByUserId: async (userId) => {
    try {
      const rows = await db.query(`SELECT * FROM shop WHERE user_id = ?`, [userId]);
      if (!rows || rows.length === 0) {
        return { isError: true, data: null, errorMessage: 'ไม่พบข้อมูลร้านค้านี้' };
      }
      return { isError: false, data: rows[0], errorMessage: '' };
    } catch (error) {
      console.error('Error getShopByUserId:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  /**
   * สร้างร้านให้บัญชีร้านรับซื้อที่ยังไม่มีร้าน (1 บัญชี = 1 ร้าน)
   * สร้าง shop_id ต่อจากเลขล่าสุด เช่น S001 -> S002
   */
  createShop: async ({ user_id, shop_name, location, phone, open_schedule }) => {
    try {
      if (!shop_name || !shop_name.trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อร้าน' };
      }
      const users = await db.query(`SELECT role_id FROM user WHERE user_id = ?`, [user_id]);
      if (users.length === 0 || users[0].role_id !== 'R003') {
        return { isError: true, data: null, errorMessage: 'บัญชีนี้ไม่ใช่บัญชีร้านรับซื้อ' };
      }
      const existing = await db.query(`SELECT shop_id FROM shop WHERE user_id = ?`, [user_id]);
      if (existing.length > 0) {
        return { isError: true, data: null, errorMessage: 'บัญชีนี้มีร้านอยู่แล้ว' };
      }
      const maxRows = await db.query(
        `SELECT MAX(CAST(SUBSTRING(shop_id, 2) AS UNSIGNED)) AS max_num FROM shop WHERE shop_id LIKE 'S%'`
      );
      const shopId = 'S' + String(Number(maxRows[0].max_num || 0) + 1).padStart(3, '0');
      await db.query(`
        INSERT INTO shop (shop_id, user_id, shop_name, location, phone, status, open_schedule)
        VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?)
      `, [shopId, user_id, shop_name.trim(), location || null, phone || null, open_schedule || null]);
      return { isError: false, data: { shop_id: shopId }, errorMessage: '' };
    } catch (error) {
      console.error('Error createShop:', error.message);
      return { isError: true, data: null, errorMessage: 'สร้างร้านไม่สำเร็จ' };
    }
  },

  /** แก้ไขข้อมูลร้าน / เปิด-ปิดร้าน (แก้ได้เฉพาะร้านของ user_id ที่ส่งมา) */
  updateShopProfile: async (shopId, { user_id, shop_name, location, phone, status, open_schedule }) => {
    try {
      if (!shop_name || !shop_name.trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อร้าน' };
      }
      const result = await db.query(`
        UPDATE shop 
        SET shop_name = ?, location = ?, phone = ?, status = ?, open_schedule = ?
        WHERE shop_id = ? AND user_id = ?
      `, [shop_name.trim(), location || null, phone || null,
          status === 'INACTIVE' ? 'INACTIVE' : 'ACTIVE', open_schedule || null, shopId, user_id]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบร้าน หรือไม่มีสิทธิ์แก้ไข' };
      }
      return { isError: false, data: null, errorMessage: '' };
    } catch (error) {
      console.error('Error updateShopProfile:', error.message);
      return { isError: true, data: null, errorMessage: 'บันทึกข้อมูลร้านไม่สำเร็จ' };
    }
  },

  // ------------------------------------------------------------
  // ฟังก์ชันฝั่งร้านรับซื้อ: ภาพ 4.3.3 กำหนดราคารับซื้อ (Price Rate)
  // ------------------------------------------------------------
  getPriceRates: async (shopId) => {
    try {
      const rows = await db.query(`
        SELECT price_rate_id, shop_id, quality_grade, price_per_kg,
               DATE_FORMAT(effective_date, '%Y-%m-%d') AS effective_date,
               DATE_FORMAT(end_date, '%Y-%m-%d') AS end_date
        FROM price_rate
        WHERE shop_id = ?
        ORDER BY effective_date DESC
      `, [shopId]);
      return { isError: false, data: rows, errorMessage: '' };
    } catch (error) {
      console.error('Error getPriceRates:', error.message);
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  /**
   * เพิ่ม/แก้ไขราคารับซื้อ 1 เกรด (ทำได้เฉพาะร้านของ user_id ที่ส่งมา)
   * ไม่ส่ง price_rate_id = เพิ่มใหม่ (สร้างรหัสต่อจากเลขล่าสุด เช่น PR001 -> PR002)
   */
  savePriceRate: async ({ user_id, price_rate_id, shop_id, quality_grade, price_per_kg, effective_date, end_date }) => {
    try {
      const owned = await db.query(`SELECT shop_id FROM shop WHERE shop_id = ? AND user_id = ?`, [shop_id, user_id]);
      if (owned.length === 0) {
        return { isError: true, data: null, errorMessage: 'ไม่พบร้าน หรือไม่มีสิทธิ์แก้ไขราคา' };
      }
      if (!quality_grade || !String(quality_grade).trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกเกรด' };
      }
      if (!(parseFloat(price_per_kg) > 0)) {
        return { isError: true, data: null, errorMessage: 'ราคาต้องมากกว่า 0' };
      }
      if (!effective_date) {
        return { isError: true, data: null, errorMessage: 'กรุณาเลือกวันที่เริ่มใช้ราคา' };
      }
      if (end_date && end_date < effective_date) {
        return { isError: true, data: null, errorMessage: 'วันหมดอายุต้องไม่ก่อนวันเริ่มใช้' };
      }
      // แก้ไขรายการเดิม: ต้องเป็นราคาของร้านนี้จริง (กันการแก้ราคาร้านอื่นด้วยรหัส)
      if (price_rate_id) {
        const mine = await db.query(
          `SELECT price_rate_id FROM price_rate WHERE price_rate_id = ? AND shop_id = ?`,
          [price_rate_id, shop_id]
        );
        if (mine.length === 0) {
          return { isError: true, data: null, errorMessage: 'ไม่พบรายการราคานี้' };
        }
      }
      let rateId = price_rate_id;
      if (!rateId) {
        const maxRows = await db.query(
          `SELECT MAX(CAST(SUBSTRING(price_rate_id, 3) AS UNSIGNED)) AS max_num FROM price_rate WHERE price_rate_id LIKE 'PR%'`
        );
        rateId = 'PR' + String(Number(maxRows[0].max_num || 0) + 1).padStart(3, '0');
      }
      await db.query(`
        INSERT INTO price_rate (price_rate_id, shop_id, quality_grade, price_per_kg, effective_date, end_date)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
          quality_grade = VALUES(quality_grade),
          price_per_kg = VALUES(price_per_kg),
          effective_date = VALUES(effective_date),
          end_date = VALUES(end_date)
      `, [rateId, shop_id, String(quality_grade).trim(), parseFloat(price_per_kg), effective_date, end_date || null]);
      return { isError: false, data: { price_rate_id: rateId }, errorMessage: '' };
    } catch (error) {
      console.error('Error savePriceRate:', error.message);
      return { isError: true, data: null, errorMessage: 'บันทึกราคาไม่สำเร็จ' };
    }
  },

  /** ลบราคา 1 รายการ (เฉพาะราคาของร้านที่ user_id เป็นเจ้าของ) */
  deletePriceRate: async (priceRateId, userId) => {
    try {
      const result = await db.query(`
        DELETE FROM price_rate
        WHERE price_rate_id = ? AND shop_id IN (SELECT shop_id FROM shop WHERE user_id = ?)
      `, [priceRateId, userId]);
      if (!result.affectedRows) {
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์ลบ' };
      }
      return { isError: false, data: null, errorMessage: '' };
    } catch (error) {
      console.error('Error deletePriceRate:', error.message);
      return { isError: true, data: null, errorMessage: 'ลบราคาไม่สำเร็จ' };
    }
  },

  // ------------------------------------------------------------
  // ฟังก์ชันฝั่งร้านรับซื้อ: ภาพ 4.3.4 บันทึกการรับซื้อผลผลิต (Purchase)
  // ------------------------------------------------------------
  /**
   * ค้นหาเกษตรกรเพื่อรับซื้อ: ค้นจากชื่อ เบอร์โทร หรือเลขบัตรประชาชน (อย่างน้อย 2 ตัวอักษร)
   * ส่งกลับเฉพาะบัญชีเกษตรกร (R002) พร้อมจำนวนผลผลิตรอขายที่ร้านนี้รับซื้อได้
   * (ไม่นับล็อตที่เกษตรกรเลือกขายให้ร้านอื่นไว้)
   * ต้องเป็นบัญชีร้านรับซื้อเท่านั้นถึงค้นได้ (กันคนทั่วไปดึงรายชื่อเกษตรกร)
   */
  searchFarmers: async (userId, keyword) => {
    try {
      const shopOwner = await db.query(`SELECT user_id FROM user WHERE user_id = ? AND role_id = 'R003'`, [userId]);
      if (shopOwner.length === 0) {
        return { isError: true, data: [], errorMessage: 'เฉพาะบัญชีร้านรับซื้อเท่านั้น' };
      }
      const q = String(keyword || '').trim();
      if (q.length < 2) return { isError: false, data: [], errorMessage: '' };
      const like = `%${q}%`;
      const rows = await db.query(`
        SELECT u.user_id, u.full_name, u.phone,
               (SELECT COUNT(*) FROM harvest h JOIN garden g ON h.garden_id = g.garden_id
                WHERE g.user_id = u.user_id AND h.status = 'pending'
                  AND (h.shop_id IS NULL OR h.shop_id = (SELECT shop_id FROM shop WHERE user_id = ? LIMIT 1))) AS pending_count
        FROM user u
        WHERE u.role_id = 'R002' AND (u.full_name LIKE ? OR u.phone LIKE ? OR u.citizen_id = ?)
        ORDER BY pending_count DESC, u.full_name
        LIMIT 20
      `, [userId, like, like, q]);
      // COUNT ได้ค่าเป็น BigInt แปลงเป็น number ก่อนส่ง JSON
      return { isError: false, data: rows.map((r) => ({ ...r, pending_count: Number(r.pending_count) })), errorMessage: '' };
    } catch (error) {
      console.error('Error searchFarmers:', error.message);
      return { isError: true, data: [], errorMessage: 'ค้นหาเกษตรกรไม่สำเร็จ' };
    }
  },

  /**
   * ผลผลิตที่ "รอขาย" ของเกษตรกร 1 คน ที่ร้านนี้รับซื้อได้ (ให้ร้านเลือกว่ารับซื้อล็อตไหน)
   * reserved = 1 คือเกษตรกรเลือกขายให้ร้านนี้ไว้แล้ว
   */
  getPendingHarvests: async (userId, farmerId) => {
    try {
      const shopOwner = await db.query(`SELECT user_id FROM user WHERE user_id = ? AND role_id = 'R003'`, [userId]);
      if (shopOwner.length === 0) {
        return { isError: true, data: [], errorMessage: 'เฉพาะบัญชีร้านรับซื้อเท่านั้น' };
      }
      const rows = await db.query(`
        SELECT h.harvest_id, COALESCE(h.code, h.harvest_id) AS code,
               DATE_FORMAT(h.harvest_date, '%Y-%m-%d') AS harvest_date,
               CAST(h.total_quantity AS DOUBLE) AS quantity,
               COALESCE(g.garden_name, 'แปลงปาล์ม') AS garden_name,
               (h.shop_id IS NOT NULL) AS reserved
        FROM harvest h
        JOIN garden g ON h.garden_id = g.garden_id
        WHERE g.user_id = ? AND h.status = 'pending' AND (h.shop_id IS NULL OR h.shop_id = (SELECT shop_id FROM shop WHERE user_id = ? LIMIT 1))
        ORDER BY reserved DESC, h.harvest_date DESC
      `, [farmerId, userId]);
      return { isError: false, data: rows.map((r) => ({ ...r, reserved: Boolean(Number(r.reserved)) })), errorMessage: '' };
    } catch (error) {
      console.error('Error getPendingHarvests:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดผลผลิตไม่สำเร็จ' };
    }
  },

  /** ล็อตที่เกษตรกรเลือกขายให้ร้านนี้ และยังรอร้านยืนยันรับซื้อ (เก่าสุดก่อน ร้านจะได้ไม่ลืม) */
  getIncomingHarvests: async (shopId, userId) => {
    try {
      const owned = await db.query(`SELECT shop_id FROM shop WHERE shop_id = ? AND user_id = ?`, [shopId, userId]);
      if (owned.length === 0) {
        return { isError: true, data: [], errorMessage: 'ไม่พบร้าน หรือไม่มีสิทธิ์ดูข้อมูล' };
      }
      const rows = await db.query(`
        SELECT h.harvest_id, COALESCE(h.code, h.harvest_id) AS code,
               DATE_FORMAT(h.harvest_date, '%Y-%m-%d') AS harvest_date,
               CAST(h.total_quantity AS DOUBLE) AS quantity,
               COALESCE(g.garden_name, 'แปลงปาล์ม') AS garden_name,
               u.user_id AS farmer_id, u.full_name AS farmer_name, u.phone AS farmer_phone
        FROM harvest h
        JOIN garden g ON h.garden_id = g.garden_id
        JOIN user u ON g.user_id = u.user_id
        WHERE h.shop_id = ? AND h.status = 'pending'
        ORDER BY h.harvest_date ASC
      `, [shopId]);
      return { isError: false, data: rows, errorMessage: '' };
    } catch (error) {
      console.error('Error getIncomingHarvests:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดล็อตที่รอรับซื้อไม่สำเร็จ' };
    }
  },

  /**
   * ส่วนกลางของ "การรับซื้อ 1 ครั้ง": บันทึก purchase + เปลี่ยน harvest เป็น sold (ร้าน/ราคา/น้ำหนัก/วันที่ขาย)
   * ต้องเรียกภายใน transaction ที่เปิดไว้แล้ว (conn) และตรวจสิทธิ์/สถานะรอขายมาก่อน
   */
  recordSaleTx: async (conn, { harvest_id, shop_id, farmer_id, purchase_date, quantity, price_per_kg, quality_grade }) => {
    const maxRows = await conn.query(
      `SELECT MAX(CAST(SUBSTRING(purchase_id, 2) AS UNSIGNED)) AS max_num FROM purchase WHERE purchase_id REGEXP '^P[0-9]+$'`
    );
    const purchaseId = 'P' + String(Number(maxRows[0].max_num || 0) + 1).padStart(3, '0');
    const total = Math.round(quantity * price_per_kg * 100) / 100;

    await conn.query(`
      INSERT INTO purchase (purchase_id, harvest_id, quality_grade, shop_id, user_id, purchase_date, quantity, price_per_kg, total_price)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [purchaseId, harvest_id, String(quality_grade || '').trim().slice(0, 100) || null,
        shop_id, farmer_id, purchase_date, quantity, price_per_kg, total]);

    // ฝั่งเกษตรกร: ขายแล้ว + ร้าน + ราคา + น้ำหนัก -> รายรับขึ้นในหน้าการเงินทันที
    await conn.query(`
      UPDATE harvest
      SET status = 'sold', shop_id = ?, total_quantity = ?, price_per_kg = ?, total_price = ?,
          buyer_name = NULL, sold_date = ?
      WHERE harvest_id = ?
    `, [shop_id, quantity, price_per_kg, total, purchase_date, harvest_id]);

    return { purchase_id: purchaseId, total_price: total };
  },

  /**
   * บันทึกการรับซื้อ 1 รายการ แล้วเปลี่ยนผลผลิตฝั่งเกษตรกรเป็น "ขายแล้ว" อัตโนมัติ
   *   user_id    = เจ้าของร้าน (ผู้บันทึก) ต้องเป็นเจ้าของ shop_id จริง
   *   harvest_id = ผลผลิตที่รับซื้อ ต้องยังเป็น "รอขาย" อยู่
   *   quantity   = น้ำหนักที่ร้านชั่งจริง (ใช้แทนน้ำหนักที่เกษตรกรประมาณไว้)
   * ทำใน transaction เดียว: บันทึก purchase + อัปเดต harvest ถ้าพังกลางทางจะย้อนกลับทั้งหมด
   */
  //   quality_grade = เกรดที่ร้านเลือก (ข้อความ เช่น "เกรด A") ไม่บังคับ: กรอกราคาเอง = ไม่มีเกรด
  createPurchase: async ({ user_id, shop_id, harvest_id, purchase_date, quantity, price_per_kg, quality_grade }) => {
    const qty = parseFloat(quantity);
    const price = parseFloat(price_per_kg);
    if (!harvest_id) return { isError: true, data: null, errorMessage: 'กรุณาเลือกผลผลิตที่รับซื้อ' };
    if (!(qty > 0)) return { isError: true, data: null, errorMessage: 'น้ำหนักต้องมากกว่า 0' };
    if (!(price > 0)) return { isError: true, data: null, errorMessage: 'ราคาต้องมากกว่า 0' };
    if (!purchase_date) return { isError: true, data: null, errorMessage: 'กรุณาเลือกวันที่รับซื้อ' };

    let conn;
    try {
      conn = await db.getConnection();
      await conn.beginTransaction();

      const owned = await conn.query(`SELECT shop_id FROM shop WHERE shop_id = ? AND user_id = ?`, [shop_id, user_id]);
      if (owned.length === 0) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ไม่พบร้าน หรือไม่มีสิทธิ์บันทึกการรับซื้อ' };
      }

      // FOR UPDATE: ล็อกแถวไว้ กันสองร้านกดรับซื้อล็อตเดียวกันพร้อมกัน
      const found = await conn.query(`
        SELECT h.harvest_id, h.status, h.shop_id, g.user_id AS farmer_id,
               DATE_FORMAT(h.harvest_date, '%Y-%m-%d') AS harvest_date
        FROM harvest h JOIN garden g ON h.garden_id = g.garden_id
        WHERE h.harvest_id = ? FOR UPDATE
      `, [harvest_id]);
      if (found.length === 0) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ไม่พบผลผลิตนี้' };
      }
      if (found[0].status !== 'pending') {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ผลผลิตนี้ขายไปแล้ว' };
      }
      // วันที่รับซื้อต้องไม่ก่อนวันเก็บเกี่ยว และไม่เกินวันนี้
      const pd = String(purchase_date).slice(0, 10);
      if (pd < found[0].harvest_date || pd > new Date().toLocaleDateString('sv-SE')) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'วันที่รับซื้อต้องอยู่ระหว่างวันเก็บเกี่ยวถึงวันนี้' };
      }
      // เกษตรกรเลือกขายให้ร้านอื่นไว้ -> ร้านนี้รับซื้อแทนไม่ได้ (กันร้านแย่งล็อตกัน)
      if (found[0].shop_id && found[0].shop_id !== shop_id) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'เกษตรกรเลือกขายล็อตนี้ให้ร้านอื่นไว้แล้ว' };
      }

      const sale = await shop.recordSaleTx(conn, {
        harvest_id, shop_id, farmer_id: found[0].farmer_id, purchase_date, quantity: qty, price_per_kg: price, quality_grade,
      });

      await conn.commit();
      return { isError: false, data: sale, errorMessage: '' };
    } catch (error) {
      if (conn) await conn.rollback().catch(() => {});
      console.error('Error createPurchase:', error.message);
      return { isError: true, data: null, errorMessage: 'บันทึกการรับซื้อไม่สำเร็จ' };
    } finally {
      if (conn) conn.release();
    }
  },

  /**
   * ยกเลิกการรับซื้อ (กรณีบันทึกผิด) -> ผลผลิตฝั่งเกษตรกรกลับเป็น "รอขาย" และยังรอร้านนี้อยู่
   * (ร้านบันทึกใหม่ให้ถูกได้ทันที หรือเกษตรกรเปลี่ยนร้านเอง)
   * ลบรายการเงินที่ผูกกับ purchase นี้ด้วย (ถ้ามี) ไม่งั้นจะค้างเป็นรายการลอยๆ
   */
  cancelPurchase: async (purchaseId, userId) => {
    let conn;
    try {
      conn = await db.getConnection();
      await conn.beginTransaction();
      const found = await conn.query(`
        SELECT p.harvest_id FROM purchase p
        JOIN shop s ON p.shop_id = s.shop_id
        WHERE p.purchase_id = ? AND s.user_id = ? FOR UPDATE
      `, [purchaseId, userId]);
      if (found.length === 0) {
        await conn.rollback();
        return { isError: true, data: null, errorMessage: 'ไม่พบรายการ หรือไม่มีสิทธิ์ยกเลิก' };
      }
      await conn.query(`DELETE FROM finance WHERE ref_purchase_id = ?`, [purchaseId]);
      await conn.query(`DELETE FROM purchase WHERE purchase_id = ?`, [purchaseId]);
      await conn.query(`
        UPDATE harvest SET status = 'pending', sold_date = NULL WHERE harvest_id = ?
      `, [found[0].harvest_id]);
      await conn.commit();
      return { isError: false, data: null, errorMessage: '' };
    } catch (error) {
      if (conn) await conn.rollback().catch(() => {});
      console.error('Error cancelPurchase:', error.message);
      return { isError: true, data: null, errorMessage: 'ยกเลิกการรับซื้อไม่สำเร็จ' };
    } finally {
      if (conn) conn.release();
    }
  },

  // ดึงรายการรับซื้อทั้งหมดของร้านนี้ (ใหม่สุดก่อน) พร้อมชื่อเกษตรกรและแปลงที่มาของผลผลิต
  getPurchasesByShop: async (shopId) => {
    try {
      const rows = await db.query(`
        SELECT p.purchase_id, p.shop_id, p.user_id, p.harvest_id, p.purchase_date, p.quality_grade,
               p.quantity, p.price_per_kg, p.total_price,
               u.full_name AS farmer_name, u.phone AS farmer_phone,
               COALESCE(g.garden_name, '') AS garden_name
        FROM purchase p
        JOIN user u ON p.user_id = u.user_id
        LEFT JOIN harvest h ON p.harvest_id = h.harvest_id
        LEFT JOIN garden g ON h.garden_id = g.garden_id
        WHERE p.shop_id = ?
        ORDER BY p.purchase_date DESC, p.purchase_id DESC
      `, [shopId]);
      return { isError: false, data: rows, errorMessage: '' };
    } catch (error) {
      console.error('Error getPurchasesByShop:', error.message);
      return { isError: true, data: [], errorMessage: error.message };
    }
  },

  // ------------------------------------------------------------
  // ฟังก์ชันฝั่งร้านรับซื้อ: ภาพ 4.3.1 แดชบอร์ดภาพรวมร้านค้า
  // ------------------------------------------------------------
  getShopDashboard: async (shopId) => {
    try {
      // 1. สรุปตัวเลข 4 การ์ด
      const summary = await db.query(`
        SELECT 
          COALESCE(SUM(quantity), 0) AS total_kg,
          COUNT(DISTINCT user_id) AS total_farmers,
          COALESCE(SUM(total_price), 0) AS total_amount
        FROM purchase
        WHERE shop_id = ?
      `, [shopId]);

      // 2. ราคาล่าสุด
      const latestPrice = await db.query(`
        SELECT price_per_kg FROM price_rate 
        WHERE shop_id = ? 
        ORDER BY effective_date DESC LIMIT 1
      `, [shopId]);

      // 2.1 ยอดรับซื้อวันนี้ / เดือนนี้ (ใช้แสดงบนการ์ดสรุปของแดชบอร์ด)
      const period = await db.query(`
        SELECT
          COALESCE(SUM(CASE WHEN DATE(purchase_date) = CURDATE() THEN quantity END), 0)    AS today_kg,
          COALESCE(SUM(CASE WHEN DATE(purchase_date) = CURDATE() THEN total_price END), 0) AS today_amount,
          COALESCE(SUM(CASE WHEN YEAR(purchase_date) = YEAR(CURDATE())
                             AND MONTH(purchase_date) = MONTH(CURDATE()) THEN quantity END), 0)    AS month_kg,
          COALESCE(SUM(CASE WHEN YEAR(purchase_date) = YEAR(CURDATE())
                             AND MONTH(purchase_date) = MONTH(CURDATE()) THEN total_price END), 0) AS month_amount
        FROM purchase
        WHERE shop_id = ?
      `, [shopId]);

      // 2.2 ราคาล่าสุดของแต่ละเกรด พร้อมบอกว่ายังใช้ได้อยู่ไหม (หมดอายุ = เลย end_date แล้ว)
      const currentRates = await db.query(`
        SELECT r.quality_grade, r.price_per_kg,
               DATE_FORMAT(r.effective_date, '%Y-%m-%d') AS effective_date,
               DATE_FORMAT(r.end_date, '%Y-%m-%d') AS end_date,
               (r.end_date IS NULL OR r.end_date >= CURDATE()) AS is_current
        FROM price_rate r
        JOIN (
          SELECT quality_grade, MAX(effective_date) AS latest
          FROM price_rate
          WHERE shop_id = ? AND effective_date <= CURDATE()
          GROUP BY quality_grade
        ) last ON last.quality_grade = r.quality_grade AND last.latest = r.effective_date
        WHERE r.shop_id = ?
        ORDER BY r.price_per_kg DESC
      `, [shopId, shopId]);

      // 2.3 ล็อตที่เกษตรกรส่งมาให้ร้านนี้ และยังรอรับซื้อ
      const incoming = await db.query(
        `SELECT COUNT(*) AS c FROM harvest WHERE shop_id = ? AND status = 'pending'`, [shopId]
      );

      // 3. รายการรับซื้อล่าสุด 5 แถว
      const recentPurchases = await db.query(`
        SELECT p.purchase_id, p.purchase_date, p.quantity, p.price_per_kg, p.total_price, p.quality_grade,
               u.full_name AS farmer_name
        FROM purchase p
        JOIN user u ON p.user_id = u.user_id
        WHERE p.shop_id = ?
        ORDER BY p.purchase_date DESC LIMIT 5
      `, [shopId]);

      return {
        isError: false,
        data: {
          summary: {
            total_kg: parseFloat(summary[0]?.total_kg || 0),
            total_farmers: Number(summary[0]?.total_farmers || 0),
            total_amount: parseFloat(summary[0]?.total_amount || 0),
            latest_price: parseFloat(latestPrice[0]?.price_per_kg || 0),
            today_kg: parseFloat(period[0]?.today_kg || 0),
            today_amount: parseFloat(period[0]?.today_amount || 0),
            month_kg: parseFloat(period[0]?.month_kg || 0),
            month_amount: parseFloat(period[0]?.month_amount || 0),
            incoming_count: Number(incoming[0]?.c || 0)
          },
          currentRates: currentRates.map(r => ({
            quality_grade: r.quality_grade,
            price_per_kg: parseFloat(r.price_per_kg),
            effective_date: r.effective_date,
            end_date: r.end_date,
            is_current: Boolean(Number(r.is_current))
          })),
          recentPurchases
        },
        errorMessage: ''
      };
    } catch (error) {
      console.error('Error getShopDashboard:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  // ------------------------------------------------------------
  // ฟังก์ชันฝั่งร้านรับซื้อ: ภาพ 4.3.5 รายงานสรุปการรับซื้อ
  // ------------------------------------------------------------
  getShopReports: async (shopId, year) => {
    try {
      const y = parseInt(year, 10) || new Date().getFullYear();

      // ยอดรายเดือนของปีที่เลือก (เดือนที่ไม่มีการรับซื้อ ฝั่งแอปเติม 0 ให้)
      const monthly = await db.query(`
        SELECT MONTH(purchase_date) AS month,
               CAST(SUM(quantity) AS DOUBLE) AS total_kg,
               CAST(SUM(total_price) AS DOUBLE) AS total_amount,
               COUNT(*) AS purchase_count
        FROM purchase
        WHERE shop_id = ? AND YEAR(purchase_date) = ?
        GROUP BY MONTH(purchase_date)
        ORDER BY month
      `, [shopId, y]);

      // สรุปทั้งปี: ราคาเฉลี่ยคิดแบบถ่วงน้ำหนัก (ยอดเงิน ÷ น้ำหนักรวม) ไม่ใช่เฉลี่ยราคาแต่ละรายการ
      const [total] = await db.query(`
        SELECT CAST(COALESCE(SUM(quantity), 0) AS DOUBLE) AS total_kg,
               CAST(COALESCE(SUM(total_price), 0) AS DOUBLE) AS total_amount,
               COUNT(*) AS purchase_count,
               COUNT(DISTINCT user_id) AS farmer_count
        FROM purchase
        WHERE shop_id = ? AND YEAR(purchase_date) = ?
      `, [shopId, y]);

      // เกษตรกรที่ขายให้มากที่สุด 5 อันดับของปีนี้
      const topFarmers = await db.query(`
        SELECT u.full_name AS farmer_name,
               CAST(SUM(p.quantity) AS DOUBLE) AS total_kg,
               CAST(SUM(p.total_price) AS DOUBLE) AS total_amount,
               COUNT(*) AS purchase_count
        FROM purchase p
        JOIN user u ON p.user_id = u.user_id
        WHERE p.shop_id = ? AND YEAR(p.purchase_date) = ?
        GROUP BY p.user_id, u.full_name
        ORDER BY total_kg DESC
        LIMIT 5
      `, [shopId, y]);

      // ปีที่มีข้อมูล (ไว้ทำตัวเลือกปี) + ปีปัจจุบันเสมอ
      const yearRows = await db.query(
        `SELECT DISTINCT YEAR(purchase_date) AS y FROM purchase WHERE shop_id = ? ORDER BY y DESC`,
        [shopId]
      );
      const years = [...new Set([new Date().getFullYear(), ...yearRows.map((r) => Number(r.y))])].sort((a, b) => b - a);

      // COUNT ได้ BigInt แปลงเป็น number ก่อนส่ง JSON
      const n = (v) => Number(v || 0);
      return {
        isError: false,
        data: {
          year: y,
          years,
          summary: {
            total_kg: n(total.total_kg),
            total_amount: n(total.total_amount),
            purchase_count: n(total.purchase_count),
            farmer_count: n(total.farmer_count),
            avg_price: total.total_kg > 0 ? n(total.total_amount) / n(total.total_kg) : 0,
          },
          monthly: monthly.map((m) => ({ ...m, month: n(m.month), purchase_count: n(m.purchase_count) })),
          topFarmers: topFarmers.map((f) => ({ ...f, purchase_count: n(f.purchase_count) })),
        },
        errorMessage: '',
      };
    } catch (error) {
      console.error('Error getShopReports:', error.message);
      return { isError: true, data: null, errorMessage: 'โหลดรายงานไม่สำเร็จ' };
    }
  }
};

module.exports = shop;