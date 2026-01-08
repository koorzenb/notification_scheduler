# Announcement Scheduler

A Flutter package for scheduling announcements with support for
one-time, recurring notifications and text-to-speech.

## Features

- 📅 **Flexible Scheduling**: Schedule announcements for specific times or
recurring patterns
- 🔄 **Recurring Patterns**: Daily, weekdays, weekends, or custom day selections
- 🔊 **Text-to-Speech**: Built-in TTS support with configurable voice settings
- 📱 **Single-Platform**: Currently only Android support. 
- ⚙️ **Configurable**: Extensive configuration options for notifications and TTS
- 🛡️ **Validation**: Built-in validation to prevent excessive notifications
- 🌍 **Timezone Support**: Timezone-aware scheduling with optional forced
timezones

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  notification_scheduler: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

The recommended way to use this package is by creating a dedicated service to manage initialization and scheduling. This ensures proper handling of permissions and configuration.

### 1. Initialize in Main

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize the service
    final service = await AnnouncementService.create(
      // See AnnouncementConfig below for configuration options
      config: AnnouncementConfig(   
        notificationConfig: NotificationConfig(
          channelId: 'daily_reminders',
          channelName: 'Daily Reminders',
          channelDescription: 'Daily motivational announcements',
        ),
      ),
    );

    // Schedule announcements using your service methods
    await service.scheduleWeekly(
      content: 'Time for your workout!',
      announcementTime: TimeOfDay(hour: 7, minute: 0),
      daysOfWeek: [1, 3, 5], // Monday, Wednesday, Friday
    );
    
  } catch (e) {
    print('Failed to initialize: $e');
  }

  runApp(MyApp());
}
```

## Configuration

### AnnouncementConfig

Configure the scheduler's behavior:

```dart
final config = AnnouncementConfig(
  enableTTS: true,
  ttsRate: 0.5,          // Speech rate (0.0 to 1.0)
  ttsPitch: 1.0,         // Speech pitch (0.5 to 2.0) 
  ttsVolume: 1.0,        // Speech volume (0.0 to 1.0)
  ttsLanguage: 'en-US',  // TTS language
  forceTimezone: true,
  timezoneLocation: 'UTC',  // Important to update this to device/user timezone, otherwise notifications will default to show at UTC time
  notificationConfig: NotificationConfig(
    channelId: 'announcements',
    channelName: 'Announcements',
    channelDescription: 'Scheduled announcements',
    importance: Importance.high,
    enableLights: true,
    enableVibration: true,
  ),
  validationConfig: ValidationConfig(
    maxNotificationsPerDay: 10,
    maxScheduledNotifications: 50,
    enableEdgeCaseValidation: true,
  ),
);
```

### Recurrence Patterns

Support for various recurring patterns:

```dart
// Once off
await service.scheduleOnceOff(
  content: 'One-time reminder!',
  dateTime: DateTime.now().add(Duration(hours: 2)),
);
```

```dart
// Daily
await service.scheduleDaily(
  content: 'Daily reminder!',
  announcementTime: TimeOfDay(hour: 9, minute: 0),
);  
```

```dart
// Weekly (on specific days)
await service.scheduleWeekly(
  content: 'Weekly reminder!',
  announcementTime: TimeOfDay(hour: 10, minute: 0),
  daysOfWeek: [1, 3, 5], // Monday, Wednesday, Friday
);

### Timezone Configuration

The package supports flexible timezone configuration to ensure announcements
are delivered at the correct local time for your users:

#### Using System Timezone (Default)

By default, the package uses the device's system timezone:

```dart
final scheduler = await AnnouncementScheduler.initialize(
  config: AnnouncementConfig(
    // forceTimezone is false by default, uses system timezone
    notificationConfig: NotificationConfig(...),
  ),
);
```

#### Using a Specific Timezone

You can force a specific timezone for consistent scheduling regardless of
device location:

```dart
final scheduler = await AnnouncementScheduler.initialize(
  config: AnnouncementConfig(
    forceTimezone: true,
    timezoneLocation: 'America/New_York',  // IANA timezone identifier
    notificationConfig: NotificationConfig(...),
  ),
);
```

#### Dynamic Timezone Based on User Location

For apps that serve users in different timezones, you can determine the
timezone based on the user's selected location:

```dart
// Example: Get timezone from user's city selection
String getUserTimezone(String city) {
  final timezoneMap = {
    'New York': 'America/New_York',
    'Los Angeles': 'America/Los_Angeles',
    'London': 'Europe/London',
    'Tokyo': 'Asia/Tokyo',
    'Sydney': 'Australia/Sydney',
  };
  return timezoneMap[city] ?? 'America/New_York';  // Default fallback
}

// Initialize with user's timezone
final userCity = getUserSelectedCity();  // Your app's method
final scheduler = await AnnouncementScheduler.initialize(
  config: AnnouncementConfig(
    forceTimezone: true,
    timezoneLocation: getUserTimezone(userCity),
    notificationConfig: NotificationConfig(...),
  ),
);
```

**Important Notes:**

- Use standard IANA timezone identifiers (e.g., 'America/New_York', 'Europe/
London')
- Timezone configuration affects when announcements are delivered, not the
content
- The package handles DST (Daylight Saving Time) transitions automatically
- For location-based apps, update the scheduler configuration when the user
changes their location

## Use Cases

This package is perfect for:

- **Weather Apps**: Daily weather announcements
- **Fitness Apps**: Workout reminders and motivation
- **Productivity Apps**: Task reminders and time management
- **Meditation Apps**: Daily mindfulness prompts
- **Educational Apps**: Study reminders and learning cues
- **Health Apps**: Medication reminders and wellness tips
- **Accessibility**: Voice announcements for visually impaired users

## Platform Setup

### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

Add receivers within the `<application>` tag:

```xml
<receiver android:exported="false" android:name="com.dexterous.
flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

### iOS

No additional setup required. Permissions are requested automatically.

## Managing Announcements

```dart
// Get all scheduled announcements
final announcements = await scheduler.getScheduledAnnouncements(); //

// Cancel a specific announcement (using the ID from the scheduled announcement)
if (announcements.isNotEmpty) {
  await scheduler.cancelAnnouncementById(announcements.first.id); // using the first ScheduledAnnouncement's ID, but could be any ID
}

// Cancel all announcements
await scheduler.cancelScheduledAnnouncements();

// Listen to status updates
scheduler.statusStream.listen((status) {
  print('Announcement status: ${status.displayName}');
});

// Dispose when done
await scheduler.dispose();
```

## Error Handling

The package provides specific exception types:

```dart
try {
  await scheduler.scheduleAnnouncement(
    content: 'Test announcement',
    announcementTime: TimeOfDay(hour: 8, minute: 0),
  );
} on ValidationException catch (e) {
  print('Validation error: ${e.message}');
} on NotificationPermissionDeniedException catch (e) {
  print('Permission denied: ${e.message}');
} on NotificationSchedulingException catch (e) {
  print('Scheduling failed: ${e.message}');
} on TTSInitializationException catch (e) {
  print('TTS error: ${e.message}');
}
```

## Contributing

Contributions are welcome! Please read the
 [contributing guidelines](CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the MIT License - see the
[LICENSE](LICENSE) file for details.

## Support

If you have questions or need help, please:

1. Check the [documentation](https://pub.dev/packages/announcement_scheduler)
2. Search [existing issues](https://github.com/koorzenb/day_break/issues)
3. Create a [new issue](https://github.com/koorzenb/day_break/issues/new) if
  needed

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.
