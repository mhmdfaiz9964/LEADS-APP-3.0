import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/models/customer_model.dart';
import 'package:leads_manager/models/label_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customerToEdit;
  const AddCustomerScreen({super.key, this.customerToEdit});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _planController;
  String _selectedLabelId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customerToEdit;
    _nameController = TextEditingController(text: c?.name ?? "");
    _companyController = TextEditingController(text: c?.company ?? "");
    _phoneController = TextEditingController(text: c?.phone ?? "");
    _emailController = TextEditingController(text: c?.email ?? "");
    _addressController = TextEditingController(text: c?.address ?? "");
    _notesController = TextEditingController(text: c?.notes ?? "");
    _planController = TextEditingController(text: c?.plan ?? "Standard");
    _selectedLabelId = (c?.labelIds.isNotEmpty ?? false)
        ? c!.labelIds.first
        : "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _planController.dispose();
    super.dispose();
  }

  void _showFeedback(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _saveCustomer() async {
    if (_nameController.text.isEmpty) {
      _showFeedback("Missing Info", "Name is required.");
      return;
    }

    setState(() => _isLoading = true);
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null || userEmail.isEmpty) {
      setState(() => _isLoading = false);
      _showFeedback("Error", "Session expired. Please re-login.");
      return;
    }

    final customer = Customer(
      id: widget.customerToEdit?.id ?? '',
      name: _nameController.text,
      company: _companyController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      notes: _notesController.text,
      plan: _planController.text,
      labelIds: _selectedLabelId.isNotEmpty ? [_selectedLabelId] : [],
      status: widget.customerToEdit?.status,
      createdAt: widget.customerToEdit?.createdAt ?? DateTime.now(),
      creatorEmail: widget.customerToEdit?.creatorEmail ?? userEmail,
    );

    try {
      if (widget.customerToEdit != null) {
        await DatabaseService().updateCustomer(customer);
      } else {
        await DatabaseService().addCustomer(customer);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customerToEdit != null
                  ? "Customer updated"
                  : "Customer created",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showFeedback("Error", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerToEdit != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarGreen,
        title: Text(isEditing ? "Edit Customer" : "Add New Customer"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildField(Icons.person, "Customer Name", _nameController),
                _buildField(Icons.business, "Company", _companyController),
                _buildField(Icons.phone, "Phone Number", _phoneController),
                _buildField(
                  Icons.alternate_email,
                  "Email Address",
                  _emailController,
                ),
                _buildField(
                  Icons.location_on,
                  "Office Address",
                  _addressController,
                ),
                _buildField(Icons.notes, "Additional Notes", _notesController),
                _buildLabelDropdown(),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "OK",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    IconData icon,
    String hint,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E5A4B), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.label_outline, color: Color(0xFF2E5A4B), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: StreamBuilder<List<LabelModel>>(
              stream: DatabaseService().getLabels(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Text("Error loading labels");
                if (!snapshot.hasData) return const SizedBox.shrink();
                final labels = snapshot.data!;
                if (labels.isEmpty)
                  return const Text("No labels found. Create one first.");
                return DropdownButtonFormField<String>(
                  value: (labels.any((l) => l.id == _selectedLabelId))
                      ? _selectedLabelId
                      : null,
                  decoration: const InputDecoration(
                    hintText: "Select Label",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  items: labels.map((l) {
                    return DropdownMenuItem(
                      value: l.id,
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: l.color, size: 12),
                          const SizedBox(width: 12),
                          Text(l.name, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedLabelId = val ?? '');
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
