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

  updateShopProfile: async (shopId, { shop_name, location, phone, status, open_schedule }) => {
    try {
      await db.query(`
        UPDATE shop 
        SET shop_name = ?, location = ?, phone = ?, status = ?, open_schedule = ?
        WHERE shop_id = ?
      `, [shop_name, location, phone, status, open_schedule, shopId]);
      return { isError: false, data: null, errorMessage: '' };
    } catch (error) {
      console.error('Error updateShopProfile:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
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

  savePriceRate: async ({ price_rate_id, shop_id, quality_grade, price_per_kg, effective_date, end_date }) => {
    try {
      // หากไม่มี ID ส่งมา ให้สร้างรหัสใหม่ เช่น PR + timestamp
      const rateId = price_rate_id || `PR${Date.now().toString().slice(-6)}`;
      await db.query(`
        INSERT INTO price_rate (price_rate_id, shop_id, quality_grade, price_per_kg, effective_date, end_date)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
          quality_grade = VALUES(quality_grade),
          price_per_kg = VALUES(price_per_kg),
          effective_date = VALUES(effective_date),
          end_date = VALUES(end_date)
      `, [rateId, shop_id, quality_grade, price_per_kg, effective_date, end_date || null]);
      return { isError: false, data: { price_rate_id: rateId }, errorMessage: '' };
    } catch (error) {
      console.error('Error savePriceRate:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  // ------------------------------------------------------------
  // ฟังก์ชันฝั่งร้านรับซื้อ: ภาพ 4.3.4 บันทึกการรับซื้อผลผลิต (Purchase)
  // ------------------------------------------------------------
  createPurchase: async ({ purchase_id, shop_id, user_id, harvest_id, purchase_date, quantity, price_per_kg }) => {
    try {
      const purId = purchase_id || `P${Date.now().toString().slice(-7)}`;
      const qty = parseFloat(quantity);
      const price = parseFloat(price_per_kg);
      const total_price = (qty * price).toFixed(2);

      await db.query(`
        INSERT INTO purchase (purchase_id, shop_id, user_id, harvest_id, purchase_date, quantity, price_per_kg, total_price)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `, [purId, shop_id, user_id, harvest_id || null, purchase_date, qty, price, total_price]);

      return { isError: false, data: { purchase_id: purId, total_price }, errorMessage: '' };
    } catch (error) {
      console.error('Error createPurchase:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  },

  // ดึงรายการรับซื้อทั้งหมดของร้านนี้
  getPurchasesByShop: async (shopId) => {
    try {
      const rows = await db.query(`
        SELECT p.purchase_id, p.shop_id, p.user_id, p.purchase_date, p.quantity, p.price_per_kg, p.total_price,
               u.full_name AS farmer_name, u.phone AS farmer_phone
        FROM purchase p
        JOIN user u ON p.user_id = u.user_id
        WHERE p.shop_id = ?
        ORDER BY p.purchase_date DESC
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

      // 3. รายการรับซื้อล่าสุด 5 แถว
      const recentPurchases = await db.query(`
        SELECT p.purchase_id, p.purchase_date, p.quantity, p.price_per_kg, p.total_price,
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
            latest_price: parseFloat(latestPrice[0]?.price_per_kg || 0)
          },
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
  getShopReports: async (shopId) => {
    try {
      // กราฟสรุปยอดรับซื้อรายเดือน (6 เดือนย้อนหลัง)
      const monthlySummary = await db.query(`
        SELECT DATE_FORMAT(purchase_date, '%m/%Y') AS month_label,
               SUM(quantity) AS total_kg,
               SUM(total_price) AS total_amount
        FROM purchase
        WHERE shop_id = ?
        GROUP BY DATE_FORMAT(purchase_date, '%m/%Y')
        ORDER BY purchase_date ASC LIMIT 6
      `, [shopId]);

      // Top 3 เกษตรกรที่ขายผลผลิตมากที่สุด
      const topFarmers = await db.query(`
        SELECT u.full_name AS farmer_name,
               SUM(p.quantity) AS total_kg,
               SUM(p.total_price) AS total_amount
        FROM purchase p
        JOIN user u ON p.user_id = u.user_id
        WHERE p.shop_id = ?
        GROUP BY p.user_id, u.full_name
        ORDER BY total_kg DESC LIMIT 3
      `, [shopId]);

      return {
        isError: false,
        data: { monthlySummary, topFarmers },
        errorMessage: ''
      };
    } catch (error) {
      console.error('Error getShopReports:', error.message);
      return { isError: true, data: null, errorMessage: error.message };
    }
  }
};

module.exports = shop;