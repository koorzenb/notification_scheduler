# Changelog

## [1.0.0] - 2026-01-08

### Added

- Initial release of the announcement_scheduler package
- Support for scheduling one-time and recurring announcements
- Text-to-Speech (TTS) integration with configurable settings
- Multiple recurrence patterns: daily, weekdays, weekends, custom days
- Comprehensive configuration options for notifications and validation
- Timezone-aware scheduling with optional forced timezone support
- Cross-platform support (Android, iOS, macOS, Linux, Windows, Web)
- Built-in validation to prevent excessive notification load
- Exception handling with specific error types
- Status monitoring through streams
- Comprehensive documentation and examples

### Features

- `NotificationScheduler` - Main entry point for package functionality
- `NotificationConfig` - Configuration class for TTS and notification settings
- `RecurrencePattern` - Enum for different recurring patterns
- `ScheduledNotification` - Model for scheduled notification data
- `NotificationConfig` - Configuration for notification channels and behavior
- `ValidationConfig` - Configuration for scheduling limits and validation
- Custom exceptions for different error scenarios
- Stream-based status monitoring
