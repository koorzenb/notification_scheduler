/// Configuration for validation rules applied by the announcement scheduler.
///
/// This class defines limits and validation rules to prevent excessive
/// notifications and ensure robust scheduling behavior. These safeguards
/// help maintain good user experience and system performance.
///
/// ## Why Validation?
///
/// - Prevents notification spam that could annoy users
/// - Protects against programming errors that schedule too many notifications
/// - Ensures announcements work correctly across timezones and edge cases
/// - Maintains device performance and battery life
///
/// ## Usage Example
///
/// ```dart
/// // Strict limits for user-facing apps
/// final strictConfig = ValidationConfig(
///   maxNotificationsPerDay: 5,
///   maxScheduledNotifications: 30,
///   enableEdgeCaseValidation: true,
///   enableTimezoneValidation: true,
///   minAnnouncementIntervalMinutes: 15,
///   maxSchedulingDaysInAdvance: 7,
/// );
///
/// // Relaxed limits for internal/testing use
/// final relaxedConfig = ValidationConfig(
///   maxNotificationsPerDay: 20,
///   maxScheduledNotifications: 100,
///   enableEdgeCaseValidation: false,
///   minAnnouncementIntervalMinutes: 1,
///   maxSchedulingDaysInAdvance: 30,
/// );
/// ```
///
/// ## Configuration Options
///
/// - [maxNotificationsPerDay]: Maximum announcements allowed per day
/// - [maxScheduledNotifications]: Maximum total scheduled announcements
/// - [enableEdgeCaseValidation]: Validate DST transitions, leap days, etc.
/// - [enableTimezoneValidation]: Validate timezone-related scheduling
/// - [minAnnouncementIntervalMinutes]: Minimum time between announcements
/// - [maxSchedulingDaysInAdvance]: How far ahead to schedule recurring announcements
///
/// ## Default Values
///
/// The defaults provide reasonable limits for most applications:
///
/// - Up to 10 announcements per day
/// - Up to 50 total scheduled announcements
/// - Edge case validation enabled
/// - Timezone validation enabled
/// - Minimum 1 minute between announcements
/// - Schedule up to 14 days in advance
///
/// See also:
///
/// - [AnnouncementConfig] for overall scheduler configuration
class ValidationConfig {
  /// Maximum number of notifications that can be scheduled per day
  final int maxNotificationsPerDay;

  /// Maximum total number of scheduled notifications
  final int maxScheduledNotifications;

  /// Whether to enable edge case validation (DST transitions, leap days, etc.)
  final bool enableEdgeCaseValidation;

  /// Whether to enable timezone validation
  final bool enableTimezoneValidation;

  /// Minimum interval between announcements (in minutes)
  final int minAnnouncementIntervalMinutes;

  /// Maximum days in advance to schedule recurring notifications
  final int maxSchedulingDaysInAdvance;

  const ValidationConfig({
    this.maxNotificationsPerDay = 10,
    this.maxScheduledNotifications = 50,
    this.enableEdgeCaseValidation = true,
    this.enableTimezoneValidation = true,
    this.minAnnouncementIntervalMinutes = 1,
    this.maxSchedulingDaysInAdvance = 14,
  });

  /// Creates a copy of this configuration with the given fields replaced
  ValidationConfig copyWith({
    int? maxNotificationsPerDay,
    int? maxScheduledNotifications,
    bool? enableEdgeCaseValidation,
    bool? enableTimezoneValidation,
    int? minAnnouncementIntervalMinutes,
    int? maxSchedulingDaysInAdvance,
  }) {
    return ValidationConfig(
      maxNotificationsPerDay:
          maxNotificationsPerDay ?? this.maxNotificationsPerDay,
      maxScheduledNotifications:
          maxScheduledNotifications ?? this.maxScheduledNotifications,
      enableEdgeCaseValidation:
          enableEdgeCaseValidation ?? this.enableEdgeCaseValidation,
      enableTimezoneValidation:
          enableTimezoneValidation ?? this.enableTimezoneValidation,
      minAnnouncementIntervalMinutes:
          minAnnouncementIntervalMinutes ?? this.minAnnouncementIntervalMinutes,
      maxSchedulingDaysInAdvance:
          maxSchedulingDaysInAdvance ?? this.maxSchedulingDaysInAdvance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationConfig &&
          runtimeType == other.runtimeType &&
          maxNotificationsPerDay == other.maxNotificationsPerDay &&
          maxScheduledNotifications == other.maxScheduledNotifications &&
          enableEdgeCaseValidation == other.enableEdgeCaseValidation &&
          enableTimezoneValidation == other.enableTimezoneValidation &&
          minAnnouncementIntervalMinutes ==
              other.minAnnouncementIntervalMinutes &&
          maxSchedulingDaysInAdvance == other.maxSchedulingDaysInAdvance;

  @override
  int get hashCode =>
      maxNotificationsPerDay.hashCode ^
      maxScheduledNotifications.hashCode ^
      enableEdgeCaseValidation.hashCode ^
      enableTimezoneValidation.hashCode ^
      minAnnouncementIntervalMinutes.hashCode ^
      maxSchedulingDaysInAdvance.hashCode;

  @override
  String toString() {
    return 'ValidationConfig{'
        'maxNotificationsPerDay: $maxNotificationsPerDay, '
        'maxScheduledNotifications: $maxScheduledNotifications, '
        'enableEdgeCaseValidation: $enableEdgeCaseValidation, '
        'enableTimezoneValidation: $enableTimezoneValidation, '
        'minAnnouncementIntervalMinutes: $minAnnouncementIntervalMinutes, '
        'maxSchedulingDaysInAdvance: $maxSchedulingDaysInAdvance'
        '}';
  }
}
