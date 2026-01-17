import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../../models/reminder_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddReminderScreen extends StatefulWidget {
  final Reminder? reminderToEdit;
  final String? targetId;
  final String? targetType;
  const AddReminderScreen({
    super.key,
    this.reminderToEdit,
    this.targetId,
    this.targetType,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  bool _isLoading = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;
    _titleController = TextEditingController(text: r?.title ?? "");
    _selectedDate = r?.date;
    _selectedTime = r != null ? TimeOfDay.fromDateTime(r.date) : null;

    _dateController = TextEditingController(
      text: _selectedDate != null
          ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
          : "",
    );
    _timeController = TextEditingController(
      text: _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : "",
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _showFeedback(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _formatTimeOfDay(picked);
      });
    }
  }

  void _saveReminder() async {
    if (_titleController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      _showFeedback(
        "Data Required",
        "Please fill in the title, date, and time.",
      );
      return;
    }

    setState(() => _isLoading = true);
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      setState(() => _isLoading = false);
      _showFeedback("Error", "Auth session expired.");
      return;
    }

    final reminder = Reminder(
      id: widget.reminderToEdit?.id ?? '',
      title: _titleController.text,
      date: dateTime,
      isCompleted: widget.reminderToEdit?.isCompleted ?? false,
      targetId: widget.reminderToEdit?.targetId ?? widget.targetId,
      targetType: widget.reminderToEdit?.targetType ?? widget.targetType,
      creatorEmail: widget.reminderToEdit?.creatorEmail ?? userEmail,
    );

    try {
      if (widget.reminderToEdit != null) {
        await DatabaseService().updateReminder(reminder);
        await NotificationService().cancelNotifications(reminder.id);
        await NotificationService().scheduleReminderNotifications(
          reminder.id,
          reminder.title,
          reminder.date,
        );
        // Schedule OneSignal Push
        await NotificationService().scheduleOneSignalPush(
          title: reminder.title,
          message: "Reminder for your task",
          scheduledTime: reminder.date,
          creatorEmail: reminder.creatorEmail ?? userEmail,
        );
      } else {
        final docRef = await DatabaseService().addReminder(reminder);
        await NotificationService().scheduleReminderNotifications(
          docRef.id,
          reminder.title,
          reminder.date,
        );
        // Schedule OneSignal Push
        await NotificationService().scheduleOneSignalPush(
          title: reminder.title,
          message: "Reminder for your task",
          scheduledTime: reminder.date,
          creatorEmail: reminder.creatorEmail ?? userEmail,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reminderToEdit != null
                  ? "Reminder updated"
                  : "Reminder set",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showFeedback("Error", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminderToEdit != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBlue,
        title: Text(isEditing ? "Edit Task" : "Add New Task"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildField(
                  Icons.edit_calendar,
                  "What needs to be done?",
                  _titleController,
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: _buildField(
                      Icons.calendar_month,
                      "Date",
                      _dateController,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: _buildField(
                      Icons.access_time,
                      "Time",
                      _timeController,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 24,
                top: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            "OK",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    IconData icon,
    String hint,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0046FF), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
