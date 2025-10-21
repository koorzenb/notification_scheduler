import 'notification_config.dart';
import 'validation_config.dart';

/// Configuration for the announcement scheduler.
///
/// This class encapsulates all configuration options for the announcement
/// scheduler, including TTS (Text-to-Speech) settings, notification
/// preferences, validation rules, and timezone configuration.
///
/// ## Usage Example
///
/// ```dart
/// final config = AnnouncementConfig(
///   // TTS Configuration
///   enableTTS: true,
///   ttsRate: 0.5,           // Normal speech rate
///   ttsPitch: 1.0,          // Normal pitch
///   ttsVolume: 1.0,         // Full volume
///   ttsLanguage: 'en-US',   // American English
///
///   // Timezone Configuration
///   forceTimezone: true,
///   timezoneLocation: 'America/New_York',  // Or use user's location
///
///   // Notification Settings
///   notificationConfig: NotificationConfig(
///     channelId: 'announcements',
///     channelName: 'Announcements',
///     importance: Importance.high,
///   ),
///
///   // Validation Rules
///   validationConfig: ValidationConfig(
///     maxNotificationsPerDay: 10,
///     maxScheduledNotifications: 50,
///   ),
///
///   // Debug Options
///   enableDebugLogging: true,
/// );
/// ```
///
/// ## TTS Configuration
///
/// Control how announcements are spoken:
///
/// - [enableTTS]: Enable/disable text-to-speech functionality
/// - [ttsRate]: Speech rate (0.0 to 1.0, where 0.5 is normal)
/// - [ttsPitch]: Voice pitch (0.5 to 2.0, where 1.0 is normal)
/// - [ttsVolume]: Speech volume (0.0 to 1.0, where 1.0 is maximum)
/// - [ttsLanguage]: TTS language code (e.g., 'en-US', 'en-GB', 'es-ES')
///
/// ## Timezone Configuration
///
/// Control how times are interpreted:
///
/// - [forceTimezone]: Whether to use a specific timezone instead of system
/// - [timezoneLocation]: Timezone name (e.g., 'America/New_York', 'Europe/London', 'Asia/Tokyo')
///
/// ## Other Configuration
///
/// - [notificationConfig]: Notification channel and appearance settings
/// - [validationConfig]: Limits and validation rules for scheduling
/// - [enableDebugLogging]: Enable detailed logging for troubleshooting
///
/// See also:
///
/// - [NotificationConfig] for notification settings
/// - [ValidationConfig] for validation rules
class AnnouncementConfig {
  /// Whether to enable text-to-speech functionality
  final bool enableTTS;

  /// Speech rate for TTS (0.0 to 1.0, where 0.5 is normal speed)
  final double ttsRate;

  /// Speech pitch for TTS (0.5 to 2.0, where 1.0 is normal pitch)
  final double ttsPitch;

  /// Volume for TTS (0.0 to 1.0, where 1.0 is maximum volume)
  final double ttsVolume;

  /// Configuration for notifications
  final NotificationConfig notificationConfig;

  /// Configuration for validation rules
  final ValidationConfig validationConfig;

  /// Whether to force a specific timezone instead of system timezone
  final bool forceTimezone;

  /// The timezone location to use when forceTimezone is true
  /// (e.g., 'America/New_York', 'Europe/London', 'Asia/Tokyo')
  final String? timezoneLocation;

  /// Whether to enable debug logging
  final bool enableDebugLogging;

  /// Custom TTS language code (e.g., 'en-US', 'en-GB')
  final String? ttsLanguage;

  const AnnouncementConfig({
    this.enableTTS = true,
    this.ttsRate = 0.5,
    this.ttsPitch = 1.0,
    this.ttsVolume = 1.0,
    required this.notificationConfig,
    this.validationConfig = const ValidationConfig(),
    this.forceTimezone = false,
    this.timezoneLocation,
    this.enableDebugLogging = false,
    this.ttsLanguage,
  }) : assert(
         ttsRate >= 0.0 && ttsRate <= 1.0,
         'TTS rate must be between 0.0 and 1.0',
       ),
       assert(
         ttsPitch >= 0.5 && ttsPitch <= 2.0,
         'TTS pitch must be between 0.5 and 2.0',
       ),
       assert(
         ttsVolume >= 0.0 && ttsVolume <= 1.0,
         'TTS volume must be between 0.0 and 1.0',
       ),
       assert(
         !forceTimezone || timezoneLocation != null,
         'timezoneLocation must be provided when forceTimezone is true',
       );

  /// Creates a copy of this configuration with the given fields replaced
  AnnouncementConfig copyWith({
    bool? enableTTS,
    double? ttsRate,
    double? ttsPitch,
    double? ttsVolume,
    NotificationConfig? notificationConfig,
    ValidationConfig? validationConfig,
    bool? forceTimezone,
    String? timezoneLocation,
    bool? enableDebugLogging,
    String? ttsLanguage,
  }) {
    return AnnouncementConfig(
      enableTTS: enableTTS ?? this.enableTTS,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      notificationConfig: notificationConfig ?? this.notificationConfig,
      validationConfig: validationConfig ?? this.validationConfig,
      forceTimezone: forceTimezone ?? this.forceTimezone,
      timezoneLocation: timezoneLocation ?? this.timezoneLocation,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementConfig &&
          runtimeType == other.runtimeType &&
          enableTTS == other.enableTTS &&
          ttsRate == other.ttsRate &&
          ttsPitch == other.ttsPitch &&
          ttsVolume == other.ttsVolume &&
          notificationConfig == other.notificationConfig &&
          validationConfig == other.validationConfig &&
          forceTimezone == other.forceTimezone &&
          timezoneLocation == other.timezoneLocation &&
          enableDebugLogging == other.enableDebugLogging &&
          ttsLanguage == other.ttsLanguage;

  @override
  int get hashCode =>
      enableTTS.hashCode ^
      ttsRate.hashCode ^
      ttsPitch.hashCode ^
      ttsVolume.hashCode ^
      notificationConfig.hashCode ^
      validationConfig.hashCode ^
      forceTimezone.hashCode ^
      timezoneLocation.hashCode ^
      enableDebugLogging.hashCode ^
      ttsLanguage.hashCode;

  @override
  String toString() {
    return 'AnnouncementConfig{'
        'enableTTS: $enableTTS, '
        'ttsRate: $ttsRate, '
        'ttsPitch: $ttsPitch, '
        'ttsVolume: $ttsVolume, '
        'notificationConfig: $notificationConfig, '
        'validationConfig: $validationConfig, '
        'forceTimezone: $forceTimezone, '
        'timezoneLocation: $timezoneLocation, '
        'enableDebugLogging: $enableDebugLogging, '
        'ttsLanguage: $ttsLanguage'
        '}';
  }
}
