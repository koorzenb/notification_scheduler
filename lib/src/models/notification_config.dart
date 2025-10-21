import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configuration for notifications used by the announcement scheduler.
///
/// This class defines how notifications are displayed and behave on different
/// platforms. On Android, these settings create a notification channel. On
/// iOS and macOS, they control notification presentation.
///
/// ## Platform Support
///
/// ### Android
///
/// - Uses notification channels (required for Android 8.0+)
/// - Supports importance levels, lights, vibration, and badges
/// - Requires appropriate permissions in AndroidManifest.xml
///
/// ### iOS/macOS
///
/// - Requests notification permissions on first use
/// - Supports alerts, badges, and sounds
/// - Respects system notification settings
///
/// ## Usage Example
///
/// ```dart
/// // High-priority notifications with all features
/// final config = NotificationConfig(
///   channelId: 'daily_reminders',
///   channelName: 'Daily Reminders',
///   channelDescription: 'Important daily reminder notifications',
///   importance: Importance.high,
///   priority: Priority.high,
///   enableLights: true,
///   enableVibration: true,
///   showBadge: true,
/// );
///
/// // Quiet notifications for non-urgent announcements
/// final quietConfig = NotificationConfig(
///   channelId: 'background_announcements',
///   channelName: 'Background Announcements',
///   channelDescription: 'Low-priority background announcements',
///   importance: Importance.low,
///   priority: Priority.low,
///   enableLights: false,
///   enableVibration: false,
/// );
/// ```
///
/// ## Configuration Options
///
/// - [channelId]: Unique identifier for the notification channel (Android)
/// - [channelName]: User-visible name of the notification channel
/// - [channelDescription]: User-visible description explaining the channel's purpose
/// - [importance]: How prominently to show notifications (Android 8.0+)
/// - [priority]: Notification priority for older Android versions
/// - [showBadge]: Whether to show a badge on the app icon
/// - [enableLights]: Whether to use LED notification light (Android)
/// - [enableVibration]: Whether to vibrate on notification arrival
///
/// See also:
///
/// - [AnnouncementConfig] for overall scheduler configuration
/// - [Importance] and [Priority] from flutter_local_notifications
class NotificationConfig {
  /// The unique identifier for the notification channel
  final String channelId;

  /// The user-visible name of the notification channel
  final String channelName;

  /// The user-visible description of the notification channel
  final String channelDescription;

  /// The importance level of notifications
  final Importance importance;

  /// The priority level of notifications
  final Priority priority;

  /// Whether to show a badge on the app icon
  final bool showBadge;

  /// Whether to enable lights for notifications
  final bool enableLights;

  /// Whether to enable vibration for notifications
  final bool enableVibration;

  const NotificationConfig({
    this.channelId = 'scheduled_announcements',
    this.channelName = 'Scheduled Announcements',
    this.channelDescription = 'Automated text-to-speech announcements',
    this.importance = Importance.high,
    this.priority = Priority.high,
    this.showBadge = true,
    this.enableLights = true,
    this.enableVibration = true,
  });

  /// Creates a copy of this configuration with the given fields replaced
  NotificationConfig copyWith({
    String? channelId,
    String? channelName,
    String? channelDescription,
    Importance? importance,
    Priority? priority,
    bool? showBadge,
    bool? enableLights,
    bool? enableVibration,
  }) {
    return NotificationConfig(
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelDescription: channelDescription ?? this.channelDescription,
      importance: importance ?? this.importance,
      priority: priority ?? this.priority,
      showBadge: showBadge ?? this.showBadge,
      enableLights: enableLights ?? this.enableLights,
      enableVibration: enableVibration ?? this.enableVibration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationConfig &&
          runtimeType == other.runtimeType &&
          channelId == other.channelId &&
          channelName == other.channelName &&
          channelDescription == other.channelDescription &&
          importance == other.importance &&
          priority == other.priority &&
          showBadge == other.showBadge &&
          enableLights == other.enableLights &&
          enableVibration == other.enableVibration;

  @override
  int get hashCode =>
      channelId.hashCode ^
      channelName.hashCode ^
      channelDescription.hashCode ^
      importance.hashCode ^
      priority.hashCode ^
      showBadge.hashCode ^
      enableLights.hashCode ^
      enableVibration.hashCode;

  @override
  String toString() {
    return 'NotificationConfig{'
        'channelId: $channelId, '
        'channelName: $channelName, '
        'channelDescription: $channelDescription, '
        'importance: $importance, '
        'priority: $priority, '
        'showBadge: $showBadge, '
        'enableLights: $enableLights, '
        'enableVibration: $enableVibration'
        '}';
  }
}
