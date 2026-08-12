const express = require('express');
const router = express.Router();
const dbPool = require('../libs/db_pool');

// GET /api/profile/:user_id
router.get('/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    console.log('🔵 [Profile API] Request user_id:', user_id);

    // ดึงข้อมูล user
    const query = `
      SELECT 
        u.user_id,
        u.full_name,
        u.username,
        u.phone,
        u.citizen_id,
        u.created_at,
        r.role_id,
        r.role_name
      FROM \`user\` u
      JOIN \`role\` r ON u.role_id = r.role_id
      WHERE u.user_id = ?
    `;

    const result = await dbPool.query(query, [user_id]);
    console.log('🟢 [Profile API] Raw result:', JSON.stringify(result, null, 2));

    // 🔧 รองรับหลายรูปแบบการ return ของ dbPool
    let user = null;

    // รูปแบบ 1: result = { user_id: 'U001', full_name: '...' } (object ตรงๆ)
    if (result && typeof result === 'object' && !Array.isArray(result) && result.user_id) {
      user = result;
      console.log('🟢 [Profile API] Mode 1: Object directly');
    }
    // รูปแบบ 2: result = [{ user_id: 'U001', ... }] (array มี 1 element)
    else if (Array.isArray(result) && result.length === 1 && result[0].user_id) {
      user = result[0];
      console.log('🟢 [Profile API] Mode 2: Array with object');
    }
    // รูปแบบ 3: result = [[{ user_id: 'U001', ... }], fields] (mysql2/promise)
    else if (Array.isArray(result) && Array.isArray(result[0]) && result[0].length > 0) {
      user = result[0][0];
      console.log('🟢 [Profile API] Mode 3: [rows, fields]');
    }
    // รูปแบบ 4: result = [rows] ที่ rows เป็น array
    else if (Array.isArray(result) && result[0] && typeof result[0] === 'object' && result[0].user_id) {
      user = result[0];
      console.log('🟢 [Profile API] Mode 4: Array[0] is object');
    }

    console.log('🟢 [Profile API] Parsed user:', user);

    if (!user || !user.user_id) {
      console.log('🟡 [Profile API] User not found');
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลผู้ใช้'
      });
    }

    // นับจำนวนสวน
    let gardenCount = 0;
    try {
      const gardenResult = await dbPool.query(
        'SELECT COUNT(*) as count FROM garden WHERE user_id = ?',
        [user_id]
      );

      let gCount = 0;
      if (gardenResult && typeof gardenResult === 'object' && !Array.isArray(gardenResult)) {
        gCount = gardenResult.count || 0;
      } else if (Array.isArray(gardenResult) && gardenResult.length > 0) {
        if (gardenResult[0] && typeof gardenResult[0] === 'object') {
          gCount = gardenResult[0].count || 0;
        }
      }
      gardenCount = gCount;
    } catch (gardenErr) {
      console.log('🟡 [Profile API] Garden count error:', gardenErr.message);
    }

    // จัดรูปแบบวันที่
    let memberSince = '-';
    try {
      if (user.created_at) {
        memberSince = new Date(user.created_at).toLocaleDateString('th-TH', {
          day: 'numeric',
          month: 'long',
          year: 'numeric'
        });
      }
    } catch (dateErr) {
      console.log('🟡 [Profile API] Date format error:', dateErr.message);
    }

    const response = {
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
    };

    console.log('🟢 [Profile API] Response:', JSON.stringify(response, null, 2));
    res.json(response);

  } catch (error) {
    console.error('🔴 [Profile API] Error:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล',
      error: error.message
    });
  }
});

module.exports = router;