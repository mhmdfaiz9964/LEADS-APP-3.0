import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/models/service_model.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddLeadScreen extends StatefulWidget {
  final Lead? leadToEdit;
  const AddLeadScreen({super.key, this.leadToEdit});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  late TextEditingController _nameController;
  late TextEditingController _agentNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _passportNumberController;
  DateTime? _selectedDob;
  late TextEditingController _dobController;

  bool _isLoading = false;
  String? _selectedServiceId;

  @override
  void initState() {
    super.initState();
    final lead = widget.leadToEdit;
    _nameController = TextEditingController(text: lead?.name ?? "");
    _agentNameController = TextEditingController(text: lead?.agentName ?? "");
    _phoneController = TextEditingController(text: lead?.phone ?? "");
    _emailController = TextEditingController(text: lead?.email ?? "");
    _addressController = TextEditingController(text: lead?.address ?? "");
    _notesController = TextEditingController(text: lead?.notes ?? "");
    _passportNumberController = TextEditingController(
      text: lead?.passportNumber ?? "",
    );
    _selectedDob = lead?.dob;
    _dobController = TextEditingController(
      text: lead?.dob != null ? lead!.dob!.toIso8601String().split('T')[0] : "",
    );
    _selectedServiceId = (lead?.serviceIds.isNotEmpty ?? false)
        ? lead!.serviceIds.first
        : null;
    if (_selectedServiceId != null && _selectedServiceId!.isEmpty) {
      _selectedServiceId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _agentNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _passportNumberController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _showFeedback(String title, String message, {bool isError = false}) {
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

  void _saveLead() async {
    if (_nameController.text.isEmpty) {
      _showFeedback("Required Fields", "Please enter the Name.");
      return;
    }

    setState(() => _isLoading = true);

    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null || userEmail.isEmpty) {
      setState(() => _isLoading = false);
      _showFeedback(
        "Error",
        "User session expired. Please log in again.",
        isError: true,
      );
      return;
    }

    final lead = Lead(
      id: widget.leadToEdit?.id ?? '',
      name: _nameController.text,
      agentName: _agentNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      notes: _notesController.text,
      status: widget.leadToEdit?.status,
      serviceIds: _selectedServiceId != null ? [_selectedServiceId!] : [],
      createdAt: widget.leadToEdit?.createdAt ?? DateTime.now(),
      creatorEmail: widget.leadToEdit?.creatorEmail ?? userEmail,
      passportNumber: _passportNumberController.text,
      dob: _selectedDob,
    );

    try {
      if (widget.leadToEdit != null) {
        await DatabaseService().updateLead(lead);
      } else {
        await DatabaseService().addLead(lead);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.leadToEdit != null ? "Lead updated!" : "Lead saved!",
            ),
            backgroundColor: AppTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showFeedback("Error", e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.leadToEdit != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBlue,
        title: Text(isEditing ? "Edit Lead" : "Add New Lead"),
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
                _buildField(Icons.person, "Lead Name", _nameController),
                _buildField(
                  Icons.person_outline,
                  "Agent Name",
                  _agentNameController,
                ),
                _buildField(
                  Icons.assignment_ind_outlined,
                  "Passport Number",
                  _passportNumberController,
                ),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDob ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDob = date;
                        _dobController.text = date.toIso8601String().split(
                          'T',
                        )[0];
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: _buildField(
                      Icons.calendar_today,
                      "Date of Birth",
                      _dobController,
                    ),
                  ),
                ),
                _buildField(Icons.phone, "Phone Number", _phoneController),
                _buildField(
                  Icons.alternate_email,
                  "Email Address",
                  _emailController,
                ),
                _buildField(Icons.location_on, "Address", _addressController),
                _buildField(
                  Icons.notes,
                  "Notes",
                  _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Classification",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                _buildServicePicker(),
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
                    onPressed: _isLoading ? null : _saveLead,
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
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF0046FF), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePicker() {
    return StreamBuilder<List<ServiceModel>>(
      stream: DatabaseService()
          .getServices(), // Show all labels or filter as needed
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading services");
        if (!snapshot.hasData) return const SizedBox();
        final services = snapshot.data!;
        if (services.isEmpty)
          return const Text("No services found. Create services first.");
        return Container(
          margin: const EdgeInsets.only(top: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (services.any((l) => l.id == _selectedServiceId))
                  ? _selectedServiceId
                  : null,
              isExpanded: true,
              hint: const Text(
                "Select Service",
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              items: services.map((l) {
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
              onChanged: (val) => setState(() => _selectedServiceId = val),
            ),
          ),
        );
      },
    );
  }
}
