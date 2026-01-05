import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:announcement_scheduler/src/services/core_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockCoreNotificationService extends Mock
    implements CoreNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<int> scheduleOneTimeAnnouncement({
    required String? content,
    required DateTime? dateTime,
    int? id,
    Map<String, dynamic>? metadata,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#scheduleOneTimeAnnouncement, [], {
        #content: content,
        #dateTime: dateTime,
        #id: id,
        #metadata: metadata,
      }),
      returnValue: Future.value(id ?? 0),
      returnValueForMissingStub: Future.value(id ?? 0),
    );
  }
}

void main() {
  late MockCoreNotificationService mockNotificationService;
  late AnnouncementScheduler scheduler;

  setUp(() async {
    mockNotificationService = MockCoreNotificationService();

    scheduler = await AnnouncementScheduler.initialize(
      config: const AnnouncementConfig(
        notificationConfig: NotificationConfig(),
      ),
      notificationService: mockNotificationService,
    );
  });

  test(
    'scheduleOneTimeAnnouncement accepts id and metadata and passes them to service',
    () async {
      final dateTime = DateTime.now().add(const Duration(hours: 1));
      const content = 'Test content';
      const id = 123456789;
      const metadata = {'key': 'value'};

      await scheduler.scheduleOneTimeAnnouncement(
        content: content,
        dateTime: dateTime,
        id: id,
        metadata: metadata,
      );

      verify(
        mockNotificationService.scheduleOneTimeAnnouncement(
          content: content,
          dateTime: dateTime,
          id: id,
          metadata: metadata,
        ),
      ).called(1);
    },
  );

  test('scheduleOneTimeAnnouncement generates id if not provided', () async {
    final dateTime = DateTime.now().add(const Duration(hours: 1));
    const content = 'Test content';

    await scheduler.scheduleOneTimeAnnouncement(
      content: content,
      dateTime: dateTime,
    );

    // Verify called with SOME id (we don't know the exact timestamp)
    final verification = verify(
      mockNotificationService.scheduleOneTimeAnnouncement(
        content: content,
        dateTime: dateTime,
        id: captureAnyNamed('id'),
        metadata: anyNamed('metadata'),
      ),
    );
    verification.called(1);

    final capturedId = verification.captured.first as int;
    expect(capturedId, isNotNull);
    expect(capturedId, isPositive);
  });
}
