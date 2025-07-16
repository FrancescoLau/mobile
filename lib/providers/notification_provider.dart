import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _reviewNotifications = true;
  bool _adminNotifications = true;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get workoutReminders => _workoutReminders;
  bool get reviewNotifications => _reviewNotifications;
  bool get adminNotifications => _adminNotifications;

  // Chiavi per SharedPreferences
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyWorkoutReminders = 'workout_reminders';
  static const String _keyReviewNotifications = 'review_notifications';
  static const String _keyAdminNotifications = 'admin_notifications';

  // Carica le impostazioni salvate
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _workoutReminders = prefs.getBool(_keyWorkoutReminders) ?? true;
    _reviewNotifications = prefs.getBool(_keyReviewNotifications) ?? true;
    _adminNotifications = prefs.getBool(_keyAdminNotifications) ?? true;
    notifyListeners();
  }

  // Salva le impostazioni
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, _notificationsEnabled);
    await prefs.setBool(_keyWorkoutReminders, _workoutReminders);
    await prefs.setBool(_keyReviewNotifications, _reviewNotifications);
    await prefs.setBool(_keyAdminNotifications, _adminNotifications);
  }

  // Abilita/disabilita tutte le notifiche
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;

    // Se disabilita tutte le notifiche, disabilita anche le sottocategorie
    if (!enabled) {
      _workoutReminders = false;
      _reviewNotifications = false;
      _adminNotifications = false;
    }

    await _saveSettings();
    notifyListeners();
  }

  // Gestione promemoria allenamenti
  Future<void> setWorkoutReminders(bool enabled) async {
    _workoutReminders = enabled;

    // Se abilita una sottocategoria, abilita anche le notifiche generali
    if (enabled) {
      _notificationsEnabled = true;
    }

    await _saveSettings();
    notifyListeners();
  }

  // Gestione notifiche recensioni
  Future<void> setReviewNotifications(bool enabled) async {
    _reviewNotifications = enabled;

    if (enabled) {
      _notificationsEnabled = true;
    }

    await _saveSettings();
    notifyListeners();
  }

  // Gestione notifiche admin
  Future<void> setAdminNotifications(bool enabled) async {
    _adminNotifications = enabled;

    if (enabled) {
      _notificationsEnabled = true;
    }

    await _saveSettings();
    notifyListeners();
  }

  // Reset alle impostazioni predefinite
  Future<void> resetToDefaults() async {
    _notificationsEnabled = true;
    _workoutReminders = true;
    _reviewNotifications = true;
    _adminNotifications = true;
    await _saveSettings();
    notifyListeners();
  }
}
