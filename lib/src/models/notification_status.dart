/// Status of a notification during its lifecycle.
///
/// Represents the different states a notification can be in from creation
/// to delivery. Use these status values to track notification progress and
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
///     case NotificationStatus.scheduled:
///       print('✓ Announcement scheduled');
///       showSnackBar('Announcement scheduled successfully');
///       break;
///
///     case NotificationStatus.delivering:
///       print('📢 Delivering announcement...');
///       showLoadingIndicator();
///       break;
///
///     case NotificationStatus.completed:
///       print('✅ Announcement delivered');
///       hideLoadingIndicator();
///       logSuccess();
///       break;
///
///     case NotificationStatus.failed:
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
/// - [NotificationStatusExtension] for utility methods
/// - [NotificationScheduler.statusStream] for status updates
enum NotificationStatus {
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
extension NotificationStatusExtension on NotificationStatus {
  String get displayName {
    switch (this) {
      case NotificationStatus.scheduled:
        return 'Scheduled';
      case NotificationStatus.delivering:
        return 'Delivering';
      case NotificationStatus.completed:
        return 'Completed';
      case NotificationStatus.failed:
        return 'Failed';
    }
  }

  bool get isActive =>
      this == NotificationStatus.scheduled ||
      this == NotificationStatus.delivering;
  bool get isComplete =>
      this == NotificationStatus.completed || this == NotificationStatus.failed;
}
