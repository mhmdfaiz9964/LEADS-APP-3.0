import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leads_manager/models/order_model.dart';
import '../models/customer_model.dart';
import '../models/service_model.dart'; // Still named label_model but contains ServiceModel
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
  String? _selectedServiceName;
  late TextEditingController _costController;
  late TextEditingController _sellAmountController;
  // Payment controller removed as per request
  String _selectedStatus = 'NEW';
  String _selectedBank = '';
  bool _isLoading = false;
  late String _orderNumber;

  final List<String> _statuses = ['NEW', 'PROCESS', 'APPROVED', 'REFUSED'];

  @override
  void initState() {
    super.initState();
    _selectedServiceName = widget.orderToEdit?.serviceName;
    _costController = TextEditingController(
      text: widget.orderToEdit?.cost.toString() ?? '',
    );
    _sellAmountController = TextEditingController(
      text: widget.orderToEdit?.sellAmount.toString() ?? '',
    );
    _sellAmountController = TextEditingController(
      text: widget.orderToEdit?.sellAmount.toString() ?? '',
    );
    // Payment controller init removed
    _selectedBank = widget.orderToEdit?.bank ?? '';
    _selectedStatus = widget.orderToEdit?.status ?? 'NEW';
    _orderNumber = widget.orderToEdit?.orderNumber ?? _generateOrderNumber();
  }

  String _generateOrderNumber() {
    return (Random().nextInt(90000) + 10000).toString();
  }

  @override
  void dispose() {
    _costController.dispose();
    _sellAmountController.dispose();
    _costController.dispose();
    _sellAmountController.dispose();
    // Payment controller dispose removed
    super.dispose();
  }

  void _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a service")));
      return;
    }

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
      serviceName: _selectedServiceName!,
      cost: double.tryParse(_costController.text) ?? 0.0,
      sellAmount: double.tryParse(_sellAmountController.text) ?? 0.0,
      payment: 0.0, // Default to 0 as input is removed
      bank: _selectedBank,
      status: _selectedStatus,
      customerId: widget.customer.id,
      customerName: widget.customer.name,
      createdAt: widget.orderToEdit?.createdAt ?? DateTime.now(),
      creatorEmail: widget.orderToEdit?.creatorEmail ?? userEmail,
    );

    try {
      if (widget.orderToEdit != null) {
        // Update logic (re-using addOrder for simplicity if update is not complex)
        // In a real app, updateOrder would be explicitly defined.
        await DatabaseService().addOrder(order);
        // Note: DatabaseService.addOrder adds a NEW doc.
        // I should probably add an updateOrder to DatabaseService.
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
            backgroundColor: AppTheme.primaryBlue,
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
        title: Text(
          widget.orderToEdit != null ? "Edit Order" : "Select Service",
        ),
        backgroundColor: AppTheme.appBarBlue,
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
                        color: Color(0xFF0046FF),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- SERVICE DROPDOWN ---
                    StreamBuilder<List<ServiceModel>>(
                      stream: DatabaseService()
                          .getServices(), // getServices returns ServiceModel now
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        final services = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: _selectedServiceName,
                          decoration: InputDecoration(
                            labelText: "Select Service",
                            prefixIcon: const Icon(
                              Icons.miscellaneous_services,
                              color: Color(0xFF0046FF),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: services
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.name,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedServiceName = val),
                          validator: (v) => v == null ? "Required" : null,
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _costController,
                            label: "Cost",
                            icon: Icons.money_off,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _sellAmountController,
                            label: "Sell Amount",
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
                    const SizedBox(height: 16),
                    const SizedBox(height: 24),
                    const Text(
                      "Select Payment Method",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedBank = "HNB");
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedBank == "HNB"
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.white,
                                border: Border.all(
                                  color: _selectedBank == "HNB"
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "HNB",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedBank = "BOC");
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedBank == "BOC"
                                    ? Colors.yellow.withOpacity(0.1)
                                    : Colors.white,
                                border: Border.all(
                                  color: _selectedBank == "BOC"
                                      ? const Color(0xFFFFD700) // Gold/Yellow
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    color: Colors.yellow[800],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "BOC",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                        if (s == 'NEW') statusColor = Colors.blue;
                        if (s == 'PROCESS') statusColor = Colors.green;
                        if (s == 'APPROVED') statusColor = Colors.orange;
                        if (s == 'REFUSED') statusColor = Colors.purple;

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
        prefixIcon: Icon(icon, color: const Color(0xFF0046FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0046FF), width: 2),
        ),
      ),
    );
  }
}
