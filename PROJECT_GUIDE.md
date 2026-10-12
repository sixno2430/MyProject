# คู่มืออ่านโค้ด PalmTrack

ระบบจัดการสวนปาล์มน้ำมันในชุมชน (Community Palm Oil Plantation Management System) · กลุ่ม G24

เอกสารนี้อธิบายว่าโปรเจกต์ทำงานยังไง แต่ละไฟล์ทำอะไร และถ้าจะแก้เรื่องไหนต้องไปเปิดไฟล์ไหน อ่านตามลำดับหัวข้อได้เลย หรือข้ามไปหัวข้อ [อยากแก้เรื่องนี้ ไปไฟล์ไหน](#11-อยากแก้เรื่องนี้-ไปไฟล์ไหน) ถ้ารู้อยู่แล้วว่าจะแก้อะไร

## สารบัญ

1. [ภาพรวมระบบ](#1-ภาพรวมระบบ)
2. [รันโปรเจกต์บนเครื่องตัวเอง](#2-รันโปรเจกต์บนเครื่องตัวเอง)
3. [โครงสร้างโฟลเดอร์](#3-โครงสร้างโฟลเดอร์)
4. [ข้อมูลเดินทางยังไง (ตัวอย่าง 1 ฟีเจอร์ตั้งแต่ต้นจนจบ)](#4-ข้อมูลเดินทางยังไง)
5. [ฐานข้อมูล](#5-ฐานข้อมูล)
6. [แอป Flutter ทีละไฟล์](#6-แอป-flutter-ทีละไฟล์)
7. [Server ทีละไฟล์](#7-server-ทีละไฟล์)
8. [รายการ API ทั้งหมด](#8-รายการ-api-ทั้งหมด)
9. [สคริปต์และเทสต์](#9-สคริปต์และเทสต์)
10. [กติกาสำคัญที่ต้องรู้ก่อนแก้โค้ด](#10-กติกาสำคัญที่ต้องรู้ก่อนแก้โค้ด)
11. [อยากแก้เรื่องนี้ ไปไฟล์ไหน](#11-อยากแก้เรื่องนี้-ไปไฟล์ไหน)
12. [ทำงานร่วมกันด้วย Git](#12-ทำงานร่วมกันด้วย-git)

---

## 1. ภาพรวมระบบ

ผู้ใช้มี 3 บทบาท (ตาราง `role`):

| รหัส | บทบาท | ทำอะไรได้ |
|---|---|---|
| `R001` | ผู้ดูแลระบบ | ดูภาพรวมระบบ, เพิ่ม/แก้ไข/ระงับบัญชี, ดูประวัติการใช้งาน, ดูรายงานระบบ |
| `R002` | เกษตรกร | จัดการแปลงสวนและพันธุ์ปาล์ม, บันทึกการดูแลสวน, บันทึกเก็บเกี่ยวและขาย, การเงิน, รายงาน |
| `R003` | ร้านรับซื้อ | ข้อมูลร้าน, ตั้งราคาตามเกรด, รับซื้อหรือไม่รับล็อตที่เกษตรกรส่งมา, รายงาน |

ระบบแบ่งเป็น 3 ชั้น:

```
┌──────────────────────┐   HTTP + JSON    ┌──────────────────────────┐   SQL    ┌──────────────┐
│ แอปมือถือ (Flutter)   │ ───────────────▶ │ Server (Node.js + Express)│ ───────▶ │ MySQL        │
│ flutter_myproject/    │ ◀─────────────── │ my_project_server/        │ ◀─────── │ palm_oil_db  │
└──────────────────────┘                  └──────────────────────────┘          └──────────────┘
```

- **แอป** แสดงหน้าจอและส่ง request ไปที่ server ไม่ได้ต่อฐานข้อมูลเอง
- **server** ตรวจสิทธิ์ คำนวณ แล้วอ่าน/เขียนฐานข้อมูล
- **ฐานข้อมูล** ชื่อ `palm_oil_db` มี 15 ตาราง

เครื่องมือที่ใช้: Flutter 3.44 (Dart), Node.js 24, Express 5, MySQL 9.7 (ต่อผ่านแพ็กเกจ `mariadb`), bcrypt (เข้ารหัสรหัสผ่าน), jsonwebtoken (token ตอนล็อกอิน)

---

## 2. รันโปรเจกต์บนเครื่องตัวเอง

### ครั้งแรก

```bash
# 1) server
cd my_project_server
npm install
cp .env.example .env          # แล้วแก้รหัสผ่าน MySQL ใน .env ให้ตรงเครื่องตัวเอง
node scripts/migrate.js       # ปรับตารางให้ตรงกับโค้ดล่าสุด (รันซ้ำได้)
node scripts/create_admin.js  # สร้างบัญชีแอดมิน admin / admin1234
node scripts/seed_demo.js     # ใส่ข้อมูลตัวอย่าง (ไม่บังคับ)
node server.js                # เห็น "Server running at http://0.0.0.0:3000" = พร้อม

# 2) แอป (อีกหน้าต่าง terminal)
cd flutter_myproject
flutter pub get
flutter run
```

### ทุกครั้งที่ pull โค้ดใหม่

1. รัน `node scripts/migrate.js` (ถ้ามีการเปลี่ยนตาราง สคริปต์จะทำให้ ถ้าไม่มีก็ข้าม)
2. ปิด `node server.js` ตัวเก่า แล้วเปิดใหม่
3. หยุดแอปแล้วรันใหม่ทั้งหมด อย่าใช้แค่ hot reload เพราะถ้าไฟล์ย้ายที่หรือ model เปลี่ยน hot reload จะพัง

### บัญชีทดสอบ (หลังรัน `seed_demo.js`)

| username | รหัสผ่าน | บทบาท |
|---|---|---|
| `admin` | `admin1234` | ผู้ดูแลระบบ (เลือกปุ่มบทบาทไหนในหน้าล็อกอินก็ได้) |
| `demo_farmer` | `demo1234` | เกษตรกร 3 แปลง ข้อมูลย้อนหลังถึง ม.ค. ปีที่แล้ว |
| `demo_farmer2` | `demo1234` | เกษตรกร 1 แปลง |
| `demo_suspend` | `demo1234` | เกษตรกรที่ถูกระงับ (ล็อกอินไม่ได้) |
| `demo_shop` | `demo1234` | ร้านลานเทสุขสมบูรณ์ |
| `demo_shop2` | `demo1234` | ร้านลานเทรุ่งเรืองปาล์ม |

### แอปต่อ server ไม่ได้

ที่อยู่ server อยู่ใน `flutter_myproject/lib/config/app_config.dart` ไฟล์เดียว

- iOS Simulator / macOS / เว็บ ใช้ `localhost:3000`
- Android Emulator ใช้ `10.0.2.2:3000` (คือ localhost ของเครื่องที่รัน emulator)
- มือถือจริง ต้องแก้เป็น IP ของคอมในวง Wi-Fi เดียวกัน เช่น `http://192.168.1.10:3000/api`

ถ้าพอร์ต 3000 ถูกโปรแกรมอื่นจองอยู่ ให้ตั้ง `PORT=3001` ใน `.env` แล้วแก้ `app_config.dart` ให้ตรงกัน

---

## 3. โครงสร้างโฟลเดอร์

```
myProject/
├─ PROJECT_GUIDE.md            ← ไฟล์นี้
├─ flutter_myproject/          ← แอปมือถือ
│  ├─ lib/
│  │  ├─ main.dart             จุดเริ่มแอป
│  │  ├─ config/               ที่อยู่ server
│  │  ├─ models/               รูปร่างข้อมูล (แปลง JSON จาก server เป็น object ของ Dart)
│  │  ├─ services/             ฟังก์ชันเรียก API (ไม่มีหน้าจอ)
│  │  ├─ screens/              หน้าจอ แยกโฟลเดอร์ตามเรื่อง
│  │  │  └─ <เรื่อง>/widgets/  ชิ้นส่วนที่ใช้เฉพาะหน้าจอเรื่องนั้น
│  │  ├─ widgets/              ชิ้นส่วนที่ใช้หลายหน้า
│  │  ├─ theme/                ชุดสีตามบทบาท
│  │  └─ utils/                ฟังก์ชันช่วย (จัดรูปแบบตัวเลข/วันที่, ข้อความ error)
│  └─ test/                    เทสต์อัตโนมัติ
└─ my_project_server/          ← server
   ├─ server.js                ตั้งค่า express แล้วผูก route
   ├─ routes/                  รับ request แยกตามเรื่อง แล้วเรียก model
   ├─ models/                  SQL และการคำนวณทั้งหมด
   ├─ libs/                    ของที่ใช้ร่วมกัน (ต่อ DB, อ่าน .env, JWT, บันทึก log)
   ├─ scripts/                 สคริปต์รันมือ (migrate, สร้างแอดมิน, สำรอง DB, ข้อมูลตัวอย่าง)
   ├─ .env.example             แม่แบบค่าตั้งค่า (ตัวจริง .env ไม่ขึ้น git)
   └─ backups/                 ไฟล์สำรอง DB (ไม่ขึ้น git)
```

หลักการแบ่งไฟล์: **หน้าจอ → service → route → model → ฐานข้อมูล** แต่ละชั้นทำงานของตัวเองอย่างเดียว

| ชั้น | อยู่ที่ | หน้าที่ |
|---|---|---|
| หน้าจอ | `lib/screens/` | แสดงผล รับ input ไม่เขียน URL ของ API เอง เรียกผ่าน service เสมอ |
| service | `lib/services/` | ส่ง HTTP request แล้วแปลงคำตอบเป็น model |
| model (แอป) | `lib/models/` | class ของข้อมูล + `fromJson` |
| route | `my_project_server/routes/` | รับ request อ่านพารามิเตอร์ เรียก model ส่งคำตอบกลับ บันทึก log |
| model (server) | `my_project_server/models/` | SQL, ตรวจสิทธิ์ความเป็นเจ้าของ, คำนวณยอด |

คำตอบจาก server มีรูปแบบเดียวกันเกือบทุก API:

```json
{ "isError": false, "data": ..., "errorMessage": "" }
```

ถ้า `isError` เป็น `true` ข้อความใน `errorMessage` เป็นภาษาไทยที่โชว์ผู้ใช้ได้ทันที

---

## 4. ข้อมูลเดินทางยังไง

ตัวอย่าง: **เกษตรกรบันทึกเก็บเกี่ยวแล้วส่งให้ร้าน ร้านกดรับซื้อ**

1. เกษตรกรกรอกฟอร์มใน `screens/garden/harvest/add_harvest_screen.dart` เลือกสถานะ "รอขาย" และเลือกร้าน
2. ฟอร์มเรียก `HarvestService.saveHarvest()` (`services/harvest_service.dart`) ซึ่งส่ง `POST /api/harvests` ไปที่ server
3. `routes/harvest_routes.js` รับ request เรียก `harvest.createHarvest()` ใน `models/harvest.js`
4. model ตรวจว่าแปลงเป็นของผู้ใช้คนนี้จริง สร้างรหัส `H...` แล้ว `INSERT` ลงตาราง `harvest` ด้วย `status = 'pending'` และ `shop_id` = ร้านที่เลือก
5. route บันทึก log `ADD_HARVEST` ลงตาราง `user_log` (ผ่าน `libs/log_action.js`)
6. ฝั่งร้าน แท็บ "รับซื้อ" (`screens/shop/shop_purchase_screen.dart`) เรียก `GET /api/shop/:shopId/incoming` เห็นล็อตนี้
7. ร้านกด "รับซื้อ" แล้วกรอกน้ำหนักที่ชั่งจริงใน `record_purchase_screen.dart` แอปส่ง `POST /api/shop/purchases`
8. `models/shop.js` → `createPurchase()` ทำใน transaction เดียว:
   - ล็อกแถว harvest ไว้ (`FOR UPDATE`) กันสองร้านกดพร้อมกัน
   - `INSERT` ลงตาราง `purchase`
   - `UPDATE harvest` เป็น `sold` พร้อมน้ำหนักและราคาที่ร้านชั่งจริง
9. หน้าการเงินและรายงานของเกษตรกรนับรายรับก้อนนี้ทันที เพราะคำนวณจากตาราง `harvest` ที่ `status = 'sold'` ไม่ได้เก็บซ้ำในตาราง `finance`

ถ้าร้านไม่รับ: `POST /api/shop/harvests/:id/reject` บันทึกเหตุผลลง `harvest_rejection` แล้วล้าง `shop_id` ของล็อตนั้น เกษตรกรเห็นแถบแดงพร้อมเหตุผลบนการ์ด แล้วเลือกร้านใหม่ได้

---

## 5. ฐานข้อมูล

ฐานข้อมูล `palm_oil_db` มี 15 ตาราง และ 2 view เก่า (`v_financial_transactions`, `v_garden`) ที่โค้ดตอนนี้ไม่ได้ใช้แล้ว

| ตาราง | เก็บอะไร | ข้อควรรู้ |
|---|---|---|
| `role` | บทบาท R001–R003 | ไม่ต้องแก้ |
| `user` | บัญชีผู้ใช้ | `password` เป็น bcrypt hash, `status` = `active` / `suspended` |
| `user_log` | ประวัติการใช้งาน | บันทึกตอนล็อกอินและทุกการเพิ่ม/แก้/ลบ |
| `garden` | แปลงสวน | `plant_count` = จำนวนต้น, อายุปาล์มคำนวณจาก `plant_year` |
| `palm_variety` | พันธุ์ปาล์ม | แยกตามเจ้าของ (`user_id`) แต่ละคนเห็นแค่ของตัวเอง |
| `garden_variety` | แปลงไหนปลูกพันธุ์อะไรกี่ต้น | ตารางเชื่อม garden ↔ palm_variety |
| `palm_care` | การดูแลสวน 1 ครั้ง | `action_type` = fertilizer / pruning / weeding / watering / spraying / other, `cost` = รายจ่าย |
| `care_fertilizer` | ปุ๋ยแต่ละชนิดในการใส่ปุ๋ย 1 ครั้ง | 1 แถวใน palm_care มีได้หลายแถวที่นี่ |
| `fertilizer` | รายชื่อปุ๋ยตั้งต้น | ไม่มีหน้าจัดการแล้ว แต่ยังเก็บไว้ (อย่าลบ) |
| `harvest` | ล็อตผลผลิต | `status` = `pending` (รอขาย) / `sold` (ขายแล้ว) |
| `harvest_rejection` | ร้านไม่รับล็อต + เหตุผล | |
| `shop` | ร้านรับซื้อ | `user_id` = เจ้าของร้าน, `status` = `ACTIVE` / `INACTIVE` |
| `price_rate` | ราคารับซื้อตามเกรด | มีวันเริ่มใช้และวันสิ้นสุด |
| `purchase` | การรับซื้อที่ร้านบันทึก | มีแถวคู่กับ harvest ที่ขายผ่านร้านในแอปเสมอ |
| `finance` | รายรับ-รายจ่ายที่เกษตรกรบันทึกเอง | `garden_id` ว่าง = "ส่วนกลาง" |

**รายรับรายจ่ายมาจาก 3 แหล่ง** (หน้าการเงิน, รายงาน, หน้าหลัก ใช้หลักเดียวกัน):

1. รายรับจากการขาย = `harvest.total_price` ที่ `status = 'sold'`
2. รายจ่ายค่าดูแลสวน = `palm_care.cost`
3. รายการอื่นที่บันทึกเอง = ตาราง `finance`

ดังนั้นในหน้าเพิ่มรายการเงินจึงไม่มีหมวด "ขายผลผลิต" และ "ค่าปุ๋ย" กันการนับซ้ำ

---

## 6. แอป Flutter ทีละไฟล์

ทุกไฟล์มีคอมเมนต์อธิบายอยู่หัวไฟล์ ตารางนี้สรุปให้อ่านเร็ว จำนวนบรรทัดไว้ดูว่าไฟล์ใหญ่แค่ไหน

### จุดเริ่มต้นและของกลาง

| ไฟล์ | หน้าที่ |
|---|---|
| `lib/main.dart` | จุดเริ่มแอป เตรียมรูปแบบวันที่ภาษาไทย แล้วเปิดหน้า Splash |
| `lib/config/app_config.dart` | ที่อยู่ server (แก้ที่เดียวเมื่อย้ายเครื่อง) |
| `lib/theme/role_theme.dart` | ชุดสีตามบทบาท: เกษตรกรเขียว, ร้านส้ม (แอดมินใช้ `AdminColors` แยก) |
| `lib/utils/formatters.dart` | `formatNumber` ใส่ comma, `formatThaiDate` ปี พ.ศ. |
| `lib/utils/error_message.dart` | `friendlyError(e)` แปลง error ดิบเป็นข้อความไทย ใช้ทุกที่ที่โชว์ error |

### models/ (รูปร่างข้อมูล)

| ไฟล์ | class หลัก |
|---|---|
| `activity.dart` | `ActivityItem` (กิจกรรม 1 รายการ), `DashboardData` (ตัวเลขหน้าหลัก) |
| `admin.dart` | `AdminOverview`, `AdminUser`, `AdminLog`, `AdminReport`, `MonthValue` |
| `care_log.dart` | `CareLog` รายการดูแลสวน 1 รายการ |
| `care_type.dart` | รายการประเภทการดูแล 6 แบบ แต่ละแบบกำหนดว่าฟอร์มถามอะไร หน่วยอะไร emoji/สีอะไร |
| `finance.dart` | `TransactionItem`, `FinanceSummary` |
| `garden.dart` | `Garden` (แปลง), `GardenVariety` (พันธุ์ในแปลง + จำนวนต้น) |
| `harvest.dart` | `HarvestData` (ล็อต), `HarvestSummary` (สรุปปี + รายเดือน) |
| `palm_variety.dart` | `PalmVariety` พันธุ์ของผู้ใช้ |
| `report.dart` | `YearlyReport`, `GardenSummary`, `MonthlyMoney`, `MonthlyProduction` |
| `shop.dart` | ฝั่งร้าน: `ShopInfo`, `ShopPriceRate`, `ShopPurchase`, `IncomingLot`, `ShopReport`, `ShopDashboardData` ฯลฯ |
| `store.dart` | หน้าร้านรับซื้อของเกษตรกร: `BuyingShop`, `PriceRate` |

### services/ (เรียก API)

| ไฟล์ | เรียก API อะไร |
|---|---|
| `api.dart` | ของกลาง: ที่อยู่ server, header JSON, `Api.decode` (อ่านคำตอบ isError → โยน Exception ข้อความไทยจาก server) |
| `auth_service.dart` | ล็อกอิน 2 ขั้น, สมัคร, เปลี่ยนรหัสผ่าน + เก็บ/อ่าน/ลบ `user_id` และ token ในเครื่อง (`AuthService.getUserId()` ใช้ทุกหน้า) |
| `dashboard_service.dart` | `/dashboard`, `/activities` |
| `garden_service.dart` | `/gardens` ดึง/เพิ่ม/แก้/ลบแปลง, `fetchGardenOptions` รายการแปลงสำหรับ dropdown |
| `care_service.dart` | `/care-logs` ดึง/เพิ่ม/แก้/ลบ, `/fertilizers/used` |
| `harvest_service.dart` | `/harvests` ดึง/เพิ่ม/แก้/ลบ, `/harvests/summary`, `/harvests/:id/sell`, `/shops` |
| `finance_service.dart` | `/finance` ดึง/เพิ่ม/แก้/ลบ |
| `store_service.dart` | `/shops` รายชื่อร้านสำหรับหน้าร้านรับซื้อของเกษตรกร |
| `palm_variety_service.dart` | `/varieties` |
| `profile_service.dart` | `/profile` |
| `report_service.dart` | `/report` |
| `shop_service.dart` | `/shop/...` ทั้งหมดของฝั่งร้าน |
| `admin_service.dart` | `/admin/...` ทุกคำสั่งแนบ `admin_id` ให้ server ตรวจ |

เพิ่ม API ใหม่: เขียนฟังก์ชันใน service ของเรื่องนั้น (ใช้ `Api.base`, `Api.jsonHeaders`, `Api.decode`) แล้วให้หน้าจอเรียกฟังก์ชันนั้น อย่าเขียน `http.get(...)` ในไฟล์หน้าจอ

### screens/auth/ (เข้าสู่ระบบ)

| ไฟล์ | หน้าที่ |
|---|---|
| `splash_screen.dart` | อนิเมชันเปิดแอปประมาณ 2 วินาที แล้วไปหน้าล็อกอิน |
| `login_screen.dart` | ล็อกอิน มีปุ่มเลือกบทบาท เกษตรกร / ร้านค้า แล้วพาไปหน้าตามบทบาทจริงของบัญชี (R001 → แอดมิน, R003 → ร้าน, อื่นๆ → เกษตรกร) |
| `register_screen.dart` | สมัครสมาชิก (เป็นแอดมินผ่านหน้านี้ไม่ได้) |

### screens/main/ (โครงแอปเกษตรกร)

| ไฟล์ | หน้าที่ |
|---|---|
| `home/home_screen.dart` | โครงหลังล็อกอิน แถบเมนูล่าง 5 แท็บ ใช้ `IndexedStack` ทุกแท็บจึงจำสถานะไว้ |
| `home/dashboard_screen.dart` | แท็บหน้าหลัก: ส่วนหัว, เตือนล็อตรอขาย, เมนู, กิจกรรมล่าสุด |
| `home/activity_screen.dart` | ประวัติกิจกรรมทั้งหมด กรองตามประเภท |
| `home/activity_detail_screen.dart` | รายละเอียดกิจกรรม 1 รายการ พร้อมปุ่มแก้ไข/ลบ (เปิดฟอร์มของประเภทนั้น) |
| `profile/profile_screen.dart` | แท็บโปรไฟล์: ข้อมูลผู้ใช้, แก้ชื่อ/เบอร์, เปลี่ยนรหัส, ออกจากระบบ |
| `profile/change_password_screen.dart` | เปลี่ยนรหัสผ่าน (ต้องใส่รหัสเดิมถูก) |
| `report/report_screen.dart` | แท็บรายงาน: สลับรายปี/รายเดือน เลื่อนช่วงด้วยลูกศร |
| `report/widgets/report_common.dart` | สีและการ์ดเล็กที่ใช้ร่วมในหน้ารายงาน |
| `report/widgets/garden_summary_card.dart` | การ์ดสรุปรายแปลง (ส่วนกลางอยู่บนสุดเสมอ) |
| `report/widgets/monthly_money_chart.dart` | กราฟแท่งคู่ รายรับ-รายจ่ายรายเดือน |
| `report/widgets/production_compare_card.dart` | ตารางเทียบผลผลิตกับปีก่อน |

### screens/garden/ (งานในสวน)

| ไฟล์ | หน้าที่ |
|---|---|
| `palmplot/palmplot_screen.dart` | รายการแปลงสวน สถิติรวม ค้นหา แก้ไข ลบ |
| `palmplot/add_plot_screen.dart` | เพิ่มแปลงใหม่ |
| `palmplot/widgets/plot_card.dart` | การ์ดแปลง 1 แปลง |
| `palmplot/widgets/edit_garden_dialog.dart` | หน้าต่างแก้ไขแปลง (รวมพันธุ์ที่ปลูก) |
| `palm_varieties/palmvarieties_screen.dart` | รายการพันธุ์ปาล์มของผู้ใช้ (พันธุ์ที่มีแปลงปลูกอยู่ลบไม่ได้) |
| `palm_varieties/add_palmvariety_screen.dart` | ฟอร์มเพิ่ม/แก้ไขพันธุ์ |
| `gardencare/gardencare_screen.dart` | รายการดูแลสวน กรองตามแปลงและประเภท สรุปค่าใช้จ่าย |
| `gardencare/add_gardencare_screen.dart` | ฟอร์มดูแลสวน 3 การ์ด ช่องในการ์ดที่ 2 เปลี่ยนตามประเภท (ตั้งค่าใน `models/care_type.dart`) |
| `gardencare/widgets/care_form_fields.dart` | ชิ้นส่วนฟอร์ม: ตารางเลือกประเภท, ช่องตัวเลข, เลือกหน่วย |
| `gardencare/widgets/fertilizer_item_card.dart` | การ์ดปุ๋ย 1 ชนิด (ใส่ปุ๋ยได้หลายชนิด กด + เพิ่ม) ชื่อแนะนำมาจากปุ๋ยที่ผู้ใช้เคยใช้ |
| `gardencare/widgets/care_log_card.dart` | การ์ดรายการดูแลสวน 1 รายการ |
| `harvest/harvest_screen.dart` | รายการเก็บเกี่ยว สรุปปี กราฟ กรองสถานะ บันทึกขายนอกระบบ |
| `harvest/add_harvest_screen.dart` | ฟอร์มเพิ่ม/แก้ไขการเก็บเกี่ยว (รอขาย + เลือกร้าน หรือ ขายนอกระบบ) |
| `harvest/widgets/harvest_monthly_chart.dart` | กราฟแท่ง 12 เดือน แตะแท่งเพื่อดูยอดเดือนนั้น |
| `harvest/widgets/sale_fields.dart` | ช่องเลือกร้าน, ข้อความอธิบาย, ช่องเลือกเกรด |
| `harvest/widgets/sell_sheet.dart` | หน้าต่าง "บันทึกขายนอกระบบ" |

### screens/ เรื่องอื่นของเกษตรกร

| ไฟล์ | หน้าที่ |
|---|---|
| `finance/finance_screen.dart` | แท็บการเงิน: เลือกเดือน, กรองตามแปลง/ส่วนกลาง, ยอดรายรับ-รายจ่าย |
| `finance/add_transaction_screen.dart` | เพิ่ม/แก้รายการเงินที่บันทึกเอง (จำนวนเงินต้องมากกว่า 0) |
| `finance/widgets/transaction_tile.dart` | แถวรายการเงิน 1 แถว (ไอคอนตามหมวด) |
| `store/store_screen.dart` | รายชื่อร้านรับซื้อ ราคาแต่ละเกรด เวลาเปิด และยอดที่เคยขายให้ |
| `notifications/notifications_screen.dart` | การแจ้งเตือนในแอป คำนวณสดจากข้อมูลจริงทุกครั้ง (ไม่มีตารางแจ้งเตือน) |

### screens/shop/ (ร้านรับซื้อ)

| ไฟล์ | หน้าที่ |
|---|---|
| `shop_home_screen.dart` | โครงแอปฝั่งร้าน แถบเมนู 5 แท็บโทนส้ม โหลดข้อมูลร้านครั้งเดียวแล้วส่งต่อ |
| `shop_dashboard_screen.dart` | หน้าหลักร้าน: ยอดวันนี้/เดือนนี้ ราคาวันนี้ รับซื้อล่าสุด |
| `shop_purchase_screen.dart` | แท็บรับซื้อ: ล็อตที่เกษตรกรส่งมา (บนสุด), ประวัติ, ยกเลิกการรับซื้อ |
| `record_purchase_screen.dart` | บันทึกรับซื้อ: ค้นหาเกษตรกร → เลือกล็อต → เกรด/ราคา/น้ำหนักจริง |
| `reject_lot_sheet.dart` | หน้าต่างไม่รับล็อต (ต้องพิมพ์เหตุผล) |
| `edit_purchase_sheet.dart` | หน้าต่างแก้ไขการรับซื้อ (น้ำหนัก ราคา วันที่) |
| `my_shop_screen.dart` | ร้านของฉัน: สร้าง/แก้ร้าน สวิตช์เปิด-ปิดรับซื้อ จัดการราคา |
| `shop_report_screen.dart` | รายงานรายปีของร้าน กราฟรายเดือน เกษตรกร 5 อันดับ |
| `widgets/sheet_frame.dart` | กรอบหน้าต่างล่างและช่องกรอกที่ใช้ในฟอร์มของร้าน |
| `widgets/shop_form_sheet.dart` | ฟอร์มข้อมูลร้าน |
| `widgets/price_form_sheet.dart` | ฟอร์มราคา (ปุ่มเกรดลัดกับช่องพิมพ์เก็บค่าเดียวกัน) |

### screens/admin/ (ผู้ดูแลระบบ)

| ไฟล์ | หน้าที่ |
|---|---|
| `admin_dashboard_screen.dart` | หน้าหลักแอดมิน: ตัวเลข 4 ช่อง, เมนู, กราฟ 6 เดือน, กิจกรรมล่าสุด |
| `user_management_screen.dart` | รายชื่อบัญชี กรอง ค้นหา แตะเพื่อดูรายละเอียด (ไม่มีปุ่มลบ ใช้ระงับแทน) |
| `admin_user_form_screen.dart` | เพิ่ม/แก้ไขบัญชี (ตั้งใครเป็นแอดมินไม่ได้) |
| `admin_logs_screen.dart` | ประวัติการใช้งาน 200 รายการล่าสุด กรองตามหมวด |
| `admin_report_screen.dart` | รายงานระบบ สลับ 6 เดือน / 1 ปี |
| `widgets/admin_widgets.dart` | สี การ์ด ป้ายสถานะ กราฟแท่ง ของหน้าแอดมิน |
| `widgets/user_detail_sheet.dart` | แผ่นรายละเอียดบัญชีพร้อมปุ่ม แก้ไข / ประวัติ / ระงับ |

### widgets/ (ใช้หลายหน้า)

| ไฟล์ | หน้าที่ |
|---|---|
| `button_nav.dart` | แถบเมนูด้านล่าง (ใช้ทั้งเกษตรกรและร้าน) |
| `item_actions.dart` | เมนูแก้ไข/ลบ และกล่องยืนยันการลบ |
| `dashboard_widget/dashboard_header.dart` | ส่วนหัวเขียวของหน้าหลัก คำทักทาย ชื่อ สถิติ 3 ช่อง กระดิ่งแจ้งเตือน |
| `dashboard_widget/menu_grid.dart`, `menu_item.dart` | ตารางเมนูหลัก 4 คอลัมน์ |
| `dashboard_widget/activity_list.dart`, `recent_activity_card.dart` | กิจกรรมล่าสุด 5 รายการบนหน้าหลัก |
| `dashboard_widget/error_view.dart` | หน้าแสดง error พร้อมปุ่มลองใหม่ |
| `activity_widgets/activity_card.dart` | การ์ดในหน้าประวัติกิจกรรม |
| `activity_widgets/activity_filter_bar.dart` | ปุ่มกรอง ทั้งหมด / เก็บเกี่ยว / ดูแล / รายรับ / รายจ่าย |
| `activity_widgets/activity_type_badge.dart` | ป้ายประเภทกิจกรรม |
| `activity_widgets/activity_empty_state.dart` | หน้าว่างเมื่อไม่มีกิจกรรม |

---

## 7. Server ทีละไฟล์

### ไฟล์หลักและ libs/

| ไฟล์ | หน้าที่ |
|---|---|
| `server.js` | ตั้งค่า express (cors, อ่าน JSON) แล้ว `app.use()` route ทุกไฟล์ ไม่มี logic อื่น |
| `libs/config.js` | อ่าน `.env` (DB, JWT secret, PORT) จะรัน node จากโฟลเดอร์ไหนก็หาไฟล์เจอ |
| `libs/db_pool.js` | connection pool ของฐานข้อมูล (สูงสุด 5) **ระวัง:** `db.query()` คืน array ของแถวตรงๆ ห้ามเขียน `const [rows] = ...` |
| `libs/jwt.js` | สร้าง/ตรวจ JWT token |
| `libs/log_action.js` | `logIfOk(result, userId, action, req)` บันทึก log เมื่อทำรายการสำเร็จ |

### routes/ (รับ request)

ทุกไฟล์ใช้ `express.Router()` และเขียน path เต็ม (`/api/...`) ไว้ในแต่ละ route หน้าที่คือ อ่านพารามิเตอร์ → เรียก model → `res.json(result)` → บันทึก log

| ไฟล์ | เรื่อง |
|---|---|
| `auth_routes.js` | สมัคร, ล็อกอิน (ตรวจรหัสผ่าน → บัญชีถูกระงับไหม → บทบาทตรงปุ่มไหม → บันทึก LOGIN), แลก token, เปลี่ยนรหัสผ่าน |
| `dashboard_routes.js` | หน้าหลักและกิจกรรมของเกษตรกร |
| `garden_routes.js` | แปลงสวน |
| `variety_routes.js` | พันธุ์ปาล์ม |
| `care_routes.js` | การดูแลสวน + ชื่อปุ๋ยที่ผู้ใช้เคยใช้ |
| `harvest_routes.js` | การเก็บเกี่ยว + ขายนอกระบบ |
| `finance_routes.js` | รายการเงินที่บันทึกเอง |
| `report_routes.js` | รายงานเกษตรกร |
| `shop_routes.js` | ทุกอย่างของร้าน + รายชื่อร้านสำหรับเกษตรกร |
| `admin_routes.js` | ทุก route ผ่าน `requireAdmin` (ต้องส่ง `admin_id` ที่เป็น R001 จริง) |
| `profile_routes.js` | โปรไฟล์ (ผูกที่ `/api/profile` ใน server.js) |

### models/ (SQL และ logic)

| ไฟล์ | ตารางหลัก | เรื่องสำคัญข้างใน |
|---|---|---|
| `user_account.js` | user, user_log | สร้างผู้ใช้, หา username, เปลี่ยนรหัส (bcrypt), `logAction` |
| `garden.js` | garden, garden_variety | ลบแปลงจะลบ harvest/palm_care ของแปลงทีละตาราง, ห้ามลบแปลงที่ร้านรับซื้อแล้ว |
| `palm_variety.js` | palm_variety | ทำได้เฉพาะพันธุ์ของตัวเอง (ตรวจด้วย `user_id` ที่ส่งมา) |
| `care.js` | palm_care, care_fertilizer | ใส่ปุ๋ยหลายชนิดทำใน transaction, ตรวจความเป็นเจ้าของแปลง |
| `fertilizer.js` | care_fertilizer | `getUsedByUser` ชื่อปุ๋ยที่ผู้ใช้เคยบันทึก |
| `harvest.js` | harvest | กติกาการขาย (ดูหัวข้อ 10), ล็อตที่ร้านรับซื้อแล้วเกษตรกรแก้/ลบไม่ได้ |
| `finance.js` | finance (+ harvest, palm_care) | รวมรายการเงิน 3 แหล่ง |
| `dashboard.js` | หลายตาราง | `ACTIVITY_SQL` รวมกิจกรรม 4 แบบ ใช้ทั้งหน้าหลักและหน้ากิจกรรม |
| `report.js` | หลายตาราง | รายงานรายปี/รายเดือน, สรุปรายแปลง + ส่วนกลาง, เทียบปีก่อน |
| `shop.js` | shop, price_rate, purchase, harvest_rejection | ไฟล์ใหญ่สุด (746 บรรทัด): ร้าน, ราคา, รับซื้อ (transaction + FOR UPDATE), ยกเลิก, ไม่รับล็อต, ค้นหา, รายงาน |
| `admin.js` | หลายตาราง | ภาพรวม, จัดการผู้ใช้ (`ASSIGNABLE_ROLES` = R002, R003), log, รายงาน 6/12 เดือน |

---

## 8. รายการ API ทั้งหมด

ทุก path ขึ้นต้นด้วย `http://<server>:3000`

| Method | Path | ใช้ที่ |
|---|---|---|
| POST | `/api/register` | สมัครสมาชิก |
| POST | `/api/authen_request` | ล็อกอิน |
| POST | `/api/access_request` | แลก access token |
| PUT | `/api/user/:user_id/password` | เปลี่ยนรหัสผ่าน |
| GET / PUT | `/api/profile/:user_id` | โปรไฟล์ |
| GET | `/api/dashboard/:user_id` | หน้าหลักเกษตรกร |
| GET | `/api/activities/:user_id` | กิจกรรมทั้งหมด |
| GET | `/api/gardens/:user_id` | รายการแปลง |
| POST | `/api/gardens` | เพิ่มแปลง |
| PUT / DELETE | `/api/gardens/:garden_id` | แก้ / ลบแปลง |
| GET | `/api/gardens/:garden_id/varieties` | พันธุ์ในแปลง |
| GET / POST | `/api/varieties` | รายการ / เพิ่มพันธุ์ |
| PUT / DELETE | `/api/varieties/:id` | แก้ / ลบพันธุ์ |
| GET / POST | `/api/care-logs` | รายการ / เพิ่มการดูแล |
| GET / PUT / DELETE | `/api/care-logs/:care_id` | รายการเดียว (พร้อมปุ๋ยทุกชนิด) / แก้ / ลบ |
| GET | `/api/fertilizers/used` | ชื่อปุ๋ยที่ผู้ใช้เคยใช้ |
| GET / POST | `/api/harvests` | รายการ / เพิ่มการเก็บเกี่ยว |
| GET | `/api/harvests/summary` | สรุปปี + รายเดือน |
| PUT / DELETE | `/api/harvests/:harvest_id` | แก้ / ลบ |
| PUT | `/api/harvests/:harvest_id/sell` | บันทึกขายนอกระบบ |
| GET | `/api/finance/transactions` | รายการเงิน (เดือน, ประเภท) |
| POST | `/api/finance/add` | เพิ่มรายการเงิน |
| PUT / DELETE | `/api/finance/:finance_id` | แก้ / ลบรายการเงิน |
| GET | `/api/report/:user_id?year=&month=` | รายงานเกษตรกร |
| GET | `/api/shops` | รายชื่อร้าน + ราคา (ฝั่งเกษตรกร) |
| GET / POST / PUT | `/api/shop/profile...` | ข้อมูลร้าน |
| GET | `/api/shop/:shop_id/prices` | ประวัติราคา |
| POST / DELETE | `/api/shop/prices...` | บันทึก / ลบราคา |
| GET | `/api/shop/:shop_id/purchases` | ประวัติรับซื้อ |
| POST | `/api/shop/purchases` | บันทึกรับซื้อ |
| PUT / DELETE | `/api/shop/purchases/:purchase_id` | แก้ / ยกเลิกการรับซื้อ |
| POST | `/api/shop/harvests/:harvest_id/reject` | ไม่รับล็อต |
| GET | `/api/shop/:shop_id/incoming` | ล็อตที่เกษตรกรส่งมา |
| GET | `/api/shop/farmers/search` | ค้นหาเกษตรกร |
| GET | `/api/shop/farmers/:farmer_id/harvests` | ล็อตรอขายของเกษตรกรคนนั้น |
| GET | `/api/shop/:shop_id/dashboard` | หน้าหลักร้าน |
| GET | `/api/shop/:shop_id/reports?year=` | รายงานร้าน |
| GET | `/api/admin/overview` | ภาพรวมระบบ |
| GET / POST | `/api/admin/users` | รายชื่อ / เพิ่มผู้ใช้ |
| PUT | `/api/admin/users/:id` | แก้ไขผู้ใช้ |
| PUT | `/api/admin/users/:id/status` | ระงับ / เปิดใช้ |
| GET | `/api/admin/logs` | ประวัติการใช้งาน |
| GET | `/api/admin/report?months=12` | รายงานระบบ (ไม่ส่ง months = 6 เดือน) |

---

## 9. สคริปต์และเทสต์

### สคริปต์ (รันในโฟลเดอร์ `my_project_server`)

| คำสั่ง | ทำอะไร |
|---|---|
| `node scripts/migrate.js` | เพิ่มคอลัมน์/ตารางที่โค้ดต้องใช้ (รันซ้ำได้ ส่วนที่มีแล้วข้าม) |
| `node scripts/create_admin.js` | สร้างหรือรีเซ็ตแอดมิน `admin / admin1234` (ใส่ชื่อ/รหัสเองได้: `create_admin.js myadmin mypass`) |
| `node scripts/backup_db.js` | สำรอง DB ไปที่ `backups/` |
| `node scripts/backup_db.js restore <ไฟล์.sql> --yes` | กู้คืน (สำรองของปัจจุบันให้ก่อนอัตโนมัติ) |
| `node scripts/backup_db.js check` | นับแถวทุกตาราง ไว้เทียบหลังกู้คืน |
| `node scripts/seed_demo.js` | สร้างบัญชีเดโมและข้อมูลตัวอย่าง (รันซ้ำได้ ได้ข้อมูลชุดเดิม จบที่วันที่รัน) |
| `node scripts/seed_demo.js --remove` | ลบข้อมูลเดโมออก |

### เทสต์ของแอป (`flutter test` ในโฟลเดอร์ `flutter_myproject`)

| ไฟล์ | ทดสอบอะไร |
|---|---|
| `test/widget_test.dart` | จัดรูปแบบตัวเลข/วันที่, สถานะล็อกอินและ token หมดอายุ, เปิดแอปแล้วไปหน้าล็อกอิน |
| `test/error_message_test.dart` | แปลง error ดิบเป็นข้อความไทย |
| `test/role_theme_test.dart` | สีตามบทบาท, หน้าล็อกอินและสมัครเปลี่ยนสีเมื่อสลับบทบาท (หลายขนาดจอ) |
| `test/home_screen_test.dart` | สร้างหน้าหลักทั้ง 5 แท็บได้ไม่ error |

ก่อน commit ควรรัน `flutter analyze` และ `flutter test` ให้ผ่านทั้งคู่

---

## 10. กติกาสำคัญที่ต้องรู้ก่อนแก้โค้ด

**ตรวจความเป็นเจ้าของทุกครั้ง** ทุกคำสั่งแก้/ลบใน model มีเงื่อนไข `... AND garden_id IN (SELECT garden_id FROM garden WHERE user_id = ?)` หรือแบบเดียวกันกับร้าน กันคนหนึ่งไปแก้ข้อมูลของอีกคนด้วยการเดารหัส ถ้าเพิ่ม API ใหม่ต้องทำแบบเดียวกัน

**การสร้างรหัส** รหัสทุกตารางเป็นตัวอักษรนำหน้า + เลข เช่น `U001`, `G001`, `H015`, `FN008`, `PR003`, `L120` server หาเลขมากสุดในตารางแล้วบวก 1 (`MAX(CAST(SUBSTRING(...)))`) ไม่ได้ใช้ AUTO_INCREMENT (ยกเว้น `harvest_rejection`)

**กติกาการขาย**
- รอขาย + เลือกร้าน = ร้านนั้นร้านเดียวที่กดรับซื้อได้
- รอขาย + ไม่เลือกร้าน = ร้านไหนก็ค้นหาแล้วรับซื้อได้ หรือเกษตรกรบันทึกขายนอกระบบเอง
- ขายผ่านร้านในแอปแล้ว = เกษตรกรแก้/ลบไม่ได้ ถ้าผิดให้ร้านกดยกเลิกการรับซื้อ (ล็อตกลับเป็นรอขาย)
- วันที่ขายต้องไม่ก่อนวันเก็บเกี่ยว และไม่เกินวันนี้

**บันทึก log ทุกครั้งที่เพิ่ม/แก้/ลบ** route ใหม่ที่แก้ข้อมูลต้องเรียก `logIfOk(result, userId, 'ชื่อ_ACTION', req)` ไม่งั้นหน้าประวัติของแอดมินจะไม่เห็น ถ้าตั้งชื่อ action ใหม่ ให้เพิ่มคำแปลภาษาไทยใน `logActionLabels` (`lib/models/admin.dart`) ด้วย

**แอดมินล็อกไว้** แอปสร้างแอดมินใหม่หรือเปลี่ยนบทบาทเข้า/ออกจากแอดมินไม่ได้ (`ASSIGNABLE_ROLES` ใน `models/admin.js`) แอดมินสร้างได้ทางเดียวคือ `create_admin.js`

**ไม่มีการลบบัญชี** ใช้ระงับ (`user.status = 'suspended'`) แทน เพราะลบแล้วข้อมูลแปลงและการซื้อขายจะหายตาม

**ลบข้อมูลหลายชั้นให้ลบทีละตาราง** MySQL 9.7 ที่ใช้อยู่ลบต่อเป็นทอดๆ (`ON DELETE CASCADE` หลายชั้น) ได้ไม่ครบในบางกรณี เคยเหลือการเก็บเกี่ยวของแปลงที่ถูกลบไปแล้ว ถ้าเขียนโค้ดลบอะไรที่มีลูกหลายชั้น ให้ลบจากตารางลูกขึ้นไปเองแบบ `deleteGarden` ใน `models/garden.js`

**ไฟล์ .env ห้ามขึ้น git** มีรหัสผ่าน DB และ JWT secret ถ้าเพิ่มค่าตั้งค่าใหม่ ให้เพิ่มใน `.env.example` ด้วย (ใส่ค่าตัวอย่าง ไม่ใช่ค่าจริง)

**`server.js` ใช้ขึ้นบรรทัดแบบ Windows (CRLF)** ถ้าแก้ด้วยสคริปต์ให้คงรูปแบบนี้ไว้ แก้ใน VS Code ปกติไม่ต้องกังวล

---

## 11. อยากแก้เรื่องนี้ ไปไฟล์ไหน

| อยากแก้ | หน้าจอ (แอป) | server |
|---|---|---|
| ที่อยู่ server / พอร์ต | `lib/config/app_config.dart` | `.env` (`PORT`) |
| เรียก API เรื่องไหน | `lib/services/<เรื่อง>_service.dart` | `routes/<เรื่อง>_routes.js` |
| หน้าล็อกอิน / ปุ่มบทบาท | `screens/auth/login_screen.dart` | `routes/auth_routes.js` |
| สีของแต่ละบทบาท | `lib/theme/role_theme.dart`, `screens/admin/widgets/admin_widgets.dart` | - |
| ประเภทการดูแลสวน (เพิ่มประเภท, หน่วย, ตัวเลือก) | `lib/models/care_type.dart` | `models/care.js` |
| ฟอร์มใส่ปุ๋ย | `screens/garden/gardencare/add_gardencare_screen.dart`, `widgets/fertilizer_item_card.dart` | `models/care.js` |
| ฟอร์มเก็บเกี่ยว / ขาย | `screens/garden/harvest/add_harvest_screen.dart`, `widgets/sale_fields.dart`, `widgets/sell_sheet.dart` | `models/harvest.js` |
| หมวดรายรับ-รายจ่าย | `screens/finance/add_transaction_screen.dart` (`_incomeCategories`, `_expenseCategories`) | `models/finance.js` |
| ไอคอนหมวดเงิน | `screens/finance/finance_screen.dart`, `widgets/transaction_tile.dart` | - |
| ตัวเลขในรายงานเกษตรกร | `screens/main/report/` | `models/report.js` |
| ตัวเลขหน้าหลักเกษตรกร | `screens/main/home/dashboard_screen.dart`, `widgets/dashboard_widget/` | `models/dashboard.js` |
| เงื่อนไขการแจ้งเตือน (30 วัน, 7 วัน) | `screens/notifications/notifications_screen.dart` | - |
| เมนูบนหน้าหลัก | `widgets/dashboard_widget/menu_grid.dart` | - |
| แถบเมนูด้านล่าง | `widgets/button_nav.dart` | - |
| การรับซื้อของร้าน | `screens/shop/record_purchase_screen.dart`, `shop_purchase_screen.dart` | `models/shop.js` (`createPurchase`) |
| ราคารับซื้อ / ปุ่มเกรดลัด | `screens/shop/widgets/price_form_sheet.dart` (`_quickGrades`) | `models/shop.js` (`savePriceRate`) |
| ไม่รับล็อต | `screens/shop/reject_lot_sheet.dart` | `models/shop.js` (`rejectHarvest`) |
| หน้าแอดมิน | `screens/admin/` | `routes/admin_routes.js`, `models/admin.js` |
| ชื่อภาษาไทยของ log | `lib/models/admin.dart` (`logActionLabels`) | - |
| ข้อความ error ภาษาไทย | `lib/utils/error_message.dart` | `errorMessage` ใน model ของเรื่องนั้น |
| เพิ่มคอลัมน์ / ตารางใหม่ | - | เพิ่มขั้นตอนใน `scripts/migrate.js` แล้วบอกทีมให้รัน |

---

## 12. ทำงานร่วมกันด้วย Git

- ทำงานบน branch `main` โดยตรง
- **ก่อนเริ่มแก้ทุกครั้ง** `git pull` ก่อน โดยเฉพาะหลังมีการย้ายไฟล์ ถ้าแก้ไฟล์เก่าค้างไว้แล้วค่อย pull จะ conflict
- มีงานค้างแต่จำเป็นต้อง pull: `git stash` → `git pull` → `git stash pop`
- ข้อความ commit เขียนภาษาไทยได้ บอกว่าเปลี่ยนอะไร เช่น `แก้หน้าการเงิน: เพิ่มตัวกรองตามแปลง`
- ถ้า commit แก้โครงสร้างตาราง ให้เพิ่มขั้นตอนใน `scripts/migrate.js` และเขียนในข้อความ commit ว่าต้องรัน migrate
- สิ่งที่ไม่ขึ้น git: `node_modules/`, `.env`, `my_project_server/backups/`, ไฟล์ build ของ Flutter
