import 'package:announcement_scheduler/src/models/recurrence_pattern.dart';
import 'package:announcement_scheduler/src/models/scheduled_announcement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduledAnnouncement Serialization', () {
    test('toJson() serializes all fields correctly', () {
      final announcement = ScheduledAnnouncement(
        id: 'test_123',
        content: 'Test announcement',
        scheduledTime: DateTime(2025, 11, 25, 8, 30),
        recurrence: RecurrencePattern.weekdays,
        customDays: [1, 3, 5],
        isActive: true,
        metadata: {'category': 'health', 'priority': 'high'},
      );

      final json = announcement.toJson();

      expect(
        json['id'],
        'test_123',
        reason: 'ID should be serialized as string',
      );
      expect(
        json['content'],
        'Test announcement',
        reason: 'Content should be serialized as string',
      );
      expect(
        json['scheduledTime'],
        DateTime(2025, 11, 25, 8, 30).millisecondsSinceEpoch,
        reason: 'DateTime should be serialized as milliseconds',
      );
      expect(
        json['recurrence'],
        RecurrencePattern.weekdays.index,
        reason: 'RecurrencePattern should be serialized as index',
      );
      expect(json['customDays'], [
        1,
        3,
        5,
      ], reason: 'customDays should be preserved as list');
      expect(
        json['isActive'],
        true,
        reason: 'isActive should be serialized as bool',
      );
      expect(json['metadata'], {
        'category': 'health',
        'priority': 'high',
      }, reason: 'metadata should be preserved as map');
    });

    test('toJson() handles null recurrence', () {
      final announcement = ScheduledAnnouncement(
        id: 'test_456',
        content: 'One-time announcement',
        scheduledTime: DateTime(2025, 11, 25, 10, 0),
      );

      final json = announcement.toJson();

      expect(
        json['recurrence'],
        null,
        reason: 'Null recurrence should be serialized as null',
      );
      expect(
        json['customDays'],
        null,
        reason: 'Null customDays should be serialized as null',
      );
      expect(
        json['metadata'],
        null,
        reason: 'Null metadata should be serialized as null',
      );
      expect(json['isActive'], true, reason: 'isActive should default to true');
    });

    test('toJson() handles empty customDays and metadata', () {
      final announcement = ScheduledAnnouncement(
        id: 'test_789',
        content: 'Test with empty collections',
        scheduledTime: DateTime(2025, 11, 25, 14, 0),
        customDays: [],
        metadata: {},
      );

      final json = announcement.toJson();

      expect(
        json['customDays'],
        [],
        reason: 'Empty customDays should be serialized as empty list',
      );
      expect(
        json['metadata'],
        {},
        reason: 'Empty metadata should be serialized as empty map',
      );
    });

    test('fromJson() deserializes all fields correctly', () {
      final json = {
        'id': 'test_123',
        'content': 'Test announcement',
        'scheduledTime': DateTime(2025, 11, 25, 8, 30).millisecondsSinceEpoch,
        'recurrence': RecurrencePattern.weekdays.index,
        'customDays': [1, 3, 5],
        'isActive': true,
        'metadata': {'category': 'health', 'priority': 'high'},
      };

      final announcement = ScheduledAnnouncement.fromJson(json);

      expect(
        announcement.id,
        'test_123',
        reason: 'ID should be deserialized correctly',
      );
      expect(
        announcement.content,
        'Test announcement',
        reason: 'Content should be deserialized correctly',
      );
      expect(
        announcement.scheduledTime,
        DateTime(2025, 11, 25, 8, 30),
        reason: 'DateTime should be deserialized from milliseconds',
      );
      expect(
        announcement.recurrence,
        RecurrencePattern.weekdays,
        reason: 'RecurrencePattern should be deserialized from index',
      );
      expect(
        announcement.customDays,
        [1, 3, 5],
        reason: 'customDays should be deserialized correctly',
      );
      expect(
        announcement.isActive,
        true,
        reason: 'isActive should be deserialized correctly',
      );
      expect(announcement.metadata, {
        'category': 'health',
        'priority': 'high',
      }, reason: 'metadata should be deserialized correctly');
    });

    test('fromJson() handles null optional fields', () {
      final json = {
        'id': 'test_456',
        'content': 'One-time announcement',
        'scheduledTime': DateTime(2025, 11, 25, 10, 0).millisecondsSinceEpoch,
        'recurrence': null,
        'customDays': null,
        'isActive': true,
        'metadata': null,
      };

      final announcement = ScheduledAnnouncement.fromJson(json);

      expect(
        announcement.recurrence,
        null,
        reason: 'Null recurrence should be deserialized as null',
      );
      expect(
        announcement.customDays,
        null,
        reason: 'Null customDays should be deserialized as null',
      );
      expect(
        announcement.metadata,
        null,
        reason: 'Null metadata should be deserialized as null',
      );
    });

    test('fromJson() provides default for missing isActive', () {
      final json = {
        'id': 'test_789',
        'content': 'Test without isActive',
        'scheduledTime': DateTime(2025, 11, 25, 14, 0).millisecondsSinceEpoch,
      };

      final announcement = ScheduledAnnouncement.fromJson(json);

      expect(
        announcement.isActive,
        true,
        reason: 'isActive should default to true when missing',
      );
    });

    test('fromJson() throws ArgumentError when id is missing', () {
      final json = {
        'content': 'Missing ID',
        'scheduledTime': DateTime(2025, 11, 25, 10, 0).millisecondsSinceEpoch,
      };

      expect(
        () => ScheduledAnnouncement.fromJson(json),
        throwsA(isA<ArgumentError>()),
        reason: 'fromJson should throw ArgumentError when id is missing',
      );
    });

    test('fromJson() throws ArgumentError when content is missing', () {
      final json = {
        'id': 'test_123',
        'scheduledTime': DateTime(2025, 11, 25, 10, 0).millisecondsSinceEpoch,
      };

      expect(
        () => ScheduledAnnouncement.fromJson(json),
        throwsA(isA<ArgumentError>()),
        reason: 'fromJson should throw ArgumentError when content is missing',
      );
    });

    test('fromJson() throws ArgumentError when scheduledTime is missing', () {
      final json = {'id': 'test_123', 'content': 'Missing scheduled time'};

      expect(
        () => ScheduledAnnouncement.fromJson(json),
        throwsA(isA<ArgumentError>()),
        reason:
            'fromJson should throw ArgumentError when scheduledTime is missing',
      );
    });

    test('Round-trip serialization preserves data integrity', () {
      final original = ScheduledAnnouncement(
        id: 'test_roundtrip',
        content: 'Round-trip test',
        scheduledTime: DateTime(2025, 11, 25, 16, 45),
        recurrence: RecurrencePattern.custom,
        customDays: [2, 4, 6],
        isActive: false,
        metadata: {
          'test': 'value',
          'nested': {'key': 'data'},
        },
      );

      final json = original.toJson();
      final deserialized = ScheduledAnnouncement.fromJson(json);

      expect(
        deserialized.id,
        original.id,
        reason: 'Round-trip should preserve id',
      );
      expect(
        deserialized.content,
        original.content,
        reason: 'Round-trip should preserve content',
      );
      expect(
        deserialized.scheduledTime,
        original.scheduledTime,
        reason: 'Round-trip should preserve scheduledTime',
      );
      expect(
        deserialized.recurrence,
        original.recurrence,
        reason: 'Round-trip should preserve recurrence',
      );
      expect(
        deserialized.customDays,
        original.customDays,
        reason: 'Round-trip should preserve customDays',
      );
      expect(
        deserialized.isActive,
        original.isActive,
        reason: 'Round-trip should preserve isActive',
      );
      expect(
        deserialized.metadata,
        original.metadata,
        reason: 'Round-trip should preserve metadata',
      );
    });

    test('Round-trip serialization with null fields', () {
      final original = ScheduledAnnouncement(
        id: 'test_null_roundtrip',
        content: 'Null fields test',
        scheduledTime: DateTime(2025, 11, 25, 18, 0),
      );

      final json = original.toJson();
      final deserialized = ScheduledAnnouncement.fromJson(json);

      expect(
        deserialized.id,
        original.id,
        reason: 'Round-trip should preserve id',
      );
      expect(
        deserialized.content,
        original.content,
        reason: 'Round-trip should preserve content',
      );
      expect(
        deserialized.scheduledTime,
        original.scheduledTime,
        reason: 'Round-trip should preserve scheduledTime',
      );
      expect(
        deserialized.recurrence,
        original.recurrence,
        reason: 'Round-trip should preserve null recurrence',
      );
      expect(
        deserialized.customDays,
        original.customDays,
        reason: 'Round-trip should preserve null customDays',
      );
      expect(
        deserialized.isActive,
        original.isActive,
        reason: 'Round-trip should preserve isActive',
      );
      expect(
        deserialized.metadata,
        original.metadata,
        reason: 'Round-trip should preserve null metadata',
      );
    });

    test('fromJson() handles all RecurrencePattern values', () {
      for (final pattern in RecurrencePattern.values) {
        final json = {
          'id': 'test_pattern_${pattern.index}',
          'content': 'Test ${pattern.name}',
          'scheduledTime': DateTime(2025, 11, 25, 12, 0).millisecondsSinceEpoch,
          'recurrence': pattern.index,
        };

        final announcement = ScheduledAnnouncement.fromJson(json);

        expect(
          announcement.recurrence,
          pattern,
          reason: 'fromJson should correctly deserialize ${pattern.name}',
        );
      }
    });

    test('toJson() with various metadata types', () {
      final announcement = ScheduledAnnouncement(
        id: 'test_metadata',
        content: 'Metadata test',
        scheduledTime: DateTime(2025, 11, 25, 20, 0),
        metadata: {
          'string': 'value',
          'int': 42,
          'double': 3.14,
          'bool': true,
          'list': [1, 2, 3],
          'map': {'nested': 'data'},
        },
      );

      final json = announcement.toJson();
      final deserialized = ScheduledAnnouncement.fromJson(json);

      expect(
        deserialized.metadata?['string'],
        'value',
        reason: 'String metadata should be preserved',
      );
      expect(
        deserialized.metadata?['int'],
        42,
        reason: 'Int metadata should be preserved',
      );
      expect(
        deserialized.metadata?['double'],
        3.14,
        reason: 'Double metadata should be preserved',
      );
      expect(
        deserialized.metadata?['bool'],
        true,
        reason: 'Bool metadata should be preserved',
      );
      expect(
        deserialized.metadata?['list'],
        [1, 2, 3],
        reason: 'List metadata should be preserved',
      );
      expect(deserialized.metadata?['map'], {
        'nested': 'data',
      }, reason: 'Map metadata should be preserved');
    });
  });
}
