import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leads_manager/services/whatsapp_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SendWhatsAppMessageScreen extends StatefulWidget {
  final String phoneNumber;
  final String recipientName;
  final String? initialText;

  const SendWhatsAppMessageScreen({
    super.key,
    required this.phoneNumber,
    required this.recipientName,
    this.initialText,
  });

  @override
  State<SendWhatsAppMessageScreen> createState() =>
      _SendWhatsAppMessageScreenState();
}

class _SendWhatsAppMessageScreenState extends State<SendWhatsAppMessageScreen> {
  late TextEditingController _messageController;
  final _imageUrlController = TextEditingController();
  bool _isSending = false;
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialText);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageUrlController.clear(); // Clear manual URL if picking from gallery
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty &&
        _imageUrlController.text.isEmpty &&
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message or an image")),
      );
      return;
    }

    setState(() => _isSending = true);
    final service = WhatsAppService();
    final auth = Provider.of<AuthService>(context, listen: false);
    final senderEmail = auth.currentUser?.email ?? 'Unknown';

    String? finalImageUrl = _imageUrlController.text.isNotEmpty
        ? _imageUrlController.text
        : null;

    if (_selectedImage != null) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });
      finalImageUrl = await service.uploadMedia(
        _selectedImage!,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );
      setState(() => _isUploading = false);
      if (finalImageUrl == null) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to upload image. Please try again."),
          ),
        );
        return;
      }
    }

    final success = await service.sendMessage(
      to: widget.phoneNumber,
      text: _messageController.text,
      imageUrl: finalImageUrl,
      senderEmail: senderEmail,
    );

    setState(() => _isSending = false);

    if (mounted) {
      if (success) {
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text("Success"),
            content: const Text("WhatsApp message sent successfully."),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send message. Please check your API key."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Recipient Header (Fixed at top)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipientName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.phoneNumber,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Chat-style display area could show existing conversation if we had it
          // For now, it's just a placeholder with some instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 16),
                Text(
                  "Craft your message and attachments below. The recipient will receive this message directly on WhatsApp.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
      bottomSheet: _buildChatDock(),
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
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
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
                          "${(_uploadProgress * 100).toInt()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: InkWell(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: _isSending ? null : _pickImage,
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
                      hintText: "Type a message...",
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
                onTap: _isSending ? null : _sendMessage,
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
                _isUploading ? "Uploading Media..." : "Sending Message...",
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
}
