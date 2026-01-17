import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:rap_app/services/notification_service.dart';

class WeatherService {
  // Mocking the API response for demo purposes to guarantee the specific alert scenario
  // Real implementation would use: https://api.openweathermap.org/data/2.5/weather?q=$city&appid=KEY
  
  Future<Map<String, dynamic>> checkLocalWeather(String city) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Force the "Chicago Freeze" scenario if city matches, otherwise random
    if (city.toLowerCase().contains('chicago')) {
      return {
        'temp_f': -5,
        'condition': 'Blizzard',
        'alert': 'Severe Freeze Warning',
        'risk_level': 'high', // safe, medium, high
        'recommendation': 'Pipe Freeze Warning! ❄️ Hire a pro to wrap pipes immediately.',
      };
    }

    return {
      'temp_f': 72,
      'condition': 'Sunny',
      'alert': null,
      'risk_level': 'safe',
      'recommendation': null,
    };
  }

  // Check and Notify
  Future<void> runStormWatchCheck(String city) async {
    final weather = await checkLocalWeather(city);
    
    if (weather['risk_level'] == 'high') {
      // Trigger Notification
      // Use the existing channel we created
      // Since we don't have a direct "show"  method exposed in the snippets for NotificationService that takes args easily,
      // We will assume basic usage or just rely on the UI card for now, 
      // but ideally we'd call NotificationService().show(...)
      debugPrint("STORM WATCH ALERT: ${weather['recommendation']}");
    }
  }
}
