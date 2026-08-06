import 'package:flutter/material.dart';
import 'package:flutter_myproject/widgets/back_button_widget.dart';


class HarvestScreen extends StatelessWidget {
  const HarvestScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const BackScreen(
      title: '🌾 เก็บเกี่ยว',
      subtitle: 'บันทึกผลผลิตรายวัน',
    );
  }
}