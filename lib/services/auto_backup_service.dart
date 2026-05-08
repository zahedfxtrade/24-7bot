import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'data_service.dart';

const _kAutoBackupTask = 'dss_auto_backup';
const _kPendingBackupKey = 'pending_backup_path';
const _kLastBackupTimeKey = 'last_backup_time';

// ─── Top-level Workmanager callback ──────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _kAutoBackupTask) {
      await AutoBackupService._runBackupInBackground();
    }
    return true;
  });
}

// ─── Auto Backup Service ──────────────────────────────────────────────────────

class AutoBackupService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(
      const InitializationSettings(android: android),
      // Notification tap just brings app to foreground — 
      // the app itself handles the pending backup on resume.
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await _scheduleDaily();
  }

  // ── Schedule daily at 23:00 ───────────────────────────────────────────────

  static Future<void> _scheduleDaily() async {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 23, 0, 0);
    if (now.isAfter(next)) next = next.add(const Duration(days: 1));
    final delay = next.difference(now);

    await Workmanager().registerPeriodicTask(
      _kAutoBackupTask,
      _kAutoBackupTask,
      frequency: const Duration(hours: 24),
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.not_required),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  // ── Background backup (runs in Workmanager isolate) ───────────────────────

  static Future<void> _runBackupInBackground() async {
    try {
      await DataService().load();
      final path = await DataService().saveBackupToFile();

      // Store the path in SharedPreferences so the app can pick it up
      // whenever the user opens it — even next morning.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendingBackupKey, path);
      await prefs.setString(
          _kLastBackupTimeKey, DateTime.now().toIso8601String());

      await _showNotification(
        title: '✅ Auto Backup Done',
        body: 'Backup ready. Open the app anytime to upload to Google Drive.',
      );
    } catch (e) {
      await _showNotification(
        title: '⚠️ Auto Backup Failed',
        body: 'Could not create backup: $e',
      );
    }
  }

  // ── Check for pending backup when app opens ───────────────────────────────
  // Call this from the home screen or backup screen on build/resume.
  // Returns the pending backup file path, or null if nothing pending.

  static Future<String?> getPendingBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kPendingBackupKey);
    if (path == null) return null;
    // Check file actually exists (might have been cleared)
    if (!await File(path).exists()) {
      await prefs.remove(_kPendingBackupKey);
      return null;
    }
    return path;
  }

  static Future<String?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastBackupTimeKey);
  }

  // Call this after user uploads — clears the pending flag
  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingBackupKey);
  }

  // ── Upload pending backup to Google Drive (share sheet) ───────────────────

  static Future<void> uploadPending(BuildContext context) async {
    final path = await getPendingBackupPath();
    if (path == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending backup found.')),
        );
      }
      return;
    }
    await _shareFile(path);
    await clearPending();
  }

  static Future<void> _shareFile(String path) async {
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/json')],
      subject: 'DSS Attendance Backup',
      text: 'Daily auto backup – tap Google Drive to upload.',
    );
  }

  // ── Notification ──────────────────────────────────────────────────────────

  static Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dss_backup_channel',
      'Auto Backup',
      channelDescription: 'Daily automatic backup notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      // Keep notification visible until user dismisses
      autoCancel: false,
      ongoing: false,
    );
    await _notif.show(
      42,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  // Notification tap — just dismiss it, the banner inside the app handles upload
  static void _onNotifTap(NotificationResponse response) {
    // App is brought to foreground by the OS.
    // The backup screen / home screen will detect the pending backup
    // on its next build() via getPendingBackupPath().
  }

  // ── Manual trigger ────────────────────────────────────────────────────────

  static Future<void> triggerNow(BuildContext context) async {
    try {
      final path = await DataService().saveBackupToFile();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendingBackupKey, path);
      await prefs.setString(
          _kLastBackupTimeKey, DateTime.now().toIso8601String());
      await _shareFile(path);
      await clearPending();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }
}
