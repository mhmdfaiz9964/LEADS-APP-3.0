import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/models/reminder_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:leads_manager/screens/add_reminder_screen.dart';
import 'package:leads_manager/screens/closed_reminders_screen.dart';
import 'package:leads_manager/screens/lead_details_screen.dart';
import 'package:leads_manager/screens/customer_details_screen.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/models/customer_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemindersScreen extends StatefulWidget {
  final String searchQuery;
  const RemindersScreen({this.searchQuery = "", super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  void _confirmDelete(BuildContext context, Reminder reminder) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete Reminder"),
        content: const Text("Are you sure? This action is permanent."),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final isAdmin = user?.role == 'admin';
    final filterEmail = isAdmin ? null : user?.email;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Tap and hold on a record for more options",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Reminder>>(
            stream: DatabaseService().getReminders(filterEmail: filterEmail),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(child: Text("No reminders found"));

              var reminders = snapshot.data!;
              if (widget.searchQuery.isNotEmpty) {
                final query = widget.searchQuery.toLowerCase();
                reminders = reminders
                    .where((r) => r.title.toLowerCase().contains(query))
                    .toList();
              }

              final activeReminders = reminders
                  .where((r) => !r.isCompleted)
                  .toList();
              final closedCount = reminders.where((r) => r.isCompleted).length;

              activeReminders.sort((a, b) {
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                return a.date.compareTo(b.date);
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
                children: [
                  ...activeReminders
                      .map(
                        (reminder) => ReminderCard(
                          reminder: reminder,
                          onDelete: () => _confirmDelete(context, reminder),
                        ),
                      )
                      .toList(),
                  if (closedCount > 0) _buildClosedHistoryLink(closedCount),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClosedHistoryLink(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClosedRemindersScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  "Closed Reminder History",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReminderCard extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onDelete;
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onDelete,
  });

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  bool _isExpanded = false;

  void _showReminderOptions(BuildContext context, Reminder reminder) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(reminder.title),
        message: const Text('Reminder Actions'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddReminderScreen(reminderToEdit: reminder),
                ),
              );
            },
            child: const Text('Edit Reminder'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Delete Reminder'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(widget.reminder.date);
    final timeStr = DateFormat('hh:mm a').format(widget.reminder.date);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () async {
          final doc = await FirebaseFirestore.instance
              .collection(
                widget.reminder.targetType == 'LEAD' ? 'leads' : 'customers',
              )
              .doc(widget.reminder.targetId)
              .get();

          if (doc.exists && mounted) {
            if (widget.reminder.targetType == 'LEAD') {
              final lead = Lead.fromFirestore(doc);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadDetailsScreen(lead: lead),
                ),
              );
            } else {
              final customer = Customer.fromFirestore(doc);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerDetailsScreen(customer: customer),
                ),
              );
            }
          }
        },
        onLongPress: () => _showReminderOptions(context, widget.reminder),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: widget.reminder.isCompleted,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) async {
                      if (val != null)
                        await DatabaseService().toggleReminderStatus(
                          widget.reminder.id,
                          widget.reminder.isCompleted,
                        );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.reminder.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: widget.reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.reminder.isCompleted
                                ? Colors.grey
                                : (widget.reminder.date.isBefore(DateTime.now())
                                      ? Colors.red
                                      : Colors.black87),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: widget.reminder.isCompleted
                                  ? Colors.grey[400]
                                  : (widget.reminder.date.isBefore(
                                          DateTime.now(),
                                        )
                                        ? Colors.red
                                        : Colors.grey[400]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.reminder.isCompleted
                                    ? Colors.grey[400]
                                    : (widget.reminder.date.isBefore(
                                            DateTime.now(),
                                          )
                                          ? Colors.red
                                          : Colors.grey[400]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.reminder.isCompleted
                              ? Colors.grey[400]
                              : (widget.reminder.date.isBefore(DateTime.now())
                                    ? Colors.red
                                    : Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              await DatabaseService().toggleReminderPin(
                                widget.reminder.id,
                                widget.reminder.isPinned,
                              );
                            },
                            child: Icon(
                              widget.reminder.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: widget.reminder.isPinned
                                  ? AppTheme.secondaryOrange
                                  : Colors.grey[300],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 52),
                      _buildInlineAction(
                        Icons.edit_outlined,
                        "Edit",
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddReminderScreen(
                                reminderToEdit: widget.reminder,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.delete_outline,
                        "Delete",
                        Colors.red,
                        widget.onDelete,
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, style: TextStyle(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
