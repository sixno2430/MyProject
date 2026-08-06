import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/garden/add_plot_screen.dart';


class PalmplotScreen extends StatelessWidget {
  const PalmplotScreen({super.key});

  final Color primaryGreen = const Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text('แปลงสวนของฉัน', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPlotScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ค้นหา
            TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาแปลงสวน...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // สรุป
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummary('4', 'แปลงสวน'),
                _buildSummary('38', 'ต้นปาล์ม'),
              ],
            ),
            const SizedBox(height: 20),

            // รายการแปลง
            _buildPlotCard(
              name: 'แปลง A — บ้านหนองกวาง',
              area: '5 ไร่ 3 งาน',
              trees: '12 ต้น',
              progress: 0.75,
              progressColor: Colors.green,
              status: 'สมบูรณ์',
            ),
            _buildPlotCard(
              name: 'แปลง B — ไร่นาสวน',
              area: '8 ไร่',
              trees: '15 ต้น',
              progress: 0.45,
              progressColor: Colors.orange,
              status: 'ต้องดูแล',
            ),
            _buildPlotCard(
              name: 'แปลง C — สวนในบึง',
              area: '3 ไร่ 2 งาน',
              trees: '8 ต้น',
              progress: 0.40,
              progressColor: Colors.blue,
              status: 'ปกติ',
            ),
            _buildPlotCard(
              name: 'แปลง D — ห้วยป่าซาง',
              area: '6 ไร่',
              trees: '10 ต้น',
              progress: 0.70,
              progressColor: Colors.purple,
              status: 'สมบูรณ์',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPlotCard({
    required String name,
    required String area,
    required String trees,
    required double progress,
    required Color progressColor,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌴', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('$area · $trees', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 12, color: progressColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ความสมบูรณ์ ${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('1,800 กก.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}