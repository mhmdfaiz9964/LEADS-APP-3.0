import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/models/customer_model.dart';
import 'package:leads_manager/models/service_model.dart';
import 'package:leads_manager/models/reminder_model.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/screens/lead_details_screen.dart';
import 'package:leads_manager/screens/customer_details_screen.dart';
import 'package:leads_manager/screens/service_details_screen.dart';
import 'package:leads_manager/screens/add_lead_screen.dart';
import 'package:leads_manager/screens/add_customer_screen.dart';
import 'package:leads_manager/screens/add_service_screen.dart';
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
        backgroundColor: AppTheme.appBarBlue,
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
            Tab(text: "SERVICES"),
            Tab(text: "REMINDERS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadsList(widget.filterEmail),
          _buildCustomersList(widget.filterEmail),
          _buildServicesList(widget.filterEmail),
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

  Widget _buildServicesList(String? email) {
    return StreamBuilder<List<ServiceModel>>(
      stream: DatabaseService().getServices(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final services = snapshot.data!;
        if (services.isEmpty)
          return const Center(child: Text("No services found"));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ActivityServiceCard(service: service, filterEmail: email);
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
                    color: Color(0xFF0046FF),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.lead.name} (${widget.lead.agentName})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildServiceBadge(widget.lead.serviceIds),
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

  Widget _buildServiceBadge(List<String> labelIds) {
    if (labelIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<ServiceModel>>(
      future: DatabaseService().getServices().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final selectedServices = snapshot.data!
            .where((l) => labelIds.contains(l.id))
            .toList();
        if (selectedServices.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: selectedServices
              .map(
                (service) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailsScreen(service: service),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: service.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service.name.toUpperCase(),
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
                  const Icon(Icons.person, color: Color(0xFF0046FF), size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.customer.name} (${widget.customer.agentName})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildServiceBadge(widget.customer.serviceIds),
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

  Widget _buildServiceBadge(List<String> labelIds) {
    if (labelIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<ServiceModel>>(
      future: DatabaseService().getServices().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final selectedServices = snapshot.data!
            .where((l) => labelIds.contains(l.id))
            .toList();
        if (selectedServices.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: selectedServices
              .map(
                (service) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailsScreen(service: service),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: service.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service.name.toUpperCase(),
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

class ActivityServiceCard extends StatefulWidget {
  final ServiceModel service;
  final String? filterEmail;
  const ActivityServiceCard({
    super.key,
    required this.service,
    this.filterEmail,
  });

  @override
  State<ActivityServiceCard> createState() => _ActivityServiceCardState();
}

class _ActivityServiceCardState extends State<ActivityServiceCard> {
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
            builder: (_) => ServiceDetailsScreen(service: widget.service),
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
                      color: widget.service.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.service.name.toUpperCase(),
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
                        .getLeadsCountByService(
                          widget.service.id,
                          filterEmail: widget.filterEmail,
                        )
                        .first,
                    builder: (context, snapshot) {
                      return Text(
                        "${snapshot.data ?? 0} Records",
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
                                  ServiceDetailsScreen(service: widget.service),
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
                              builder: (_) => AddServiceScreen(
                                serviceToEdit: widget.service,
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
                          await DatabaseService().deleteService(
                            widget.service.id,
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

class ActivityReminderCard extends StatelessWidget {
  final Reminder reminder;
  const ActivityReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: () async {
          final doc = await FirebaseFirestore.instance
              .collection(
                reminder.targetType == 'LEAD'
                    ? 'booking_leads'
                    : 'booking_customers',
              )
              .doc(reminder.targetId)
              .get();

          if (doc.exists && context.mounted) {
            if (reminder.targetType == 'LEAD') {
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
        leading: Icon(
          Icons.alarm,
          color: reminder.isCompleted ? Colors.grey : Colors.purple,
          size: 36,
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            decoration: reminder.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, h:mm a').format(reminder.date),
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
        trailing: reminder.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : null,
      ),
    );
  }
}
