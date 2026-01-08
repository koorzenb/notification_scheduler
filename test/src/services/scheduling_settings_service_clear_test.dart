import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:notification_scheduler/src/services/scheduling_settings_service.dart';
import 'package:notification_scheduler/src/services/storage_service.dart';

import 'scheduling_settings_service_clear_test.mocks.dart';

@GenerateMocks([IStorageService])
void main() {
  group('SchedulingSettingsService - clearSettings', () {
    late MockIStorageService mockStorage;
    late SchedulingSettingsService service;

    setUp(() {
      mockStorage = MockIStorageService();
      service = SchedulingSettingsService(mockStorage);
    });

    test('clearSettings removes scheduledAnnouncements key', () async {
      // Arrange
      when(mockStorage.remove(any)).thenAnswer((_) async {});

      // Act
      await service.clearSettings();

      // Assert
      verify(mockStorage.remove('scheduledAnnouncements')).called(1);
    });
  });
}
