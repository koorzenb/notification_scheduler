import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:announcement_scheduler/src/services/core_notification_service.dart';
import 'package:announcement_scheduler/src/services/scheduling_settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'core_notification_service_one_time_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  SchedulingSettingsService,
  FlutterTts,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late MockSchedulingSettingsService mockSettingsService;
  late MockFlutterTts mockTts;
  late CoreNotificationService service;

  setUp(() {
    mockNotifications = MockFlutterLocalNotificationsPlugin();
    mockSettingsService = MockSchedulingSettingsService();
    mockTts = MockFlutterTts();

    // Default stubs
    when(
      mockSettingsService.getScheduledAnnouncements(),
    ).thenAnswer((_) async => []);
    when(
      mockSettingsService.addScheduledAnnouncement(any),
    ).thenAnswer((_) async {});
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
    ).thenAnswer((_) async {});

    // Stub pendingNotificationRequests to return empty list by default
    when(
      mockNotifications.pendingNotificationRequests(),
    ).thenAnswer((_) async => []);

    service = CoreNotificationService(
      settingsService: mockSettingsService,
      config: const AnnouncementConfig(
        notificationConfig: NotificationConfig(),
      ),
      notifications: mockNotifications,
      tts: mockTts,
    );
  });

  group('scheduleOneTimeAnnouncement', () {
    test('creates ScheduledAnnouncement and persists it', () async {
      final dateTime = DateTime.now().add(const Duration(hours: 1));
      const content = 'Test content';
      const id = 12345;
      const metadata = {'key': 'value'};

      await service.scheduleOneTimeAnnouncement(
        content: content,
        dateTime: dateTime,
        id: id,
        metadata: metadata,
      );

      // Verify persistence
      final captured = verify(
        mockSettingsService.addScheduledAnnouncement(captureAny),
      ).captured;
      final announcement = captured.first as ScheduledAnnouncement;

      expect(announcement.id, id);
      expect(announcement.content, content);
      expect(announcement.scheduledTime, dateTime);
      expect(announcement.isActive, true);
      expect(announcement.metadata, metadata);
      expect(announcement.recurrence, null);
      expect(announcement.customDays, null);
    });

    test('uses provided ID for notification', () async {
      final dateTime = DateTime.now().add(const Duration(hours: 1));
      const id = 12345;

      await service.scheduleOneTimeAnnouncement(
        content: 'Test',
        dateTime: dateTime,
        id: id,
      );

      verify(
        mockNotifications.zonedSchedule(
          id,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ),
      ).called(1);
    });

    test('generates ID if not provided', () async {
      final dateTime = DateTime.now().add(const Duration(hours: 1));

      await service.scheduleOneTimeAnnouncement(
        content: 'Test',
        dateTime: dateTime,
      );

      final captured = verify(
        mockSettingsService.addScheduledAnnouncement(captureAny),
      ).captured;
      final announcement = captured.first as ScheduledAnnouncement;

      expect(announcement.id, isNotNull);
      expect(announcement.id, isA<int>());

      verify(
        mockNotifications.zonedSchedule(
          announcement.id,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          payload: anyNamed('payload'),
        ),
      ).called(1);
    });
  });
}
