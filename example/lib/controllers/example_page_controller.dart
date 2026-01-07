import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../services/announcement_service.dart';

/// Controller/ViewModel that manages the business logic and state for the example page
/// Uses GetX for reactive state management following the GetX pattern
class ExamplePageController extends GetxController {
  AnnouncementService?
  _announcementService; // this can be null while initialization is in progress. Need a way to represent uninitialized state in UI.

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
  bool get isSchedulerInitialized => _announcementService != null;
  String? get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value != null;

  /// Initialize the announcement scheduler
  Future<void> _initializeScheduler() async {
    _isInitializing.value = true;
    _errorMessage.value = null;

    try {
      _announcementService = await AnnouncementService.create(
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
      _announcementService!.statusStream.listen((status) {
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

    if (_announcementService == null) return false;

    try {
      await _announcementService!.scheduleExampleAnnouncements();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to schedule announcements: $e';
      return false;
    }
  }

  /// Cancel all announcements
  Future<bool> cancelAllAnnouncements() async {
    _errorMessage.value = null;

    if (_announcementService == null) return false;

    try {
      await _announcementService!.cancelAllAnnouncements();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to cancel announcements: $e';
      return false;
    }
  }

  /// Get scheduled announcements for display
  Future<List<ScheduledAnnouncement>> getScheduledAnnouncements() async {
    _errorMessage.value = null;

    if (_announcementService == null) return [];

    try {
      return await _announcementService!.getScheduledAnnouncements();
    } catch (e) {
      _errorMessage.value = 'Failed to load announcements: $e';
      return [];
    }
  }

  @override
  void onClose() {
    _announcementService?.dispose();
    super.onClose();
  }
}
