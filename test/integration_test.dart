import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:notification_scheduler/notification_scheduler.dart';
import 'package:notification_scheduler/src/services/core_notification_service.dart';
import 'package:notification_scheduler/src/services/scheduling_settings_service.dart';
import 'package:notification_scheduler/src/services/storage_service.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'integration_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin, FlutterTts])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  group('AnnouncementScheduler Integration Tests', () {
    late FakeStorageService fakeStorage;
    late SchedulingSettingsService settingsService;
    late MockFlutterLocalNotificationsPlugin mockNotifications;
    late MockFlutterTts mockTts;
    late NotificationScheduler scheduler;

    late List<PendingNotificationRequest> pendingNotifications;

    setUp(() {
      fakeStorage = FakeStorageService();
      settingsService = SchedulingSettingsService(fakeStorage);
      mockNotifications = MockFlutterLocalNotificationsPlugin();
      mockTts = MockFlutterTts();
      pendingNotifications = [];

      // Default mocks
      when(
        mockNotifications.initialize(
          any,
          onDidReceiveNotificationResponse: anyNamed(
            'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: anyNamed(
            'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);

      when(
        mockNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      // Mock pending notifications to return our local list
      when(
        mockNotifications.pendingNotificationRequests(),
      ).thenAnswer((_) async => pendingNotifications);

      // Capture scheduled notifications
      when(
        mockNotifications.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ),
      ).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as int;
        final title = invocation.positionalArguments[1] as String?;
        final body = invocation.positionalArguments[2] as String?;
        final payload = invocation.namedArguments[#payload] as String?;

        pendingNotifications.add(
          PendingNotificationRequest(id, title, body, payload),
        );
      });

      // Handle cancellation
      when(mockNotifications.cancel(any)).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as int;
        pendingNotifications.removeWhere((n) => n.id == id);
      });

      when(mockNotifications.cancelAll()).thenAnswer((_) async {
        pendingNotifications.clear();
      });

      when(mockTts.setLanguage(any)).thenAnswer((_) async => 1);
      when(mockTts.setSpeechRate(any)).thenAnswer((_) async => 1);
      when(mockTts.setPitch(any)).thenAnswer((_) async => 1);
      when(mockTts.setVolume(any)).thenAnswer((_) async => 1);
    });

    Future<void> initializeScheduler({AnnouncementConfig? config}) async {
      final effectiveConfig =
          config ??
          const AnnouncementConfig(notificationConfig: NotificationConfig());

      final coreService = CoreNotificationService(
        settingsService: settingsService,
        config: effectiveConfig,
        notifications: mockNotifications,
        tts: mockTts,
      );

      // We need to initialize the core service manually since we are injecting it
      await coreService.initialize();

      scheduler = await NotificationScheduler.create(
        config: effectiveConfig,
        notificationService: coreService,
      );
    }

    // Task 12.1: Multiple recurring announcements
    test(
      'Task 12.1: Schedule multiple recurring announcements with different patterns',
      () async {
        await initializeScheduler();

        // 1. Schedule Daily
        final id1 = await scheduler.scheduleAnnouncement(
          id: 1001,
          content: 'Daily Announcement',
          announcementTime: const TimeOfDay(hour: 8, minute: 0),
          recurrence: RecurrencePattern.daily,
          metadata: {'type': 'daily'},
        );

        // 2. Schedule Weekdays
        final id2 = await scheduler.scheduleAnnouncement(
          id: 1002,
          content: 'Weekday Announcement',
          announcementTime: const TimeOfDay(hour: 9, minute: 0),
          recurrence: RecurrencePattern.weekdays,
          metadata: {'type': 'weekday'},
        );

        // 3. Schedule Custom
        final id3 = await scheduler.scheduleAnnouncement(
          id: 1003,
          content: 'Custom Announcement',
          announcementTime: const TimeOfDay(hour: 10, minute: 0),
          recurrence: RecurrencePattern.custom,
          customDays: [1, 3, 5],
          metadata: {'type': 'custom'},
        );

        // Verify IDs
        expect(id1, 1001, reason: 'ID should match provided ID');
        expect(id2, 1002, reason: 'ID should match provided ID');
        expect(id3, 1003, reason: 'ID should match provided ID');

        // Verify Persistence
        final announcements = await scheduler.getScheduledAnnouncements();
        expect(
          announcements.length,
          3,
          reason: 'Should have 3 scheduled announcements',
        );

        final daily = announcements.firstWhere((a) => a.id == 1001);
        expect(
          daily.content,
          'Daily Announcement',
          reason: 'Content should match',
        );
        expect(
          daily.recurrence,
          RecurrencePattern.daily,
          reason: 'Recurrence should match',
        );
        expect(
          daily.metadata?['type'],
          'daily',
          reason: 'Metadata should match',
        );

        final weekday = announcements.firstWhere((a) => a.id == 1002);
        expect(
          weekday.recurrence,
          RecurrencePattern.weekdays,
          reason: 'Recurrence should match',
        );

        final custom = announcements.firstWhere((a) => a.id == 1003);
        expect(
          custom.recurrence,
          RecurrencePattern.custom,
          reason: 'Recurrence should match',
        );
        expect(custom.customDays, [
          1,
          3,
          5,
        ], reason: 'Custom days should match');
      },
    );

    // Task 12.2: Mix of one-time and recurring
    test(
      'Task 12.2: Schedule mix of one-time and recurring announcements',
      () async {
        await initializeScheduler();

        // One-time 1
        await scheduler.scheduleOneTimeAnnouncement(
          id: 2001,
          content: 'One-time 1',
          dateTime: DateTime.now().add(const Duration(hours: 1)),
        );

        // Recurring 1
        await scheduler.scheduleAnnouncement(
          id: 2002,
          content: 'Recurring 1',
          announcementTime: const TimeOfDay(hour: 12, minute: 0),
          recurrence: RecurrencePattern.daily,
        );

        // One-time 2
        await scheduler.scheduleOneTimeAnnouncement(
          id: 2003,
          content: 'One-time 2',
          dateTime: DateTime.now().add(const Duration(hours: 2)),
        );

        // Recurring 2
        await scheduler.scheduleAnnouncement(
          id: 2004,
          content: 'Recurring 2',
          announcementTime: const TimeOfDay(hour: 13, minute: 0),
          recurrence: RecurrencePattern.weekends,
        );

        final announcements = await scheduler.getScheduledAnnouncements();
        expect(
          announcements.length,
          4,
          reason: 'Should have 4 scheduled announcements',
        );

        expect(
          announcements.any((a) => a.id == 2001 && a.isOneTime),
          isTrue,
          reason: 'Should have one-time 1',
        );
        expect(
          announcements.any((a) => a.id == 2002 && a.isRecurring),
          isTrue,
          reason: 'Should have recurring 1',
        );
        expect(
          announcements.any((a) => a.id == 2003 && a.isOneTime),
          isTrue,
          reason: 'Should have one-time 2',
        );
        expect(
          announcements.any((a) => a.id == 2004 && a.isRecurring),
          isTrue,
          reason: 'Should have recurring 2',
        );
      },
    );

    // Task 12.3: Cancellation
    test('Task 12.3: Cancellation removes from platform and storage', () async {
      await initializeScheduler();

      await scheduler.scheduleAnnouncement(
        id: 3001,
        content: 'To be cancelled',
        announcementTime: const TimeOfDay(hour: 10, minute: 0),
        recurrence: RecurrencePattern.daily,
      );

      await scheduler.scheduleAnnouncement(
        id: 3002,
        content: 'To keep',
        announcementTime: const TimeOfDay(hour: 11, minute: 0),
        recurrence: RecurrencePattern.daily,
      );

      // Cancel 3001
      await scheduler.cancelAnnouncementById(3001);

      // Verify platform cancellation
      verify(mockNotifications.cancel(3001)).called(1);

      // Verify storage removal
      final announcements = await scheduler.getScheduledAnnouncements();
      expect(
        announcements.length,
        1,
        reason: 'Should have 1 announcement left',
      );
      expect(announcements.first.id, 3002, reason: 'Should be the one we kept');
    });

    // Task 12.4: Cleanup (Simulated)
    test('Task 12.4: Cleanup removes completed announcements', () async {
      await initializeScheduler();

      // Schedule one-time
      await scheduler.scheduleOneTimeAnnouncement(
        id: 4001,
        content: 'Completed',
        dateTime: DateTime.now().add(const Duration(seconds: 1)),
      );

      // Simulate completion by manually removing from pending notifications
      // and triggering reconciliation via getScheduledAnnouncements

      // Mock pending notifications to NOT include 4001 (simulating it finished)
      when(
        mockNotifications.pendingNotificationRequests(),
      ).thenAnswer((_) async => []);

      // Call getScheduledAnnouncements which triggers reconciliation
      final announcements = await scheduler.getScheduledAnnouncements();

      expect(
        announcements.isEmpty,
        isTrue,
        reason: 'Should be empty after cleanup',
      );
    });

    // Task 12.5: Reconciliation
    test('Task 12.5: Reconciliation removes stale announcements', () async {
      await initializeScheduler();

      // Add directly to storage to simulate "stale" data (e.g. app crash before cleanup)
      await settingsService.addScheduledAnnouncement(
        ScheduledNotification(
          id: 5001,
          content: 'Stale',
          scheduledTime: DateTime.now(),
          isActive: true,
        ),
      );

      // Mock pending notifications to be empty (so 5001 is stale)
      when(
        mockNotifications.pendingNotificationRequests(),
      ).thenAnswer((_) async => []);

      // Trigger reconciliation
      final announcements = await scheduler.getScheduledAnnouncements();

      expect(
        announcements.isEmpty,
        isTrue,
        reason: 'Stale announcement should be removed',
      );
    });

    // Task 12.6: Validation limits
    test('Task 12.6: Validation limits enforce max notifications', () async {
      await initializeScheduler(
        config: const AnnouncementConfig(
          notificationConfig: NotificationConfig(),
          validationConfig: ValidationConfig(
            maxScheduledNotifications: 2, // Low limit for testing
          ),
        ),
      );

      await scheduler.scheduleOneTimeAnnouncement(
        id: 6001,
        content: '1',
        dateTime: DateTime.now().add(const Duration(hours: 1)),
      );

      await scheduler.scheduleOneTimeAnnouncement(
        id: 6002,
        content: '2',
        dateTime: DateTime.now().add(const Duration(hours: 2)),
      );

      // Third one should fail
      expect(
        () => scheduler.scheduleOneTimeAnnouncement(
          id: 6003,
          content: '3',
          dateTime: DateTime.now().add(const Duration(hours: 3)),
        ),
        throwsA(isA<ValidationException>()),
        reason: 'Should throw when limit reached',
      );
    });
  });
}

class FakeStorageService implements IStorageService {
  final Map<String, dynamic> _storage = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<T?> get<T>(String key) async {
    return _storage[key] as T?;
  }

  @override
  Future<void> set<T>(String key, T value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _storage.keys.toList();
  }

  @override
  Future<void> dispose() async {}
}
