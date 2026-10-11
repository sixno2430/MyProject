// ============================================================
// admin.js — model ฝั่งผู้ดูแลระบบ (role R001)
//
// - ภาพรวมระบบ: จำนวนผู้ใช้แยกบทบาท, แปลง, ล็อตผลผลิต, ยอดรับซื้อ, กราฟผลผลิต 6 เดือน, กิจกรรมล่าสุด
// - จัดการผู้ใช้: รายชื่อ + เข้าสู่ระบบล่าสุด, เพิ่ม/แก้ไขผู้ใช้, ระงับ/เปิดใช้บัญชี (user.status)
// - ประวัติการใช้งาน: ตาราง user_log (LOGIN, ADD_HARVEST, ADD_PURCHASE ฯลฯ)
// - รายงานระบบ: ผลผลิต/การรับซื้อทั้งชุมชนรายเดือน, เกษตรกร Top 5, สถิติการเข้าใช้, ร้านรับซื้อ
// ============================================================

const bcrypt = require('bcrypt');
const db = require('../libs/db_pool');
const userAccount = require('./user_account');

// บทบาทที่แอดมินกำหนดให้ผู้ใช้ได้ — ไม่มี R001: บัญชีแอดมินล็อกไว้เฉพาะที่มีอยู่แล้ว
// เพิ่มแอดมินไม่ได้ และเปลี่ยนบัญชีอื่นให้เป็น/เลิกเป็นแอดมินผ่านแอปไม่ได้
const ASSIGNABLE_ROLES = ['R002', 'R003'];

// รายชื่อเดือนย้อนหลัง n เดือนถึงเดือนนี้ เช่น ['2026-05', ..., '2026-10']
function lastMonths(n) {
  const now = new Date();
  const months = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    months.push(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`);
  }
  return months;
}

// เติมเดือนที่ไม่มีข้อมูลเป็น 0 ให้กราฟมีครบทุกเดือน (rows ต้องมีคอลัมน์ month = 'YYYY-MM')
function fillMonths(months, rows, fields) {
  return months.map((month) => {
    const row = rows.find((r) => r.month === month) || {};
    const item = { month };
    for (const f of fields) item[f] = Number(row[f] || 0);
    return item;
  });
}

// ผลผลิตที่เก็บเกี่ยวได้ทั้งชุมชนรายเดือน (กก.) n เดือนล่าสุด
async function harvestByMonth(n) {
  const months = lastMonths(n);
  const rows = await db.query(
    `SELECT DATE_FORMAT(harvest_date, '%Y-%m') AS month, SUM(total_quantity) AS qty
     FROM harvest WHERE harvest_date >= ? GROUP BY month`,
    [months[0] + '-01']
  );
  return fillMonths(months, rows, ['qty']);
}

const admin = {
  // เช็กว่า user นี้เป็นแอดมินจริง (ทุก API ของแอดมินเรียกก่อนทำงาน)
  isAdmin: async (userId) => {
    if (!userId) return false;
    const rows = await db.query(`SELECT role_id FROM user WHERE user_id = ?`, [userId]);
    return rows.length > 0 && rows[0].role_id === 'R001';
  },

  // ตัวเลขภาพรวมทั้งระบบ
  getOverview: async () => {
    try {
      const users = await db.query(`
        SELECT COUNT(*) AS total,
               SUM(role_id = 'R002') AS farmers,
               SUM(role_id = 'R003') AS shops,
               SUM(role_id = 'R001') AS admins
        FROM user
      `);
      const gardens = await db.query(`SELECT COUNT(*) AS n, COALESCE(SUM(area_size), 0) AS area FROM garden`);
      const harvests = await db.query(`
        SELECT COUNT(*) AS total, SUM(status = 'pending') AS pending, SUM(status = 'sold') AS sold
        FROM harvest
      `);
      const purchases = await db.query(`
        SELECT COUNT(*) AS n, COALESCE(SUM(quantity), 0) AS qty, COALESCE(SUM(total_price), 0) AS amount
        FROM purchase
      `);
      const thisMonth = await db.query(`
        SELECT COALESCE(SUM(quantity), 0) AS qty, COALESCE(SUM(total_price), 0) AS amount
        FROM purchase WHERE DATE_FORMAT(purchase_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
      `);
      // กิจกรรมล่าสุดของทั้งระบบ: เก็บเกี่ยว / ร้านรับซื้อ / สมัครสมาชิก
      const recent = await db.query(`
        SELECT * FROM (
          (SELECT 'harvest' AS type, h.harvest_date AS at, u.full_name AS who,
                  CONCAT('แปลง', g.garden_name, ' ', FORMAT(h.total_quantity, 0), ' กก.') AS detail
           FROM harvest h JOIN garden g ON g.garden_id = h.garden_id JOIN user u ON u.user_id = g.user_id)
          UNION ALL
          (SELECT 'purchase', p.purchase_date, s.shop_name,
                  CONCAT(FORMAT(p.quantity, 0), ' กก. มูลค่า ', FORMAT(p.total_price, 0), ' บาท')
           FROM purchase p JOIN shop s ON s.shop_id = p.shop_id)
          UNION ALL
          (SELECT 'register', u.created_at, u.full_name, 'สมัครสมาชิกใหม่' FROM user u)
        ) a
        ORDER BY at DESC LIMIT 6
      `);
      // คนที่เข้าสู่ระบบภายใน 7 วันล่าสุด = ผู้ใช้ที่ยังใช้งานอยู่
      const active = await db.query(`
        SELECT COUNT(DISTINCT user_id) AS n FROM user_log
        WHERE action = 'LOGIN' AND log_date >= NOW() - INTERVAL 7 DAY
      `);

      return {
        isError: false,
        errorMessage: "",
        data: {
          user_count: Number(users[0].total),
          farmer_count: Number(users[0].farmers || 0),
          shop_count: Number(users[0].shops || 0),
          admin_count: Number(users[0].admins || 0),
          active_7d: Number(active[0].n),
          garden_count: Number(gardens[0].n),
          garden_area: Number(gardens[0].area),
          harvest_count: Number(harvests[0].total),
          harvest_pending: Number(harvests[0].pending || 0),
          harvest_sold: Number(harvests[0].sold || 0),
          purchase_count: Number(purchases[0].n),
          purchase_qty: Number(purchases[0].qty),
          purchase_amount: Number(purchases[0].amount),
          month_purchase_qty: Number(thisMonth[0].qty),
          month_purchase_amount: Number(thisMonth[0].amount),
          harvest_monthly: await harvestByMonth(6),
          recent: recent.map((r) => ({
            type: r.type,
            at: r.at,
            who: r.who,
            detail: r.detail,
          })),
        },
      };
    } catch (error) {
      console.error('Error admin.getOverview:', error.message);
      return { isError: true, data: null, errorMessage: 'โหลดภาพรวมระบบไม่สำเร็จ' };
    }
  },

  // ผู้ใช้ทั้งหมด (ใหม่สุดก่อน) พร้อมเข้าสู่ระบบล่าสุด, จำนวนแปลง (เกษตรกร), ชื่อร้าน (ร้านรับซื้อ)
  getUsers: async () => {
    try {
      const rows = await db.query(`
        SELECT u.user_id, u.role_id, u.full_name, u.phone, u.username, u.citizen_id, u.status,
               DATE_FORMAT(u.created_at, '%Y-%m-%d') AS created_at,
               DATE_FORMAT(l.last_login, '%Y-%m-%d %H:%i') AS last_login,
               (SELECT COUNT(*) FROM garden g WHERE g.user_id = u.user_id) AS garden_count,
               (SELECT s.shop_name FROM shop s WHERE s.user_id = u.user_id LIMIT 1) AS shop_name
        FROM user u
        LEFT JOIN (
          SELECT user_id, MAX(log_date) AS last_login FROM user_log
          WHERE action = 'LOGIN' GROUP BY user_id
        ) l ON l.user_id = u.user_id
        ORDER BY u.created_at DESC, u.user_id DESC
      `);
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error admin.getUsers:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดรายชื่อผู้ใช้ไม่สำเร็จ' };
    }
  },

  // แอดมินเพิ่มผู้ใช้ได้เฉพาะเกษตรกร / ร้านรับซื้อ เลขบัตรประชาชนไม่บังคับ
  createUser: async ({ role_id, full_name, citizen_id, phone, username, password }) => {
    try {
      if (!ASSIGNABLE_ROLES.includes(role_id)) {
        return { isError: true, data: null, errorMessage: 'เลือกบทบาทได้เฉพาะเกษตรกรหรือร้านรับซื้อ' };
      }
      if (!full_name || !full_name.trim() || !username || !username.trim()) {
        return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อและ username' };
      }
      if (!password || password.length < 4) {
        return { isError: true, data: null, errorMessage: 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร' };
      }
      const citizen = (citizen_id || '').trim();
      if (citizen && !/^\d{13}$/.test(citizen)) {
        return { isError: true, data: null, errorMessage: 'เลขบัตรประชาชนต้องเป็นตัวเลข 13 หลัก' };
      }
      const idResult = await userAccount.getNextUserId();
      if (idResult.isError) return { isError: true, data: null, errorMessage: 'สร้างรหัสผู้ใช้ไม่สำเร็จ' };

      const hashed = await bcrypt.hash(password, 10);
      // createUser ของ user_account แปลง error ชื่อซ้ำ/เลขบัตรซ้ำเป็นข้อความไทยให้แล้ว
      const result = await userAccount.createUser(
        idResult.data, role_id, citizen || null, full_name.trim(), (phone || '').trim(), username.trim(), hashed
      );
      if (result.isError) return { isError: true, data: null, errorMessage: result.errorMessage };
      return { isError: false, data: { user_id: idResult.data }, errorMessage: "" };
    } catch (error) {
      console.error('Error admin.createUser:', error.message);
      return { isError: true, data: null, errorMessage: 'เพิ่มผู้ใช้ไม่สำเร็จ' };
    }
  },

  // แก้ไขผู้ใช้: ชื่อ, เบอร์, เลขบัตร, บทบาท, รหัสผ่านใหม่ (ไม่กรอก = คงเดิม)
  // เปลี่ยนบทบาทได้เฉพาะ เกษตรกร <-> ร้านรับซื้อ ของบัญชีที่ยังไม่มีแปลง/ร้าน (กันข้อมูลเดิมค้างผิดบทบาท)
  // บัญชีแอดมินเปลี่ยนบทบาทไม่ได้ และตั้งใครเป็นแอดมินไม่ได้
  updateUser: async (userId, { role_id, full_name, citizen_id, phone, password }) => {
    try {
      const rows = await db.query(
        `SELECT u.role_id,
                (SELECT COUNT(*) FROM garden g WHERE g.user_id = u.user_id) AS gardens,
                (SELECT COUNT(*) FROM shop s WHERE s.user_id = u.user_id) AS shops
         FROM user u WHERE u.user_id = ?`,
        [userId]
      );
      if (rows.length === 0) return { isError: true, data: null, errorMessage: 'ไม่พบผู้ใช้นี้' };
      const old = rows[0];

      if (!full_name || !full_name.trim()) return { isError: true, data: null, errorMessage: 'กรุณากรอกชื่อ' };
      const newRole = role_id || old.role_id;
      if (newRole !== old.role_id) {
        if (old.role_id === 'R001') {
          return { isError: true, data: null, errorMessage: 'เปลี่ยนบทบาทของบัญชีแอดมินไม่ได้' };
        }
        if (!ASSIGNABLE_ROLES.includes(newRole)) {
          return { isError: true, data: null, errorMessage: 'เปลี่ยนเป็นได้เฉพาะเกษตรกรหรือร้านรับซื้อ' };
        }
        if (Number(old.gardens) > 0 || Number(old.shops) > 0) {
          return { isError: true, data: null, errorMessage: 'เปลี่ยนบทบาทไม่ได้ เพราะบัญชีนี้มีแปลงสวนหรือร้านอยู่แล้ว' };
        }
      }
      const citizen = (citizen_id || '').trim();
      if (citizen && !/^\d{13}$/.test(citizen)) {
        return { isError: true, data: null, errorMessage: 'เลขบัตรประชาชนต้องเป็นตัวเลข 13 หลัก' };
      }
      if (password && password.length < 4) {
        return { isError: true, data: null, errorMessage: 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร' };
      }

      await db.query(
        `UPDATE user SET role_id = ?, full_name = ?, citizen_id = ?, phone = ? WHERE user_id = ?`,
        [newRole, full_name.trim(), citizen || null, (phone || '').trim(), userId]
      );
      if (password) {
        await db.query(`UPDATE user SET password = ? WHERE user_id = ?`, [await bcrypt.hash(password, 10), userId]);
      }
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error admin.updateUser:', error.message);
      if (error.errno === 1062) return { isError: true, data: null, errorMessage: 'เลขบัตรประชาชนนี้ถูกลงทะเบียนแล้ว' };
      return { isError: true, data: null, errorMessage: 'แก้ไขผู้ใช้ไม่สำเร็จ' };
    }
  },

  // ระงับ ('suspended') หรือเปิดใช้ ('active') บัญชี — ระงับตัวเองไม่ได้
  // ใช้แทนการลบผู้ใช้ เพราะลบแล้วข้อมูลแปลง/การซื้อขายที่ผูกกับบัญชีจะหายตามไปด้วย
  setUserStatus: async (adminId, userId, status) => {
    try {
      if (!['active', 'suspended'].includes(status)) {
        return { isError: true, data: null, errorMessage: 'สถานะไม่ถูกต้อง' };
      }
      if (userId === adminId && status === 'suspended') {
        return { isError: true, data: null, errorMessage: 'ระงับบัญชีของตัวเองไม่ได้' };
      }
      const result = await db.query(`UPDATE user SET status = ? WHERE user_id = ?`, [status, userId]);
      if (!result.affectedRows) return { isError: true, data: null, errorMessage: 'ไม่พบผู้ใช้นี้' };
      return { isError: false, data: null, errorMessage: "" };
    } catch (error) {
      console.error('Error admin.setUserStatus:', error.message);
      return { isError: true, data: null, errorMessage: 'เปลี่ยนสถานะบัญชีไม่สำเร็จ' };
    }
  },

  // ประวัติการใช้งานล่าสุด ใหม่สุดก่อน
  // กรองได้ตาม action (ส่งหลายค่าคั่นด้วย comma ได้ เช่น 'ADD_HARVEST,ADD_CARE') และตาม user
  getLogs: async ({ action, user_id, limit }) => {
    try {
      const where = [];
      const params = [];
      const actions = (action || '').split(',').map((a) => a.trim()).filter(Boolean);
      if (actions.length) { where.push(`l.action IN (${actions.map(() => '?').join(',')})`); params.push(...actions); }
      if (user_id) { where.push('l.user_id = ?'); params.push(user_id); }
      params.push(Math.min(Number(limit) || 200, 500));
      const rows = await db.query(
        `SELECT l.log_id, l.user_id, l.action, l.ip_address,
                DATE_FORMAT(l.log_date, '%Y-%m-%d %H:%i:%s') AS log_date,
                u.username, u.full_name, u.role_id
         FROM user_log l LEFT JOIN user u ON u.user_id = l.user_id
         ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
         ORDER BY l.log_date DESC, l.log_id DESC
         LIMIT ?`,
        params
      );
      return { isError: false, data: rows, errorMessage: "" };
    } catch (error) {
      console.error('Error admin.getLogs:', error.message);
      return { isError: true, data: [], errorMessage: 'โหลดประวัติการใช้งานไม่สำเร็จ' };
    }
  },

  // รายงานระบบ: รายเดือน 6 เดือน, เกษตรกรผลผลิตสูงสุด 5 คน, สถิติการเข้าใช้, ร้านรับซื้อ
  getReport: async () => {
    try {
      const months = lastMonths(6);
      const from = months[0] + '-01';

      const harvest = await harvestByMonth(6);
      const purchaseRows = await db.query(
        `SELECT DATE_FORMAT(purchase_date, '%Y-%m') AS month,
                SUM(quantity) AS qty, SUM(total_price) AS amount
         FROM purchase WHERE purchase_date >= ? GROUP BY month`,
        [from]
      );
      const purchase = fillMonths(months, purchaseRows, ['qty', 'amount']);

      const usageRows = await db.query(
        `SELECT DATE_FORMAT(log_date, '%Y-%m') AS month,
                SUM(action = 'LOGIN') AS logins,
                SUM(action <> 'LOGIN') AS actions,
                COUNT(DISTINCT user_id) AS users
         FROM user_log WHERE log_date >= ? GROUP BY month`,
        [from]
      );
      const usage = fillMonths(months, usageRows, ['logins', 'actions', 'users']);

      const topFarmers = await db.query(`
        SELECT u.user_id, u.full_name, COUNT(h.harvest_id) AS lots,
               COALESCE(SUM(h.total_quantity), 0) AS qty
        FROM harvest h
        JOIN garden g ON g.garden_id = h.garden_id
        JOIN user u ON u.user_id = g.user_id
        GROUP BY u.user_id, u.full_name
        ORDER BY qty DESC
        LIMIT 5
      `);

      // ราคาล่าสุดของร้าน = ราคาที่เริ่มใช้ล่าสุด (สูงสุดถ้าวันเดียวกันหลายเกรด)
      const shops = await db.query(`
        SELECT s.shop_id, s.shop_name, s.status,
               (SELECT MAX(pr.price_per_kg) FROM price_rate pr
                WHERE pr.shop_id = s.shop_id
                  AND pr.effective_date = (SELECT MAX(effective_date) FROM price_rate WHERE shop_id = s.shop_id)
               ) AS latest_price,
               COUNT(p.purchase_id) AS purchase_count,
               COALESCE(SUM(p.quantity), 0) AS purchase_qty
        FROM shop s
        LEFT JOIN purchase p ON p.shop_id = s.shop_id
        GROUP BY s.shop_id, s.shop_name, s.status
        ORDER BY purchase_qty DESC
      `);

      return {
        isError: false,
        errorMessage: "",
        data: {
          harvest_monthly: harvest,
          purchase_monthly: purchase,
          usage_monthly: usage,
          top_farmers: topFarmers.map((f) => ({ ...f, lots: Number(f.lots), qty: Number(f.qty) })),
          shops: shops.map((s) => ({
            ...s,
            latest_price: s.latest_price === null ? null : Number(s.latest_price),
            purchase_count: Number(s.purchase_count),
            purchase_qty: Number(s.purchase_qty),
          })),
        },
      };
    } catch (error) {
      console.error('Error admin.getReport:', error.message);
      return { isError: true, data: null, errorMessage: 'โหลดรายงานระบบไม่สำเร็จ' };
    }
  },
};

module.exports = admin;
