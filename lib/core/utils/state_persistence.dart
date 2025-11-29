import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Utility for persisting and restoring application state
class StatePersistence {
  StatePersistence._();
  
  static final StatePersistence instance = StatePersistence._();
  
  SharedPreferences? _prefs;
  
  /// Initialize shared preferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Ensure preferences are initialized
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }
  
  /// Save navigation state
  Future<bool> saveNavigationIndex(int index) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setInt('navigation_index', index);
    } catch (e) {
      debugPrint('Failed to save navigation index: $e');
      return false;
    }
  }
  
  /// Load navigation state
  Future<int?> loadNavigationIndex() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getInt('navigation_index');
    } catch (e) {
      debugPrint('Failed to load navigation index: $e');
      return null;
    }
  }
  
  /// Save last AI inference results (for quick access)
  Future<bool> saveLastInferenceResults(String featureKey, Map<String, dynamic> results) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(results);
      return await prefs.setString('last_inference_$featureKey', jsonString);
    } catch (e) {
      debugPrint('Failed to save inference results: $e');
      return false;
    }
  }
  
  /// Load last AI inference results
  Future<Map<String, dynamic>?> loadLastInferenceResults(String featureKey) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString('last_inference_$featureKey');
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to load inference results: $e');
      return null;
    }
  }
  
  /// Save app settings
  Future<bool> saveSetting(String key, dynamic value) async {
    try {
      final prefs = await _getPrefs();
      
      if (value is bool) {
        return await prefs.setBool(key, value);
      } else if (value is int) {
        return await prefs.setInt(key, value);
      } else if (value is double) {
        return await prefs.setDouble(key, value);
      } else if (value is String) {
        return await prefs.setString(key, value);
      } else if (value is List<String>) {
        return await prefs.setStringList(key, value);
      } else {
        // For complex objects, serialize to JSON
        final jsonString = jsonEncode(value);
        return await prefs.setString(key, jsonString);
      }
    } catch (e) {
      debugPrint('Failed to save setting $key: $e');
      return false;
    }
  }
  
  /// Load app setting
  Future<T?> loadSetting<T>(String key) async {
    try {
      final prefs = await _getPrefs();
      
      if (T == bool) {
        return prefs.getBool(key) as T?;
      } else if (T == int) {
        return prefs.getInt(key) as T?;
      } else if (T == double) {
        return prefs.getDouble(key) as T?;
      } else if (T == String) {
        return prefs.getString(key) as T?;
      } else {
        // For complex objects, deserialize from JSON
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          return jsonDecode(jsonString) as T?;
        }
        return null;
      }
    } catch (e) {
      debugPrint('Failed to load setting $key: $e');
      return null;
    }
  }
  
  /// Clear specific key
  Future<bool> clearKey(String key) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.remove(key);
    } catch (e) {
      debugPrint('Failed to clear key $key: $e');
      return false;
    }
  }
  
  /// Clear all persisted state
  Future<bool> clearAll() async {
    try {
      final prefs = await _getPrefs();
      return await prefs.clear();
    } catch (e) {
      debugPrint('Failed to clear all state: $e');
      return false;
    }
  }
  
  /// Check if key exists
  Future<bool> hasKey(String key) async {
    try {
      final prefs = await _getPrefs();
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('Failed to check key $key: $e');
      return false;
    }
  }
  
  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getKeys();
    } catch (e) {
      debugPrint('Failed to get all keys: $e');
      return {};
    }
  }
}
