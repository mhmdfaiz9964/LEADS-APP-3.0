import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/models/order_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:leads_manager/screens/customer_details_screen.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  final String initialStatusFilter;

  const CartScreen({this.initialStatusFilter = "ALL", super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedStatusFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _selectedStatusFilter = widget.initialStatusFilter;
  }

  @override
  void didUpdateWidget(CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatusFilter != widget.initialStatusFilter) {
      setState(() {
        _selectedStatusFilter = widget.initialStatusFilter;
      });
    }
  }

  void _showStatusChangeDialog(OrderModel order) {
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
              order,
              "NEW",
              Icons.note_add_rounded,
              Colors.purple,
            ),
            _buildStatusOption(
              ctx,
              order,
              "PROCESS",
              Icons.pending_outlined,
              Colors.orange,
            ),
            _buildStatusOption(
              ctx,
              order,
              "APPROVED",
              Icons.check_circle_rounded,
              Colors.green,
            ),
            _buildStatusOption(
              ctx,
              order,
              "REFUSED",
              Icons.cancel_rounded,
              Colors.red,
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
    OrderModel order,
    String status,
    IconData icon,
    Color color,
  ) {
    final isSelected = order.status == status;
    return GestureDetector(
      onTap: () async {
        await DatabaseService().updateOrderStatus(order.id, status);
        if (ctx.mounted) Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppTheme.textGrey,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final isAdmin = user?.role == 'Admin';
    final filterEmail = isAdmin ? null : user?.email;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Long press on an order to change status",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        // Status Filter Row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip(
                  "ALL",
                  "ALL",
                  Icons.layers_rounded,
                  Colors.blue,
                ),
                _buildStatusFilterChip(
                  "NEW",
                  "NEW",
                  Icons.note_add_rounded,
                  Colors.purple,
                ),
                _buildStatusFilterChip(
                  "PROCESS",
                  "PROCESS",
                  Icons.pending_outlined,
                  Colors.orange,
                ),
                _buildStatusFilterChip(
                  "APPROVED",
                  "APPROVED",
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
                _buildStatusFilterChip(
                  "REFUSED",
                  "REFUSED",
                  Icons.cancel_rounded,
                  Colors.red,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: DatabaseService().getOrders(filterEmail: filterEmail),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(child: Text("No orders found"));

              var orders = snapshot.data!;

              // Apply status filter
              if (_selectedStatusFilter != "ALL") {
                orders = orders
                    .where((o) => o.status == _selectedStatusFilter)
                    .toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderListTile(
                    order: order,
                    onStatusChange: () => _showStatusChangeDialog(order),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilterChip(
    String label,
    String status,
    IconData icon,
    Color color,
  ) {
    bool isSelected = _selectedStatusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textGrey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderListTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onStatusChange;

  const _OrderListTile({required this.order, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    if (order.status == 'NEW') statusColor = Colors.purple;
    if (order.status == 'PROCESS') statusColor = Colors.orange;
    if (order.status == 'APPROVED') statusColor = Colors.green;
    if (order.status == 'REFUSED') statusColor = Colors.red;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () async {
          final customer = await DatabaseService().getCustomerById(
            order.customerId,
          );
          if (customer != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailsScreen(customer: customer),
              ),
            );
          }
        },
        onLongPress: onStatusChange,
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${DateFormat('MMM d, yyyy').format(order.createdAt)} at ${DateFormat('h:mm a').format(order.createdAt)}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
}
