import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUri {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }
}

