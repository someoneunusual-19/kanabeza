import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';

class HiveService {
  // Box Names
  static const String productsBox = 'products';
  static const String purchasesBox = 'purchases';
  static const String salesBox = 'sales';

  // SharedPreferences Keys
  static const String pinKey = 'user_pin';
  static const String biometricsEnabledKey = 'biometrics_enabled';

  // Initialize all Hive boxes
  static Future<void> initBoxes() async {
    await Hive.openBox<Product>(productsBox);
    await Hive.openBox<Purchase>(purchasesBox);
    await Hive.openBox<Sale>(salesBox);
  }

  // Get Box Instances
  static Box<Product> get productsBoxInstance => Hive.box<Product>(productsBox);
  static Box<Purchase> get purchasesBoxInstance => Hive.box<Purchase>(purchasesBox);
  static Box<Sale> get salesBoxInstance => Hive.box<Sale>(salesBox);

  // ========================
  // PIN Management
  // ========================

  /// Get the stored 4-digit PIN
  static Future<String?> getStoredPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(pinKey);
  }

  /// Save a new 4-digit PIN
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pinKey, pin);
  }

  /// Check if it's the first launch (no PIN set yet)
  static Future<bool> isFirstLaunch() async {
    final pin = await getStoredPin();
    return pin == null || pin.isEmpty;
  }

  /// Change PIN (with validation)
  static Future<bool> changePin(String oldPin, String newPin) async {
    final currentPin = await getStoredPin();
    if (currentPin != oldPin) {
      return false; // Old PIN incorrect
    }

    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      return false; // Invalid new PIN
    }

    await setPin(newPin);
    return true;
  }

  // ========================
  // Biometrics Management
  // ========================

  /// Check if biometrics is enabled by user
  static Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(biometricsEnabledKey) ?? false;
  }

  /// Enable or disable biometrics
  static Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(biometricsEnabledKey, enabled);
  }

  // ========================
  // Data Management
  // ========================

  /// Clear all app data (use with caution)
  static Future<void> clearAllData() async {
    await productsBoxInstance.clear();
    await purchasesBoxInstance.clear();
    await salesBoxInstance.clear();
  }

  /// Get total number of products
  static int getProductCount() {
    return productsBoxInstance.length;
  }

  /// Get total number of sales
  static int getSalesCount() {
    return salesBoxInstance.length;
  }

  /// Get total number of purchases
  static int getPurchasesCount() {
    return purchasesBoxInstance.length;
  }

  // ========================
  // Utility Methods
  // ========================

  /// Close all boxes (useful when app is terminating)
  static Future<void> closeBoxes() async {
    await Hive.close();
  }
}