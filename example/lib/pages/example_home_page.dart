import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/example_page_controller.dart';
import '../services/announcement_service.dart';
import '../utils/feedback_helper.dart';

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller using GetX dependency injection
    final controller = Get.put(ExamplePageController(AnnouncementService()));

    // Initialize the scheduler when the controller is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isSchedulerInitialized) {
        controller.initializeScheduler();
      }
    });

    return _buildScaffold(controller, context);
  }

  Widget _buildScaffold(
    ExamplePageController controller,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Scheduler Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(
        () => controller.isInitializing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing announcement scheduler...'),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This example demonstrates the announcement_scheduler package capabilities:',
                            ),
                            SizedBox(height: 8),
                            Text('• Daily, weekly and one-time announcements'),
                            Text('• TTS (Text-to-Speech) integration'),
                            SizedBox(height: 8),
                            Text(
                              'Suggest starting at AnnouncementScheduler.scheduleAnnouncement()',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: !controller.isSchedulerInitialized
                          ? null
                          : () => _scheduleExampleAnnouncements(
                              controller,
                              context,
                            ),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Schedule Example Announcements'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: !controller.isSchedulerInitialized
                          ? null
                          : () => _showScheduledAnnouncements(
                              controller,
                              context,
                            ),
                      icon: const Icon(Icons.list),
                      label: const Text('View Scheduled Announcements'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: !controller.isSchedulerInitialized
                          ? null
                          : () => _cancelAllAnnouncements(controller, context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel All Announcements'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scheduler initialized: ${controller.isSchedulerInitialized ? "✅" : "❌"}',
                            ),
                            Text(
                              'Scheduled announcements: ${controller.scheduledAnnouncementIds.length}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Helper methods for button actions
  Future<void> _scheduleExampleAnnouncements(
    ExamplePageController controller,
    BuildContext context,
  ) async {
    final success = await controller.scheduleExampleAnnouncements();

    if (!context.mounted) return;

    if (success) {
      FeedbackHelper.showSuccess(
        context,
        'Example announcements scheduled successfully!',
      );
    } else if (controller.hasError) {
      FeedbackHelper.showError(context, controller.errorMessage!);
    }
  }

  Future<void> _cancelAllAnnouncements(
    ExamplePageController controller,
    BuildContext context,
  ) async {
    final success = await controller.cancelAllAnnouncements();

    if (!context.mounted) return;

    if (success) {
      FeedbackHelper.showWarning(context, 'All announcements cancelled!');
    } else if (controller.hasError) {
      FeedbackHelper.showError(context, controller.errorMessage!);
    }
  }

  Future<void> _showScheduledAnnouncements(
    ExamplePageController controller,
    BuildContext context,
  ) async {
    final announcements = await controller.getScheduledAnnouncements();

    if (!context.mounted) return;

    if (controller.hasError) {
      FeedbackHelper.showError(context, controller.errorMessage!);
      return;
    }

    await FeedbackHelper.showScheduledAnnouncementsDialog(
      context,
      announcements,
    );
  }
}
