import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/models/customer_model.dart';
import 'package:leads_manager/models/label_model.dart';
import 'package:leads_manager/models/reminder_model.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/screens/lead_details_screen.dart';
import 'package:leads_manager/screens/customer_details_screen.dart';
import 'package:leads_manager/screens/label_details_screen.dart';
import 'package:leads_manager/screens/add_lead_screen.dart';
import 'package:leads_manager/screens/add_customer_screen.dart';
import 'package:leads_manager/screens/add_reminder_screen.dart';
import 'package:leads_manager/screens/add_label_screen.dart';
import 'package:flutter/cupertino.dart';

class UserActivitiesScreen extends StatefulWidget {
  final String? filterEmail;
  final String? title;

  const UserActivitiesScreen({super.key, this.filterEmail, this.title});

  @override
  State<UserActivitiesScreen> createState() => _UserActivitiesScreenState();
}

class _UserActivitiesScreenState extends State<UserActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.title ?? "User Activities",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.appBarGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.secondaryOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: "LEADS"),
            Tab(text: "CUSTOMERS"),
            Tab(text: "LABELS"),
            Tab(text: "REMINDERS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadsList(widget.filterEmail),
          _buildCustomersList(widget.filterEmail),
          _buildLabelsList(widget.filterEmail),
          _buildRemindersList(widget.filterEmail),
        ],
      ),
    );
  }

  Widget _buildLeadsList(String? email) {
    return StreamBuilder<List<Lead>>(
      stream: DatabaseService().getLeads(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final leads = snapshot.data!;
        if (leads.isEmpty) return const Center(child: Text("No leads found"));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: leads.length,
          itemBuilder: (context, index) {
            final lead = leads[index];
            final now = DateTime.now();
            final diff = now.difference(lead.createdAt);
            String timeStr = diff.inMinutes < 60
                ? "+ ${diff.inMinutes} min. ago, ${DateFormat('h:mm a').format(lead.createdAt)}"
                : "${DateFormat('MMM d').format(lead.createdAt)}, ${DateFormat('h:mm a').format(lead.createdAt)}";

            return ActivityLeadCard(lead: lead, timeStr: timeStr);
          },
        );
      },
    );
  }

  Widget _buildCustomersList(String? email) {
    return StreamBuilder<List<Customer>>(
      stream: DatabaseService().getCustomers(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final customers = snapshot.data!;
        if (customers.isEmpty)
          return const Center(child: Text("No customers found"));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            final now = DateTime.now();
            final diff = now.difference(customer.createdAt);
            String timeStr = diff.inMinutes < 60
                ? "+ ${diff.inMinutes} min. ago, ${DateFormat('h:mm a').format(customer.createdAt)}"
                : "${DateFormat('MMM d').format(customer.createdAt)}, ${DateFormat('h:mm a').format(customer.createdAt)}";

            return ActivityCustomerCard(customer: customer, timeStr: timeStr);
          },
        );
      },
    );
  }

  Widget _buildLabelsList(String? email) {
    return StreamBuilder<List<LabelModel>>(
      stream: DatabaseService().getLabels(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final labels = snapshot.data!;
        if (labels.isEmpty) return const Center(child: Text("No labels found"));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: labels.length,
          itemBuilder: (context, index) {
            final label = labels[index];
            return ActivityLabelCard(label: label, filterEmail: email);
          },
        );
      },
    );
  }

  Widget _buildRemindersList(String? email) {
    return StreamBuilder<List<Reminder>>(
      stream: DatabaseService().getReminders(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final reminders = snapshot.data!;
        if (reminders.isEmpty)
          return const Center(child: Text("No reminders found"));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return ActivityReminderCard(reminder: reminder);
          },
        );
      },
    );
  }
}

class ActivityLeadCard extends StatefulWidget {
  final Lead lead;
  final String timeStr;
  const ActivityLeadCard({
    super.key,
    required this.lead,
    required this.timeStr,
  });

  @override
  State<ActivityLeadCard> createState() => _ActivityLeadCardState();
}

class _ActivityLeadCardState extends State<ActivityLeadCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeadDetailsScreen(lead: widget.lead),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.track_changes,
                    color: Color(0xFF2E5A4B),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.lead.name} (${widget.lead.company})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildLabelBadge(widget.lead.labelIds),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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
                          Icon(
                            widget.lead.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: widget.lead.isPinned
                                ? AppTheme.secondaryOrange
                                : Colors.grey[300],
                            size: 18,
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
                      const SizedBox(width: 48),
                      _buildInlineAction(
                        Icons.edit_outlined,
                        "Edit",
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddLeadScreen(leadToEdit: widget.lead),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.visibility_off_outlined,
                        "Hide",
                        Colors.orange,
                        () {},
                      ),
                      _buildInlineAction(
                        Icons.delete_outline,
                        "Delete",
                        Colors.red,
                        () async {
                          await DatabaseService().deleteLead(widget.lead.id);
                        },
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

  Widget _buildLabelBadge(List<String> labelIds) {
    if (labelIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<LabelModel>>(
      future: DatabaseService().getLabels().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final selectedLabels = snapshot.data!
            .where((l) => labelIds.contains(l.id))
            .toList();
        if (selectedLabels.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: selectedLabels
              .map(
                (label) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LabelDetailsScreen(label: label),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: label.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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

class ActivityCustomerCard extends StatefulWidget {
  final Customer customer;
  final String timeStr;
  const ActivityCustomerCard({
    super.key,
    required this.customer,
    required this.timeStr,
  });

  @override
  State<ActivityCustomerCard> createState() => _ActivityCustomerCardState();
}

class _ActivityCustomerCardState extends State<ActivityCustomerCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailsScreen(customer: widget.customer),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Color(0xFF2E5A4B), size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.customer.name} (${widget.customer.company})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildLabelBadge(widget.customer.labelIds),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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
                          Icon(
                            widget.customer.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: widget.customer.isPinned
                                ? AppTheme.secondaryOrange
                                : Colors.grey[300],
                            size: 18,
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
                              builder: (_) => AddCustomerScreen(
                                customerToEdit: widget.customer,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.visibility_off_outlined,
                        "Hide",
                        Colors.orange,
                        () {},
                      ),
                      _buildInlineAction(
                        Icons.delete_outline,
                        "Delete",
                        Colors.red,
                        () async {
                          await DatabaseService().deleteCustomer(
                            widget.customer.id,
                          );
                        },
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

  Widget _buildLabelBadge(List<String> labelIds) {
    if (labelIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<LabelModel>>(
      future: DatabaseService().getLabels().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final selectedLabels = snapshot.data!
            .where((l) => labelIds.contains(l.id))
            .toList();
        if (selectedLabels.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: selectedLabels
              .map(
                (label) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LabelDetailsScreen(label: label),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: label.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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

class ActivityLabelCard extends StatefulWidget {
  final LabelModel label;
  final String? filterEmail;
  const ActivityLabelCard({super.key, required this.label, this.filterEmail});

  @override
  State<ActivityLabelCard> createState() => _ActivityLabelCardState();
}

class _ActivityLabelCardState extends State<ActivityLabelCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LabelDetailsScreen(label: widget.label),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.label.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.label.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  const Spacer(),
                  FutureBuilder<int>(
                    future: DatabaseService()
                        .getLeadsCountByLabel(
                          widget.label.id,
                          filterEmail: widget.filterEmail,
                        )
                        .first,
                    builder: (context, snapshot) {
                      return Text(
                        "${snapshot.data ?? 0} Customers",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Roboto',
                        ),
                      );
                    },
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
                      const SizedBox(width: 4),
                      _buildInlineAction(
                        Icons.visibility_outlined,
                        "View",
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LabelDetailsScreen(label: widget.label),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.edit_outlined,
                        "Edit",
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddLabelScreen(labelToEdit: widget.label),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.delete_outline,
                        "Delete",
                        Colors.red,
                        () async {
                          await DatabaseService().deleteLabel(widget.label.id);
                        },
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

class ActivityReminderCard extends StatefulWidget {
  final Reminder reminder;
  const ActivityReminderCard({super.key, required this.reminder});

  @override
  State<ActivityReminderCard> createState() => _ActivityReminderCardState();
}

class _ActivityReminderCardState extends State<ActivityReminderCard> {
  bool _isExpanded = false;

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
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: widget.reminder.isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    child: Icon(
                      widget.reminder.isCompleted
                          ? Icons.check_circle
                          : Icons.notifications,
                      color: widget.reminder.isCompleted
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
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
                          Icon(
                            widget.reminder.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: widget.reminder.isPinned
                                ? AppTheme.secondaryOrange
                                : Colors.grey[200],
                            size: 18,
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
                        () async {
                          await DatabaseService().deleteReminder(
                            widget.reminder.id,
                          );
                        },
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
