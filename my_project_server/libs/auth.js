// ============================================================
// auth.js — ตรวจ JWT ทุก request ของ /api (ยกเว้นล็อกอิน/สมัคร)
//
// แอปแนบ token มาใน header:  Authorization: Bearer <access token>
// ตรวจผ่านแล้ว:
//   - req.user = { user_id, role_id } จาก token (เชื่อได้ เพราะเซ็นด้วย JWT_SECRET ของเซิร์ฟเวอร์)
//   - เขียนทับ user_id ใน query/body ด้วยค่าจาก token
//     เดิมเซิร์ฟเวอร์เชื่อ user_id ที่แอปส่งมา ใครยิง API เองก็ปลอมเป็นคนอื่นได้
//     ทับตรงนี้ที่เดียว model เดิมทุกตัวที่ใช้ user_id จึงปลอดภัยโดยไม่ต้องแก้ทีละ route
// token ผิด/หมดอายุ/ไม่มี -> 401 แอปจะพากลับไปหน้าล็อกอิน
// ============================================================

const jwt = require('./jwt');
const db = require('./db_pool');

/** route ที่เรียกได้โดยไม่ต้องล็อกอิน */
const PUBLIC_PATHS = new Set(['/api/register', '/api/authen_request', '/api/access_request']);

const unauthorized = (res, msg) => res.status(401).json({ isError: true, data: null, errorMessage: msg });
const forbidden = (res, msg) => res.status(403).json({ isError: true, data: null, errorMessage: msg });

/** middleware หลัก: ใช้กับทุก request (app.use) */
async function requireAuth(req, res, next) {
  if (!req.path.startsWith('/api/') || PUBLIC_PATHS.has(req.path)) return next();

  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return unauthorized(res, 'กรุณาเข้าสู่ระบบ');

  let decoded;
  try {
    decoded = await jwt.verify(token);
  } catch (_) {
    return unauthorized(res, 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
  }
  req.user = { user_id: decoded.user_id, role_id: decoded.role_id };

  // Express 5: req.query เป็น getter (กำหนดค่าตรงๆ ไม่ได้) -> สร้าง property ใหม่ทับ
  Object.defineProperty(req, 'query', {
    value: { ...req.query, user_id: decoded.user_id },
    writable: true,
    configurable: true,
    enumerable: true,
  });
  if (req.body && typeof req.body === 'object' && !Array.isArray(req.body)) {
    req.body.user_id = decoded.user_id;
  }
  next();
}

/** app.param('user_id'): URL ที่มี :user_id ต้องเป็นของคนที่ล็อกอินอยู่ */
function checkUserParam(req, res, next, userId) {
  if (req.user && userId !== req.user.user_id) return forbidden(res, 'ไม่มีสิทธิ์ดูข้อมูลของผู้ใช้อื่น');
  next();
}

/** app.param('shop_id'): URL ที่มี :shop_id ต้องเป็นร้านของคนที่ล็อกอินอยู่ */
async function checkShopParam(req, res, next, shopId) {
  try {
    const rows = await db.query(`SELECT shop_id FROM shop WHERE shop_id = ? AND user_id = ?`, [shopId, req.user?.user_id]);
    if (rows.length === 0) return forbidden(res, 'ไม่มีสิทธิ์เข้าถึงข้อมูลร้านนี้');
    next();
  } catch (error) {
    res.status(500).json({ isError: true, data: null, errorMessage: 'ตรวจสิทธิ์ร้านไม่สำเร็จ' });
  }
}

/** ใช้กับ /api/shop/* : ต้องเป็นบัญชีร้านรับซื้อ (R003) */
function requireShopRole(req, res, next) {
  if (req.user?.role_id !== 'R003') return forbidden(res, 'เฉพาะบัญชีร้านรับซื้อเท่านั้น');
  next();
}

module.exports = { requireAuth, checkUserParam, checkShopParam, requireShopRole };
