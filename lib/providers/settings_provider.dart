import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  final HiveService _hiveService;
  final NotificationService _notificationService;

  SettingsProvider(this._hiveService, this._notificationService);

  bool _dailyReminderEnabled = false;
  bool get dailyReminderEnabled => _dailyReminderEnabled;

  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay get dailyReminderTime => _dailyReminderTime;
  
  bool _showWhatsNew = false;
  bool get showWhatsNew => _showWhatsNew;

  Future<void> loadSettings() async {
    _dailyReminderEnabled = await _hiveService.dailyReminderEnabled;
    final timeString = await _hiveService.dailyReminderTime;
    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        _dailyReminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    
    // Check version for what's new dialog
    final isFirstLaunch = await _hiveService.isFirstLaunch;
    final lastSeenVersion = await _hiveService.lastSeenVersion;
    
    if (!isFirstLaunch) {
      if (lastSeenVersion == null || lastSeenVersion != AppConstants.appVersion) {
        _showWhatsNew = true;
      }
    } else {
      // If it's a new install, just save the version silently
      await _hiveService.setLastSeenVersion(AppConstants.appVersion);
    }
    
    notifyListeners();
  }
  
  Future<void> dismissWhatsNew() async {
    _showWhatsNew = false;
    await _hiveService.setLastSeenVersion(AppConstants.appVersion);
    notifyListeners();
  }

  Future<bool> toggleDailyReminder(bool value) async {
    try {
      _dailyReminderEnabled = value;
      await _hiveService.setDailyReminderEnabled(value);
      
      if (value) {
        final granted = await _notificationService.requestPermissions();
        if (granted) {
          await _notificationService.scheduleDailyNotification(_dailyReminderTime);
        } else {
          _dailyReminderEnabled = false;
          await _hiveService.setDailyReminderEnabled(false);
          notifyListeners();
          return false;
        }
      } else {
        await _notificationService.cancelNotifications();
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error toggling reminder: $e");
      _dailyReminderEnabled = !value;
      await _hiveService.setDailyReminderEnabled(!value);
      notifyListeners();
      return false;
    }
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    try {
      _dailyReminderTime = time;
      final timeString = '${time.hour}:${time.minute}';
      await _hiveService.setDailyReminderTime(timeString);
      
      if (_dailyReminderEnabled) {
        await _notificationService.scheduleDailyNotification(time);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error scheduling time: $e");
    }
  }
}
