import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/models/reminder_model.dart';
import 'package:leads_manager/models/note_model.dart';
import 'package:leads_manager/models/label_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:leads_manager/screens/add_reminder_screen.dart';
import 'package:leads_manager/screens/select_lead_labels_screen.dart';
import 'package:leads_manager/screens/reminders_list_screen.dart';
import 'package:leads_manager/screens/notes_screen.dart';

class LeadDetailsScreen extends StatefulWidget {
  final Lead lead;
  const LeadDetailsScreen({super.key, required this.lead});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps(String address) async {
    if (address.isEmpty) return;

    final String encodedAddress = Uri.encodeComponent(address);
    // Try geo scheme first for native Android performance
    final Uri geoUri = Uri.parse("geo:0,0?q=$encodedAddress");
    final Uri httpsUri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$encodedAddress",
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(httpsUri)) {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      } else {
        // Direct launch attempt if canLaunchUrl fails (sometimes happens on certain Android builds)
        await launchUrl(
          httpsUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      }
    } catch (e) {
      debugPrint("Error launching maps: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leads')
          .doc(widget.lead.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        final lead = Lead.fromFirestore(snapshot.data!);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: AppTheme.appBarGreen,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  color: AppTheme.appBarGreen,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lead.name,
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildHeaderAction(
                            Icons.call,
                            "Call",
                            () => _makePhoneCall(lead.phone),
                          ),
                          _buildHeaderAction(
                            Icons.chat_bubble,
                            "Message",
                            () => _sendMessage(lead.phone),
                          ),
                          _buildHeaderAction(
                            Icons.email,
                            "Email",
                            () => _sendEmail(lead.email),
                          ),
                          _buildHeaderAction(
                            Icons.location_on,
                            "Navigate",
                            () => _openMaps(lead.address),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dashboard Cards
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildDashboardCard(
                        icon: Icons.label,
                        color: const Color(0xFF3498DB),
                        title: "ADD LABELS",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectLeadLabelsScreen(lead: lead),
                          ),
                        ),
                        trailing: _buildLabelChips(lead.labelIds),
                      ),
                      const SizedBox(height: 8),
                      _buildDashboardCard(
                        icon: Icons.notifications,
                        color: const Color(0xFFC0392B),
                        title: "REMINDERS",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RemindersListScreen(
                              targetId: lead.id,
                              targetType: 'LEAD',
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFFC0392B),
                            size: 28,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddReminderScreen(
                                targetId: lead.id,
                                targetType: 'LEAD',
                              ),
                            ),
                          ),
                        ),
                        subtitleStream: DatabaseService().getRemindersByTarget(
                          lead.id,
                          'LEAD',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDashboardCard(
                        icon: Icons.edit_note,
                        color: const Color(0xFFF1C40F),
                        title: "ADD NOTES",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotesScreen(
                              targetId: lead.id,
                              targetType: 'LEAD',
                              targetName: lead.name,
                            ),
                          ),
                        ),
                        isNotes: true,
                        subtitleStream: DatabaseService().getNotesByTarget(
                          lead.id,
                          'LEAD',
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        "+ ${DateFormat('MMM d, h:mm a').format(lead.createdAt)}",
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFB37424),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Stream? subtitleStream,
    bool isNotes = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 85),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isNotes
                              ? Colors.grey[400]
                              : const Color(0xFFB37424),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        Expanded(child: trailing),
                      ],
                    ],
                  ),
                  if (subtitleStream != null)
                    StreamBuilder(
                      stream: subtitleStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData ||
                            (snapshot.data as List).isEmpty)
                          return const SizedBox.shrink();
                        final items = (snapshot.data as List);

                        if (isNotes) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...items.take(5).map((item) {
                                final note = item as Note;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'MMM d, yyyy',
                                        ).format(note.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        note.content,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Divider(
                                        height: 1,
                                        color: Colors.grey.withOpacity(0.1),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (items.length > 5)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4, bottom: 8),
                                  child: Text(
                                    "See all notes...",
                                    style: TextStyle(
                                      color: Color(0xFFB37424),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }

                        if (items.isNotEmpty && items.first is Reminder) {
                          final reminder = items.first as Reminder;
                          final now = DateTime.now();
                          final isDue = now.isAfter(reminder.date);
                          final color = isDue ? Colors.red : Colors.green;

                          String timeText;
                          if (isDue) {
                            final diff = now.difference(reminder.date);
                            if (diff.inDays > 0) {
                              timeText = "Due ${diff.inDays}d ago";
                            } else if (diff.inHours > 0) {
                              timeText = "Due ${diff.inHours}h ago";
                            } else {
                              timeText = "Due ${diff.inMinutes}m ago";
                            }
                          } else {
                            timeText = DateFormat(
                              'MMM d, h:mm a',
                            ).format(reminder.date);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.alarm, size: 14, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reminder.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          timeText,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (items.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 22,
                                  ),
                                  child: Text(
                                    "+ ${items.length - 1} more reminders...",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }

                        // Fallback/Legacy logic (should not be reached if proper types)
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChips(List<String> labelIds) {
    if (labelIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<LabelModel>>(
      future: DatabaseService().getLabels().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final selectedLabels = snapshot.data!
            .where((l) => labelIds.contains(l.id))
            .toList();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: selectedLabels
              .map(
                (l) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: l.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
