import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/models/reminder_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/screens/add_reminder_screen.dart';

class RemindersListScreen extends StatelessWidget {
  final String targetId;
  final String targetType;

  const RemindersListScreen({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarGreen,
        title: const Text("Reminders"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddReminderScreen(targetId: targetId, targetType: targetType),
            ),
          );
        },
        backgroundColor: AppTheme.secondaryOrange,
        child: const Icon(Icons.add, size: 30),
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: DatabaseService().getRemindersByTarget(targetId, targetType),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No reminders set",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final reminders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final now = DateTime.now();
              final isDue = now.isAfter(reminder.date);
              final isCompleted = reminder.isCompleted;

              return Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Reminder"),
                      content: const Text(
                        "Are you sure you want to delete this reminder?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  DatabaseService().deleteReminder(reminder.id);
                },
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.5)
                          : (isDue
                                ? Colors.red.withOpacity(0.5)
                                : Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  color: isCompleted
                      ? Colors.green.withOpacity(0.05)
                      : Colors.white,
                  child: ListTile(
                    leading: IconButton(
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isCompleted
                            ? Colors.green
                            : (isDue ? Colors.red : Colors.grey),
                      ),
                      onPressed: () {
                        DatabaseService().toggleReminderStatus(
                          reminder.id,
                          reminder.isCompleted,
                        );
                      },
                    ),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted ? Colors.grey : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('EEE, MMM d • h:mm a').format(reminder.date),
                      style: TextStyle(
                        color: isDue && !isCompleted
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddReminderScreen(reminderToEdit: reminder),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
