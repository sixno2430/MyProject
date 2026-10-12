// ============================================================
// log_action.js — บันทึกประวัติการใช้งาน (ตาราง user_log) เมื่อทำรายการสำเร็จ
//
// ใช้ใน route ที่เพิ่ม/แก้/ลบข้อมูล หน้า "ประวัติการใช้งานระบบ" ของแอดมินอ่านจากตารางนี้
// บันทึกไม่สำเร็จก็ไม่กระทบรายการหลัก (logAction จัดการ error เอง)
// ============================================================

const userAccount = require('../models/user_account');

function logIfOk(result, userId, action, req) {
  if (result && !result.isError) userAccount.logAction(userId, action, req.ip);
}

module.exports = { logIfOk };
