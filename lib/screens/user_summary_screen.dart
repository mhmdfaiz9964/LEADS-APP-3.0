import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/lead_model.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/reminder_model.dart';
import '../models/service_model.dart';
import 'lead_details_screen.dart';
import 'customer_details_screen.dart';

class UserSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserSummaryScreen({required this.userData, super.key});

  @override
  State<UserSummaryScreen> createState() => _UserSummaryScreenState();
}

class _UserSummaryScreenState extends State<UserSummaryScreen>
    with SingleTickerProviderStateMixin {
  Map<String, int>? _stats;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    final email = widget.userData['email'] as String;
    final stats = await DatabaseService().getUserStats(email);
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.userData['email'] ?? 'Unknown';
    final fullName = widget.userData['fullName'] ?? 'No Name';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBlue,
        title: Text(
          fullName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.secondaryOrange,
          isScrollable: true,
          tabs: [
            Tab(text: "Leads (${_stats?['leads'] ?? 0})"),
            Tab(text: "Customers (${_stats?['customers'] ?? 0})"),
            Tab(text: "Services (${_stats?['orders'] ?? 0})"),
            Tab(text: "Reminders (${_stats?['reminders'] ?? 0})"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeadsList(email),
                _buildCustomersList(email),
                _buildOrdersList(email),
                _buildRemindersList(email),
              ],
            ),
    );
  }

  Widget _buildLeadsList(String email) {
    return StreamBuilder<List<Lead>>(
      stream: DatabaseService().getLeads(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final leads = snapshot.data!;
        if (leads.isEmpty)
          return const Center(child: Text("No leads added by this user"));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: leads.length,
          itemBuilder: (context, index) {
            final lead = leads[index];
            final timeStr = DateFormat('MMM d, h:mm a').format(lead.createdAt);
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeadDetailsScreen(lead: lead),
                  ),
                ),
                leading: const Icon(
                  Icons.track_changes,
                  color: AppTheme.primaryBlue,
                  size: 36,
                ),
                title: Text(
                  "${lead.name} (${lead.agentName})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildServiceBadge(lead.serviceIds),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomersList(String email) {
    return StreamBuilder<List<Customer>>(
      stream: DatabaseService().getCustomers(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final customers = snapshot.data!;
        if (customers.isEmpty)
          return const Center(child: Text("No customers added by this user"));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            final timeStr = DateFormat(
              'MMM d, h:mm a',
            ).format(customer.createdAt);
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailsScreen(customer: customer),
                  ),
                ),
                leading: const Icon(
                  Icons.person,
                  color: Color(0xFF0046FF),
                  size: 36,
                ),
                title: Text(
                  "${customer.name} (${customer.agentName})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildServiceBadge(customer.serviceIds),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersList(String email) {
    return StreamBuilder<List<OrderModel>>(
      stream: DatabaseService().getOrders(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        if (orders.isEmpty)
          return const Center(child: Text("No orders added by this user"));
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            Color statusColor = Colors.blue;
            if (order.status == 'NEW') statusColor = Colors.purple;
            if (order.status == 'PROCESS') statusColor = Colors.orange;
            if (order.status == 'APPROVED') statusColor = Colors.green;
            if (order.status == 'REFUSED') statusColor = Colors.red;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.appBarBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: AppTheme.appBarBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Service #${order.orderNumber} - ${order.serviceName}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${DateFormat('MMM d').format(order.createdAt)} - ${order.sellAmount} AED",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRemindersList(String email) {
    return StreamBuilder<List<Reminder>>(
      stream: DatabaseService().getReminders(filterEmail: email),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final reminders = snapshot.data!;
        if (reminders.isEmpty)
          return const Center(child: Text("No reminders added by this user"));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reminders.length,
          separatorBuilder: (ctx, idx) => const Divider(),
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return ListTile(
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
                        builder: (_) =>
                            CustomerDetailsScreen(customer: customer),
                      ),
                    );
                  }
                }
              },
              leading: Icon(
                Icons.alarm,
                color: reminder.isCompleted ? Colors.grey : Colors.purple,
              ),
              title: Text(
                reminder.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: reminder.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                DateFormat('MMM dd, hh:mm a').format(reminder.date),
              ),
              trailing: reminder.isCompleted
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  : null,
            );
          },
        );
      },
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
            .take(2)
            .toList();
        if (selectedServices.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 4,
          children: selectedServices
              .map(
                (service) => Container(
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
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
