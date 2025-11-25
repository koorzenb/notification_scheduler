import 'recurrence_pattern.dart';

/// Represents a scheduled announcement.
///
/// This class encapsulates all data associated with a scheduled announcement,
/// including its content, timing, recurrence pattern, and metadata. Each
/// announcement has a unique [id] that can be used to cancel or query it.
///
/// ## Usage Example
///
/// ```dart
/// // Create a one-time announcement
/// final oneTime = ScheduledAnnouncement(
///   id: 'announcement_123',
///   content: 'Meeting in 5 minutes',
///   scheduledTime: DateTime.now().add(Duration(minutes: 55)),
/// );
///
/// // Create a recurring announcement
/// final recurring = ScheduledAnnouncement(
///   id: 'announcement_456',
///   content: 'Daily standup time',
///   scheduledTime: DateTime(2025, 1, 20, 9, 0),
///   recurrence: RecurrencePattern.weekdays,
///   metadata: {'type': 'standup', 'team': 'engineering'},
/// );
///
/// // Custom recurrence pattern
/// final custom = ScheduledAnnouncement(
///   id: 'announcement_789',
///   content: 'Workout reminder',
///   scheduledTime: DateTime(2025, 1, 20, 6, 0),
///   recurrence: RecurrencePattern.custom,
///   customDays: [1, 3, 5], // Monday, Wednesday, Friday
/// );
/// ```
///
/// ## Properties
///
/// - [id]: Unique identifier for the announcement
/// - [content]: Text content to be announced
/// - [scheduledTime]: When the announcement is scheduled to be delivered
/// - [recurrence]: Recurrence pattern (null for one-time announcements)
/// - [customDays]: Days for custom recurrence (1=Monday, 7=Sunday)
/// - [isActive]: Whether this announcement is currently active
/// - [metadata]: Optional custom data associated with the announcement
///
/// ## Convenience Methods
///
/// - [isRecurring]: Returns true if this is a recurring announcement
/// - [isOneTime]: Returns true if this is a one-time announcement
/// - [effectiveDays]: Returns the list of days this announcement runs
///
/// See also:
///
/// - [RecurrencePattern] for recurring announcement patterns
/// - [AnnouncementScheduler.scheduleAnnouncement] to create announcements
class ScheduledAnnouncement {
  /// Unique identifier for the announcement
  final String id;

  /// The text content to be announced
  final String content;

  /// When the announcement is scheduled to be delivered
  final DateTime scheduledTime;

  /// The recurrence pattern (null for one-time announcements)
  final RecurrencePattern? recurrence;

  /// Custom days for custom recurrence pattern (1=Monday, 7=Sunday)
  final List<int>? customDays;

  /// Whether this announcement is currently active
  final bool isActive;

  /// Optional metadata associated with the announcement
  final Map<String, dynamic>? metadata;

  const ScheduledAnnouncement({
    required this.id,
    required this.content,
    required this.scheduledTime,
    this.recurrence,
    this.customDays,
    this.isActive = true,
    this.metadata,
  });

  /// Creates a [ScheduledAnnouncement] from a JSON map
  ///
  /// Deserializes a Map<String, dynamic> previously created by [toJson].
  /// Handles all nullable fields gracefully with safe defaults.
  ///
  /// Throws [ArgumentError] if required fields are missing or invalid.
  factory ScheduledAnnouncement.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (!json.containsKey('id') || json['id'] == null) {
      throw ArgumentError('Required field "id" is missing or null');
    }
    if (!json.containsKey('content') || json['content'] == null) {
      throw ArgumentError('Required field "content" is missing or null');
    }
    if (!json.containsKey('scheduledTime') || json['scheduledTime'] == null) {
      throw ArgumentError('Required field "scheduledTime" is missing or null');
    }

    // Deserialize RecurrencePattern from index
    RecurrencePattern? recurrence;
    if (json['recurrence'] != null) {
      final recurrenceIndex = json['recurrence'] as int;
      if (recurrenceIndex >= 0 &&
          recurrenceIndex < RecurrencePattern.values.length) {
        recurrence = RecurrencePattern.values[recurrenceIndex];
      }
    }

    // Deserialize customDays with type safety
    List<int>? customDays;
    if (json['customDays'] != null) {
      final dynamicList = json['customDays'] as List<dynamic>;
      customDays = dynamicList.cast<int>();
    }

    // Deserialize metadata with type safety
    Map<String, dynamic>? metadata;
    if (json['metadata'] != null) {
      metadata = Map<String, dynamic>.from(json['metadata'] as Map);
    }

    return ScheduledAnnouncement(
      id: json['id'] as String,
      content: json['content'] as String,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(
        json['scheduledTime'] as int,
      ),
      recurrence: recurrence,
      customDays: customDays,
      isActive: json['isActive'] as bool? ?? true,
      metadata: metadata,
    );
  }

  /// Converts this announcement to a JSON map for persistence
  ///
  /// Returns a Map<String, dynamic> that can be stored in local storage.
  /// All fields are serialized to JSON-compatible types:
  /// - DateTime → milliseconds since epoch (int)
  /// - RecurrencePattern → index (int)
  /// - Lists and Maps → preserved as-is
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'recurrence': recurrence?.index,
      'customDays': customDays,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Creates a copy of this announcement with the given fields replaced
  ScheduledAnnouncement copyWith({
    String? id,
    String? content,
    DateTime? scheduledTime,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ScheduledAnnouncement(
      id: id ?? this.id,
      content: content ?? this.content,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recurrence: recurrence ?? this.recurrence,
      customDays: customDays ?? this.customDays,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Whether this is a recurring announcement
  bool get isRecurring => recurrence != null;

  /// Whether this is a one-time announcement
  bool get isOneTime => recurrence == null;

  /// Get the days this announcement should run
  List<int> get effectiveDays {
    if (recurrence == null) return [];
    if (recurrence == RecurrencePattern.custom) {
      return customDays ?? [];
    }
    return recurrence!.defaultDays;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledAnnouncement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          scheduledTime == other.scheduledTime &&
          recurrence == other.recurrence &&
          _listEquals(customDays, other.customDays) &&
          isActive == other.isActive &&
          _mapEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      id.hashCode ^
      content.hashCode ^
      scheduledTime.hashCode ^
      recurrence.hashCode ^
      customDays.hashCode ^
      isActive.hashCode ^
      metadata.hashCode;

  @override
  String toString() {
    return 'ScheduledAnnouncement{'
        'id: $id, '
        'content: $content, '
        'scheduledTime: $scheduledTime, '
        'recurrence: $recurrence, '
        'customDays: $customDays, '
        'isActive: $isActive, '
        'metadata: $metadata'
        '}';
  }

  /// Helper method for comparing lists
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// Helper method for comparing maps
  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}
