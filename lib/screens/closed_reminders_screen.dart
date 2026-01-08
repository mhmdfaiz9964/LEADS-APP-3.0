import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../../models/reminder_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ClosedRemindersScreen extends StatelessWidget {
  const ClosedRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final isAdmin = user?.role == 'admin';
    final filterEmail = isAdmin ? null : user?.email;

    return StreamBuilder<List<Reminder>>(
      stream: DatabaseService().getReminders(filterEmail: filterEmail),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Closed History")),
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("Closed History")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final closedReminders =
            snapshot.data?.where((r) => r.isCompleted).toList() ?? [];

        closedReminders.sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              "Closed History (${closedReminders.length})",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: closedReminders.isEmpty
              ? const Center(child: Text("No closed reminders"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: closedReminders.length,
                  itemBuilder: (context, index) {
                    final reminder = closedReminders[index];
                    return _buildClosedReminderCard(context, reminder);
                  },
                ),
        );
      },
    );
  }

  Widget _buildClosedReminderCard(BuildContext context, Reminder reminder) {
    final dateStr = DateFormat('MMM dd, yyyy').format(reminder.date);
    final timeStr = DateFormat('hh:mm a').format(reminder.date);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$dateStr • $timeStr",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => _confirmDelete(context, reminder),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Reminder reminder) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete History"),
        content: const Text("Remove this reminder from history?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await DatabaseService().deleteReminder(reminder.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
