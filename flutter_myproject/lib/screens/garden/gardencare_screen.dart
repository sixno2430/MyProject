import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/back_button_widget.dart';


class GardenCareScreen extends StatelessWidget {
  const GardenCareScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const BackScreen(
      title: '💊 ดูแลสวน',
      subtitle: 'บันทึกการใส่ปุ๋ยและดูแลต้นปาล์ม',
    );
  }
}