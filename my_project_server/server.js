const http = require('http');
const express = require('express');
const bp = require('body-parser');
const bcrypt = require('bcrypt');
const userAccount = require('./models/user_account');

const app = express();
app.use(bp.json());
app.use(bp.urlencoded({ extended: true }));

const hostname = '127.0.0.1';
const port = 3000;


app.get("/api/users", (req, res) => {
    var response = {
      isEror: true,
      data: "You are unauthorized for this data"
    };

    res.json(JSON.stringify(response));
});

app.post("/api/multiple_by_2", (req, res) => {
    var response = {
        isError: false,
        data: {
            no1: req.body.no_1 * 2,
            no2: req.body.no_2 * 2
        }
    };

    res.send(JSON.stringify(response));
});

app.get("/api/users", async (req, res) => {
       const response = await userAccount.getUsers();
       res.json(response);

}); 


//ตอนสมัครสมาชิก
app.post('/api/register', async (req, res) => {
  const { role_id, full_name, id_card, phone, username, password } = req.body;

  const hashedPassword = await bcrypt.hash(password, 10);

  const result = await userAccount.createUser(
    userId, role_id, id_card, full_name, phone, username, hashedPassword
  );

  res.json(result);
});

//ตอน login
app.post('/api/authen_request', async (req, res) => {
  const { username, password } = req.body;

  const result = await userAccount.getUserByUsername(username);

  if (result.isError || result.data.length === 0) {
    return res.json({ isError: true, errorMessage: 'ไม่พบผู้ใช้งาน' });
  }

  const user = result.data[0];
  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    return res.json({ isError: true, errorMessage: 'รหัสผ่านไม่ถูกต้อง' });
  }

  // password ถูกต้อง → ไปต่อขั้นตอนออก token (JWT) จาก libs/jwt.js
  res.json({ isError: false, data: { user_id: user.user_id, username: user.username } });
});

app.listen(port,  () => {
  console.log(`Server running at http://${hostname}:${port}`);
});




// server.js
// app.post('/api/register', (req, res) => {
//   const { role, full_name, id_card, phone, username, password } = req.body;
  
//   // 1. ตรวจสอบข้อมูล
//   if (!username || !password) {
//     return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
//   }
  
//   // 2. บันทึกลงฐานข้อมูล
//   // INSERT INTO users ...
  
//   // 3. ตอบกลับ
//   res.status(201).json({ 
//     message: 'สมัครสมาชิกสำเร็จ',
//     user: { id: 1, username: username }
//   });
// });