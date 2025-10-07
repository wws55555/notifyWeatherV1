import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "b38637011a720c6704b4a7f781107b9f";

  getWeather() async {
    final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=Seoul&appid=$apiKey&units=metric&lang=kr"
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final temp = data['main']['temp'];
      final desc = data['weather'][0]['description'];
      return "오늘 서울의 날씨는 $desc, 기온은 $temp도입니다.";
    } else {
      return "날씨 정보를 가져올 수 없습니다.";
    }
  }
}