import 'package:announcement_scheduler/announcement_scheduler.dart';
import 'package:flutter/material.dart';

/// Utility class for showing user feedback messages
/// Follows the Strategy pattern for different types of user notifications
class FeedbackHelper {
  /// Show a success message
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Show an error message
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Show a warning message
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  /// Show a dialog with scheduled announcements
  static Future<void> showScheduledAnnouncementsDialog(
    BuildContext context,
    List<ScheduledAnnouncement> announcements,
  ) async {
    if (!context.mounted) return;

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
                        title: Text(
                          announcement.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${announcement.id}'),
                            Text(
                              'Scheduled Time: ${_formatDateTime(announcement.scheduledTime)}',
                            ),
                            if (announcement.isRecurring)
                              Text('Recurs: ${announcement.recurrence}'),
                          ],
                        ),
                        trailing: announcement.isActive
                            ? const Icon(Icons.schedule, color: Colors.green)
                            : const Icon(
                                Icons.schedule_send,
                                color: Colors.grey,
                              ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Format DateTime to display date and time in hours:minutes format
  static String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Not scheduled';

    DateTime dt;
    if (dateTime is DateTime) {
      dt = dateTime;
    } else if (dateTime is String) {
      try {
        dt = DateTime.parse(dateTime);
      } catch (e) {
        return dateTime.toString();
      }
    } else {
      return dateTime.toString();
    }

    // Format: Nov 5, 2025 14:30
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$month $day, $year $hour:$minute';
  }
}
