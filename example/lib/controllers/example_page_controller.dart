import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../services/announcement_service.dart';

/// Controller/ViewModel that manages the business logic and state for the example page
/// Uses GetX for reactive state management following the GetX pattern
class ExamplePageController extends GetxController {
  final AnnouncementService _announcementService;

  final _scheduledAnnouncementIds = <String>[].obs;
  final _isInitializing = false.obs;
  final _errorMessage = Rxn<String>();

  ExamplePageController(this._announcementService);

  // Getters for state (GetX reactive)
  bool get isInitializing => _isInitializing.value;
  bool get isSchedulerInitialized => _announcementService.isInitialized;
  List<String> get scheduledAnnouncementIds => _scheduledAnnouncementIds;
  String? get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value != null;

  /// Initialize the announcement scheduler
  Future<void> initializeScheduler() async {
    _isInitializing.value = true;
    _errorMessage.value = null;

    try {
      await _announcementService.initialize();

      // Listen to status updates
      _announcementService.statusStream?.listen((status) {
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

    try {
      final ids = await _announcementService.scheduleExampleAnnouncements();
      _scheduledAnnouncementIds.addAll(ids);
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to schedule announcements: $e';
      return false;
    }
  }

  /// Cancel all announcements
  Future<bool> cancelAllAnnouncements() async {
    _errorMessage.value = null;

    try {
      await _announcementService.cancelAllAnnouncements();
      _scheduledAnnouncementIds.clear();
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to cancel announcements: $e';
      return false;
    }
  }

  /// Get scheduled announcements for display
  Future<List<ScheduledAnnouncement>> getScheduledAnnouncements() async {
    _errorMessage.value = null;

    try {
      return await _announcementService.getScheduledAnnouncements();
    } catch (e) {
      _errorMessage.value = 'Failed to load announcements: $e';
      return [];
    }
  }

  @override
  void onClose() {
    _announcementService.dispose();
    super.onClose();
  }
}
