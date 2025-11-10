import 'dart:async';

import 'package:announcement_scheduler/src/models/announcement_config.dart';
import 'package:announcement_scheduler/src/models/announcement_status.dart';
import 'package:announcement_scheduler/src/models/notification_config.dart';
import 'package:announcement_scheduler/src/services/core_notification_service.dart';
import 'package:announcement_scheduler/src/services/scheduling_settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'core_notification_service_test.mocks.dart';

@GenerateMocks([FlutterTts, SchedulingSettingsService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoreNotificationService - onNotificationResponse', () {
    late StreamController<AnnouncementStatus> statusController;
    late AnnouncementConfig config;
    late MockFlutterTts mockTts;
    late MockSchedulingSettingsService mockSettingsService;
    late CoreNotificationService service;

    setUp(() {
      statusController = StreamController<AnnouncementStatus>.broadcast();
      mockTts = MockFlutterTts();
      mockSettingsService = MockSchedulingSettingsService();
      config = const AnnouncementConfig(
        enableTTS: true,
        notificationConfig: NotificationConfig(),
      );

      // Stub the speak method by default
      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      // Create a minimal service instance
      service = CoreNotificationService(
        settingsService: mockSettingsService,
        config: config,
      );
    });

    tearDown(() {
      statusController.close();
    });

    test(
      'emits AnnouncementStatus.completed when notification is received',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: 'Test announcement',
        );

        // Act
        final statusFuture = statusController.stream.first;
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

        // Assert
        final status = await statusFuture;
        expect(
          status,
          AnnouncementStatus.completed,
          reason: 'Should emit completed status when notification is received',
        );
      },
    );

    test(
      'triggers TTS with payload when TTS is enabled and payload exists',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: 'Good morning! Time to wake up.',
        );

        when(mockTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

        // Allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verify(mockTts.speak('Good morning! Time to wake up.')).called(1);
      },
    );

    test(
      'triggers TTS with actionId when payload is null but actionId exists',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: 1,
          actionId: 'snooze_action',
        );

        when(mockTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

        // Allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verify(mockTts.speak('snooze_action')).called(1);
      },
    );

    test('does not trigger TTS when TTS is disabled in config', () async {
      // Arrange
      final configWithoutTts = const AnnouncementConfig(
        enableTTS: false,
        notificationConfig: NotificationConfig(),
      );

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      // Act
      service.onNotificationResponse(
        response,
        statusController,
        configWithoutTts,
        mockTts,
      );

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verifyNever(mockTts.speak(any));
    });

    test('does not trigger TTS when tts is null', () async {
      // Arrange
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      // Act
      service.onNotificationResponse(
        response,
        statusController,
        config,
        null, // No TTS instance
      );

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      verifyNever(mockTts.speak(any));
    });

    test(
      'does not trigger TTS when payload and actionId are both empty',
      () async {
        // Arrange
        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: '',
        );

        when(mockTts.speak(any)).thenAnswer((_) async => 1);

        // Act
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );

        // Allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verifyNever(mockTts.speak(any));
      },
    );

    test('emits completed status even when TTS is disabled', () async {
      // Arrange
      final configWithoutTts = const AnnouncementConfig(
        enableTTS: false,
        notificationConfig: NotificationConfig(),
      );

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1,
        payload: 'Test announcement',
      );

      // Act
      final statusFuture = statusController.stream.first;
      service.onNotificationResponse(
        response,
        statusController,
        configWithoutTts,
        mockTts,
      );

      // Assert
      final status = await statusFuture;
      expect(
        status,
        AnnouncementStatus.completed,
        reason: 'Should emit completed status regardless of TTS configuration',
      );
    });

    test('handles multiple rapid notification responses correctly', () async {
      // Arrange
      final responses = [
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 1,
          payload: 'First announcement',
        ),
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 2,
          payload: 'Second announcement',
        ),
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          id: 3,
          payload: 'Third announcement',
        ),
      ];

      when(mockTts.speak(any)).thenAnswer((_) async => 1);

      // Act
      final statusList = <AnnouncementStatus>[];
      statusController.stream.listen(statusList.add);

      for (final response in responses) {
        service.onNotificationResponse(
          response,
          statusController,
          config,
          mockTts,
        );
      }

      // Allow async operations to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(
        statusList.length,
        3,
        reason: 'Should emit completed status for each notification',
      );
      expect(
        statusList.every((s) => s == AnnouncementStatus.completed),
        true,
        reason: 'All statuses should be completed',
      );
      verify(mockTts.speak('First announcement')).called(1);
      verify(mockTts.speak('Second announcement')).called(1);
      verify(mockTts.speak('Third announcement')).called(1);
    });
  });
}
