import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:schedule_voice_app/tts_service.dart';
import 'package:schedule_voice_app/weather_service.dart';
import 'package:schedule_voice_app/background_service.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  final WeatherService weatherService;
  final TtsService ttsService;

  NotificationService({
    required this.weatherService,
    required this.ttsService,
  });

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await notificationsPlugin.initialize(settings, onDidReceiveNotificationResponse: onNotificationTapped);
    
    // WorkManager 초기화
    await BackgroundService.initialize();
  }
  
  // 알림 클릭 시 실행되는 함수
  void onNotificationTapped(NotificationResponse response) async {
    print('알림이 클릭되었습니다: ${response.payload}');
    
    // 페이로드에서 날씨 정보 추출
    if (response.payload != null && response.payload!.isNotEmpty) {
      await ttsService.speak(response.payload!);
    } else {
      // 페이로드가 없으면 현재 날씨를 가져와서 읽어주기
      await notifyWeather();
    }
  }

  Future<void> notifyWeather() async {
    String weather = await weatherService.getWeather();
    await ttsService.speak(weather);
  }

  Future<void> scheduleDaily7AM() async {
    final now = tz.TZDateTime.now(tz.local);
    
    // 오늘 아침 7시를 기준으로 TZDateTime 생성
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7, // 시(hour): 7시
      0, // 분(minute): 0분
    );

    // 만약 현재 시각이 이미 7시 이후라면 → 내일 아침 7시로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 1. flutter_local_notifications로 정확한 시간에 알림 스케줄링
    await notificationsPlugin.zonedSchedule(
      0,
      '🌤️ 오늘의 날씨',
      '알림을 터치하면 날씨를 음성으로 안내해드립니다',
      scheduledDate,
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
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'weather_voice', // 페이로드 설정
    );

    // 2. WorkManager로 백그라운드 작업 스케줄링 (백업용)
    await BackgroundService.scheduleWeatherNotification();

    print('매일 아침 7시 날씨 음성 알림이 예약되었습니다: $scheduledDate');
  }
  
  Future<void> cancelDaily7AM() async {
    // 기존 알림 취소
    await notificationsPlugin.cancel(0);
    
    // WorkManager 작업 취소
    await BackgroundService.cancelWeatherNotification();
    
    print('매일 아침 7시 날씨 알림이 취소되었습니다.');
  }
}