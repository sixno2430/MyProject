// ============================================================
// profile_routes.js — API โปรไฟล์ผู้ใช้ (ผูกไว้ที่ /api/profile ใน server.js)
//
// GET /api/profile/:user_id -> ข้อมูลผู้ใช้ + บทบาท + วันที่สมัคร + จำนวนแปลงสวน
// PUT /api/profile/:user_id -> แก้ไขชื่อ-นามสกุล และเบอร์โทร
// ============================================================

const express = require('express');
const router = express.Router();

// /:user_id ต้องเป็นของคนที่ล็อกอินอยู่ (router แยกไฟล์ จึงต้องผูก param เองไม่ได้รับจาก app.param)
router.param('user_id', require('../libs/auth').checkUserParam);
const dbPool = require('../libs/db_pool');
const userAccount = require('../models/user_account');

// GET /api/profile/:user_id
router.get('/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;

    // ข้อมูล user + ชื่อบทบาท (mariadb คืน array ของแถวเสมอ)
    const rows = await dbPool.query(`
      SELECT u.user_id, u.full_name, u.username, u.phone, u.citizen_id, u.created_at,
             r.role_id, r.role_name
      FROM \`user\` u
      JOIN \`role\` r ON u.role_id = r.role_id
      WHERE u.user_id = ?
    `, [user_id]);
    const user = rows[0];
    if (!user) {
      return res.status(404).json({ success: false, message: 'ไม่พบข้อมูลผู้ใช้' });
    }

    // จำนวนแปลงสวน (COUNT ได้ BigInt -> แปลงเป็น number)
    const gardenRows = await dbPool.query('SELECT COUNT(*) AS count FROM garden WHERE user_id = ?', [user_id]);
    const gardenCount = Number(gardenRows[0]?.count || 0);

    // วันที่สมัคร เช่น "3 สิงหาคม 2569"
    const memberSince = user.created_at
      ? new Date(user.created_at).toLocaleDateString('th-TH', { day: 'numeric', month: 'long', year: 'numeric' })
      : '-';

    res.json({
      success: true,
      profile: {
        user_id: user.user_id,
        full_name: user.full_name,
        username: user.username,
        phone: user.phone,
        citizen_id: user.citizen_id,
        role: {
          role_id: user.role_id,
          role_name: user.role_name
        },
        member_since: memberSince,
        garden_count: gardenCount
      }
    });

  } catch (error) {
    console.error('🔴 [Profile API] Error:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล',
      error: error.message
    });
  }
});

/**
 * แก้ไขชื่อ-นามสกุล และเบอร์โทร
 * body: { full_name, phone }  ตอบกลับ { success, message } ตามที่แอป (ProfileService) รอรับ
 */
router.put('/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const fullName = (req.body.full_name || '').trim();
    const phone = (req.body.phone || '').trim().replace(/-/g, '');

    if (!fullName) {
      return res.json({ success: false, message: 'กรุณากรอกชื่อ-นามสกุล' });
    }
    if (!/^0\d{8,9}$/.test(phone)) {
      return res.json({ success: false, message: 'เบอร์โทรไม่ถูกต้อง (ต้องขึ้นต้นด้วย 0 และมี 9-10 หลัก)' });
    }

    const result = await userAccount.updateUser(user_id, fullName, phone);
    if (result.isError) {
      console.error('🔴 [Profile API] Update error:', result.errorMessage);
      return res.json({ success: false, message: 'บันทึกข้อมูลไม่สำเร็จ' });
    }
    if (!result.data || !result.data.affectedRows) {
      return res.json({ success: false, message: 'ไม่พบผู้ใช้นี้' });
    }
    res.json({ success: true, message: 'บันทึกข้อมูลเรียบร้อยแล้ว' });
  } catch (error) {
    console.error('🔴 [Profile API] Update error:', error);
    res.status(500).json({ success: false, message: 'เกิดข้อผิดพลาดในการบันทึกข้อมูล' });
  }
});

module.exports = router;
