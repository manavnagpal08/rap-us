import 'package:flutter/foundation.dart';

class MaterialPriceService {
  // Mock Database of tracked items
  final List<Map<String, dynamic>> _watchlist = [
    {
      'id': '1',
      'name': 'Pressure Treated Lumber (2x4)',
      'current_price': 8.50,
      'original_price': 10.00,
      'trend': 'down', // up, down, stable
      'percent_change': -15.0,
      'alert_threshold': -10.0,
    },
    {
      'id': '2',
      'name': 'Copper Pipe (Type L, 10ft)',
      'current_price': 25.00,
      'original_price': 22.00,
      'trend': 'up',
      'percent_change': 13.6,
      'alert_threshold': -5.0,
    },
    {
      'id': '3',
      'name': 'Drywall Sheet (4x8)',
      'current_price': 14.00,
      'original_price': 14.50,
      'trend': 'stable',
      'percent_change': -3.4,
      'alert_threshold': -10.0,
    }
  ];

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Sim network
    return _watchlist;
  }

  Future<void> addToWatchlist(String itemName) async {
    // Mock add
    debugPrint("Added $itemName to watchlist");
  }
}
