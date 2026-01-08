import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AddUserScreen extends StatefulWidget {
  final Map<String, dynamic>? userToEdit;
  const AddUserScreen({super.key, this.userToEdit});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _passwordController;
  late String _role;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final u = widget.userToEdit;
    _fullNameController = TextEditingController(text: u?['fullName'] ?? "");
    _emailController = TextEditingController(text: u?['email'] ?? "");
    _passwordController = TextEditingController();
    _role = u?['role'] ?? 'user';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
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

  void _handleSubmit() async {
    final isEditing = widget.userToEdit != null;
    if (_emailController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        (!isEditing && _passwordController.text.isEmpty)) {
      _showFeedback("Data Required", "Please fill all fields.");
      return;
    }

    setState(() => _isLoading = true);

    if (isEditing) {
      try {
        await DatabaseService().updateUserProfile(
          widget.userToEdit!['uid'],
          _emailController.text.trim(),
          _role,
          _fullNameController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        _showFeedback("Error", e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      final error = await Provider.of<AuthService>(context, listen: false)
          .createNewUser(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _role,
            fullName: _fullNameController.text.trim(),
          );

      if (mounted) {
        setState(() => _isLoading = false);
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.pop(context);
        } else {
          _showFeedback("Error", error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.userToEdit != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit User" : "New User",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildModernInput(
              "Full Name",
              Icons.person_outline,
              _fullNameController,
            ),
            _buildModernInput(
              "Email Address",
              Icons.email_outlined,
              _emailController,
              enabled: !isEditing,
            ),
            if (!isEditing)
              _buildModernInput(
                "Password",
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _role,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('Standard User'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrator'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _role = val!),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        isEditing ? "UPDATE USER" : "CREATE USER",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInput(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool enabled = true,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isPassword && _obscurePassword,
        style: GoogleFonts.outfit(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.blue[300], size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
