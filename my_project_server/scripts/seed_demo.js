// ============================================================
// seed_demo.js — สร้างข้อมูลตัวอย่าง (mock data) สำหรับสาธิตระบบ
//
// สร้างบัญชีเดโมแยกจากข้อมูลจริง ข้อมูลเดิมในฐานข้อมูลไม่ถูกแตะ:
//   เกษตรกร  demo_farmer   (3 แปลง ข้อมูลย้อนหลังตั้งแต่ 1 ม.ค. ปีที่แล้วถึงวันนี้ — หน้ารายงานเทียบปีก่อนได้)
//   เกษตรกร  demo_farmer2  (1 แปลง)
//   เกษตรกร  demo_suspend  (บัญชีถูกระงับ ใช้สาธิตหน้าแอดมิน)
//   ร้าน      demo_shop     ลานเทสุขสมบูรณ์ (ราคา 3 เกรด)
//   ร้าน      demo_shop2    ลานเทรุ่งเรืองปาล์ม (ราคา 2 เกรด)
// รหัสผ่านทุกบัญชี: demo1234
//
// ข้อมูลที่ได้: การเก็บเกี่ยวทุก ~15 วัน (ส่วนใหญ่ขายผ่านร้านในแอป บางส่วนขายนอกระบบ),
//   ล็อตล่าสุดที่รอขาย/ส่งให้ร้าน/ถูกร้านปฏิเสธ, ราคารับซื้อรายไตรมาส, การดูแลสวนทุกประเภท
//   (ใส่ปุ๋ยหลายชนิดในรอบเดียว), รายรับ-รายจ่ายที่บันทึกเอง และประวัติการใช้งาน 180 วันล่าสุด
// ตัวเลขสุ่มแบบกำหนด seed ไว้ รันกี่ครั้งก็ได้ข้อมูลชุดเดิม (วันสิ้นสุด = วันที่รัน)
//
// วิธีรัน (ในโฟลเดอร์ my_project_server):
//   node scripts/seed_demo.js            -> ลบข้อมูลเดโมเดิม (ถ้ามี) แล้วสร้างใหม่
//   node scripts/seed_demo.js --remove   -> ลบข้อมูลเดโมออกอย่างเดียว
// ทำใน transaction เดียว พังกลางทางจะย้อนกลับทั้งหมด
// ============================================================

const bcrypt = require('bcrypt');
const db = require('../libs/db_pool');

const PASSWORD = 'demo1234';
const DEMO_USERNAMES = ['demo_farmer', 'demo_farmer2', 'demo_suspend', 'demo_shop', 'demo_shop2'];

// ---------- ตัวช่วย: สุ่มแบบกำหนด seed, วันที่ (ข้อความ yyyy-mm-dd กันปัญหา timezone)
let seed = 20261015;
function rand() {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
const randInt = (min, max) => min + Math.floor(rand() * (max - min + 1));
const pick = (list) => list[Math.floor(rand() * list.length)];
const round2 = (n) => Math.round(n * 100) / 100;

const ymd = (d) => d.toISOString().slice(0, 10);
const parse = (s) => new Date(s + 'T00:00:00Z');
const addDays = (s, n) => ymd(new Date(parse(s).getTime() + n * 86400000));
const TODAY = new Date().toLocaleDateString('sv-SE');
const START = `${Number(TODAY.slice(0, 4)) - 1}-01-01`;
const monthOf = (s) => Number(s.slice(5, 7));
const yearOf = (s) => Number(s.slice(0, 4));
const THAI_MONTHS = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
const thaiMonth = (s) => `${THAI_MONTHS[monthOf(s) - 1]} ${yearOf(s) + 543}`;

/** เดือนที่อยู่ในช่วง START..TODAY (คืนวันที่ 1 ของแต่ละเดือน) */
function monthsInRange() {
  const out = [];
  for (let y = yearOf(START); y <= yearOf(TODAY); y++) {
    for (let m = 1; m <= 12; m++) {
      const first = `${y}-${String(m).padStart(2, '0')}-01`;
      if (first <= TODAY) out.push(first);
    }
  }
  return out;
}

/** วันที่ในเดือนนั้น (ไม่เกินวันนี้) หรือ null ถ้าเลยวันนี้ */
function dayIn(monthFirst, day) {
  const d = monthFirst.slice(0, 8) + String(day).padStart(2, '0');
  return d <= TODAY ? d : null;
}

// ---------- ราคารับซื้อ: เปลี่ยนทุกไตรมาส (ทะลายสด บาท/กก.) เกรดอื่นบวกเพิ่มจากราคานี้
const QUARTER_BASE = [5.4, 5.9, 5.2, 5.6, 5.8, 6.3, 5.9, 6.1];
const GRADE_EXTRA = { 'ทะลายสด': 0, 'เกรด A': 0.6, 'ลูกร่วง': 3.5 };
const quarterIndex = (s) => (yearOf(s) - yearOf(START)) * 4 + Math.floor((monthOf(s) - 1) / 3);
const quarterStart = (qi) => {
  const y = yearOf(START) + Math.floor(qi / 4);
  return `${y}-${String((qi % 4) * 3 + 1).padStart(2, '0')}-01`;
};
function priceOf(shop, grade, date) {
  const base = QUARTER_BASE[Math.min(quarterIndex(date), QUARTER_BASE.length - 1)];
  return round2(base + GRADE_EXTRA[grade] + (grade === 'ลูกร่วง' ? 0 : shop.offset));
}

// ผลผลิตตามฤดู (ต้นปีแล้งผลผลิตน้อย ช่วงปลายฝนผลผลิตมาก)
const SEASON = [0.7, 0.65, 0.8, 1.0, 1.15, 1.1, 0.95, 1.0, 1.1, 1.2, 1.05, 0.85];
/** ต้นปาล์มให้ผลเต็มที่เมื่ออายุ ~7 ปี ก่อนหน้านั้นค่อยๆ เพิ่ม (อายุ < 3 ปี ยังไม่ให้ผล) */
const ageFactor = (plantYear, date) => {
  const age = yearOf(date) - plantYear;
  if (age < 3) return 0;
  return Math.min(1, 0.25 + (age - 3) * 0.2);
};

// ---------- ข้อมูลตั้งต้น
const SHOPS = [
  {
    username: 'demo_shop', fullName: 'สุขสม ใจซื่อ', citizen: '3849900101011', phone: '0812345601',
    shopName: 'ลานเทสุขสมบูรณ์', location: '45 ม.3 ต.ท่าข้าม อ.พุนพิน จ.สุราษฎร์ธานี',
    shopPhone: '077311234', schedule: 'ทุกวัน 07:00-18:00', grades: ['เกรด A', 'ทะลายสด', 'ลูกร่วง'], offset: 0,
  },
  {
    username: 'demo_shop2', fullName: 'รุ่งเรือง มั่งมี', citizen: '3849900101012', phone: '0812345602',
    shopName: 'ลานเทรุ่งเรืองปาล์ม', location: '9 ม.5 ต.เขาหัวควาย อ.พุนพิน จ.สุราษฎร์ธานี',
    shopPhone: '077311567', schedule: 'จันทร์-เสาร์ 08:00-17:00', grades: ['เกรด A', 'ทะลายสด'], offset: 0.1,
  },
];

const FARMERS = [
  {
    username: 'demo_farmer', fullName: 'สมหมาย ใจดี', citizen: '3849900101001', phone: '0891234501',
    varieties: [['เทเนอรา (Tenera)', 'Elaeis guineensis'], ['สุราษฎร์ธานี 2', 'Elaeis guineensis (Deli x Calabar)']],
    gardens: [
      { name: 'สวนบนควน', area: 25, plantYear: 2012, trees: 550, variety: 0, address: '112 ม.4 ต.ท่าข้าม อ.พุนพิน จ.สุราษฎร์ธานี', lat: 9.0721, lng: 99.2034 },
      { name: 'สวนริมคลอง', area: 15, plantYear: 2015, trees: 330, variety: 1, address: '78 ม.6 ต.ท่าข้าม อ.พุนพิน จ.สุราษฎร์ธานี', lat: 9.0815, lng: 99.2198 },
      { name: 'สวนปลูกใหม่', area: 8, plantYear: 2021, trees: 176, variety: 1, address: 'ม.2 ต.เขาหัวควาย อ.พุนพิน จ.สุราษฎร์ธานี', lat: 9.0532, lng: 99.1876 },
    ],
    preferShop: 0,
  },
  {
    username: 'demo_farmer2', fullName: 'วิไล ทองดี', citizen: '3849900101002', phone: '0891234502',
    varieties: [['เทเนอรา (Tenera)', 'Elaeis guineensis']],
    gardens: [
      { name: 'สวนบ้านนา', area: 12, plantYear: 2014, trees: 264, variety: 0, address: '23 ม.1 ต.เขาหัวควาย อ.พุนพิน จ.สุราษฎร์ธานี', lat: 9.0611, lng: 99.1752 },
    ],
    preferShop: 1,
  },
  {
    username: 'demo_suspend', fullName: 'บุญมี ศรีสุข', citizen: '3849900101003', phone: '0891234503',
    suspended: true,
    varieties: [['เทเนอรา (Tenera)', 'Elaeis guineensis']],
    gardens: [
      { name: 'สวนหลังบ้าน', area: 5, plantYear: 2016, trees: 110, variety: 0, address: 'ม.7 ต.ท่าข้าม อ.พุนพิน จ.สุราษฎร์ธานี', lat: null, lng: null },
    ],
    preferShop: 0,
    historyUntil: 150, // หยุดใช้งานก่อนถูกระงับ (วันก่อนวันนี้)
  },
];

const OUTSIDE_BUYERS = ['ลานเทป้าแดง', 'รถรับซื้อเคลื่อนที่', null];

// ปุ๋ย: [ชื่อ, หน่วย, ปริมาณต่อต้น, ราคาต่อหน่วย]
const FERTILIZER_ROUNDS = [
  [['ปุ๋ยเคมี สูตร 13-13-21', 'กระสอบ', 0.03, 980], ['ปุ๋ยอินทรีย์อัดเม็ด', 'กระสอบ', 0.04, 320]],
  [['ปุ๋ยเคมี สูตร 15-15-15', 'กระสอบ', 0.025, 1050], ['ปุ๋ยโบรอน', 'กก.', 0.05, 85]],
];

// ---------- ตัวสร้างรหัสตามรูปแบบเดิมของแต่ละตาราง (ต่อจากเลขมากสุดที่มีอยู่)
async function makeIdGen(conn) {
  const next = {};
  const spec = {
    user: ['user', 'user_id', 'U', 1], garden: ['garden', 'garden_id', 'G', 1],
    variety: ['palm_variety', 'variety_id', 'V', 1], shop: ['shop', 'shop_id', 'S', 1],
    rate: ['price_rate', 'price_rate_id', 'PR', 2], harvest: ['harvest', 'harvest_id', 'H', 1],
    purchase: ['purchase', 'purchase_id', 'P', 1], care: ['palm_care', 'care_id', 'C', 1],
    finance: ['finance', 'finance_id', 'FN', 2], log: ['user_log', 'log_id', 'L', 1],
  };
  for (const [key, [table, col, prefix, len]] of Object.entries(spec)) {
    const rows = await conn.query(
      `SELECT MAX(CAST(SUBSTRING(${col}, ${len + 1}) AS UNSIGNED)) AS n FROM ${table} WHERE ${col} REGEXP ?`,
      [`^${prefix}[0-9]+$`]
    );
    next[key] = { prefix, n: Number(rows[0].n || 0) };
  }
  return (key) => {
    const g = next[key];
    g.n += 1;
    return g.prefix + String(g.n).padStart(3, '0');
  };
}

// ---------- ลบข้อมูลเดโมเดิม
async function removeDemo(conn) {
  const users = await conn.query(`SELECT user_id FROM user WHERE username IN (?)`, [DEMO_USERNAMES]);
  if (users.length === 0) return 0;
  const ids = users.map((u) => u.user_id);
  // ลบจากตารางลูกขึ้นไปทีละตาราง (แบบเดียวกับ models/garden.js) ไม่พึ่ง CASCADE หลายชั้นจาก user
  // เพราะ MySQL ลบต่อเป็นทอดๆ ไม่ครบทุกแถว (เคยเหลือการเก็บเกี่ยวของแปลงที่ถูกลบไปแล้ว)
  const gardens = `SELECT garden_id FROM garden WHERE user_id IN (?)`;
  const shops = `SELECT shop_id FROM shop WHERE user_id IN (?)`;
  const steps = [
    [`DELETE FROM purchase WHERE user_id IN (?) OR shop_id IN (${shops})`, [ids, ids]],
    [`DELETE FROM harvest_rejection WHERE shop_id IN (${shops}) OR harvest_id IN (SELECT harvest_id FROM harvest WHERE garden_id IN (${gardens}))`, [ids, ids]],
    [`DELETE FROM finance WHERE user_id IN (?)`, [ids]],
    [`DELETE FROM care_fertilizer WHERE care_id IN (SELECT care_id FROM palm_care WHERE garden_id IN (${gardens}))`, [ids]],
    [`DELETE FROM palm_care WHERE garden_id IN (${gardens})`, [ids]],
    [`DELETE FROM harvest WHERE garden_id IN (${gardens})`, [ids]],
    [`DELETE FROM garden_variety WHERE garden_id IN (${gardens})`, [ids]],
    [`DELETE FROM garden WHERE user_id IN (?)`, [ids]],
    [`DELETE FROM palm_variety WHERE user_id IN (?)`, [ids]],
    [`DELETE FROM price_rate WHERE shop_id IN (${shops})`, [ids]],
    [`DELETE FROM shop WHERE user_id IN (?)`, [ids]],
    [`DELETE FROM user_log WHERE user_id IN (?)`, [ids]],
    [`DELETE FROM user WHERE user_id IN (?)`, [ids]],
  ];
  for (const [sql, params] of steps) await conn.query(sql, params);
  return ids.length;
}

// ---------- สร้างข้อมูลเดโม
async function createDemo(conn) {
  const nextId = await makeIdGen(conn);
  const hashed = await bcrypt.hash(PASSWORD, 10);
  const logs = []; // [user_id, action, datetime]
  const LOG_FROM = addDays(TODAY, -180);
  const addLog = (userId, action, date) => {
    if (date >= LOG_FROM && date <= TODAY) {
      logs.push([userId, action, `${date} ${String(randInt(7, 19)).padStart(2, '0')}:${String(randInt(0, 59)).padStart(2, '0')}:${String(randInt(0, 59)).padStart(2, '0')}`]);
    }
  };
  const counts = { harvest: 0, purchase: 0, care: 0, finance: 0 };

  const insertUser = async (u, roleId) => {
    const userId = nextId('user');
    await conn.query(
      `INSERT INTO user (user_id, role_id, citizen_id, full_name, phone, username, password, created_at, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, roleId, u.citizen, u.fullName, u.phone, u.username, hashed, `${addDays(START, -20)} 09:30:00`,
        u.suspended ? 'suspended' : 'active']
    );
    return userId;
  };

  // 1) ร้านรับซื้อ + ราคารายไตรมาส (ไตรมาสล่าสุดไม่มีวันสิ้นสุด = ราคาปัจจุบัน)
  for (const s of SHOPS) {
    s.userId = await insertUser(s, 'R003');
    s.shopId = nextId('shop');
    await conn.query(
      `INSERT INTO shop (shop_id, user_id, shop_name, location, phone, status, open_schedule) VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?)`,
      [s.shopId, s.userId, s.shopName, s.location, s.shopPhone, s.schedule]
    );
    const lastQ = quarterIndex(TODAY);
    for (let q = 0; q <= lastQ; q++) {
      const from = quarterStart(q);
      const to = q < lastQ ? addDays(quarterStart(q + 1), -1) : null;
      for (const grade of s.grades) {
        await conn.query(
          `INSERT INTO price_rate (price_rate_id, shop_id, quality_grade, price_per_kg, effective_date, end_date) VALUES (?, ?, ?, ?, ?, ?)`,
          [nextId('rate'), s.shopId, grade, priceOf(s, grade, from), from, to]
        );
      }
      addLog(s.userId, 'UPDATE_PRICE', from);
    }
  }

  const knownFertilizers = await conn.query(`SELECT fertilizer_id, fertilizer_name FROM fertilizer`);

  // 2) เกษตรกร
  for (const f of FARMERS) {
    const userId = await insertUser(f, 'R002');
    const lastDay = f.historyUntil ? addDays(TODAY, -f.historyUntil) : TODAY;
    const inHistory = (d) => d && d <= lastDay;

    const varietyIds = [];
    for (const [name, sci] of f.varieties) {
      const vid = nextId('variety');
      await conn.query(`INSERT INTO palm_variety (variety_id, user_id, variety_name, scientific_name) VALUES (?, ?, ?, ?)`, [vid, userId, name, sci]);
      varietyIds.push(vid);
    }

    for (const g of f.gardens) {
      g.id = nextId('garden');
      await conn.query(
        `INSERT INTO garden (garden_id, user_id, garden_name, latitude, longitude, address, area_size, plant_year, plant_count, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [g.id, userId, g.name, g.lat, g.lng, g.address, g.area, g.plantYear, g.trees, `${addDays(START, -15)} 10:00:00`]
      );
      await conn.query(`INSERT INTO garden_variety (variety_id, garden_id, plant_count, note) VALUES (?, ?, ?, ?)`,
        [varietyIds[g.variety], g.id, g.trees, `ปลูกปี ${g.plantYear + 543}`]);

      // 2.1) เก็บเกี่ยวทุก 14-17 วัน
      const harvests = [];
      for (let d = addDays(START, randInt(3, 12)); inHistory(d); d = addDays(d, randInt(14, 17))) {
        const growth = yearOf(d) === yearOf(TODAY) ? 1.08 : 1; // ปีนี้ดูแลดีขึ้น ผลผลิตเพิ่ม
        const kg = Math.round((g.area * 135 * SEASON[monthOf(d) - 1] * ageFactor(g.plantYear, d) * growth * (0.9 + rand() * 0.2)) / 10) * 10;
        if (kg > 0) harvests.push({ date: d, kg });
      }
      // ล็อตล่าสุดยังไม่ขาย (เฉพาะบัญชีที่ใช้งานอยู่): ส่งให้ร้านแล้ว / ถูกร้านปฏิเสธ / ยังไม่เลือกร้าน
      const pendingPlan = f.historyUntil || g === f.gardens[2] ? [] : (g === f.gardens[0] ? ['rejected', 'toShop'] : ['open']);
      const pendingFrom = harvests.length - pendingPlan.length;

      for (let i = 0; i < harvests.length; i++) {
        const h = harvests[i];
        const hid = nextId('harvest');
        const plan = i >= pendingFrom ? pendingPlan[i - pendingFrom] : (rand() < 0.15 ? 'outside' : 'app');
        let shopId = null, buyer = null, grade = null, price, status = 'sold', soldDate = null, purchase = null;

        if (plan === 'app') {
          const shop = rand() < 0.75 ? SHOPS[f.preferShop] : SHOPS[1 - f.preferShop];
          grade = rand() < 0.7 ? 'เกรด A' : 'ทะลายสด';
          price = priceOf(shop, grade, h.date);
          shopId = shop.shopId;
          soldDate = h.date < TODAY && rand() < 0.4 ? addDays(h.date, 1) : h.date;
          purchase = { shop, grade };
        } else if (plan === 'outside') {
          buyer = pick(OUTSIDE_BUYERS);
          grade = rand() < 0.5 ? 'ทะลายสด' : null;
          price = round2(priceOf(SHOPS[0], 'ทะลายสด', h.date) - 0.2);
          soldDate = h.date;
        } else {
          // รอขาย: ราคาประมาณจากราคาปัจจุบันของร้านที่ขายประจำ
          status = 'pending';
          price = priceOf(SHOPS[f.preferShop], 'เกรด A', h.date);
          if (plan === 'toShop') shopId = SHOPS[f.preferShop].shopId;
        }
        const total = round2(h.kg * price);

        await conn.query(
          `INSERT INTO harvest (harvest_id, garden_id, shop_id, buyer_name, quality_grade, harvest_date, total_quantity, price_per_kg, total_price, status, sold_date, note)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)`,
          [hid, g.id, shopId, buyer, plan === 'app' ? null : grade, h.date, h.kg, price, total, status, soldDate]
        );
        counts.harvest++;
        addLog(userId, 'ADD_HARVEST', h.date);
        if (plan === 'outside') addLog(userId, 'SELL_HARVEST', soldDate);

        if (purchase) {
          await conn.query(
            `INSERT INTO purchase (purchase_id, harvest_id, quality_grade, shop_id, user_id, purchase_date, total_price, price_per_kg, quantity)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [nextId('purchase'), hid, purchase.grade, purchase.shop.shopId, userId, soldDate, total, price, h.kg]
          );
          counts.purchase++;
          addLog(purchase.shop.userId, 'ADD_PURCHASE', soldDate);
        }
        if (plan === 'rejected') {
          const shop = SHOPS[1 - f.preferShop];
          await conn.query(
            `INSERT INTO harvest_rejection (harvest_id, shop_id, reason, created_at) VALUES (?, ?, ?, ?)`,
            [hid, shop.shopId, 'ทะลายยังไม่สุก น้ำมันต่ำ ขอให้ตัดรอบหน้า', `${h.date} 15:20:00`]
          );
          addLog(shop.userId, 'REJECT_HARVEST', h.date);
        }
      }

      // 2.2) การดูแลสวนแต่ละเดือน
      const addCare = async (date, type, { quantity = 0, unit = null, detail = null, cost = 0, note = '', items = null }) => {
        if (!inHistory(date)) return;
        const cid = nextId('care');
        let fertId = null;
        if (items) {
          const sameUnit = items.every((it) => it.unit === items[0].unit);
          quantity = sameUnit ? items.reduce((s, it) => s + it.qty, 0) : 0;
          unit = sameUnit ? items[0].unit : 'รายการ';
          fertId = (items.map((it) => knownFertilizers.find((k) => k.fertilizer_name === it.name)).find(Boolean) || {}).fertilizer_id || null;
        }
        await conn.query(
          `INSERT INTO palm_care (care_id, garden_id, fertilizer_id, action_type, quantity, quantity_type, detail, cost, record_date, note)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [cid, g.id, fertId, type, quantity, unit, detail, cost, date, note]
        );
        if (items) {
          for (let i = 0; i < items.length; i++) {
            const it = items[i];
            const known = knownFertilizers.find((k) => k.fertilizer_name === it.name);
            await conn.query(
              `INSERT INTO care_fertilizer (care_id, line_no, fertilizer_id, fertilizer_name, quantity, unit) VALUES (?, ?, ?, ?, ?, ?)`,
              [cid, i + 1, known ? known.fertilizer_id : null, it.name, it.qty, it.unit]
            );
          }
        }
        counts.care++;
        addLog(userId, 'ADD_CARE', date);
      };

      for (const m of monthsInRange()) {
        const month = monthOf(m);
        // ใส่ปุ๋ยปีละ 2 รอบ (เม.ย. / ก.ย.) รอบละ 2 ชนิด
        if (month === 4 || month === 9) {
          const round = FERTILIZER_ROUNDS[month === 4 ? 0 : 1];
          const items = round.map(([name, unit, perTree, unitPrice]) => {
            const qty = Math.max(1, Math.round(g.trees * perTree));
            return { name, unit, qty, cost: qty * unitPrice };
          });
          await addCare(dayIn(m, randInt(5, 12)), 'fertilizer', {
            items, cost: items.reduce((s, it) => s + it.cost, 0),
            note: month === 4 ? 'ใส่ต้นฝน' : 'ใส่ปลายฝน',
          });
        }
        // ตัดแต่งทางใบทุก 4 เดือน
        if (month % 4 === 2) {
          await addCare(dayIn(m, randInt(13, 20)), 'pruning', {
            quantity: g.trees, unit: 'ต้น', detail: pick(['ตัดแต่งทางใบ', 'ตัดทางใบแห้ง/เป็นโรค']), cost: g.trees * 6,
          });
        }
        // กำจัดวัชพืชทุก 3 เดือน
        if (month % 3 === 1) {
          const method = pick(['ตัดหญ้า', 'ฉีดยาฆ่าหญ้า']);
          await addCare(dayIn(m, randInt(20, 27)), 'weeding', {
            quantity: g.area, unit: 'ไร่', detail: method, cost: g.area * (method === 'ตัดหญ้า' ? 150 : 110),
          });
        }
        // ให้น้ำช่วงแล้ง (ก.พ.-เม.ย.) เฉพาะแปลงต้นยังเล็ก
        if (month >= 2 && month <= 4 && yearOf(m) - g.plantYear < 8) {
          await addCare(dayIn(m, randInt(1, 9)), 'watering', {
            quantity: randInt(4, 8), unit: 'ชั่วโมง', detail: 'สปริงเกอร์', cost: 350,
          });
        }
        // พ่นยากำจัดด้วงแรดปีละครั้ง
        if (month === 7) {
          await addCare(dayIn(m, randInt(8, 15)), 'spraying', {
            quantity: Math.ceil(g.trees / 25), unit: 'ลิตร', detail: 'คลอร์ไพริฟอส (กำจัดด้วงแรด)', cost: Math.ceil(g.trees / 25) * 160,
          });
        }
      }
      if (g.plantYear >= 2020) {
        await addCare(`${yearOf(START)}-06-18`, 'other', { detail: 'ปลูกซ่อมต้นที่ตาย', quantity: 0, cost: 1200, note: 'ปลูกซ่อม 8 ต้น' });
      }
    }

    // 2.3) รายรับ-รายจ่ายที่บันทึกเอง
    const addFinance = async (date, type, category, amount, description, gardenId = null) => {
      if (!inHistory(date)) return;
      await conn.query(
        `INSERT INTO finance (finance_id, user_id, garden_id, record_type, amount, expense_category, description, record_date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [nextId('finance'), userId, gardenId, type, round2(amount), category, description, date]
      );
      counts.finance++;
      addLog(userId, 'ADD_FINANCE', date);
    };

    const totalTrees = f.gardens.reduce((s, g) => s + g.trees, 0);
    for (const m of monthsInRange()) {
      const month = monthOf(m);
      // ค่าจ้างตัดปาล์มรายเดือนของแต่ละแปลง
      for (const g of f.gardens) {
        if (ageFactor(g.plantYear, m) === 0) continue;
        const wage = Math.round((g.area * 135 * 2 * SEASON[month - 1] * ageFactor(g.plantYear, m) * 0.5) / 50) * 50;
        await addFinance(dayIn(m, 28), 'EXPENSE', 'ค่าแรงงาน', wage, `ค่าจ้างตัดปาล์ม ${thaiMonth(m)}`, g.id);
      }
      await addFinance(dayIn(m, randInt(10, 25)), 'EXPENSE', 'ค่าน้ำมัน/เชื้อเพลิง', Math.round(totalTrees * 1.6 + randInt(-100, 200)), 'ค่าน้ำมันรถขนปาล์ม');
      if (month === 6) await addFinance(dayIn(m, 15), 'INCOME', 'เงินอุดหนุน', 1000 * Math.min(20, f.gardens.reduce((s, g) => s + g.area, 0)) / 2, 'เงินช่วยเหลือเกษตรกรชาวสวนปาล์ม');
      if (month === 3) await addFinance(dayIn(m, 30), 'EXPENSE', 'รายจ่ายอื่นๆ', 650, 'ภาษีที่ดินและสิ่งปลูกสร้าง');
      if (month === 8 || month === 12) await addFinance(dayIn(m, 12), 'INCOME', 'รายรับอื่นๆ', randInt(12, 20) * 100, 'ขายทางปาล์มให้ฟาร์มวัว', f.gardens[0].id);
    }
    await addFinance(`${yearOf(START)}-02-10`, 'EXPENSE', 'ค่าอุปกรณ์', 8500, 'ซื้อเครื่องตัดหญ้า');
    await addFinance(`${yearOf(START)}-10-03`, 'EXPENSE', 'ค่าอุปกรณ์', 650, 'เสียมแทงปาล์มอันใหม่', f.gardens[0].id);
    await addFinance(`${yearOf(TODAY)}-05-21`, 'EXPENSE', 'ค่าอุปกรณ์', 1200, 'ซ่อมรถเข็นปาล์ม');

    // 2.4) เข้าสู่ระบบทุก 2-4 วัน
    for (let d = addDays(TODAY, -180); inHistory(d); d = addDays(d, randInt(2, 4))) addLog(userId, 'LOGIN', d);
  }

  for (const s of SHOPS) {
    for (let d = addDays(TODAY, -180); d <= TODAY; d = addDays(d, randInt(1, 3))) addLog(s.userId, 'LOGIN', d);
  }

  // 3) ประวัติการใช้งาน เรียงตามเวลา แล้วให้รหัสตามลำดับ
  logs.sort((a, b) => a[2].localeCompare(b[2]));
  for (const [userId, action, at] of logs) {
    await conn.query(`INSERT INTO user_log (log_id, user_id, action, ip_address, log_date) VALUES (?, ?, ?, ?, ?)`,
      [nextId('log'), userId, action, `192.168.1.${randInt(20, 60)}`, at]);
  }
  return { ...counts, log: logs.length };
}

(async () => {
  const removeOnly = process.argv.includes('--remove');
  let conn;
  try {
    conn = await db.getConnection();
    await conn.beginTransaction();
    const removed = await removeDemo(conn);
    if (removed) console.log(`🧹 ลบข้อมูลเดโมเดิม (${removed} บัญชี)`);
    if (!removeOnly) {
      const c = await createDemo(conn);
      console.log(`✅ สร้างข้อมูลเดโม ${START} ถึง ${TODAY}`);
      console.log(`   เก็บเกี่ยว ${c.harvest} | รับซื้อ ${c.purchase} | ดูแลสวน ${c.care} | การเงิน ${c.finance} | log ${c.log}`);
      console.log(`   บัญชี (รหัสผ่าน ${PASSWORD}): ${DEMO_USERNAMES.join(', ')}`);
    }
    await conn.commit();
  } catch (error) {
    if (conn) await conn.rollback().catch(() => {});
    console.error('❌ ไม่สำเร็จ (ย้อนกลับทั้งหมดแล้ว):', error.message);
    process.exitCode = 1;
  } finally {
    if (conn) conn.release();
    await db.end();
  }
})();
