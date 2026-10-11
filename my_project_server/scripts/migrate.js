// ============================================================
// migrate.js — ปรับโครงสร้างฐานข้อมูลให้ตรงกับโค้ดล่าสุด (รันซ้ำได้ ส่วนที่มีแล้วจะข้าม)
//
// วิธีรัน (ในโฟลเดอร์ my_project_server):  node scripts/migrate.js
//
// รายการที่ทำ:
//   1) user.status            สถานะบัญชี 'active' / 'suspended' (แอดมินระงับบัญชี)
//   2) palm_care.detail       รายละเอียดตามประเภทกิจกรรม เช่น วิธีให้น้ำ, ชื่อสารที่พ่น, วิธีกำจัดวัชพืช
//   3) ตาราง care_fertilizer  ปุ๋ยแต่ละชนิดในการใส่ปุ๋ย 1 ครั้ง (ใส่ได้หลายชนิดในรอบเดียว)
//   4) ย้ายปุ๋ยของรายการใส่ปุ๋ยแบบเก่า (palm_care.fertilizer_id ตัวเดียว) ไปไว้ใน care_fertilizer
//      ประวัติเดิมจะได้แสดงชื่อปุ๋ยเหมือนรายการใหม่ และชื่อนั้นขึ้นเป็นปุ๋ยแนะนำของเจ้าของแปลง
// ============================================================

const db = require('../libs/db_pool');

async function hasColumn(table, column) {
  const rows = await db.query(
    `SELECT COUNT(*) AS n FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  return Number(rows[0].n) > 0;
}

async function hasTable(table) {
  const rows = await db.query(
    `SELECT COUNT(*) AS n FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?`,
    [table]
  );
  return Number(rows[0].n) > 0;
}

const steps = [
  {
    name: 'user.status',
    done: () => hasColumn('user', 'status'),
    sql: `ALTER TABLE user ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active'`,
  },
  {
    name: 'palm_care.detail',
    done: () => hasColumn('palm_care', 'detail'),
    sql: `ALTER TABLE palm_care ADD COLUMN detail VARCHAR(200) NULL AFTER quantity_type`,
  },
  {
    name: 'ตาราง care_fertilizer',
    done: () => hasTable('care_fertilizer'),
    // line_no = ลำดับปุ๋ยในรายการนั้น (1, 2, 3 ...)
    // fertilizer_id มีค่าเมื่อชื่อตรงกับตาราง fertilizer, ปุ๋ยที่พิมพ์เองจะเก็บแค่ชื่อ
    // ลบรายการดูแลสวน -> ปุ๋ยในรายการนั้นถูกลบตาม (ON DELETE CASCADE)
    sql: `CREATE TABLE care_fertilizer (
            care_id         VARCHAR(10)   NOT NULL,
            line_no         INT           NOT NULL,
            fertilizer_id   VARCHAR(10)   NULL,
            fertilizer_name VARCHAR(100)  NOT NULL,
            quantity        DECIMAL(10,2) NOT NULL DEFAULT 0,
            unit            VARCHAR(20)   NOT NULL DEFAULT 'กก.',
            PRIMARY KEY (care_id, line_no),
            CONSTRAINT fk_cf_care FOREIGN KEY (care_id) REFERENCES palm_care (care_id) ON DELETE CASCADE,
            CONSTRAINT fk_cf_fertilizer FOREIGN KEY (fertilizer_id) REFERENCES fertilizer (fertilizer_id) ON DELETE SET NULL
          ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`,
  },
  {
    name: 'ย้ายปุ๋ยของรายการเก่าไป care_fertilizer',
    done: async () => {
      const rows = await db.query(
        `SELECT COUNT(*) AS n FROM palm_care c
         WHERE c.fertilizer_id IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM care_fertilizer cf WHERE cf.care_id = c.care_id)`
      );
      return Number(rows[0].n) === 0;
    },
    sql: [
      `INSERT INTO care_fertilizer (care_id, line_no, fertilizer_id, fertilizer_name, quantity, unit)
       SELECT c.care_id, 1, c.fertilizer_id, f.fertilizer_name, COALESCE(c.quantity, 0),
              IF(c.quantity_type IS NULL OR c.quantity_type = '' OR c.quantity_type = 'กิโลกรัม', 'กก.', c.quantity_type)
       FROM palm_care c JOIN fertilizer f ON f.fertilizer_id = c.fertilizer_id
       WHERE NOT EXISTS (SELECT 1 FROM care_fertilizer cf WHERE cf.care_id = c.care_id)`,
      // รายการเก่าบางรายการไม่มี action_type -> มีปุ๋ย = ใส่ปุ๋ย
      `UPDATE palm_care SET action_type = 'fertilizer' WHERE fertilizer_id IS NOT NULL AND action_type IS NULL`,
    ],
  },
];

(async () => {
  try {
    for (const step of steps) {
      if (await step.done()) {
        console.log(`• ${step.name} มีอยู่แล้ว`);
      } else {
        for (const sql of [].concat(step.sql)) await db.query(sql); // sql เป็นคำสั่งเดียวหรือหลายคำสั่งก็ได้
        console.log(`✅ เพิ่ม ${step.name} แล้ว`);
      }
    }
  } catch (error) {
    console.error('❌ ปรับฐานข้อมูลไม่สำเร็จ:', error.message);
    process.exitCode = 1;
  } finally {
    await db.end();
  }
})();
