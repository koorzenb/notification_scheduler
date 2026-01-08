import 'package:flutter_test/flutter_test.dart';
import 'package:notification_scheduler/src/models/recurrence_pattern.dart';
import 'package:notification_scheduler/src/models/scheduled_notification.dart';
import 'package:notification_scheduler/src/services/scheduling_settings_service.dart';
import 'package:notification_scheduler/src/services/storage_service.dart';

/// Mock implementation of IStorageService for testing
class MockStorageService implements IStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> initialize() async {
    // No-op for mock
  }

  @override
  Future<T?> get<T>(String key) async {
    return _data[key] as T?;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _data.keys.toList();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _data.containsKey(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<void> dispose() async {
    // No-op for mock
  }

  // Test helper
  void clearTestData() {
    _data.clear();
  }
}

void main() {
  group('SchedulingSettingsService - Storage Methods', () {
    late SchedulingSettingsService service;
    late MockStorageService mockStorage;

    setUp(() {
      mockStorage = MockStorageService();
      service = SchedulingSettingsService(mockStorage);
    });

    tearDown(() {
      mockStorage.clearTestData();
    });

    group('getScheduledAnnouncements', () {
      test('returns empty list when no announcements stored', () async {
        final announcements = await service.getScheduledAnnouncements();

        expect(
          announcements,
          isEmpty,
          reason: 'Should return empty list when no data exists',
        );
      });

      test('returns list of stored announcements', () async {
        // Arrange
        final expectedAnnouncements = <ScheduledNotification>[
          ScheduledNotification(
            id: 1,
            content: 'Test content',
            scheduledTime: DateTime(2024, 1, 15, 9, 0),
            recurrence: RecurrencePattern.daily,
          ),
          ScheduledNotification(
            id: 2,
            content: 'Test content 2',
            scheduledTime: DateTime(2024, 1, 16, 10, 0),
            recurrence: RecurrencePattern.weekdays,
            isActive: false,
          ),
        ];

        await service.setScheduledAnnouncements(expectedAnnouncements);

        // Act
        final actualAnnouncements = await service.getScheduledAnnouncements();

        // Assert
        expect(
          actualAnnouncements.length,
          equals(2),
          reason: 'Should return same number of announcements as stored',
        );
        expect(
          actualAnnouncements[0].id,
          equals(1),
          reason: 'First announcement ID should match',
        );
        expect(
          actualAnnouncements[1].content,
          equals('Test content 2'),
          reason: 'Second announcement content should match',
        );
      });
    });

    group('setScheduledAnnouncements', () {
      test('stores list of announcements correctly', () async {
        // Arrange
        final announcements = <ScheduledNotification>[
          ScheduledNotification(
            id: 101,
            content: 'Set content',
            scheduledTime: DateTime(2024, 2, 1, 12, 0),
            recurrence: RecurrencePattern.weekends,
          ),
        ];

        // Act
        await service.setScheduledAnnouncements(announcements);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(1),
          reason: 'Should store and retrieve same number of announcements',
        );
        expect(
          retrieved[0].id,
          equals(101),
          reason: 'Stored announcement ID should match',
        );
      });

      test('overwrites existing announcements', () async {
        // Arrange
        final firstList = <ScheduledNotification>[
          ScheduledNotification(
            id: 201,
            content: 'Old content',
            scheduledTime: DateTime(2024, 1, 1),
            recurrence: RecurrencePattern.daily,
          ),
        ];

        final secondList = <ScheduledNotification>[
          ScheduledNotification(
            id: 202,
            content: 'New content',
            scheduledTime: DateTime(2024, 2, 1),
            recurrence: RecurrencePattern.weekdays,
            isActive: false,
          ),
        ];

        // Act
        await service.setScheduledAnnouncements(firstList);
        await service.setScheduledAnnouncements(secondList);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(1),
          reason: 'Should only have announcements from second set',
        );
        expect(
          retrieved[0].id,
          equals(202),
          reason: 'Should contain announcement from second set, not first',
        );
      });
    });

    group('addScheduledAnnouncement', () {
      test('adds announcement to empty list', () async {
        // Arrange
        final announcement = ScheduledNotification(
          id: 301,
          content: 'Added content',
          scheduledTime: DateTime(2024, 3, 1, 14, 30),
          recurrence: RecurrencePattern.weekdays,
        );

        // Act
        await service.addScheduledAnnouncement(announcement);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(1),
          reason: 'Should have one announcement after adding to empty list',
        );
        expect(
          retrieved[0].id,
          equals(301),
          reason: 'Added announcement should be present',
        );
      });

      test('adds announcement to existing list', () async {
        // Arrange
        final existingAnnouncement = ScheduledNotification(
          id: 401,
          content: 'Existing content',
          scheduledTime: DateTime(2024, 1, 1),
        );

        final newAnnouncement = ScheduledNotification(
          id: 402,
          content: 'New content',
          scheduledTime: DateTime(2024, 2, 1),
          recurrence: RecurrencePattern.weekends,
          isActive: false,
        );

        await service.setScheduledAnnouncements([existingAnnouncement]);

        // Act
        await service.addScheduledAnnouncement(newAnnouncement);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(2),
          reason: 'Should have both existing and new announcements',
        );

        final ids = retrieved.map((a) => a.id).toList();
        expect(
          ids,
          contains(401),
          reason: 'Should still contain existing announcement',
        );
        expect(
          ids,
          contains(402),
          reason: 'Should contain newly added announcement',
        );
      });
    });

    group('removeScheduledAnnouncement', () {
      test('removes announcement with matching ID', () async {
        // Arrange
        final announcements = <ScheduledNotification>[
          ScheduledNotification(
            id: 501,
            content: 'Keep content',
            scheduledTime: DateTime(2024, 1, 1),
          ),
          ScheduledNotification(
            id: 502,
            content: 'Remove content',
            scheduledTime: DateTime(2024, 2, 1),
            recurrence: RecurrencePattern.daily,
          ),
          ScheduledNotification(
            id: 503,
            content: 'Keep content 2',
            scheduledTime: DateTime(2024, 3, 1),
            recurrence: RecurrencePattern.weekends,
            isActive: false,
          ),
        ];

        await service.setScheduledAnnouncements(announcements);

        // Act
        await service.removeScheduledAnnouncement(502);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(2),
          reason: 'Should have 2 announcements after removing 1',
        );

        final ids = retrieved.map((a) => a.id).toList();
        expect(
          ids,
          contains(501),
          reason: 'Should still contain first kept announcement',
        );
        expect(
          ids,
          contains(503),
          reason: 'Should still contain second kept announcement',
        );
        expect(
          ids,
          isNot(contains(502)),
          reason: 'Should not contain removed announcement',
        );
      });

      test('does nothing when ID not found', () async {
        // Arrange
        final announcements = <ScheduledNotification>[
          ScheduledNotification(
            id: 601,
            content: 'Existing content',
            scheduledTime: DateTime(2024, 1, 1),
          ),
        ];

        await service.setScheduledAnnouncements(announcements);

        // Act
        await service.removeScheduledAnnouncement(999);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(1),
          reason:
              'Should still have original announcement when removing non-existent ID',
        );
        expect(
          retrieved[0].id,
          equals(601),
          reason: 'Original announcement should remain unchanged',
        );
      });

      test('handles empty list gracefully', () async {
        // Act
        await service.removeScheduledAnnouncement(999);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved,
          isEmpty,
          reason: 'Should remain empty when removing from empty list',
        );
      });
    });

    group('removeScheduledAnnouncements (bulk removal)', () {
      test('removes multiple announcements by IDs', () async {
        // Arrange
        final announcements = <ScheduledNotification>[
          ScheduledNotification(
            id: 701,
            content: 'Keep content',
            scheduledTime: DateTime(2024, 1, 1),
          ),
          ScheduledNotification(
            id: 702,
            content: 'Remove content',
            scheduledTime: DateTime(2024, 2, 1),
            recurrence: RecurrencePattern.daily,
          ),
          ScheduledNotification(
            id: 703,
            content: 'Keep content 2',
            scheduledTime: DateTime(2024, 3, 1),
            recurrence: RecurrencePattern.weekends,
            isActive: false,
          ),
          ScheduledNotification(
            id: 704,
            content: 'Remove content 2',
            scheduledTime: DateTime(2024, 4, 1),
            recurrence: RecurrencePattern.custom,
            customDays: [1, 3, 5],
          ),
        ];

        await service.setScheduledAnnouncements(announcements);

        // Act
        await service.removeScheduledAnnouncements([702, 704]);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(2),
          reason: 'Should have 2 announcements after bulk removing 2',
        );

        final ids = retrieved.map((a) => a.id).toList();
        expect(
          ids,
          contains(701),
          reason: 'Should still contain first kept announcement',
        );
        expect(
          ids,
          contains(703),
          reason: 'Should still contain second kept announcement',
        );
        expect(
          ids,
          isNot(contains(702)),
          reason: 'Should not contain first removed announcement',
        );
        expect(
          ids,
          isNot(contains(704)),
          reason: 'Should not contain second removed announcement',
        );
      });

      test('handles mixed existing and non-existing IDs', () async {
        // Arrange
        final announcements = <ScheduledNotification>[
          ScheduledNotification(
            id: 801,
            content: 'Existing content',
            scheduledTime: DateTime(2024, 1, 1),
          ),
          ScheduledNotification(
            id: 802,
            content: 'Existing content 2',
            scheduledTime: DateTime(2024, 2, 1),
            recurrence: RecurrencePattern.daily,
          ),
        ];

        await service.setScheduledAnnouncements(announcements);

        // Act - try to remove one existing and one non-existing
        await service.removeScheduledAnnouncements([801, 999]);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(1),
          reason:
              'Should have 1 announcement after removing 1 existing (ignoring non-existing)',
        );
        expect(
          retrieved[0].id,
          equals(802),
          reason:
              'Should contain the announcement that was not in removal list',
        );
      });

      test('handles empty removal list', () async {
        // Arrange
        final announcements = <ScheduledNotification>[
          ScheduledNotification(
            id: 901,
            content: 'Keep content',
            scheduledTime: DateTime(2024, 1, 1),
          ),
        ];

        await service.setScheduledAnnouncements(announcements);

        // Act
        await service.removeScheduledAnnouncements([]);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved.length,
          equals(1),
          reason:
              'Should still have original announcement when removing empty list',
        );
        expect(
          retrieved[0].id,
          equals(901),
          reason: 'Original announcement should remain unchanged',
        );
      });

      test('handles removal from empty announcement list', () async {
        // Act
        await service.removeScheduledAnnouncements([998, 999]);

        // Assert
        final retrieved = await service.getScheduledAnnouncements();
        expect(
          retrieved,
          isEmpty,
          reason: 'Should remain empty when bulk removing from empty list',
        );
      });
    });
  });
}
