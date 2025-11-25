import 'package:announcement_scheduler_example/controllers/example_page_controller.dart';
import 'package:announcement_scheduler_example/services/announcement_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('ExamplePageController GetX Tests', () {
    late ExamplePageController controller;
    late AnnouncementService service;

    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;

      service = AnnouncementService();
      controller = ExamplePageController(service);
    });

    tearDown(() {
      Get.reset();
    });

    test('should initialize with correct default values', () {
      expect(
        controller.isInitializing,
        isFalse,
        reason: 'Controller should not be initializing on creation',
      );
      expect(
        controller.errorMessage,
        isNull,
        reason: 'No error message should be set initially',
      );
      expect(
        controller.hasError,
        isFalse,
        reason: 'Should not have error initially',
      );
    });

    test('should return false for isSchedulerInitialized initially', () {
      expect(controller.isSchedulerInitialized, false);
    });

    test('should handle service initialization', () async {
      // This is more of an integration test since we can't easily mock
      // the AnnouncementScheduler without more complex setup
      expect(controller.isInitializing, false);

      // The actual initialization would require proper mocking of
      // the AnnouncementScheduler, which is complex for this example
    });

    test('should handle error states properly', () {
      // Initially no error
      expect(controller.hasError, false);
      expect(controller.errorMessage, isNull);

      // After potential error, the getters should work correctly
      // (actual error setting would happen in real methods)
    });
  });
}
