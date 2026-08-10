import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/utils/formatters.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/stat_item.dart';

class DashboardHeader extends StatelessWidget {
  final DashboardData data;
  const DashboardHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildGreenHeader(),
        Positioned(
          bottom: -40,
          left: 16,
          right: 16,
          child: _buildStatsCard(),
        ),
      ],
    );
  }

  Widget _buildGreenHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2D6A4F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สมชาย มีทรัพย์',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'เกษตรกร · สวนปาล์มน้ำมัน',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationBell(),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'สวัสดี ยินดีต้อนรับ 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatThaiDate(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Center(
        child: Text('👨‍🌾', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Text('🔔', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          StatItem(value: '${data.gardenCount}', label: 'แปลงสวน\nจำนวน'),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          StatItem(
            value: formatNumber(data.monthlyProduction),
            label: 'กก.\nผลผลิต/เดือน',
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          StatItem(
            value: formatNumber(data.monthlyIncome),
            label: 'บาท\nรายรับเดือนนี้',
          ),
        ],
      ),
    );
  }
}
