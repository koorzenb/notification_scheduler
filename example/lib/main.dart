import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:flutter/material.dart';

/// Simple, standalone example showing how to use the announcement_scheduler package.
/// This demonstrates the core functionality in a straightforward way.
///
/// For a more advanced example using GetX architecture, see:
/// - pages/example_home_page.dart
/// - controllers/example_page_controller.dart
///
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the announcement service with configuration
  final announcementService = await AnnouncementService.create(
    config: AnnouncementConfig(
      enableTTS: true,
      ttsRate: 0.5,
      ttsPitch: 1.0,
      ttsVolume: 1.0,
      enableDebugLogging: true,
      forceTimezone: true, // Use the timezone from settings
      timezoneLocation: 'America/Halifax',
      notificationConfig: NotificationConfig(
        channelId: 'example_announcements',
        channelName: 'Example Announcements',
        channelDescription: 'Example scheduled announcements',
      ),
      validationConfig: const ValidationConfig(
        maxNotificationsPerDay: 5,
        maxScheduledNotifications: 20,
      ),
    ),
  );

  runApp(SimpleAnnouncementExample(service: announcementService));
}

class SimpleAnnouncementExample extends StatelessWidget {
  final AnnouncementService service;

  const SimpleAnnouncementExample({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Announcement Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: SimpleExamplePage(service: service),
    );
  }
}

class SimpleExamplePage extends StatefulWidget {
  final AnnouncementService service;

  const SimpleExamplePage({super.key, required this.service});

  @override
  State<SimpleExamplePage> createState() => _SimpleExamplePageState();
}

class _SimpleExamplePageState extends State<SimpleExamplePage> {
  String _statusMessage = 'Ready to schedule announcements';
  List<ScheduledNotification> _scheduledAnnouncements = [];

  @override
  void initState() {
    super.initState();
    // Listen to status updates from the service
    widget.service.statusStream.listen((status) {
      debugPrint('Announcement status: $status');
    });
  }

  @override
  void dispose() {
    widget.service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Announcement Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
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
                      'Announcement Scheduler Example',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('This example demonstrates:'),
                    Text('• One-time announcements'),
                    Text('• Daily recurring announcements'),
                    Text('• Weekly recurring announcements'),
                    Text('• TTS (Text-to-Speech) integration'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _scheduleExamples,
              icon: const Icon(Icons.schedule),
              label: const Text('Schedule Example Announcements'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _viewScheduled,
              icon: const Icon(Icons.list),
              label: const Text('View Scheduled Announcements'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _cancelAll,
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
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_statusMessage),
                  ],
                ),
              ),
            ),
            if (_scheduledAnnouncements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Scheduled Announcements:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _scheduledAnnouncements.length,
                  itemBuilder: (context, index) {
                    final announcement = _scheduledAnnouncements[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(announcement.content),
                        subtitle: Text(
                          'ID: ${announcement.id}\n'
                          'Next: ${announcement.scheduledTime}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Schedule example announcements
  Future<void> _scheduleExamples() async {
    try {
      final now = DateTime.now();

      // Example 1: One-time announcement 5 seconds from now
      await widget.service.scheduleOnceOff(
        content: 'This is a one-time announcement from 5 seconds ago.',
        dateTime: now.add(const Duration(seconds: 5)),
        metadata: {'type': 'one-time'},
      );

      // Example 2: Daily announcement at 9:00 AM
      await widget.service.scheduleDaily(
        content: 'Good morning! This is your daily announcement at 9:00 AM.',
        time: const TimeOfDay(hour: 9, minute: 0),
        metadata: {'type': 'daily'},
      );

      // Example 3: Weekly announcement on odd days at 5:00 PM
      await widget.service.scheduleWeekly(
        content: 'Happy Odd Day! This is your weekly announcement at 5:00 PM.',
        time: const TimeOfDay(hour: 17, minute: 0),
        weekdays: [1, 3, 5, 7], // Monday, Wednesday, Friday, Sunday
        metadata: {'type': 'weekly'},
      );

      setState(() {
        _statusMessage = 'Successfully scheduled 3 announcements!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcements scheduled!')),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  /// View all scheduled announcements
  Future<void> _viewScheduled() async {
    try {
      final announcements = await widget.service.getScheduledAnnouncements();
      setState(() {
        _scheduledAnnouncements = announcements;
        _statusMessage =
            'Found ${announcements.length} scheduled announcement(s)';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading announcements: $e';
      });
    }
  }

  /// Cancel all announcements
  Future<void> _cancelAll() async {
    try {
      await widget.service.cancelAllAnnouncements();
      setState(() {
        _scheduledAnnouncements = [];
        _statusMessage = 'All announcements cancelled';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All announcements cancelled')),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error cancelling announcements: $e';
      });
    }
  }
}
