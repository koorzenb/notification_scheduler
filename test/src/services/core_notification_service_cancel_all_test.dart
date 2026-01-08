import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:notification_scheduler/notification_scheduler.dart';
import 'package:notification_scheduler/src/services/core_notification_service.dart';
import 'package:notification_scheduler/src/services/scheduling_settings_service.dart';

import 'core_notification_service_cancel_all_test.mocks.dart';

@GenerateMocks([
  FlutterLocalNotificationsPlugin,
  FlutterTts,
  SchedulingSettingsService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreNotificationService - cancelAllNotifications', () {
    late MockFlutterLocalNotificationsPlugin mockNotifications;
    late MockFlutterTts mockTts;
    late MockSchedulingSettingsService mockSettingsService;
    late CoreNotificationService service;
    late AnnouncementConfig config;

    setUp(() {
      mockNotifications = MockFlutterLocalNotificationsPlugin();
      mockTts = MockFlutterTts();
      mockSettingsService = MockSchedulingSettingsService();
      config = const AnnouncementConfig(
        enableTTS: true,
        notificationConfig: NotificationConfig(),
      );

      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: config,
        notifications: mockNotifications,
        tts: mockTts,
      );
    });

    test('cancels all notifications on platform and clears storage', () async {
      // Arrange
      when(mockNotifications.cancelAll()).thenAnswer((_) async {});
      when(
        mockSettingsService.setScheduledAnnouncements(any),
      ).thenAnswer((_) async {});

      // Act
      await service.cancelAllNotifications();

      // Assert
      verify(mockNotifications.cancelAll()).called(1);
      verify(mockSettingsService.setScheduledAnnouncements([])).called(1);
    });

    test('handles errors gracefully', () async {
      // Arrange
      when(
        mockNotifications.cancelAll(),
      ).thenThrow(Exception('Platform error'));

      // Act & Assert
      expect(
        () => service.cancelAllNotifications(),
        throwsA(isA<NotificationSchedulingException>()),
        reason:
            'Should throw NotificationSchedulingException on platform error',
      );
    });
  });
}
