import 'package:flutter/services.dart';

class CloverService {
  static const MethodChannel _channel = MethodChannel('com.tuapp.clover');

  static Future<bool> initialize() async {
    try {
      return await _channel.invokeMethod('initialize');
    } catch (e) {
      print('Error initializing Clover: $e');
      return false;
    }
  }

  static Future<String> makePayment(int amount) async {
    try {
      return await _channel.invokeMethod('makePayment', {'amount': amount});
    } catch (e) {
      print('Error making payment: $e');
      return 'Error: ${e.toString()}';
    }
  }

  static Future<bool> disconnect() async {
    try {
      return await _channel.invokeMethod('disconnect');
    } catch (e) {
      print('Error disconnecting Clover: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getInventoryItems() async {
    try {
      final items = await _channel.invokeMethod('getInventoryItems');
      return items as List<dynamic>;
    } catch (e) {
      print('Error getting inventory items: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getItemDetails(String itemId) async {
    try {
      final item =
          await _channel.invokeMethod('getItemDetails', {'itemId': itemId});
      return item as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting item details: $e');
      return null;
    }
  }
}
