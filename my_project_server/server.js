const http = require('http');
const express = require('express');
const app = express();

app.use(express.json());
const hostname = '127.0.0.1';
const port = 3000;

const server = http.createServer((req, res) => {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('Hello World\n');
});

server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname}:${port}/`);
});




// server.js
app.post('/api/register', (req, res) => {
  const { role, full_name, id_card, phone, username, password } = req.body;
  
  // 1. ตรวจสอบข้อมูล
  if (!username || !password) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
  }
  
  // 2. บันทึกลงฐานข้อมูล
  // INSERT INTO users ...
  
  // 3. ตอบกลับ
  res.status(201).json({ 
    message: 'สมัครสมาชิกสำเร็จ',
    user: { id: 1, username: username }
  });
});