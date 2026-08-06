import 'package:flutter/material.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD97706), // สีส้มตามภาพ
        elevation: 0,
        title: const Text('ร้านค้าปุ๋ยปาล์มน้ำมัน', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แบนเนอร์
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ส่งฟรี!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD97706))),
                        Text('เมื่อซื้อครบ 5,000 บาท', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ดูเพิ่มเติม', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // หมวดหมู่
            const Text('สินค้ายอดนิยม', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
              children: [
                _buildProductCard('ปุ๋ย NPK 15-15-15', '1,250 บาท/ถุง', '🧪'),
                _buildProductCard('ปุ๋ยอินทรีย์', '890 บาท/ถุง', '🌿'),
                _buildProductCard('สารกำจัดศัตรูพืช', '450 บาท/ขวด', '🔧'),
                _buildProductCard('ปุ๋ยยูเรีย', '680 บาท/ถุง', '💧'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(String name, String price, String emoji) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('สั่งซื้อ', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}