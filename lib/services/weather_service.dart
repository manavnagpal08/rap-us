import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Real implementation using Open-Meteo (No API Key Required)
  
  Future<Map<String, dynamic>> checkLocalWeather() async {
    try {
      // 1. Get Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'risk_level': 'safe', 'alert': 'Location Denied', 'temp_f': 70};
        }
      }

      if (permission == LocationPermission.deniedForever) {
         return {'risk_level': 'safe', 'alert': 'Location Perm Disabled', 'temp_f': 70};
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      
      // 2. Call API
      // Using temperature_2m, weathercode
      final url = Uri.parse(
        "https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true&temperature_unit=fahrenheit&windspeed_unit=mph"
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        final temp = current['temperature'];
        final code = current['weathercode']; // WMO interpretation
        
        // 3. Analyze Risk
        String? alert;
        String? recommendation;
        String riskLevel = 'safe';
        String condition = _getWeatherDescription(code);

        // FREEZE Logic
        if (temp <= 32) {
           riskLevel = 'medium';
           alert = 'Freeze Warning';
           recommendation = 'Temps are freezing. Ensure pipes are insulated.';
           if (temp <= 10) {
             riskLevel = 'high';
             alert = 'Severe Freeze Alert';
             recommendation = 'CRITICAL: Pipes may burst. Keep water dripping or add heat tape.';
           }
        }
        
        // STORM Logic (WMO Codes: 95, 96, 99 = Thunderstorm; 66, 67 = Freezing Rain)
        if ([95, 96, 99].contains(code)) {
          riskLevel = 'high';
          alert = 'Thunderstorm Alert';
          recommendation = 'High winds/lightning detected. Secure outdoor items.';
        } else if ([66, 67, 71, 73, 75].contains(code) && temp < 32) {
           riskLevel = 'high';
           alert = 'Snow/Ice Alert';
           recommendation = 'Heavy snow or ice expected. Check roof load.';
        }

        return {
          'temp_f': temp,
          'condition': condition,
          'alert': alert ?? 'Clear Condition',
          'risk_level': riskLevel,
          'recommendation': recommendation ?? 'Weather is good. Great day for repairs!',
        };
      } else {
        throw 'Weather API Error';
      }
    } catch (e) {
      debugPrint("Weather Error: $e");
      return {
        'temp_f': 72, // Return a safe temp so UI hides the alert (72 > 40)
        'condition': 'Unknown',
        'alert': 'Weather Info Unavailable', 
        'risk_level': 'safe',
        'recommendation': null,
      };
    }
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1 || code == 2 || code == 3) return 'Partly Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Unknown';
  }
}
