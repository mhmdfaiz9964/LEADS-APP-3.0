import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:leads_manager/theme/app_theme.dart';
import 'package:leads_manager/models/lead_model.dart';
import 'package:leads_manager/models/label_model.dart';
import 'package:leads_manager/services/database_service.dart';
import 'package:leads_manager/services/auth_service.dart';
import 'package:leads_manager/screens/lead_details_screen.dart';
import 'package:leads_manager/screens/add_lead_screen.dart';
import 'package:leads_manager/screens/label_details_screen.dart';
import 'package:provider/provider.dart';

class LeadsScreen extends StatefulWidget {
  final String searchQuery;
  const LeadsScreen({this.searchQuery = "", super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  void _confirmMoveToCustomer(BuildContext context, Lead lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.add, color: Colors.orange, size: 48),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Move 1 leads to customers list?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().moveLeadToCustomer(lead);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Moved to Customers")),
                );
              }
            },
            child: const Text(
              "MOVE TO CUSTOMERS LIST",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Lead lead) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Delete Lead"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await DatabaseService().deleteLead(lead.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final isAdmin = user?.role == 'admin';
    final filterEmail = isAdmin ? null : user?.email;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Tap and hold on a record for more options",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Lead>>(
            stream: DatabaseService().getLeads(filterEmail: filterEmail),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Center(child: Text("Error: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(child: Text("No leads found"));

              var leads = snapshot.data!;
              if (widget.searchQuery.isNotEmpty) {
                final query = widget.searchQuery.toLowerCase();
                leads = leads
                    .where(
                      (l) =>
                          l.name.toLowerCase().contains(query) ||
                          l.company.toLowerCase().contains(query),
                    )
                    .toList();
              }

              leads.sort((a, b) {
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                return b.createdAt.compareTo(a.createdAt);
              });

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 100),
                itemCount: leads.length,
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  final now = DateTime.now();
                  final diff = now.difference(lead.createdAt);
                  String timeStr = "";
                  if (diff.inMinutes < 60) {
                    timeStr =
                        "+ ${diff.inMinutes} min. ago, ${DateFormat('h:mm a').format(lead.createdAt)}";
                  } else {
                    timeStr =
                        "${DateFormat('MMM d').format(lead.createdAt)}, ${DateFormat('h:mm a').format(lead.createdAt)}";
                  }
                  return LeadCard(
                    lead: lead,
                    timeStr: timeStr,
                    onMove: () => _confirmMoveToCustomer(context, lead),
                    onDelete: () => _confirmDelete(context, lead),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class LeadCard extends StatefulWidget {
  final Lead lead;
  final String timeStr;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const LeadCard({
    super.key,
    required this.lead,
    required this.timeStr,
    required this.onDelete,
    required this.onMove,
  });

  @override
  State<LeadCard> createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  bool _isExpanded = false;

  void _showLeadOptions(BuildContext context, Lead lead) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(lead.name),
        message: Text(lead.company),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadDetailsScreen(lead: lead),
                ),
              );
            },
            child: const Text('View Details'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddLeadScreen(leadToEdit: lead),
                ),
              );
            },
            child: const Text('Edit Lead'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onMove();
            },
            child: const Text('Move to Customer'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Delete Lead'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeadDetailsScreen(lead: widget.lead),
          ),
        ),
        onLongPress: () => _showLeadOptions(context, widget.lead),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.track_changes,
                    color: Color(0xFF2E5A4B),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.lead.name} (${widget.lead.company})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildLabelBadge(widget.lead.labelIds),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              await DatabaseService().toggleLeadPin(
                                widget.lead.id,
                                widget.lead.isPinned,
                              );
                            },
                            child: Icon(
                              widget.lead.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: widget.lead.isPinned
                                  ? AppTheme.secondaryOrange
                                  : Colors.grey[300],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 48),
                      _buildInlineAction(
                        Icons.edit_outlined,
                        "Edit",
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddLeadScreen(leadToEdit: widget.lead),
                            ),
                          );
                        },
                      ),
                      _buildInlineAction(
                        Icons.add_circle_outline,
                        "Customer",
                        Colors.green,
                        widget.onMove,
                      ),
                      _buildInlineAction(
                        Icons.visibility_off_outlined,
                        "Hide",
                        Colors.orange,
                        () {},
                      ),
                      _buildInlineAction(
                        Icons.delete_outline,
                        "Delete",
                        Colors.red,
                        widget.onDelete,
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelBadge(List<String> labelIds) {
    if (labelIds.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<LabelModel>>(
      future: DatabaseService().getLabels().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final selectedLabels = snapshot.data!
            .where((l) => labelIds.contains(l.id))
            .toList();
        if (selectedLabels.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: selectedLabels
              .map(
                (label) => InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LabelDetailsScreen(label: label),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: label.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildInlineAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, style: TextStyle(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
