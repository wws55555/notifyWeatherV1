import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:schedule_voice_app/notification_service.dart';
import 'package:schedule_voice_app/tts_service.dart';
import 'package:schedule_voice_app/weather_service.dart';

class HomePage extends StatelessWidget {

  final NotificationService notificationService = NotificationService(
    weatherService: WeatherService(),
    ttsService: TtsService(),
  );

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("날씨 음성 알림")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await notificationService.notifyWeather();
              },
              child: Text("지금 날씨 들려주기"),
            ),
            ElevatedButton(
              onPressed: () async {
                await notificationService.scheduleDaily7AM();
              },
              child: Text("아침 7시 음성 알림 예약"),
            ),
            ElevatedButton(
              onPressed: () async {
                await notificationService.cancelDaily7AM();
              },
              child: Text("음성 알림 취소"),
            ),
          ],
        ),
      ),
    );
  }
}