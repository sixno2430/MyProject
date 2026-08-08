var jwt = require('jsonwebtoken');
var secretKey = "MySecretKey";

module.exports = {
  // payload = ข้อมูลที่จะฝังใน token เช่น { user_id, username }
  // expiresIn = อายุ token เช่น '5m' (5 นาที), '1d' (1 วัน)
  sign(payload, expiresIn = '1d') {
    let token = jwt.sign(payload, secretKey, {
      expiresIn: expiresIn
    });
    return token;
  },
 
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