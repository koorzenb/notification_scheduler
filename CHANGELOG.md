# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic
  Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-15

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

- `AnnouncementScheduler` - Main entry point for package functionality
- `AnnouncementConfig` - Configuration class for TTS and notification settings
- `RecurrencePattern` - Enum for different recurring patterns
- `ScheduledAnnouncement` - Model for scheduled announcement data
- `NotificationConfig` - Configuration for notification channels and behavior
- `ValidationConfig` - Configuration for scheduling limits and validation
- Custom exceptions for different error scenarios
- Stream-based status monitoring
