import 'package:flutter/material.dart';
import 'package:schedule_voice_app/notification_service.dart';
import 'package:schedule_voice_app/tts_service.dart';
import 'package:schedule_voice_app/weather_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 타임존 데이터 초기화 (이걸 안 하면 tz.local이 null!)
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul')); // 한국 시간 기준 설정

  final notificationService = NotificationService(
    weatherService: WeatherService(),
    ttsService: TtsService(),
  );
  await notificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}
