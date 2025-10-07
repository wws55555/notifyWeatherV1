import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schedule_voice_app/weather_service.dart';
import 'package:schedule_voice_app/tts_service.dart';

class BackgroundService {
  static const String taskName = "weatherNotificationTask";
  
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }
  
  static Future<void> scheduleWeatherNotification() async {
    await Workmanager().registerPeriodicTask(
      "1",
      taskName,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
  
  static Future<void> cancelWeatherNotification() async {
    await Workmanager().cancelByUniqueName("1");
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final weatherService = WeatherService();
      final ttsService = TtsService();
      final notificationService = FlutterLocalNotificationsPlugin();
      
      // 알림 초기화
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings, 
        iOS: iosSettings
      );
      await notificationService.initialize(settings);
      
      // 날씨 정보 가져오기
      final weather = await weatherService.getWeather();
      
      // 중복 알림 방지: 이미 zonedSchedule 알림이 있는지 확인
      final pendingNotifications = await notificationService.pendingNotificationRequests();
      final hasZonedScheduleNotification = pendingNotifications.any((notification) => notification.id == 0);
      
      // zonedSchedule 알림이 없을 때만 백업 알림 표시
      if (!hasZonedScheduleNotification) {
        // 알림 표시 (날씨 정보를 페이로드로 포함)
        // ID 1을 사용하여 zonedSchedule과 구분
        await notificationService.show(
        1, // ⭐ 다른 ID 사용
        '🌤️ 오늘의 날씨 (백업)',
        '알림을 터치하면 날씨를 음성으로 안내해드립니다',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weather_channel',
            '날씨 알림',
            channelDescription: '매일 아침 7시 날씨 알림',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            actions: [
              AndroidNotificationAction(
                'speak_weather',
                '음성으로 들려주기',
                icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: weather, // 날씨 정보를 페이로드로 전달
        );
      }
      
      return Future.value(true);
    } catch (e) {
      print('백그라운드 작업 실행 중 오류: $e');
      return Future.value(false);
    }
  });
}
