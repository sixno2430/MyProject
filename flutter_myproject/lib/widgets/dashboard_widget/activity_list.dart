import 'package:flutter/material.dart';
import 'package:flutter_myproject/services/dashboard_service.dart';
import 'package:flutter_myproject/widgets/dashboard_widget/recent_activity_card.dart';

class ActivityList extends StatelessWidget {
  final List<ActivityItem> activities;
  const ActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'กิจกรรมล่าสุด',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: ไปหน้า ActivityScreen (รายการทั้งหมด)
                  // import 'package:flutter_myproject/screens/activity/activity_screen.dart';
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
                },
                child: const Row(
                  children: [
                    Text(
                      'ดูทั้งหมด',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2D6A4F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF2D6A4F)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'ยังไม่มีกิจกรรม',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ...activities.map((a) => RecentActivityCard(activity: a)),
        ],
      ),
    );
  }
}
