import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notification_scheduler/notification_scheduler.dart';

/// Controller/ViewModel that manages the business logic and state for the example page
/// Uses GetX for reactive state management following the GetX pattern
class ExamplePageController extends GetxController {
  NotificationService?
  _notificationService; // this can be null while initialization is in progress. Need a way to represent uninitialized state in UI.

  final _isInitializing = false.obs;
  final _errorMessage = Rxn<String>();

  static ExamplePageController get getOrPut {
    try {
      return Get.find<ExamplePageController>();
    } catch (e) {
      return Get.put(ExamplePageController._());
    }
  }

  ExamplePageController._() {
    _initializeScheduler();
  }

  // Getters for state (GetX reactive)
  bool get isInitializing => _isInitializing.value;
  bool get isSchedulerInitialized => _notificationService != null;
  String? get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value != null;

  /// Initialize the announcement scheduler
  Future<void> _initializeScheduler() async {
    _isInitializing.value = true;
    _errorMessage.value = null;

    try {
      _notificationService = await NotificationService.create(
        config: AnnouncementConfig(
          enableTTS: true,
          ttsRate: 0.5,
          ttsPitch: 1.0,
          ttsVolume: 1.0,
          enableDebugLogging: true,
          forceTimezone: true, // Use the timezone from settings
          timezoneLocation: 'America/Halifax',
          notificationConfig: NotificationConfig(
            channelId: 'example_announcements',
            channelName: 'Example Announcements',
            channelDescription: 'Example scheduled announcements',
          ),
          validationConfig: const ValidationConfig(
            maxNotificationsPerDay: 5,
            maxScheduledNotifications: 20,
          ),
        ),
      );

      // Listen to status updates
      _notificationService!.statusStream.listen((status) {
        debugPrint('Announcement status: $status');
      });
    } catch (e) {
      _errorMessage.value = 'Failed to initialize scheduler: $e';
      debugPrint('Failed to initialize scheduler: $e');
    } finally {
      _isInitializing.value = false;
    }
  }

  /// Schedule example announcements
  Future<bool> scheduleExampleAnnouncements() async {
    _errorMessage.value = null;

    if (_notificationService == null) return false;

    try {
      await _scheduleExampleAnnouncements();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to schedule announcements: $e';
      return false;
    }
  }

  Future<void> _scheduleExampleAnnouncements() async {
    final now = DateTime.now();

    // Schedule a one-time announcement 1 minute from now
    await _notificationService!.scheduleOnceOff(
      content: 'This is a one-time announcement 5 seconds ago.',
      dateTime: now.add(const Duration(seconds: 5)),
      metadata: {'type': 'one-time'},
    );

    await _notificationService!.scheduleDaily(
      content: 'Good morning! This is your daily announcement at 9:00 AM.',
      time: const TimeOfDay(hour: 9, minute: 0),
      metadata: {'type': 'daily'},
    );

    await _notificationService!.scheduleWeekly(
      content: 'Happy Odd Day! This is your weekly announcement at 5:00 PM.',
      time: const TimeOfDay(hour: 17, minute: 0),
      weekdays: [1, 3, 5, 7], // Odd days
      metadata: {'type': 'weekly'},
    );
  }

  /// Cancel all announcements
  Future<bool> cancelAllAnnouncements() async {
    _errorMessage.value = null;

    if (_notificationService == null) return false;

    try {
      await _notificationService!.cancelAllAnnouncements();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to cancel announcements: $e';
      return false;
    }
  }

  /// Get scheduled announcements for display
  Future<List<ScheduledNotification>> getScheduledAnnouncements() async {
    _errorMessage.value = null;

    if (_notificationService == null) return [];

    try {
      return await _notificationService!.getScheduledAnnouncements();
    } catch (e) {
      _errorMessage.value = 'Failed to load announcements: $e';
      return [];
    }
  }

  @override
  void onClose() {
    _notificationService?.dispose();
    super.onClose();
  }
}
