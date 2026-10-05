-- ============================================================
-- 001_setup_roles.sql — จัดบทบาทผู้ใช้ให้เหลือ 3 แบบ
--
--   R001 = แอดมิน      (ผู้ดูแลระบบ)
--   R002 = เกษตรกร     (เจ้าของสวน)
--   R003 = ร้านรับซื้อ   (ลานเทปาล์ม)
--
-- ของเดิม: R002 = Owner, R003 = Farmer และบางเครื่องอาจมี R004 = Buyer
-- ไฟล์นี้รันซ้ำได้ และรันได้ทั้งเครื่องที่มีหรือไม่มี R004
--
-- วิธีรัน:
--   HeidiSQL: File > Run SQL file... แล้วเลือกไฟล์นี้
--   หรือ terminal: mysql -u root palm_oil_db < sql/001_setup_roles.sql
-- ทุกคนในทีมต้องรันบนฐานข้อมูลของตัวเอง
-- ============================================================

-- 1) เปลี่ยนชื่อบทบาทเป็นภาษาไทย (ชื่อนี้แสดงในหน้าโปรไฟล์)
UPDATE role SET role_name = 'แอดมิน',     role_description = 'ผู้ดูแลระบบ'             WHERE role_id = 'R001';
UPDATE role SET role_name = 'เกษตรกร',    role_description = 'เกษตรกร / เจ้าของสวน'      WHERE role_id = 'R002';
UPDATE role SET role_name = 'ร้านรับซื้อ', role_description = 'ร้านรับซื้อ / ลานเทปาล์ม' WHERE role_id = 'R003';

-- 2) ผู้ใช้ทดสอบ U003 เป็นเกษตรกร (เดิมอยู่ R003 ซึ่งตอนนี้กลายเป็นร้านรับซื้อ)
UPDATE user SET role_id = 'R002' WHERE user_id = 'U003' AND full_name = 'ทดสอบ ระบบ';

-- 3) ใครที่อยู่ R004 (ร้านรับซื้อแบบเก่า) ย้ายมา R003 ก่อน แล้วค่อยลบ R004
--    ต้องย้ายก่อน เพราะ user.role_id ผูก foreign key กับตาราง role
UPDATE user SET role_id = 'R003' WHERE role_id = 'R004';
DELETE FROM role WHERE role_id = 'R004';
