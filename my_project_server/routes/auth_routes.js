// ============================================================
// auth_routes.js — API สมัครสมาชิก / เข้าสู่ระบบ / เปลี่ยนรหัสผ่าน
//
// POST /api/register, POST /api/authen_request (ตรวจรหัสผ่าน + บทบาท + บัญชีถูกระงับ),
// POST /api/access_request (แลก access token), PUT /api/user/:user_id/password
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const userAccount = require('../models/user_account');
const bcrypt = require('bcrypt');
const jwt = require('../libs/jwt');
const { logIfOk } = require('../libs/log_action');

const router = express.Router();

// ตอน login
// body: { username, password, role_id? }
//   role_id = บทบาทที่ผู้ใช้เลือกในหน้าล็อกอิน (R002 ชาวสวน / R003 ร้านรับซื้อ)
//   ถ้าไม่ตรงกับบทบาทจริงของบัญชี จะไม่ให้เข้าสู่ระบบ (บัญชีชาวสวนเข้าฝั่งร้านไม่ได้ และกลับกัน)
const ROLE_LABELS = { R001: 'ผู้ดูแลระบบ', R002: 'ชาวสวน', R003: 'ร้านรับซื้อ' };

// ตอนสมัครสมาชิก
router.post('/api/register', async (req, res) => {
  const { role_id, full_name, id_card, phone, username, password } = req.body;

  // สมัครเองได้แค่ เกษตรกร (R002) หรือ ร้านรับซื้อ (R003) — กันการยิง API สมัครเป็นแอดมิน (R001)
  if (role_id && !['R002', 'R003'].includes(role_id)) {
    return res.json({ isError: true, errorMessage: 'ประเภทผู้ใช้ไม่ถูกต้อง', data: null });
  }

  if (!role_id || !full_name || !id_card || !phone || !username || !password) {
    return res.json({
      isError: true,
      errorMessage: 'กรุณากรอกข้อมูลให้ครบถ้วน',
      data: null
    });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    const idResult = await userAccount.getNextUserId();
    if (idResult.isError) {
      return res.json(idResult);
    }
    const userId = idResult.data;

    const result = await userAccount.createUser(
      userId, role_id, id_card, full_name, phone, username, hashedPassword
    );
    if (!result.isError) userAccount.logAction(userId, 'REGISTER', req.ip);

    res.json(result);
  } catch (error) {
    console.error('Register error:', error);
    res.json({
      isError: true,
      errorMessage: 'เกิดข้อผิดพลาด: ' + error.message,
      data: null
    });
  }
});

router.post('/api/authen_request', async (req, res) => {
  try {
    const { username, password, role_id: requestedRole } = req.body;
    const result = await userAccount.getUserByUsername(username);

    if (result.isError || !result.data || result.data.length === 0) {
      return res.json({ isError: true, data: "", errorMessage: 'ไม่พบผู้ใช้งาน' });
    }

    const user = result.data[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.json({ isError: true, data: "", errorMessage: 'รหัสผ่านไม่ถูกต้อง' });
    }

    // บัญชีที่แอดมินระงับไว้ เข้าสู่ระบบไม่ได้
    if (user.status === 'suspended') {
      return res.json({ isError: true, data: "", errorMessage: 'บัญชีนี้ถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ' });
    }

    // ตรวจบทบาทหลังรหัสผ่านถูกแล้วเท่านั้น (ไม่บอกคนที่เดารหัสว่าบัญชีนี้เป็นบทบาทอะไร)
    // แอดมิน (R001) ไม่มีปุ่มบทบาทในหน้าล็อกอิน จึงเข้าได้ไม่ว่าจะเลือกปุ่มไหน
    if (requestedRole && requestedRole !== user.role_id && user.role_id !== 'R001') {
      const actual = ROLE_LABELS[user.role_id] || 'บทบาทอื่น';
      return res.json({
        isError: true,
        data: "",
        errorMessage: `บัญชีนี้เป็นบัญชี${actual} กรุณาเลือกบทบาท "${actual}" แล้วเข้าสู่ระบบใหม่`
      });
    }

    // ใส่ role_id ไว้ใน token ด้วย วันหลังจะใช้ตรวจสิทธิ์ API เฉพาะร้านรับซื้อ/ชาวสวนได้
    const authenToken = jwt.sign(
      { user_id: user.user_id, username: user.username, role_id: user.role_id },
      '5m'
    );

    // เก็บประวัติเข้าสู่ระบบ ให้แอดมินดูสถานะการใช้งานล่าสุดของแต่ละคน
    await userAccount.logAction(user.user_id, 'LOGIN', req.ip);

    res.json({
      isError: false, 
      data: authenToken, 
      user_id: user.user_id,
      role_id: user.role_id, 
      errorMessage: "" 
    });
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message, data: "" });
  }
});

// แลก accessToken
router.post('/api/access_request', async (req, res) => {
  const { token } = req.body;
  try {
    const decoded = await jwt.verify(token);
    const accessToken = jwt.sign(
      { user_id: decoded.user_id, username: decoded.username, role_id: decoded.role_id },
      '1d'
    );
    res.json({ isError: false, data: accessToken, errorMessage: "" });
  } catch (error) {
    res.json({ isError: true, data: "", errorMessage: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
});

/** เปลี่ยนรหัสผ่าน body: { old_password, new_password } */
router.put('/api/user/:user_id/password', async (req, res) => {
  try {
    const { old_password, new_password } = req.body;
    if (!old_password || !new_password) {
      return res.json({ isError: true, errorMessage: 'กรุณากรอกรหัสผ่านให้ครบ' });
    }
    if (new_password.length < 8) {
      return res.json({ isError: true, errorMessage: 'รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัว' });
    }
    const result = await userAccount.changePassword(req.params.user_id, old_password, new_password);
    logIfOk(result, req.params.user_id, 'CHANGE_PASSWORD', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
