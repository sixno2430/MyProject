// ============================================================
// backup_db.js — สำรอง / กู้คืนฐานข้อมูล (ขอบเขตแอดมิน: การสำรองและกู้คืนข้อมูลระบบ)
//
// ใช้ mysqldump / mysql ของเครื่อง อ่านค่าการเชื่อมต่อจาก .env (ผ่าน libs/config.js)
// ไฟล์สำรองเก็บที่โฟลเดอร์ backups/ (ไม่ขึ้น git เพราะมีข้อมูลผู้ใช้)
//
// วิธีรัน (ในโฟลเดอร์ my_project_server):
//   node scripts/backup_db.js                          สำรอง -> backups/palm_oil_db_YYYYMMDD_HHMMSS.sql
//   node scripts/backup_db.js restore <ไฟล์.sql> --yes  กู้คืนจากไฟล์ (ข้อมูลปัจจุบันจะถูกแทนที่ทั้งหมด)
//   node scripts/backup_db.js check                    นับจำนวนแถวแต่ละตาราง ไว้เทียบหลังกู้คืน
// ============================================================

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const config = require('../libs/config');

const BACKUP_DIR = path.join(__dirname, '..', 'backups');
const { host, port, user, password, database } = config.db;

// ส่งรหัสผ่านผ่าน env (MYSQL_PWD) ไม่ใส่ในบรรทัดคำสั่ง จะได้ไม่โผล่ในรายการ process
const env = { ...process.env, MYSQL_PWD: password };
const connArgs = ['-h', host, '-P', String(port), '-u', user];

function run(cmd, args, { stdin, stdout } = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { env, stdio: [stdin ? 'pipe' : 'ignore', stdout ? 'pipe' : 'inherit', 'pipe'] });
    let err = '';
    child.stderr.on('data', (d) => (err += d));
    if (stdout) child.stdout.pipe(stdout);
    if (stdin) stdin.pipe(child.stdin);
    child.on('error', (e) => reject(new Error(`เรียก ${cmd} ไม่ได้ (${e.message}) ติดตั้ง MySQL client แล้วหรือยัง`)));
    child.on('close', (code) => (code === 0 ? resolve() : reject(new Error(err.trim() || `${cmd} จบด้วย code ${code}`))));
  });
}

function stamp() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  // ใส่วินาทีด้วย ไม่งั้นสำรองซ้ำในนาทีเดียวกันจะทับไฟล์เดิม (รวมถึงไฟล์ที่กำลังจะกู้คืน)
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

// MySQL ที่เปิด GTID จะใส่ SET @@GLOBAL.GTID_PURGED ในไฟล์ ทำให้กู้คืนกลับเครื่องเดิมไม่ได้
// ปิดด้วย --set-gtid-purged=OFF (เฉพาะ mysqldump ของ MySQL, ของ MariaDB ไม่มีตัวเลือกนี้)
function gtidArgs() {
  const help = require('child_process').spawnSync('mysqldump', ['--help'], { encoding: 'utf8' });
  return (help.stdout || '').includes('set-gtid-purged') ? ['--set-gtid-purged=OFF'] : [];
}

async function backup() {
  fs.mkdirSync(BACKUP_DIR, { recursive: true });
  const file = path.join(BACKUP_DIR, `${database}_${stamp()}.sql`);
  const out = fs.createWriteStream(file);
  // --single-transaction: สำรองได้โดยไม่ล็อกตาราง (แอปยังใช้งานได้ระหว่างสำรอง)
  // --routines --triggers: เก็บ view/trigger ไปด้วย (มี view v_garden, v_financial_transactions)
  await run('mysqldump', [...connArgs, ...gtidArgs(), '--single-transaction', '--routines', '--triggers', database], { stdout: out });
  await new Promise((r) => out.end(r));
  const kb = (fs.statSync(file).size / 1024).toFixed(1);
  console.log(`✅ สำรองแล้ว: ${path.relative(process.cwd(), file)} (${kb} KB)`);
  return file;
}

async function restore(file, confirmed) {
  if (!file || !fs.existsSync(file)) throw new Error('ไม่พบไฟล์สำรอง: ' + (file || '(ไม่ได้ระบุ)'));
  if (!confirmed) {
    throw new Error('การกู้คืนจะแทนที่ข้อมูลปัจจุบันทั้งหมด ถ้าแน่ใจให้เติม --yes ท้ายคำสั่ง');
  }
  // สำรองของปัจจุบันไว้ก่อนเสมอ เผื่อกู้ผิดไฟล์
  console.log('สำรองข้อมูลปัจจุบันไว้ก่อนกู้คืน...');
  const before = await backup();
  if (path.resolve(before) === path.resolve(file)) throw new Error('ไฟล์สำรองชนกับไฟล์ที่จะกู้คืน ลองใหม่อีกครั้ง');
  await run('mysql', [...connArgs, database], { stdin: fs.createReadStream(file) });
  console.log(`✅ กู้คืนจาก ${file} แล้ว`);
  await check();
}

// ตรวจความถูกต้องหลังกู้คืน: นับแถวทุกตาราง
async function check() {
  const db = require('../libs/db_pool');
  try {
    const tables = await db.query(
      `SELECT TABLE_NAME AS t FROM information_schema.TABLES
       WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME`
    );
    for (const { t } of tables) {
      const rows = await db.query(`SELECT COUNT(*) AS n FROM \`${t}\``);
      console.log(`  ${t.padEnd(20)} ${Number(rows[0].n)} แถว`);
    }
  } finally {
    await db.end();
  }
}

(async () => {
  const [cmd, file, flag] = process.argv.slice(2);
  try {
    if (!cmd || cmd === 'backup') await backup();
    else if (cmd === 'restore') await restore(file, flag === '--yes');
    else if (cmd === 'check') await check();
    else throw new Error('คำสั่งที่ใช้ได้: backup | restore <ไฟล์> --yes | check');
  } catch (error) {
    console.error('❌', error.message);
    process.exitCode = 1;
  }
})();
