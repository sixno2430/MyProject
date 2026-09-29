// ============================================================
// splash_screen.dart — หน้าเปิดแอป (อนิเมชันประมาณ 2 วินาที)
//
// โลโก้เด้งขึ้น -> ชื่อแอปค่อยๆ ปรากฏ -> แถบโหลดวิ่งจนเต็ม -> ไปหน้า Login
// โลโก้ใช้ Hero ทำให้ลอยต่อไปยังตำแหน่งเดียวกันในหน้า Login
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_myproject/screens/auth/login_screen.dart';

/// หน้าเปิดแอป: โลโก้เด้งขึ้น → ชื่อแอปค่อยๆ โผล่ → แถบโหลดวิ่งจนเต็ม → ไปหน้า Login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// tag ของ Hero ต้องตรงกับที่หน้า Login ใช้ โลโก้จึงจะลอยต่อกันได้
  static const logoHeroTag = 'app-logo';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // แต่ละท่อนของอนิเมชันใช้ช่วงเวลา (Interval) ต่างกันบน controller ตัวเดียว
  late final Animation<double> _logoScale;
  late final Animation<double> _ring;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );
    _ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.85, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic)),
    );
    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward().whenComplete(_goToLogin);
  }

  /// อนิเมชันจบแล้ว เปลี่ยนไปหน้า Login แบบค่อยๆ จางเข้า
  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF064E3B), Color(0xFF15803D)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // วงแหวนที่ขยายออกแล้วจางหาย
                      Opacity(
                        opacity: (1 - _ring.value).clamp(0.0, 1.0) * 0.5,
                        child: Container(
                          width: 80 + 80 * _ring.value,
                          height: 80 + 80 * _ring.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: _logoScale.value,
                        child: const Hero(tag: SplashScreen.logoHeroTag, child: AppLogo()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: const Text(
                      'PalmTrack',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _subtitleFade,
                  child: const Text(
                    'ระบบจัดการสวนปาล์มน้ำมัน',
                    style: TextStyle(color: Color(0xFF86EFAC), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),
                // แถบโหลด
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress.value,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF86EFAC)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// กล่องโลโก้ 🌴 ใช้ร่วมกันระหว่างหน้า Splash กับหน้า Login
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    // Material ครอบไว้ ไม่ให้ตัวอักษรขึ้นขีดเส้นใต้สีเหลืองระหว่างที่ Hero กำลังลอย
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: Text('🌴', style: TextStyle(fontSize: 40)),
        ),
      ),
    );
  }
}
