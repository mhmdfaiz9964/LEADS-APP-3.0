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
              "ORDER",
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildStatusOption(
              ctx,
              order,
              "PAYMENT",
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatusOption(
              ctx,
              order,
              "PREPARED",
              Icons.inventory,
              Colors.orange,
            ),
            _buildStatusOption(
              ctx,
              order,
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
                status,
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
                  Icons.apps,
                  AppTheme.appBarGreen,
                ),
                _buildStatusFilterChip(
                  "ORDER",
                  "ORDER",
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatusFilterChip(
                  "PAYMENT",
                  "PAYMENT",
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatusFilterChip(
                  "PREPARED",
                  "PREPARED",
                  Icons.inventory,
                  Colors.orange,
                ),
                _buildStatusFilterChip(
                  "DELIVERED",
                  "DELIVERED",
                  Icons.local_shipping,
                  Colors.purple,
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
    if (order.status == 'ORDER') statusColor = Colors.blue;
    if (order.status == 'PAYMENT') statusColor = Colors.green;
    if (order.status == 'PREPARED') statusColor = Colors.orange;
    if (order.status == 'DELIVERED') statusColor = Colors.purple;

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
                  color: AppTheme.appBarGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: AppTheme.appBarGreen,
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
                      "Order #${order.orderNumber} - ${order.productName}",
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
