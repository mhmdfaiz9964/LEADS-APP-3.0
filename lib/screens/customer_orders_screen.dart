import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/models/order_model.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'add_order_screen.dart';

class CustomerOrdersScreen extends StatelessWidget {
  final Customer customer;

  const CustomerOrdersScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("${customer.name}'s Orders"),
        backgroundColor: AppTheme.appBarBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddOrderScreen(customer: customer),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: DatabaseService().getOrdersByCustomer(customer.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No orders found",
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;
  const OrderCard({super.key, required this.order});

  void _showStatusDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Update Status"),
        content: const Text("Select new status for this order."),
        actions: [
          _buildStatusAction(ctx, "NEW", Colors.purple),
          _buildStatusAction(ctx, "PROCESS", Colors.orange),
          _buildStatusAction(ctx, "APPROVED", Colors.green),
          _buildStatusAction(ctx, "REFUSED", Colors.red),
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(BuildContext ctx, String status, Color color) {
    return CupertinoDialogAction(
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: order.status == status
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onPressed: () async {
        await DatabaseService().updateOrderStatus(order.id, status);
        if (ctx.mounted) Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    if (order.status == 'NEW') statusColor = Colors.purple;
    if (order.status == 'PROCESS') statusColor = Colors.orange;
    if (order.status == 'APPROVED') statusColor = Colors.green;
    if (order.status == 'REFUSED') statusColor = Colors.red;

    return GestureDetector(
      onLongPress: () => _showStatusDialog(context),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#${order.orderNumber}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "\$${order.sellAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.serviceName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd.MM.yyyy').format(order.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Cost: \$${order.cost.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
              ),
              if (order.bank.isNotEmpty || order.payment > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (order.payment > 0)
                      Text(
                        "Paid: \$${order.payment.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (order.bank.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 16,
                            color: order.bank == 'HNB'
                                ? Colors.orange
                                : (order.bank == 'BOC'
                                      ? Colors.yellow[700]
                                      : Colors.grey),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.bank,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
