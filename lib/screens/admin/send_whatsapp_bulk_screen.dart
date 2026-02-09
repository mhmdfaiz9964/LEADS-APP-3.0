import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leads_manager/models/customer_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/services/whatsapp_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/models/service_model.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SendWhatsAppBulkScreen extends StatefulWidget {
  const SendWhatsAppBulkScreen({super.key});

  @override
  State<SendWhatsAppBulkScreen> createState() => _SendWhatsAppBulkScreenState();
}

class _SendWhatsAppBulkScreenState extends State<SendWhatsAppBulkScreen> {
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final Set<String> _selectedCustomerIds = {};
  bool _isSending = false;
  List<Customer> _allCustomers = [];
  bool _isLoadingCustomers = true;
  List<File> _selectedImages = [];
  bool _isUploading = false;
  Map<int, double> _uploadProgressMap = {};
  final _picker = ImagePicker();

  List<ServiceModel> _allServices = [];
  String? _selectedServiceId;
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await DatabaseService().getCustomers().first;
    final services = await DatabaseService().getServices().first;
    setState(() {
      _allCustomers = customers;
      _filteredCustomers = customers;
      _allServices = services;
      _isLoadingCustomers = false;
    });
  }

  void _filterCustomers(String? serviceId) {
    setState(() {
      _selectedServiceId = serviceId;
      if (serviceId == null) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers
            .where((c) => c.serviceIds.contains(serviceId))
            .toList();
      }
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _sendBulk() async {
    if (_selectedCustomerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one customer")),
      );
      return;
    }
    if (_messageController.text.isEmpty &&
        _imageUrlController.text.isEmpty &&
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a message or select images"),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final service = WhatsAppService();
    final auth = Provider.of<AuthService>(context, listen: false);
    final senderEmail = auth.currentUser?.email ?? 'Unknown';

    List<String> imageUrls = _imageUrlController.text.isNotEmpty
        ? [_imageUrlController.text]
        : [];

    if (_selectedImages.isNotEmpty) {
      setState(() {
        _isUploading = true;
        _uploadProgressMap.clear();
      });

      for (int i = 0; i < _selectedImages.length; i++) {
        final url = await service.uploadMedia(
          _selectedImages[i],
          onProgress: (progress) {
            setState(() => _uploadProgressMap[i] = progress);
          },
        );
        if (url != null) imageUrls.add(url);
      }

      setState(() => _isUploading = false);
    }

    int successCount = 0;
    int failCount = 0;
    int currentRecipientIndex = 0;

    for (var customerId in _selectedCustomerIds) {
      final customer = _allCustomers.firstWhere((c) => c.id == customerId);
      currentRecipientIndex++;

      // Implement 6-second delay for account protection
      if (currentRecipientIndex > 1) {
        await Future.delayed(const Duration(seconds: 6));
      }

      // Send text message
      if (_messageController.text.isNotEmpty) {
        final success = await service.sendMessage(
          to: customer.phone,
          text: _messageController.text,
          senderEmail: senderEmail,
        );
        if (success)
          successCount++;
        else
          failCount++;

        // Brief delay between text and images if needed
        if (imageUrls.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      // Send each image as a separate message
      for (int imgIndex = 0; imgIndex < imageUrls.length; imgIndex++) {
        final success = await service.sendMessage(
          to: customer.phone,
          text: "", // Just the image
          imageUrl: imageUrls[imgIndex],
          senderEmail: senderEmail,
        );
        if (success)
          successCount++;
        else
          failCount++;

        // Delay between images
        if (imgIndex < imageUrls.length - 1) {
          await Future.delayed(const Duration(seconds: 6));
        }
      }
    }

    setState(() => _isSending = false);

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Bulk Send Complete"),
          content: Text(
            "Successfully sent $successCount messages.\nFailed: $failCount messages.",
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Bulk WhatsApp",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingCustomers
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                // Step 1: Select Customers (Scrollable Area)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SELECT RECIPIENTS",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Service Filtering Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text(
                                  "All",
                                  style: GoogleFonts.outfit(fontSize: 13),
                                ),
                                selected: _selectedServiceId == null,
                                onSelected: (val) => _filterCustomers(null),
                                backgroundColor: Colors.white,
                                selectedColor: AppTheme.primaryBlue.withOpacity(
                                  0.1,
                                ),
                                labelStyle: TextStyle(
                                  color: _selectedServiceId == null
                                      ? AppTheme.primaryBlue
                                      : Colors.black,
                                  fontWeight: _selectedServiceId == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ..._allServices.map((service) {
                                final isSelected =
                                    _selectedServiceId == service.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      service.name,
                                      style: GoogleFonts.outfit(fontSize: 13),
                                    ),
                                    selected: isSelected,
                                    onSelected: (val) => _filterCustomers(
                                      val ? service.id : null,
                                    ),
                                    backgroundColor: Colors.white,
                                    selectedColor: AppTheme.primaryBlue
                                        .withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ListView.builder(
                            itemCount: _filteredCustomers.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              final isSelected = _selectedCustomerIds.contains(
                                customer.id,
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedCustomerIds.add(customer.id);
                                    } else {
                                      _selectedCustomerIds.remove(customer.id);
                                    }
                                  });
                                },
                                title: Text(
                                  customer.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  customer.phone,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                activeColor: AppTheme.primaryBlue,
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCustomerIds.addAll(
                                    _filteredCustomers.map((c) => c.id),
                                  );
                                });
                              },
                              child: Text(
                                "Select Filtered",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCustomerIds.clear();
                                });
                              },
                              child: Text(
                                "Deselect All",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 120), // Space for the dock
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomSheet: _buildChatDock(),
      floatingActionButton: _selectedCustomerIds.isNotEmpty && !_isSending
          ? Padding(
              padding: const EdgeInsets.only(bottom: 140),
              child: _buildSelectionSummary(),
            )
          : null,
    );
  }

  Widget _buildChatDock() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                padding: const EdgeInsets.only(bottom: 12),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                            colorFilter: _isUploading
                                ? ColorFilter.mode(
                                    Colors.black.withOpacity(0.5),
                                    BlendMode.darken,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              "${((_uploadProgressMap[index] ?? 0) * 100).toInt()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: -2,
                        right: 4,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedImages.removeAt(index)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: _isSending ? null : _pickImages,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: "Type a broadcast message...",
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending ? null : _sendBulk,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isSending
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 10,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
          if (_isSending)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _isUploading
                    ? "Uploading Media..."
                    : "Broadcasting to Recipients...",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            "${_selectedCustomerIds.length} Selected",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
