import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../models/service_model.dart';
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddServiceScreen extends StatefulWidget {
  final ServiceModel? serviceToEdit;
  const AddServiceScreen({super.key, this.serviceToEdit});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  bool _isLoading = false;

  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.serviceToEdit?.name ?? "",
    );
    _selectedColor = widget.serviceToEdit != null
        ? widget.serviceToEdit!.color
        : Colors.black;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  void _saveService() async {
    if (_nameController.text.isEmpty) {
      _showFeedback("Error", "Service name cannot be empty.");
      return;
    }

    setState(() => _isLoading = true);
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      setState(() => _isLoading = false);
      _showFeedback("Error", "Authentication error.");
      return;
    }

    final service = ServiceModel(
      id: widget.serviceToEdit?.id ?? '',
      name: _nameController.text.toUpperCase(),
      colorValue: _selectedColor.value,
      creatorEmail: widget.serviceToEdit?.creatorEmail ?? userEmail,
    );

    try {
      if (widget.serviceToEdit != null) {
        await DatabaseService().updateService(service);
      } else {
        await DatabaseService().addService(service);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.serviceToEdit != null
                  ? "Service updated"
                  : "Service created",
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryBlue,
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
    final isEditing = widget.serviceToEdit != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarBlue,
        title: Text(
          isEditing ? "Edit Service" : "Add Service",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "New Service Name",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.secondaryOrange),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.secondaryOrange,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Choose Color",
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(
                          color: AppTheme.secondaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _isLoading ? null : _saveService,
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          color: AppTheme.secondaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
