# Announcement Scheduler - Public API Reference

## Overview

The `announcement_scheduler` package provides a clean, intuitive API for
scheduling text-to-speech announcements with support for one-time and recurring
  notifications.

## Core Components

### 1. AnnouncementScheduler (Main API)

The central class for all scheduling operations.

**Initialization:**

```dart
final scheduler = await AnnouncementScheduler.initialize(
  config: AnnouncementConfig(...),
);
```

**Scheduling Operations:**

- `scheduleAnnouncement()` - Schedule recurring or one-time announcement
- `scheduleOneTimeAnnouncement()` - Schedule at specific DateTime
- `cancelScheduledAnnouncements()` - Cancel all announcements
- `cancelAnnouncementById()` - Cancel specific announcement
- `getScheduledAnnouncements()` - Query scheduled items

**Monitoring:**

- `statusStream` - Stream of announcement status updates

**Cleanup:**

- `dispose()` - Release resources

### 2. Configuration Classes

#### AnnouncementConfig

Main configuration for the scheduler.

```dart
AnnouncementConfig(
  // TTS Settings
  enableTTS: true,
  ttsRate: 0.5,              // 0.0 to 1.0
  ttsPitch: 1.0,             // 0.5 to 2.0
  ttsVolume: 1.0,            // 0.0 to 1.0
  ttsLanguage: 'en-US',
  
  // Timezone Settings
  forceTimezone: true,
  timezoneLocation: 'America/New_York',  // Or use user's location
  
  // Sub-configurations
  notificationConfig: NotificationConfig(...),
  validationConfig: ValidationConfig(...),
  
  // Debug
  enableDebugLogging: false,
)
```

#### NotificationConfig

Notification appearance and behavior.

```dart
NotificationConfig(
  channelId: 'my_channel',
  channelName: 'My Channel',
  channelDescription: 'Description',
  importance: Importance.high,
  priority: Priority.high,
  showBadge: true,
  enableLights: true,
  enableVibration: true,
)
```

#### ValidationConfig

Limits and validation rules.

```dart
ValidationConfig(
  maxNotificationsPerDay: 10,
  maxScheduledNotifications: 50,
  enableEdgeCaseValidation: true,
  enableTimezoneValidation: true,
  minAnnouncementIntervalMinutes: 1,
  maxSchedulingDaysInAdvance: 14,
)
```

### 3. Data Models

#### ScheduledAnnouncement

Represents a scheduled announcement.

```dart
ScheduledAnnouncement(
  id: 'unique_id',
  content: 'Announcement text',
  scheduledTime: DateTime(...),
  recurrence: RecurrencePattern.daily,  // optional
  customDays: [1, 3, 5],               // for custom recurrence
  isActive: true,
  metadata: {'key': 'value'},          // optional
)
```

**Properties:**

- `isRecurring` - Whether this is a recurring announcement
- `isOneTime` - Whether this is a one-time announcement
- `effectiveDays` - List of days this announcement runs

#### RecurrencePattern

Enum for recurrence patterns.

**Values:**

- `daily` - Every day (all 7 days)
- `weekdays` - Monday through Friday
- `weekends` - Saturday and Sunday
- `custom` - User-specified days

**Extension Methods:**

- `displayName` - User-friendly name
- `defaultDays` - List of days (1=Monday, 7=Sunday)

#### AnnouncementStatus

Enum for announcement lifecycle states.

**Values:**

- `scheduled` - Announcement is scheduled
- `delivering` - Currently being delivered
- `completed` - Successfully delivered
- `failed` - Delivery failed

**Extension Methods:**

- `displayName` - User-friendly name
- `isActive` - Whether announcement is active
- `isComplete` - Whether announcement is complete

### 4. Exceptions

All exceptions extend `AnnouncementException`.

**Exception Types:**

- `NotificationPermissionDeniedException` - Permission denied by user
- `NotificationInitializationException` - Notification setup failed
- `NotificationSchedulingException` - Scheduling operation failed
- `TTSInitializationException` - TTS setup failed
- `TTSAnnouncementException` - TTS delivery failed
- `ValidationException` - Input validation failed

**Example Error Handling:**

```dart
try {
  await scheduler.scheduleAnnouncement(...);
} on ValidationException catch (e) {
  print('Validation error: ${e.message}');
} on NotificationSchedulingException catch (e) {
  print('Scheduling failed: ${e.message}');
} on AnnouncementException catch (e) {
  print('General error: ${e.message}');
}
```

## Usage Examples

### Basic Daily Announcement

```dart
final scheduler = await AnnouncementScheduler.initialize(
  config: AnnouncementConfig(
    notificationConfig: NotificationConfig(
      channelId: 'daily_reminders',
      channelName: 'Daily Reminders',
    ),
  ),
);

await scheduler.scheduleAnnouncement(
  content: 'Good morning! Time to start your day.',
  announcementTime: TimeOfDay(hour: 7, minute: 0),
  recurrence: RecurrencePattern.daily,
);
```

### Weekday Work Reminder

```dart
await scheduler.scheduleAnnouncement(
  content: 'Time for work!',
  announcementTime: TimeOfDay(hour: 8, minute: 30),
  recurrence: RecurrencePattern.weekdays,
);
```

### Custom Schedule

```dart
await scheduler.scheduleAnnouncement(
  content: 'Gym day!',
  announcementTime: TimeOfDay(hour: 6, minute: 0),
  recurrence: RecurrencePattern.custom,
  customDays: [1, 3, 5], // Monday, Wednesday, Friday
);
```

### One-Time Announcement

```dart
await scheduler.scheduleOneTimeAnnouncement(
  content: 'Meeting in 5 minutes',
  dateTime: DateTime.now().add(Duration(hours: 1)),
);
```

### Monitoring Status

```dart
scheduler.statusStream.listen((status) {
  switch (status) {
    case AnnouncementStatus.scheduled:
      print('✓ Scheduled');
      break;
    case AnnouncementStatus.delivering:
      print('📢 Delivering...');
      break;
    case AnnouncementStatus.completed:
      print('✅ Completed');
      break;
    case AnnouncementStatus.failed:
      print('❌ Failed');
      break;
  }
});
```

### Managing Announcements

```dart
// Get all scheduled
final announcements = await scheduler.getScheduledAnnouncements();

// Cancel specific announcement
await scheduler.cancelAnnouncementById(announcementId);

// Cancel all
await scheduler.cancelScheduledAnnouncements();

// Cleanup
await scheduler.dispose();
```

## API Design Principles

### 1. Simplicity

- Single entry point (`AnnouncementScheduler`)
- Intuitive method names
- Sensible defaults
- Clear error messages

### 2. Flexibility

- Multiple recurrence patterns
- Configurable TTS settings
- Customizable notifications
- Optional metadata support

### 3. Safety

- Input validation
- Type safety
- Comprehensive error handling
- Resource cleanup

### 4. Observability

- Status stream for monitoring
- Query scheduled announcements
- Debug logging option

## Re-exported Types

For convenience, the package re-exports commonly needed types:

- `Importance` - From flutter_local_notifications
- `Priority` - From flutter_local_notifications

## Platform Support

- ✅ Android (API 21+)
- ✅ iOS
- ✅ macOS
- ⚠️ Linux, Windows, Web (limited notification support)

## See Also

- [README.md](README.md) - Package overview and quick start
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [Example App](example/) - Complete working examples
