/// Status of an announcement during its lifecycle.
///
/// Represents the different states an announcement can be in from creation
/// to delivery. Use these status values to track announcement progress and
/// handle different scenarios in your application.
///
/// ## Lifecycle Flow
///
/// ```
/// scheduled -> delivering -> completed
///                         -> failed
/// ```
///
/// ## Usage Example
///
/// ```dart
/// // Listen to status updates
/// scheduler.statusStream.listen((status) {
///   switch (status) {
///     case AnnouncementStatus.scheduled:
///       print('✓ Announcement scheduled');
///       showSnackBar('Announcement scheduled successfully');
///       break;
///
///     case AnnouncementStatus.delivering:
///       print('📢 Delivering announcement...');
///       showLoadingIndicator();
///       break;
///
///     case AnnouncementStatus.completed:
///       print('✅ Announcement delivered');
///       hideLoadingIndicator();
///       logSuccess();
///       break;
///
///     case AnnouncementStatus.failed:
///       print('❌ Announcement failed');
///       hideLoadingIndicator();
///       showErrorDialog();
///       break;
///   }
/// });
/// ```
///
/// See also:
///
/// - [AnnouncementStatusExtension] for utility methods
/// - [AnnouncementScheduler.statusStream] for status updates
enum AnnouncementStatus {
  /// Announcement is scheduled and waiting to be delivered.
  ///
  /// The announcement has been successfully scheduled with the notification
  /// system and will be delivered at the specified time.
  scheduled,

  /// Announcement is currently being delivered (TTS playing).
  ///
  /// The notification has been triggered and text-to-speech is actively
  /// speaking the announcement content.
  delivering,

  /// Announcement was successfully delivered.
  ///
  /// The announcement notification was shown and TTS completed successfully.
  completed,

  /// Announcement delivery failed.
  ///
  /// The announcement could not be delivered due to an error (e.g., TTS
  /// failure, notification permission denied, system error).
  failed,
}

/// Extension methods for AnnouncementStatus
extension AnnouncementStatusExtension on AnnouncementStatus {
  String get displayName {
    switch (this) {
      case AnnouncementStatus.scheduled:
        return 'Scheduled';
      case AnnouncementStatus.delivering:
        return 'Delivering';
      case AnnouncementStatus.completed:
        return 'Completed';
      case AnnouncementStatus.failed:
        return 'Failed';
    }
  }

  bool get isActive =>
      this == AnnouncementStatus.scheduled ||
      this == AnnouncementStatus.delivering;
  bool get isComplete =>
      this == AnnouncementStatus.completed || this == AnnouncementStatus.failed;
}
