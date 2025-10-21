import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnnouncementSchedulerExample());
}

class AnnouncementSchedulerExample extends StatelessWidget {
  const AnnouncementSchedulerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Announcement Scheduler Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  AnnouncementScheduler? _scheduler;
  final List<String> _scheduledAnnouncements = [];
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeScheduler();
  }

  Future<void> _initializeScheduler() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      _scheduler = await AnnouncementScheduler.initialize(
        config: AnnouncementConfig(
          enableTTS: true,
          ttsRate: 0.5,
          ttsPitch: 1.0,
          ttsVolume: 1.0,
          enableDebugLogging: true,
          notificationConfig: NotificationConfig(
            channelId: 'example_announcements',
            channelName: 'Example Announcements',
            channelDescription: 'Example scheduled announcements',
          ),
          validationConfig: const ValidationConfig(maxNotificationsPerDay: 5, maxScheduledNotifications: 20),
        ),
      );

      // Listen to status updates
      _scheduler!.statusStream.listen((status) {
        debugPrint('Announcement status: ${status.displayName}'); // todo:
      });
    } catch (e) {
      debugPrint('Failed to initialize scheduler: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _scheduleExampleAnnouncements() async {
    if (_scheduler == null) return;

    try {
      // Schedule a daily morning motivation
      final dailyId = await _scheduler!.scheduleAnnouncement(
        content: 'Good morning! Time to start your day with positive energy!',
        announcementTime: const TimeOfDay(hour: 8, minute: 0),
        recurrence: RecurrencePattern.daily,
        metadata: {'type': 'motivation', 'category': 'morning'},
      );

      // Schedule a weekday work reminder
      final weekdayId = await _scheduler!.scheduleAnnouncement(
        content: 'Don\'t forget to review your daily goals and priorities.',
        announcementTime: const TimeOfDay(hour: 9, minute: 30),
        recurrence: RecurrencePattern.weekdays,
        metadata: {'type': 'productivity', 'category': 'work'},
      );

      // Schedule a one-time reminder
      final oneTimeId = await _scheduler!.scheduleOneTimeAnnouncement(
        content: 'This is a one-time announcement scheduled for 2 minutes from now.',
        dateTime: DateTime.now().add(const Duration(minutes: 2)),
        metadata: {'type': 'reminder', 'category': 'test'},
      );

      setState(() {
        _scheduledAnnouncements.addAll([dailyId, weekdayId, oneTimeId]);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Example announcements scheduled successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule announcements: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _cancelAllAnnouncements() async {
    if (_scheduler == null) return;

    try {
      await _scheduler!.cancelScheduledAnnouncements();
      setState(() {
        _scheduledAnnouncements.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All announcements cancelled!'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel announcements: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showScheduledAnnouncements() async {
    if (_scheduler == null) return;

    try {
      final announcements = await _scheduler!.getScheduledAnnouncements();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Scheduled Announcements'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: announcements.isEmpty
                  ? const Text('No announcements scheduled.')
                  : ListView.builder(
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return Card(
                          child: ListTile(
                            title: Text(announcement.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${announcement.id}'),
                                Text('Time: ${announcement.scheduledTime}'),
                                if (announcement.isRecurring) Text('Recurs: ${announcement.recurrence?.displayName}'),
                              ],
                            ),
                            trailing: announcement.isActive
                                ? const Icon(Icons.schedule, color: Colors.green)
                                : const Icon(Icons.schedule_send, color: Colors.grey),
                          ),
                        );
                      },
                    ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load announcements: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcement Scheduler Example'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Initializing announcement scheduler...')],
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
                          Text('Announcement Scheduler Example', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('This example demonstrates the announcement_scheduler package capabilities:'),
                          SizedBox(height: 8),
                          Text('• Daily morning motivation at 8:00 AM'),
                          Text('• Weekday work reminders at 9:30 AM'),
                          Text('• One-time announcements'),
                          Text('• TTS (Text-to-Speech) integration'),
                          Text('• Status monitoring and management'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _scheduler == null ? null : _scheduleExampleAnnouncements,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Schedule Example Announcements'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _scheduler == null ? null : _showScheduledAnnouncements,
                    icon: const Icon(Icons.list),
                    label: const Text('View Scheduled Announcements'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _scheduler == null ? null : _cancelAllAnnouncements,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel All Announcements'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Scheduler initialized: ${_scheduler != null ? "✅" : "❌"}'),
                          Text('Scheduled announcements: ${_scheduledAnnouncements.length}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scheduler?.dispose();
    super.dispose();
  }
}
