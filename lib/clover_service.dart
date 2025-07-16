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
}
