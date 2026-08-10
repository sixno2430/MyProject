import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text('การเงินและรายรับรายจ่าย', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // สรุปยอด
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('ยอดเงินคงเหลือ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text(
                    '+22,728 ฿',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBalanceItem('รายรับ', '+39,538 ฿', Colors.greenAccent),
                      _buildBalanceItem('รายจ่าย', '-16,810 ฿', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // แท็บรายรับ/รายจ่าย
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('รายรับ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('รายจ่าย', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // รายการ
            _buildTransactionItem(
              title: 'ขายผลปาล์มน้ำมัน แปลง A',
              date: '10 มิ.ย. 2568',
              amount: '+9,900 ฿',
              isIncome: true,
              icon: '🌴',
            ),
            _buildTransactionItem(
              title: 'ค่าปุ๋ย 15-15-15',
              date: '8 มิ.ย. 2568',
              amount: '-1,200 ฿',
              isIncome: false,
              icon: '🧪',
            ),
            _buildTransactionItem(
              title: 'ขายผลปาล์มน้ำมัน แปลง B',
              date: '5 มิ.ย. 2568',
              amount: '+6,360 ฿',
              isIncome: true,
              icon: '🌴',
            ),
            _buildTransactionItem(
              title: 'ค่าแรงงาน',
              date: '1 มิ.ย. 2568',
              amount: '-1,500 ฿',
              isIncome: false,
              icon: '👷',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String date,
    required String amount,
    required bool isIncome,
    required String icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}