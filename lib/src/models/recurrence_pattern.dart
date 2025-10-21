/// Enumeration for different recurrence patterns for announcements.
///
/// Defines common patterns for recurring announcements. Use these patterns
/// to easily schedule announcements that repeat on a regular basis without
/// having to manually specify dates.
///
/// ## Values
///
/// - [daily]: Announcement occurs every day (all 7 days of the week)
/// - [weekdays]: Announcement occurs Monday through Friday
/// - [weekends]: Announcement occurs Saturday and Sunday
/// - [custom]: Announcement occurs on user-specified days (requires customDays)
///
/// ## Usage Example
///
/// ```dart
/// // Daily morning reminder
/// await scheduler.scheduleAnnouncement(
///   content: 'Good morning!',
///   announcementTime: TimeOfDay(hour: 7, minute: 0),
///   recurrence: RecurrencePattern.daily,
/// );
///
/// // Work week reminder
/// await scheduler.scheduleAnnouncement(
///   content: 'Time for work',
///   announcementTime: TimeOfDay(hour: 8, minute: 30),
///   recurrence: RecurrencePattern.weekdays,
/// );
///
/// // Weekend reminder
/// await scheduler.scheduleAnnouncement(
///   content: 'Enjoy your weekend!',
///   announcementTime: TimeOfDay(hour: 10, minute: 0),
///   recurrence: RecurrencePattern.weekends,
/// );
///
/// // Custom pattern (Monday, Wednesday, Friday)
/// await scheduler.scheduleAnnouncement(
///   content: 'Gym day!',
///   announcementTime: TimeOfDay(hour: 6, minute: 0),
///   recurrence: RecurrencePattern.custom,
///   customDays: [1, 3, 5], // 1=Monday, 2=Tuesday, ..., 7=Sunday
/// );
/// ```
///
/// See also:
///
/// - [RecurrencePatternExtension] for utility methods
/// - [AnnouncementScheduler.scheduleAnnouncement] to create recurring announcements
enum RecurrencePattern { daily, weekdays, weekends, custom }

/// Extension methods for RecurrencePattern to provide utility functions
extension RecurrencePatternExtension on RecurrencePattern {
  String get displayName {
    switch (this) {
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekdays:
        return 'Weekdays';
      case RecurrencePattern.weekends:
        return 'Weekends';
      case RecurrencePattern.custom:
        return 'Custom';
    }
  }

  /// Get the default days for non-custom patterns
  /// Returns days of week where 1=Monday, 2=Tuesday, ..., 7=Sunday
  List<int> get defaultDays {
    switch (this) {
      case RecurrencePattern.daily:
        return [1, 2, 3, 4, 5, 6, 7]; // All days
      case RecurrencePattern.weekdays:
        return [1, 2, 3, 4, 5]; // Monday to Friday
      case RecurrencePattern.weekends:
        return [6, 7]; // Saturday and Sunday
      case RecurrencePattern.custom:
        return []; // Custom pattern has no defaults
    }
  }
}
