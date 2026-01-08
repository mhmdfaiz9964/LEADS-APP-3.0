import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/models/customer_model.dart';
import 'package:leads_manager/models/label_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:leads_manager/screens/customer_details_screen.dart';
import 'package:leads_manager/screens/add_customer_screen.dart';
import 'package:leads_manager/screens/label_details_screen.dart';
import 'package:provider/provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _selectedFilter = "ALL";

  void _showStatusChangeDialog(Customer customer) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Change Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            _buildStatusOption(
              ctx,
              customer,
              "ORDER",
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildStatusOption(
              ctx,
              customer,
              "PAYMENT_APPROVED",
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatusOption(
              ctx,
              customer,
              "PREPARED",
              Icons.inventory,
              Colors.orange,
            ),
            _buildStatusOption(
              ctx,
              customer,
              "DELIVERED",
              Icons.local_shipping,
              Colors.purple,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext ctx,
    Customer customer,
    String status,
    IconData icon,
    Color color,
  ) {
    final isSelected = customer.status == status;
    return GestureDetector(
      onTap: () async {
        final updatedCustomer = customer.copyWith(status: status);
        await DatabaseService().updateCustomer(updatedCustomer);
        if (ctx.mounted) Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status.replaceAll('_', ' '),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Customer customer) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete Customer"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await DatabaseService().deleteCustomer(customer.id);
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
        // Label Filter Row
        Container(
          color: AppTheme.appBarGreen,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: StreamBuilder<List<LabelModel>>(
            stream: DatabaseService().getLabels(),
            builder: (context, labelSnapshot) {
              if (!labelSnapshot.hasData) return const SizedBox();
              final labels = labelSnapshot.data!;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildFilterChip("ALL", "ALL", AppTheme.secondaryOrange),
                    ...labels.map(
                      (l) => _buildFilterChip(
                        l.name.toUpperCase(),
                        l.id,
                        Color(l.colorValue),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: DatabaseService().getCustomers(filterEmail: filterEmail),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(child: Text("No customers found"));

              var customers = snapshot.data!;

              // Apply label filter
              if (_selectedFilter != "ALL") {
                customers = customers
                    .where((c) => c.labelIds.contains(_selectedFilter))
                    .toList();
              }

              customers.sort((a, b) {
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                return b.createdAt.compareTo(a.createdAt);
              });

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final now = DateTime.now();
                  final diff = now.difference(customer.createdAt);
                  String timeStr = "";
                  if (diff.inMinutes < 60) {
                    timeStr =
                        "+ ${diff.inMinutes} min. ago, ${DateFormat('h:mm a').format(customer.createdAt)}";
                  } else {
                    timeStr =
                        "${DateFormat('MMM d').format(customer.createdAt)}, ${DateFormat('h:mm a').format(customer.createdAt)}";
                  }
                  return CustomerCard(
                    customer: customer,
                    timeStr: timeStr,
                    onDelete: () => _confirmDelete(context, customer),
                    onStatusChange: () => _showStatusChangeDialog(customer),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String id, Color color) {
    bool isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = isSelected ? "ALL" : id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class CustomerCard extends StatefulWidget {
  final Customer customer;
  final String timeStr;
  final VoidCallback onDelete;
  final VoidCallback onStatusChange;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.timeStr,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  bool _isExpanded = false;

  void _showCustomerOptions(BuildContext context, Customer customer) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(customer.name),
        message: Text(customer.company),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerDetailsScreen(customer: customer),
                ),
              );
            },
            child: const Text('View Details'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCustomerScreen(customerToEdit: customer),
                ),
              );
            },
            child: const Text('Edit Customer'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onStatusChange();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 20),
                SizedBox(width: 8),
                Text('Change Status'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Delete Customer'),
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
        onLongPress: () => _showCustomerOptions(context, widget.customer),
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
                          GestureDetector(
                            onTap: () async {
                              await DatabaseService().toggleCustomerPin(
                                widget.customer.id,
                                widget.customer.isPinned,
                              );
                            },
                            child: Icon(
                              widget.customer.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: widget.customer.isPinned
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
                      const SizedBox(width: 48),
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
                        Icons.assignment_outlined,
                        "Details",
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailsScreen(
                                customer: widget.customer,
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
