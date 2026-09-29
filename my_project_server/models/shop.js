// ============================================================
// shop.js — model ร้านรับซื้อ (ตาราง shop + price_rate + purchase)
// ============================================================

const db = require('../libs/db_pool');

const shop = {
  // รายชื่อร้านรับซื้อ + ราคาล่าสุดแต่ละเกรด + ประวัติที่ user คนนี้เคยขายให้ร้านนั้น
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

      // ราคาล่าสุดของแต่ละเกรดในแต่ละร้าน (effective_date ใหม่สุดที่ไม่ใช่อนาคต)
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
};

module.exports = shop;
