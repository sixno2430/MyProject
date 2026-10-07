// ============================================================
// jwt.js — สร้างและตรวจสอบ JWT token (ห่อ jsonwebtoken ไว้ พร้อม secret key)
// ============================================================

var jwt = require('jsonwebtoken');
// secret อ่านจาก .env (เดิมเขียนไว้ในโค้ด ใครเห็นโค้ดก็ปลอม token ได้)
var secretKey = require('./config').jwtSecret;

module.exports = {
  // payload = ข้อมูลที่จะฝังใน token เช่น { user_id, username }
  // expiresIn = อายุ token เช่น '5m' (5 นาที), '1d' (1 วัน)
  sign(payload, expiresIn = '1d') {
    let token = jwt.sign(payload, secretKey, {
      expiresIn: expiresIn
    });
    return token;
  },
 
  /**
   * ตรวจ token คืน Promise ของข้อมูลที่ฝังไว้ (reject ถ้า token ผิดหรือหมดอายุ)
   */
  verify(token) {
    return new Promise((resolve, reject) => {
      jwt.verify(token, secretKey, (err, decoded) => {
        if (err) {
          reject(err)
        } else {
          resolve(decoded)
        }
      });
    });
  }
}