/// Base class for all announcement-related exceptions.
///
/// All exceptions thrown by the announcement scheduler package extend this
/// base class, making it easy to catch all scheduler-related errors with a
/// single catch block if desired.
///
/// ## Example
///
/// ```dart
/// try {
///   await scheduler.scheduleAnnouncement(...);
/// } on AnnouncementException catch (e) {
///   print('Scheduler error: ${e.message}');
/// }
/// ```
abstract class AnnouncementException implements Exception {
  /// Human-readable error message
  final String message;

  const AnnouncementException(this.message);

  @override
  String toString() => 'AnnouncementException: $message';
}

/// Thrown when notification permission is denied by the user.
///
/// This exception occurs when:
/// - User denies notification permission when requested
/// - User revokes notification permission in system settings
/// - Notification permission is restricted by device policy
///
/// ## Handling
///
/// Guide users to enable notifications in system settings:
///
/// ```dart
/// try {
///   await scheduler.initialize(config);
/// } on NotificationPermissionDeniedException {
///   showDialog(
///     context: context,
///     builder: (context) => AlertDialog(
///       title: Text('Notification Permission Required'),
///       content: Text('Please enable notifications in system settings.'),
///       actions: [
///         TextButton(
///           child: Text('Open Settings'),
///           onPressed: () => openAppSettings(),
///         ),
///       ],
///     ),
///   );
/// }
/// ```
class NotificationPermissionDeniedException extends AnnouncementException {
  const NotificationPermissionDeniedException()
    : super('Notification permission denied by user');
}

/// Thrown when notification system initialization fails.
///
/// This exception occurs when:
/// - Notification plugin fails to initialize
/// - Notification channel creation fails (Android)
/// - Invalid notification configuration provided
/// - System notification service is unavailable
///
/// ## Handling
///
/// ```dart
/// try {
///   await scheduler.initialize(config);
/// } on NotificationInitializationException catch (e) {
///   print('Failed to initialize notifications: ${e.message}');
///   // Fall back to non-notification mode or show error to user
/// }
/// ```
class NotificationInitializationException extends AnnouncementException {
  const NotificationInitializationException(super.message);
}

/// Thrown when scheduling a notification fails.
///
/// This exception occurs when:
/// - Notification could not be scheduled with the system
/// - Scheduling would exceed system limits
/// - Invalid scheduling parameters provided
/// - System notification service error
///
/// ## Handling
///
/// ```dart
/// try {
///   await scheduler.scheduleAnnouncement(...);
/// } on NotificationSchedulingException catch (e) {
///   print('Failed to schedule notification: ${e.message}');
///   // Retry with different parameters or notify user
/// }
/// ```
class NotificationSchedulingException extends AnnouncementException {
  const NotificationSchedulingException(super.message);
}

/// Thrown when TTS (Text-to-Speech) initialization fails.
///
/// This exception occurs when:
/// - TTS engine fails to initialize
/// - Requested TTS language is not available
/// - TTS service is unavailable on the device
/// - Invalid TTS configuration provided
///
/// ## Handling
///
/// ```dart
/// try {
///   await scheduler.initialize(config);
/// } on TTSInitializationException catch (e) {
///   print('TTS initialization failed: ${e.message}');
///   // Continue without TTS or use alternative voice settings
/// }
/// ```
class TTSInitializationException extends AnnouncementException {
  const TTSInitializationException(super.message);
}

/// Thrown when TTS (Text-to-Speech) announcement delivery fails.
///
/// This exception occurs when:
/// - TTS engine fails during speech
/// - TTS service becomes unavailable during announcement
/// - Audio output is unavailable
/// - TTS was interrupted by system
///
/// ## Handling
///
/// ```dart
/// try {
///   // TTS announcement triggered by notification
/// } on TTSAnnouncementException catch (e) {
///   print('TTS announcement failed: ${e.message}');
///   // Log failure and potentially retry
/// }
/// ```
class TTSAnnouncementException extends AnnouncementException {
  const TTSAnnouncementException(super.message);
}

/// Thrown when input validation fails.
///
/// This exception occurs when:
/// - Empty content provided for announcement
/// - Invalid recurrence pattern configuration
/// - Scheduling time is in the past
/// - Custom days are invalid (not 1-7)
/// - Scheduling would exceed configured limits
/// - Invalid timezone configuration
///
/// ## Handling
///
/// ```dart
/// try {
///   await scheduler.scheduleAnnouncement(
///     content: content,
///     announcementTime: time,
///     recurrence: RecurrencePattern.custom,
///     customDays: customDays,
///   );
/// } on ValidationException catch (e) {
///   print('Validation error: ${e.message}');
///   // Show error message to user with specific validation issue
///   showSnackBar(e.message);
/// }
/// ```
class ValidationException extends AnnouncementException {
  const ValidationException(super.message);
}
