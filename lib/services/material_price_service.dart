import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MaterialPriceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    try {
      final snapshot = await _db.collection('market_prices').get();
      if (snapshot.docs.isEmpty) {
        // Seed default data if empty (First run)
        await _seedDefaultPrices();
        return _defaultPrices;
      }
      
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      debugPrint("Price Service Error: $e");
      return _defaultPrices; // Fallback to local default if offline/error
    }
  }

  Future<void> _seedDefaultPrices() async {
    for (var item in _defaultPrices) {
       await _db.collection('market_prices').add(item);
    }
  }

  // Fallback / Initial Data
  final List<Map<String, dynamic>> _defaultPrices = [
    {
      'name': 'Pressure Treated Lumber (2x4)',
      'current_price': 8.50,
      'original_price': 10.00,
      'trend': 'down', 
      'percent_change': -15.0,
      'alert_threshold': -10.0,
    },
    {
      'name': 'Copper Pipe (Type L, 10ft)',
      'current_price': 25.00,
      'original_price': 22.00,
      'trend': 'up',
      'percent_change': 13.6,
      'alert_threshold': -5.0,
    },
    {
      'name': 'Drywall Sheet (4x8)',
      'current_price': 14.00,
      'original_price': 14.50,
      'trend': 'stable',
      'percent_change': -3.4,
      'alert_threshold': -10.0,
    }
  ];

  Future<void> addToWatchlist(String itemName) async {
     // Implementation for user-specific watchlist would go here
     debugPrint("User tracked: $itemName");
  }
}
