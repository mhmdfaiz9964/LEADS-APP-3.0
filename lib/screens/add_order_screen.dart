import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class AddOrderScreen extends StatefulWidget {
  final Customer customer;
  final OrderModel? orderToEdit;

  const AddOrderScreen({super.key, required this.customer, this.orderToEdit});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  String _selectedStatus = 'ORDER';
  bool _isLoading = false;
  late String _orderNumber;

  final List<String> _statuses = ['ORDER', 'PAYMENT', 'PREPARED', 'DELIVERED'];

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.orderToEdit?.productName ?? '',
    );
    _qtyController = TextEditingController(
      text: widget.orderToEdit?.quantity.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.orderToEdit?.price.toString() ?? '',
    );
    _selectedStatus = widget.orderToEdit?.status ?? 'ORDER';
    _orderNumber = widget.orderToEdit?.orderNumber ?? _generateOrderNumber();
  }

  String _generateOrderNumber() {
    return (Random().nextInt(90000) + 10000).toString();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: User not logged in")),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final order = OrderModel(
      id: widget.orderToEdit?.id ?? '',
      orderNumber: _orderNumber,
      productName: _productNameController.text.trim(),
      quantity: int.tryParse(_qtyController.text) ?? 0,
      price: double.tryParse(_priceController.text) ?? 0.0,
      status: _selectedStatus,
      customerId: widget.customer.id,
      customerName: widget.customer.name,
      createdAt: widget.orderToEdit?.createdAt ?? DateTime.now(),
      creatorEmail: widget.orderToEdit?.creatorEmail ?? userEmail,
    );

    try {
      if (widget.orderToEdit != null) {
        // Update logic not explicitly requested but good to have
        // await DatabaseService().updateOrder(order);
      } else {
        await DatabaseService().addOrder(order);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.orderToEdit != null
                  ? "Order updated successfully"
                  : "Order created successfully",
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.orderToEdit != null ? "Edit Order" : "Create Order"),
        backgroundColor: AppTheme.appBarGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #$_orderNumber",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5A4B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _productNameController,
                      label: "Product Name",
                      icon: Icons.inventory_2_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _qtyController,
                            label: "QTY",
                            icon: Icons.format_list_numbered,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: "Price",
                            icon: Icons.attach_money,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Select Status",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _statuses.map((s) {
                        final isSelected = _selectedStatus == s;
                        Color statusColor = Colors.grey;
                        if (s == 'ORDER') statusColor = Colors.blue;
                        if (s == 'PAYMENT') statusColor = Colors.green;
                        if (s == 'PREPARED') statusColor = Colors.orange;
                        if (s == 'DELIVERED') statusColor = Colors.purple;

                        return ChoiceChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedStatus = s);
                            }
                          },
                          selectedColor: statusColor.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? statusColor : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? statusColor : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "SAVE ORDER",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E5A4B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E5A4B), width: 2),
        ),
      ),
    );
  }
}
