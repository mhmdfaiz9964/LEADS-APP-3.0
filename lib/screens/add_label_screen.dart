import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../../models/label_model.dart';
import '../../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddLabelScreen extends StatefulWidget {
  final LabelModel? labelToEdit;
  const AddLabelScreen({super.key, this.labelToEdit});

  @override
  State<AddLabelScreen> createState() => _AddLabelScreenState();
}

class _AddLabelScreenState extends State<AddLabelScreen> {
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
      text: widget.labelToEdit?.name ?? "",
    );
    _selectedColor = widget.labelToEdit != null
        ? widget.labelToEdit!.color
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

  void _saveLabel() async {
    if (_nameController.text.isEmpty) {
      _showFeedback("Error", "Label name cannot be empty.");
      return;
    }

    setState(() => _isLoading = true);
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      setState(() => _isLoading = false);
      _showFeedback("Error", "Authentication error.");
      return;
    }

    final label = LabelModel(
      id: widget.labelToEdit?.id ?? '',
      name: _nameController.text.toUpperCase(),
      colorValue: _selectedColor.value,
      creatorEmail: widget.labelToEdit?.creatorEmail ?? userEmail,
    );

    try {
      if (widget.labelToEdit != null) {
        await DatabaseService().updateLabel(label);
      } else {
        await DatabaseService().addLabel(label);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.labelToEdit != null ? "Label updated" : "Label created",
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
    final isEditing = widget.labelToEdit != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarGreen,
        title: Text(
          isEditing ? "Edit Label" : "Add Label",
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
                  labelText: "New Label Name",
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
              Row(
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
                    onPressed: _isLoading ? null : _saveLabel,
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
            ],
          ),
        ),
      ),
    );
  }
}
