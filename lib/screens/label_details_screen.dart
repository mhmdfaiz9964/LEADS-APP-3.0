import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/models/label_model.dart';
import 'package:leads_manager/models/customer_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/screens/customer_details_screen.dart';
import 'package:leads_manager/screens/add_customer_screen.dart';
import 'package:flutter/cupertino.dart';

class LabelDetailsScreen extends StatefulWidget {
  final LabelModel label;
  const LabelDetailsScreen({super.key, required this.label});

  @override
  State<LabelDetailsScreen> createState() => _LabelDetailsScreenState();
}

class _LabelDetailsScreenState extends State<LabelDetailsScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.label.name),
        backgroundColor: AppTheme.appBarGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Tap and hold on a record for more options",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: DatabaseService().getCustomersByLabel(widget.label.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final customers = snapshot.data!;
                if (customers.isEmpty)
                  return const Center(
                    child: Text("No customers assigned to this label"),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final now = DateTime.now();
                    final diff = now.difference(customer.createdAt);
                    String timeStr = diff.inMinutes < 60
                        ? "+ ${diff.inMinutes} min. ago, ${DateFormat('h:mm a').format(customer.createdAt)}"
                        : "${DateFormat('MMM d').format(customer.createdAt)}, ${DateFormat('h:mm a').format(customer.createdAt)}";

                    return RecordCard(
                      customer: customer,
                      timeStr: timeStr,
                      onDelete: () => _confirmDelete(context, customer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecordCard extends StatefulWidget {
  final Customer customer;
  final String timeStr;
  final VoidCallback onDelete;

  const RecordCard({
    super.key,
    required this.customer,
    required this.timeStr,
    required this.onDelete,
  });

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
